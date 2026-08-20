# Contributing to iPaste

Thanks for considering a contribution — patches, bug reports, and ideas are
all welcome.

## Before you start

For anything beyond a small fix, please open an issue first to discuss the
approach. It saves everyone time if a design direction turns out to be a bad
fit before code gets written.

## Getting set up

No Xcode project is checked in — this is a plain SwiftPM package.

```bash
git clone https://github.com/adrianxviziteu/iPaste.git
cd iPaste
./Scripts/bundle.sh && open build/iPaste.app
```

`bundle.sh` compiles the package, assembles `iPaste.app`, and signs it
ad-hoc. See the [README](README.md#stable-signing) if you want stable
Accessibility permissions across rebuilds (use a self-signed certificate via
`IPASTE_SIGN_IDENTITY`).

The app has no Dock icon — look for it in the menu bar after launching.

## Code layout

See [How the code is laid out](README.md#how-the-code-is-laid-out) in the
README for a map of `Sources/iPaste/`. In short: `Core/` holds the clipboard
monitor, store, paster, and hotkeys; `UI/` holds the SwiftUI views; `Models/`
holds `Clip` and how its kind is classified.

## Making changes

- Keep pull requests focused — one change per PR is easier to review than a
  bundle of unrelated fixes.
- Match the existing code style (SwiftUI idioms, no external dependencies —
  the package currently has none, and that's deliberate).
- There is no automated test suite yet. Manually verify your change by
  running `./Scripts/bundle.sh` and exercising the affected feature (quick
  search, the notch shelf, collections, etc.) before opening a PR.
- Update the feature table in the README if you add, remove, or change a
  user-facing feature.

## Commit messages

Write commit messages that explain *why*, not just *what* — the diff already
shows what changed.

## Submitting a pull request

1. Fork the repo and create a branch off `main`.
2. Make your change, and test it locally.
3. Open a PR describing the motivation and, if relevant, how you tested it.
4. Be responsive to review feedback — small follow-up commits are fine.

## Reporting bugs

Open a [GitHub issue](https://github.com/adrianxviziteu/iPaste/issues) with:

- macOS version and iPaste build/version
- Steps to reproduce
- What you expected vs. what happened

For security vulnerabilities, please follow [SECURITY.md](SECURITY.md)
instead of opening a public issue.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be kind.
