# 🍎 macOS App Blueprint

<p align="center">
  <strong>Production-tested blueprint & scaffolding toolkit for shipping native macOS Swift applications.</strong><br>
  <em>1-Command Install • Zero-Gatekeeper Trust • Automated GitHub Releases • Single-Source Versioning • Persistent Permissions</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-black?style=flat-square&logo=apple&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white" alt="CI/CD">
  <img src="https://img.shields.io/badge/Bundle%20ID-com.aoh.*-orange?style=flat-square" alt="Bundle ID">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
</p>

---

## 💡 What Is This?

This blueprint extracts and standardizes the entire distribution and release pipeline used across production macOS utilities like **[ClipLocal](https://github.com/arunofhyd/ClipLocal)**, **[HTML2PPTX](https://github.com/arunofhyd/HTML2PPTX)**, **[JobsMonitor](https://github.com/arunofhyd/JobsMonitor)**, **[Rec](https://github.com/arunofhyd/Rec)**, and **[SnapBack](https://github.com/arunofhyd/SnapBack)**.

It provides everything needed to ship, install, and auto-update lightweight native macOS apps **without paid Apple Developer accounts, notarization fees, or Gatekeeper security bypass prompts**.

---

## 🔒 Standard Bundle Identifier: `com.aoh.<appname>` (Permission Persistence)

Every macOS application built with this blueprint **must** use the standard bundle identifier:
```xml
<key>CFBundleIdentifier</key>
<string>com.aoh.__appname__</string>
```
*(Examples: `com.aoh.cliplocal`, `com.aoh.html2pptx`, `com.aoh.rec`, `com.aoh.jobsmonitor`, `com.aoh.snapback`)*

### Why This Matters:
macOS TCC security ties user permissions (**Accessibility**, **Screen Recording**, **Disk Access**, **Keychain**, **Notifications**) to the Bundle ID and app binary. By strictly standardizing on `com.aoh.<appname>`, **all permissions are preserved across future updates without re-prompting or forcing the user back into System Settings**.

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

---

## 🛠️ Development, Testing & Git Push Workflow Rules

### 1. Local Iteration & Testing (Do NOT Bump Version)
- When making code tweaks, styling changes, or bug fixes for the user to test:
  - **Do NOT bump the version number in `version.json` yet.**
  - Rebuild the local `.app` bundle via `build_app.sh` (or `swiftc`).
  - Automatically relaunch the app so the user can test the change immediately on their screen:
    ```bash
    killall <AppName> 2>/dev/null || true && sleep 1 && open -a "/path/to/<AppName>.app"
    ```

### 2. Git Push Constraint (Explicit Permission Required)
- **NEVER execute `git push` automatically.**
- Stage and commit locally as appropriate, but **ONLY run `git push` when the user explicitly sends a message containing the word "push" in the current turn.**

### 3. Release & Update Verification
- When the user is satisfied with all local testing and explicitly says **"push"**:
  1. Bump the version number in **`version.json`** and add the changelog notes.
  2. Rebuild the app so `Info.plist` is stamped with the new version.
  3. Commit and push to `origin main`.
  4. GitHub Actions CI will automatically build and publish the release `.zip` on GitHub.
  5. The user can click **"Check for Updates"** in the app's About window to verify the update live!

---

## 📁 Repository Structure

```
macos-app-blueprint/
├── README.md                           # This overview & human guide
├── SKILL.md                            # Complete technical instructions for AI agents
├── AGENTS.md                           # Universal AI agent instruction reference
└── templates/                          # Reusable production templates
    ├── version.json                    # Single-source version & changelog manifest
    ├── Info.plist                      # PlistBuddy-ready app bundle metadata (com.aoh.*)
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

The agent reads **`SKILL.md`** / **`AGENTS.md`**, copies the templates, sets `com.aoh.quicksnap`, replaces the placeholders, and wires up the full pipeline automatically in seconds.

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
| `com.aoh.__appname__` | `com.aoh.quicksnap` | Standard Bundle ID (persists permissions) |
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
