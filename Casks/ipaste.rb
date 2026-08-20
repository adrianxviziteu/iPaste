cask "ipaste" do
  version "0.1.0"
  sha256 :no_check

  url "https://github.com/adrianxviziteu/iPaste/releases/download/v#{version}/iPaste.zip",
      verified: "github.com/adrianxviziteu/iPaste/"
  name "iPaste"
  desc "Clipboard manager for macOS"
  homepage "https://github.com/adrianxviziteu/iPaste"

  depends_on macos: ">= :sonoma"

  app "iPaste.app"

  caveats <<~EOS
    iPaste is currently distributed without Apple notarization.
    If macOS blocks the first launch, right-click iPaste.app in /Applications
    and choose Open, then confirm.

    iPaste needs Accessibility permission to paste into the active app:
    System Settings → Privacy & Security → Accessibility.
  EOS
end
