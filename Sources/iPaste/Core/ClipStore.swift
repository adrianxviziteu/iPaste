import AppKit
import Combine
import CryptoKit
import Foundation
import UserNotifications

/// The source of truth for the history. Holds clips in memory, persists them as
/// JSON, and keeps images as separate files alongside it.
@MainActor
final class ClipStore: ObservableObject {
    @Published private(set) var clips: [Clip] = []
    @Published var categories: [String] = []

    /// How many unpinned clips to keep. Pinned ones are never trimmed.
    var historyLimit = 500

    private let directory: URL
    private let imagesDirectory: URL
    private let databaseURL: URL
    private var saveTask: Task<Void, Never>?
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private var cloudDirectory: URL?

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("iPaste", isDirectory: true)

        self.directory = base
        self.imagesDirectory = base.appendingPathComponent("Images", isDirectory: true)
        self.databaseURL = base.appendingPathComponent("history.json")

        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Reading

    /// Pinned first, then newest to oldest.
    var orderedClips: [Clip] {
        clips.sorted { lhs, rhs in
            if lhs.pinned != rhs.pinned { return lhs.pinned }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func clips(matching query: String, kind: ClipKind? = nil, category: String? = nil) -> [Clip] {
        var result = orderedClips
        if let kind { result = result.filter { $0.kind == kind } }
        if let category { result = result.filter { $0.category == category } }

        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return result }

        // Every word has to appear somewhere — searching "json api" finds both.
        let terms = needle.split(separator: " ").map(String.init)
        return result.filter { clip in
            let haystack = clip.searchHaystack
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    func clip(withShortcut shortcut: String) -> Clip? {
        clips.first { $0.shortcut == shortcut }
    }

    // MARK: - Writing

    /// Adds a clip. If the same content is already stored, it moves back to the
    /// top of the list instead of being duplicated.
    @discardableResult
    func insert(_ clip: Clip) -> Clip {
        if let index = clips.firstIndex(where: { $0.fingerprint == clip.fingerprint }) {
            var existing = clips[index]
            existing.createdAt = clip.createdAt
            existing.sourceAppName = clip.sourceAppName ?? existing.sourceAppName
            existing.sourceBundleID = clip.sourceBundleID ?? existing.sourceBundleID
            clips[index] = existing
            scheduleSave()
            return existing
        }

        clips.append(clip)
        trimHistory()
        scheduleSave()
        return clip
    }

    func delete(_ clip: Clip) {
        clips.removeAll { $0.id == clip.id }
        removeImageFile(for: clip)
        cancelReminderNotification(for: clip)
        scheduleSave()
    }

    func togglePin(_ clip: Clip) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].pinned.toggle()
        scheduleSave()
    }

    func updateText(_ text: String, for clip: Clip) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = clips.firstIndex(where: { $0.id == clip.id }),
              ![ClipKind.image, .file, .multi].contains(clips[index].kind)
        else { return }

        clips[index].text = text
        clips[index].fingerprint = SHA256.hash(data: Data(text.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        scheduleSave()
    }

    // MARK: - Collections

    /// Adds a collection. Returns `false` if the name is empty or already taken.
    @discardableResult
    func addCategory(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Compared without case or diacritics: "Templates" and "templates" are
        // the same collection to a person, so they should be to us.
        guard !categories.contains(where: { $0.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame })
        else { return false }

        categories.append(trimmed)
        scheduleSave()
        return true
    }

    /// Deletes the collection and empties it — the clips stay in the history.
    func removeCategory(_ name: String) {
        categories.removeAll { $0 == name }
        for index in clips.indices where clips[index].category == name {
            clips[index].category = nil
        }
        scheduleSave()
    }

    @discardableResult
    func renameCategory(_ old: String, to new: String) -> Bool {
        let trimmed = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != old else { return false }
        guard let index = categories.firstIndex(of: old) else { return false }
        guard !categories.contains(trimmed) else { return false }

        categories[index] = trimmed
        for i in clips.indices where clips[i].category == old {
            clips[i].category = trimmed
        }
        scheduleSave()
        return true
    }

    func count(inCategory category: String?) -> Int {
        guard let category else { return clips.count }
        return clips.count { $0.category == category }
    }

    func setCategory(_ category: String?, for clip: Clip) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].category = category
        if let category, !categories.contains(category) { categories.append(category) }
        scheduleSave()
    }

    func setOCRText(_ text: String?, for clipID: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == clipID }) else { return }
        clips[index].ocrText = text
        scheduleSave()
    }

    func setReminder(_ reminder: ClipReminder?, for clip: Clip) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].reminder = reminder
        scheduleSave()
    }

    /// Removes everything that isn't pinned.
    func clearHistory() {
        let removed = clips.filter { !$0.pinned }
        clips.removeAll { !$0.pinned }
        removed.forEach {
            removeImageFile(for: $0)
            cancelReminderNotification(for: $0)
        }
        scheduleSave()
    }

    /// Removes unpinned clips older than the requested number of days. A zero
    /// value disables expiry. Returns the number of removed clips so callers
    /// can decide whether to refresh any UI or show feedback.
    @discardableResult
    func removeExpiredClips(olderThanDays days: Int, now: Date = Date()) -> Int {
        guard days > 0 else { return 0 }
        let cutoff = now.addingTimeInterval(-TimeInterval(days) * 86_400)
        let removed = clips.filter { !$0.pinned && $0.createdAt < cutoff }
        guard !removed.isEmpty else { return 0 }

        clips.removeAll { clip in removed.contains { $0.id == clip.id } }
        removed.forEach {
            removeImageFile(for: $0)
            cancelReminderNotification(for: $0)
        }
        scheduleSave()
        return removed.count
    }

    // MARK: - Images

    func storeImage(_ image: NSImage) -> String? {
        ensureDirectories()
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        let filename = "\(UUID().uuidString).png"
        do {
            try png.write(to: imagesDirectory.appendingPathComponent(filename))
            return filename
        } catch {
            NSLog("iPaste: could not save image — \(error.localizedDescription)")
            return nil
        }
    }

    func imageURL(for clip: Clip) -> URL? {
        clip.imageFilename.map { imagesDirectory.appendingPathComponent($0) }
    }

    func image(for clip: Clip) -> NSImage? {
        guard let filename = clip.imageFilename else { return nil }
        if let cached = thumbnailCache.object(forKey: filename as NSString) { return cached }
        guard let image = NSImage(contentsOf: imagesDirectory.appendingPathComponent(filename)) else { return nil }
        thumbnailCache.setObject(image, forKey: filename as NSString)
        return image
    }

    private func removeImageFile(for clip: Clip) {
        guard let url = imageURL(for: clip) else { return }
        thumbnailCache.removeObject(forKey: (clip.imageFilename ?? "") as NSString)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Persistence

    private func trimHistory() {
        let unpinned = clips.filter { !$0.pinned }.sorted { $0.createdAt > $1.createdAt }
        guard unpinned.count > historyLimit else { return }
        for old in unpinned.dropFirst(historyLimit) {
            clips.removeAll { $0.id == old.id }
            removeImageFile(for: old)
            cancelReminderNotification(for: old)
        }
    }

    private func cancelReminderNotification(for clip: Clip) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["clip-reminder-\(clip.id.uuidString)"]
        )
    }

    /// Saving is debounced: copying rapidly shouldn't rewrite the file dozens of times.
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }

    func save() {
        ensureDirectories()
        let snapshot = Database(clips: clips, categories: categories)
        let url = databaseURL
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: .atomic)
            saveCloudSnapshot(data: data)
        } catch {
            NSLog("iPaste: saving history failed — \(error.localizedDescription)")
        }
    }

    // MARK: - iCloud snapshot

    func enableICloudSync(at directory: URL) throws {
        cloudDirectory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: directory.appendingPathComponent("Images", isDirectory: true),
            withIntermediateDirectories: true
        )
        try mergeICloudSnapshot()
        save()
    }

    func disableICloudSync() {
        cloudDirectory = nil
    }

    /// Pulls a downloaded iCloud snapshot and merges it without replacing newer
    /// local copies. Fingerprints are stable across Macs, unlike local file paths.
    func mergeICloudSnapshot() throws {
        guard let cloudDirectory else { return }
        let cloudDatabase = cloudDirectory.appendingPathComponent("history.json")
        guard let data = try? Data(contentsOf: cloudDatabase) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let remote = try decoder.decode(Database.self, from: data)
        let cloudImages = cloudDirectory.appendingPathComponent("Images", isDirectory: true)

        for remoteClip in remote.clips {
            if let localIndex = clips.firstIndex(where: { $0.fingerprint == remoteClip.fingerprint }) {
                if remoteClip.createdAt > clips[localIndex].createdAt {
                    clips[localIndex] = remoteClip
                }
            } else {
                clips.append(remoteClip)
            }

            if let filename = remoteClip.imageFilename {
                let localURL = imagesDirectory.appendingPathComponent(filename)
                let cloudURL = cloudImages.appendingPathComponent(filename)
                if !FileManager.default.fileExists(atPath: localURL.path),
                   FileManager.default.fileExists(atPath: cloudURL.path) {
                    try? FileManager.default.copyItem(at: cloudURL, to: localURL)
                }
            }
        }

        categories = Array(Set(categories).union(remote.categories)).sorted()
        trimHistory()
        save()
    }

    private func saveCloudSnapshot(data: Data) {
        guard let cloudDirectory else { return }
        let cloudDatabase = cloudDirectory.appendingPathComponent("history.json")
        let cloudImages = cloudDirectory.appendingPathComponent("Images", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: cloudImages, withIntermediateDirectories: true)
            try data.write(to: cloudDatabase, options: .atomic)

            for clip in clips {
                guard let filename = clip.imageFilename else { continue }
                let localURL = imagesDirectory.appendingPathComponent(filename)
                let cloudURL = cloudImages.appendingPathComponent(filename)
                guard FileManager.default.fileExists(atPath: localURL.path),
                      !FileManager.default.fileExists(atPath: cloudURL.path)
                else { continue }
                try? FileManager.default.copyItem(at: localURL, to: cloudURL)
            }
        } catch {
            NSLog("iPaste: iCloud snapshot save failed — \(error.localizedDescription)")
        }
    }

    /// Checked before every write, not just at startup: if the folder is removed
    /// while iPaste runs — by a cleanup tool, a migration, a sync client — every
    /// later save would fail silently and the history would be lost at the next
    /// launch, with nothing on screen suggesting anything was wrong.
    private func ensureDirectories() {
        guard !FileManager.default.fileExists(atPath: imagesDirectory.path) else { return }
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    private func load() {
        guard let data = try? Data(contentsOf: databaseURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let database = try? decoder.decode(Database.self, from: data) else {
            NSLog("iPaste: history.json unreadable, starting fresh")
            return
        }
        clips = database.clips
        categories = database.categories
    }

    private struct Database: Codable {
        var clips: [Clip]
        var categories: [String]
    }
}
