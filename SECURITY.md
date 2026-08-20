# Security Policy

## Supported versions

iPaste ships as a single rolling release from the `main` branch. Only the
latest [GitHub Release](https://github.com/adrianxviziteu/iPaste/releases/latest)
receives security fixes.

## Reporting a vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Instead, report it privately to **hello@ipaste.app** with:

- A description of the vulnerability and its potential impact
- Steps to reproduce it (a minimal repro is very helpful)
- The macOS version and iPaste build/version you tested against

You should get an initial response within a few days. Once a fix is ready,
we'll credit you in the release notes if you'd like.

## Scope

iPaste is a local-first macOS clipboard manager: clipboard history is stored
only on-device (`~/Library/Application Support/iPaste/`), and the app has no
backend server. Reports of particular interest include:

- Ways sensitive clipboard content (passwords, keys, tokens, card numbers)
  could bypass the built-in sensitive-content detection or ignored-app rules
- Local privilege escalation or sandbox-escape issues in `ClipboardMonitor`,
  `Paster`, or the Accessibility/hotkey integration (`HotKeyCenter.swift`)
- Ways stored clip data could be read by another user or process without
  the appropriate macOS permissions
- Supply-chain issues in the build/release scripts (`Scripts/`, the GitHub
  Actions release workflow)

Denial-of-service reports (e.g. "the app crashes if you paste a huge string")
are welcome as regular bug reports/issues rather than security reports, unless
they demonstrate a real security impact.
