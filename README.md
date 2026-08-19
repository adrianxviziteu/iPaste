# iPaste

A clipboard manager for macOS: it remembers everything you copy, sorts it by
kind on its own, and hands it back in seconds — from the menu bar, from a quick
search window, or from a shelf that drops out of the top edge of the screen.

## Status

v1 — the working core. Built with SwiftUI and SwiftPM, without Xcode.

| Feature | State |
|---|---|
| Automatic capture: text, links, code, colors, images, files | done |
| Automatic capture of macOS screenshots from Desktop/Screenshots | done |
| Persistent history with deduplication and pinned clips | done |
| Quick search on ⌃⌘V, pasting into the app you came from | done |
| Dedicated filters by clip type in the shelf and quick search | done |
| Top shelf beside the notch, with drag and drop | done |
| Shelf modes: always open, on hover, never | done |
| Collections: create, rename, delete, move clips between them | done |
| ⌃⌘0–9 for the ten most recent clips | done |
| Library window: sidebar, grid, detail pane | removed — iPaste stays in the menu bar and notch |
| Menu bar menu and launch at login | done |
| First-run guide | done |
| Screenshot and image OCR (Vision) | done |
| Ignored applications for sensitive clipboard data | done |
| Sensitive-content detection for passwords, keys, tokens and card numbers | done |
| Filter by source application and Smart Auto-Filter | done |
| iCloud Drive sync engine | done; requires Apple iCloud entitlement |
| Automatic deletion after N days, with pinned clips preserved | done |
| Dedicated Settings window | done |
| Color Picker, Text Capture and Quick Notes | done |
| Inline shortcuts (`;hello`) | next |
| Multi-clip copy, clip reminders, iCloud sync | later |

## Running it

```bash
./Scripts/bundle.sh && open build/iPaste.app
```

The script compiles, assembles `iPaste.app` and signs it ad-hoc. The app has no
Dock icon — look for it in the menu bar, top right.

Pasting needs macOS **Accessibility** permission:
System Settings → Privacy & Security → Accessibility → add `iPaste.app`.
Without it iPaste still works, but it only places content on the clipboard and
you press ⌘V yourself. The first-run guide walks through this.

## Stable signing

macOS does not remember a permission for "the app at this path" — it remembers it
for a *signature*. An ad-hoc signature is not an identity: its hash changes on
every compile, so the system sees a different app each time and asks again, while
the old tick stays in the list belonging to a build that no longer exists.

`bundle.sh` uses only the identity passed explicitly through
`IPASTE_SIGN_IDENTITY`; it never picks an unrelated certificate automatically.
Without that variable it signs ad-hoc with a warning. Any self-signed
code-signing certificate in your own keychain works — no Apple account needed:

Keychain Access → Certificate Assistant → Create a Certificate…
name it, set the type to **Code Signing**, and leave the rest as offered.

To pick a specific one when several exist:

```bash
IPASTE_SIGN_IDENTITY="iPaste Dev" ./Scripts/bundle.sh
```

After switching from ad-hoc to a real identity, clear the stale grants once —
they belong to signatures that no longer exist:

```bash
tccutil reset Accessibility com.adrianviziteu.ipaste
```

Then launch iPaste and grant access once more. From that point rebuilds keep it.

## Shortcuts

| Shortcut | Effect |
|---|---|
| `⌃⌘V` | open quick search |
| `⌃⌘N` | open Quick Notes |
| `⌃⌘S` | show or hide the shelf |
| `⌃⌘0` … `⌃⌘9` | paste the clip at that position |
| `↑` `↓` `↩` `esc` | move, paste, dismiss |

## How the code is laid out

```
Sources/iPaste/
  iPasteApp.swift          entry point and the menu bar scene
  Models/Clip.swift        a clip and how its kind is decided
  Core/
    ClipboardMonitor.swift watches the pasteboard, classifies what arrives
    ClipStore.swift        the history: memory, JSON on disk, images beside it
    Paster.swift           writes to the pasteboard and sends ⌘V to the active app
    HotKeyCenter.swift     global shortcuts, via Carbon
    ShelfHoverMonitor.swift detects the cursor reaching the top edge
    AppState.swift         ties it together and owns the windows
    Preferences.swift      user settings, in UserDefaults
    LoginItem.swift        launch at login, via SMAppService
    ColorParsing.swift     recognizes colors in text
  UI/
    QuickSearchView.swift  the search window
    NotchShelfView.swift   the top shelf
    LibraryView.swift      the full window
    ClipRowView.swift      one row of results
    FloatingPanel.swift    the chromeless window both panels use
    Theme.swift            visual constants, in one place
    Onboarding/            the first-run guide
```

## Where the data lives

`~/Library/Application Support/iPaste/` — `history.json` for the clips,
`Images/` for screenshots and copied pictures. Everything stays local; nothing
leaves the Mac.
