# 🍎 macOS App Blueprint

<p align="center">
  <strong>Production-tested blueprint & scaffolding toolkit for shipping native macOS Swift applications.</strong><br>
  <em>1-Command Install • Zero-Gatekeeper Trust • Automated GitHub Releases • Single-Source Versioning</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-black?style=flat-square&logo=apple&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white" alt="CI/CD">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
</p>

---

## 💡 What Is This?

This blueprint extracts and standardizes the entire distribution and release pipeline used across production macOS utilities like **[ClipLocal](https://github.com/arunofhyd/ClipLocal)**, **[HTML2PPTX](https://github.com/arunofhyd/HTML2PPTX)**, **[JobsMonitor](https://github.com/arunofhyd/JobsMonitor)**, **[Rec](https://github.com/arunofhyd/Rec)**, and **[SnapBack](https://github.com/arunofhyd/SnapBack)**.

It provides everything needed to ship, install, and auto-update lightweight native macOS apps **without paid Apple Developer accounts, notarization fees, or Gatekeeper security bypass prompts**.

---

## ⚡ Core Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    version.json                         │
│              (Single Source of Truth)                    │
│         { "version": "1.0.0", "changelog": [...] }      │
├────────────┬──────────────┬─────────────┬───────────────┤
│            │              │             │               │
│   Info.plist        Swift App     install script    index.html
│   (PlistBuddy)    (Bundle read)  (python3 parse)  (fetch+JS)
│            │              │             │               │
│     Build-time       Runtime      Install-time      Client-side
└────────────┴──────────────┴─────────────┴───────────────┘

Push version.json to main ➔ GitHub Actions Auto-Release ➔ App.zip on GitHub
```

### Key Pillars:
1. **Zero Gatekeeper Friction**: The `install-*.command` compiles Swift source locally on the user's Mac (`swiftc -O -parse-as-library`), so macOS automatically trusts the binary.
2. **Single Source of Truth (`version.json`)**: Bumping version in `version.json` automatically flows into `Info.plist`, in-app About dialogs, update checker, and triggers GitHub Releases.
3. **Automated CI/CD**: GitHub Actions compiles on `macos-latest` (`CI=true`), zips to `.zip`, creates GitHub Release with formatted changelog notes, and generates SHA-256 checksums.
4. **Smart In-App Updates**: Silent background checks (24-hour rate-limited), cache-busted API queries, multi-version changelog aggregator, and 1-click self-updating.
5. **Interactive Drag-to-Applications GUI**: Embedded Swift installer showing a draggable icon, brand gradient arrow, and drop target.

---

## 📁 Repository Structure

```
macos-app-blueprint/
├── README.md                           # This overview & human guide
├── SKILL.md                            # Complete technical instructions for AI agents
├── AGENTS.md                           # Universal AI agent instruction reference
└── templates/                          # Reusable production templates
    ├── version.json                    # Single-source version & changelog manifest
    ├── Info.plist                      # PlistBuddy-ready app bundle metadata
    ├── auto-release.yml                # GitHub Actions automated release pipeline
    ├── install-template.command        # 1-line terminal installer script
    ├── InstallerGUI.swift              # Interactive drag-to-Applications GUI
    ├── UpdateChecker.swift             # In-app update checker + silent rate limiter
    ├── build_app.sh                    # Fast local development build script
    ├── README.template.md              # Beautiful GitHub README template
    ├── index.template.html             # Landing page with dynamic version loader
    ├── homebrew-cask.rb                # Homebrew Cask tap formula
    ├── render_assets.template.js       # High-DPI headless Puppeteer logo renderer
    └── make_app_icon.template.py       # iconutil 1024x1024 to AppIcon.icns generator
```

---

## 🚀 How to Use

### Option A: With AI Coding Assistants (Cursor, Antigravity, Claude, Copilot)
Simply point the agent to this repository:
> *"Create a new macOS app called **QuickSnap** using the patterns in `macos-app-blueprint`."*

The agent reads **`SKILL.md`** / **`AGENTS.md`**, copies the templates, replaces the placeholders, and wires up the full pipeline automatically in seconds.

---

### Option B: Manual Setup in 3 Steps

#### 1. Copy Templates to Your App Directory
```bash
cp -r templates/* /path/to/MyNewApp/
```

#### 2. Replace Placeholders
| Placeholder | Example | Description |
|---|---|---|
| `__APP_NAME__` | `QuickSnap` | Application name & binary |
| `__appname__` | `quicksnap` | Lowercase identifier for scripts & bundle ID |
| `USERNAME` | `arunofhyd` | GitHub username |
| `APPNAME` | `QuickSnap` | GitHub repository name |
| `__TAGLINE__` | `Lightning-fast window manager for macOS` | One-sentence summary |

#### 3. Releasing New Versions
1. Edit **`version.json`** (bump version & prepend release notes).
2. Commit and push:
   ```bash
   git add . && git commit -m "Release v1.0.1" && git push origin main
   ```
3. GitHub Actions automatically builds, zips, and publishes the release on GitHub!

---

## 📄 License
MIT License • Free for open-source and commercial use.

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/arunofhyd">Arun Thomas</a>
</p>
