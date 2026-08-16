---
name: macos-app-blueprint
description: >
  Complete blueprint for shipping native macOS Swift apps with one-command install,
  GitHub Actions auto-release, single-source-of-truth versioning, in-app update checker,
  interactive drag-to-Applications installer GUI, landing page, README, and portfolio integration.
  Extracted from production patterns in ClipLocal and HTML2PPTX by Arun Thomas.
---

# macOS App Blueprint — Comprehensive Skill Reference

> **Purpose**: This skill gives an AI coding agent everything it needs to scaffold, build, release,
> and maintain a native macOS Swift app — without re-reading entire codebases every time.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Repository File Structure](#2-repository-file-structure)
3. [Bundle Identifier Standard: com.aoh.APPNAME (Permission Persistence)](#3-bundle-identifier-standard-comaohappname-permission-persistence)
4. [Development, Testing & Git Push Rules](#4-development-testing--git-push-rules)
5. [version.json — Single Source of Truth](#5-versionjson--single-source-of-truth)
6. [Info.plist Template](#6-infoplist-template)
7. [Swift App Constants & Version Loading](#7-swift-app-constants--version-loading)
8. [In-App Update Checker (Swift)](#8-in-app-update-checker-swift)
9. [Auto-Update Downloader (Swift)](#9-auto-update-downloader-swift)
10. [Install Script (.command) Pattern](#10-install-script-command-pattern)
11. [Interactive Drag-to-Applications GUI (Swift)](#11-interactive-drag-to-applications-gui-swift)
12. [build_app.sh — Local Build Script](#12-build_appsh--local-build-script)
13. [GitHub Actions Auto-Release Workflow](#13-github-actions-auto-release-workflow)
14. [README.md Template](#14-readmemd-template)
15. [Landing Page (index.html) Pattern](#15-landing-page-indexhtml-pattern)
16. [Portfolio Integration Pattern](#16-portfolio-integration-pattern)
17. [Homebrew Cask Tap (Optional)](#17-homebrew-cask-tap-optional)
18. [Version Bumping Checklist](#18-version-bumping-checklist)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    version.json                         │
│              (Single Source of Truth)                    │
│         { "version": "X.Y.Z", ... }                    │
├────────────┬──────────────┬─────────────┬───────────────┤
│            │              │             │               │
│   Info.plist        Swift App     install script    index.html
│   (PlistBuddy)    (Bundle read)  (python3 parse)  (fetch+JS)
│            │              │             │               │
│     Build-time       Runtime      Install-time      Client-side
└────────────┴──────────────┴─────────────┴───────────────┘

Push version.json to main → GitHub Actions auto-release → .zip on Releases
```

### Key Principles

1. **Version lives in ONE place**: `version.json`. Everything else reads from it.
2. **Build locally, trust automatically**: The install script compiles Swift on the user's Mac so Gatekeeper never blocks it.
3. **CI mirrors the local build**: GitHub Actions runs the same `install-*.command` in CI mode (`CI=true`) to produce the release zip.
4. **Update check = fetch version.json**: The app fetches `version.json` from GitHub raw, compares semver, and shows a native alert with changelog.
5. **Standard Bundle Identifier**: Always use `com.aoh.<appname>` to preserve macOS system permissions across all updates.

---

## 2. Repository File Structure

```
MyApp/
├── .github/
│   └── workflows/
│       └── auto-release.yml        # GitHub Actions: build + release on version bump
├── MyApp.swift                      # Main Swift source (single-file app)
├── Info.plist                       # macOS app bundle metadata (CFBundleIdentifier: com.aoh.myapp)
├── build_app.sh                     # Local dev build script
├── install-myapp.command            # One-liner installer (compiles + GUI drag-to-Apps)
├── version.json                     # Single Source of Truth for version + changelog
├── AppIcon.png                      # 1024x1024 squircle icon for iconutil
├── AppIcon.icns                     # macOS icon set
├── AppLogo.png                      # Transparent brand glyph for in-app UI
├── logo.svg                         # Vector logo for README / web
├── index.html                       # Landing page (optional, for Vercel/Netlify)
└── README.md                        # GitHub README with badges + install instructions
```

---

## 3. Bundle Identifier Standard: com.aoh.APPNAME (Permission Persistence)

> [!IMPORTANT]
> **CRITICAL RULE**: Every macOS app MUST use the standard Bundle Identifier format:
> `com.aoh.<appname>` (e.g. `com.aoh.cliplocal`, `com.aoh.html2pptx`, `com.aoh.rec`, `com.aoh.jobsmonitor`, `com.aoh.snapback`).

### Why This Is Essential:
macOS TCC (Transparency, Consent, and Control) ties system permissions directly to the **Bundle Identifier** and app path:
- **Accessibility Permissions** (keyboard shortcuts, clipboard monitoring, layout management)
- **Screen & System Audio Recording** permissions
- **Full Disk / File Access**
- **Apple Keychain Access Groups & Service Names**
- **System Notifications**

If the bundle identifier varies (e.g., changing between `com.arunthomas.app`, `com.aoh.app`, or `com.user.app`), macOS treats the update as an unknown foreign application and **revokes all permissions, forcing the user to manually re-grant them in System Settings on every update**.

By strictly maintaining **`com.aoh.<appname>`** across:
1. `Info.plist` (`CFBundleIdentifier` = `com.aoh.__appname__`)
2. In-app Keychain Service identifier (`service = "com.aoh.__appname__"`)
3. LaunchAgent plist names (`~/Library/LaunchAgents/com.aoh.__appname__.plist`)
4. App bundle install destination (`/Applications/__APP_NAME__.app`)

All existing macOS permissions are **reused seamlessly without fresh permission prompts across every future update**.

---

## 4. Development, Testing & Git Push Rules (CRITICAL)

### Rule 1: Local Iteration & UI Testing (Do NOT Bump Version Yet)
- When making code changes, UI tweaks, or bug fixes during development and testing:
  - **DO NOT bump the version number in `version.json`** for intermediate test builds.
  - Rebuild the local application bundle using `build_app.sh` (or `swiftc`).
  - Automatically restart/relaunch the application (`killall <AppName> 2>/dev/null || true && sleep 1 && open -a "/path/to/<AppName>.app"`) so the user can immediately test and visually verify the change on screen.
  - Leave the app running and await user feedback.

### Rule 2: Git Push Constraint (Explicit Permission Required)
- **NEVER execute `git push` automatically.**
- Stage changes or commit locally as needed, but **ONLY run `git push` when the user explicitly sends a message containing the word "push" in the current turn**.

### Rule 3: Release & Update Verification
- Once the user is satisfied with local testing and explicitly says **"push"**:
  1. Bump the version number in **`version.json`** (e.g. `1.0.0` ➔ `1.0.1`) and append the bulleted release notes to `"changelog"`.
  2. Rebuild the app so `Info.plist` reflects the new version.
  3. Commit all changes and push to `origin main`.
  4. GitHub Actions CI will automatically build and publish the release `v1.0.1` with `.zip` attached.
  5. The user can then click **"Check for Updates"** in the app's About / Info window (or the agent can verify via GitHub API) to confirm the new release is live!

---

## 5. version.json — Single Source of Truth

This is the ONLY file you edit when releasing a new version. Everything else reads from it.

```json
{
  "version": "1.0.0",
  "downloadURL": "https://github.com/USERNAME/APPNAME/releases/latest",
  "changelog": [
    {
      "version": "1.0.0",
      "date": "2026-08-16",
      "changes": [
        "First release of MyApp.",
        "Feature A: Description.",
        "Feature B: Description."
      ]
    }
  ]
}
```

---

## 6. Info.plist Template

See full template: `templates/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>__EXECUTABLE_NAME__</string>
    <key>CFBundleIdentifier</key>
    <string>com.aoh.__appname__</string>
    <key>CFBundleName</key>
    <string>__APP_DISPLAY_NAME__</string>
    <key>CFBundleDisplayName</key>
    <string>__APP_DISPLAY_NAME__</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

---

## 7. Swift App Constants & Version Loading

### Pattern A: Read from Bundle (preferred — zero duplication)

```swift
let appVersion: String = {
    if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !v.isEmpty { return v }
    return "1.0.0"
}()
let updateCheckURL = "https://raw.githubusercontent.com/USERNAME/APPNAME/main/version.json"
let githubRepoURL  = "https://github.com/USERNAME/APPNAME"
```

---

## 8. In-App Update Checker (Swift)

Full production code in `templates/UpdateChecker.swift`. Key design:
- **24-hour rate limit** on silent checks to avoid pestering
- **Cache-busting** timestamp `?t=` param + `no-cache` headers to defeat GitHub CDN
- **Multi-release changelog**: Shows ALL unread versions between current and latest
- **Silent vs manual**: `silentIfCurrent: true` = app launch, `false` = user-triggered

---

## 9. Auto-Update Downloader (Swift)

Downloads install script → saves to ~/Downloads → opens in Terminal:

```swift
func downloadAndInstallUpdate() {
    let url = URL(string: "https://raw.githubusercontent.com/USERNAME/APPNAME/main/install-myapp.command")!
    URLSession.shared.downloadTask(with: url) { tempURL, _, error in
        DispatchQueue.main.async {
            guard error == nil, let tempURL = tempURL else { return }
            let dest = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                .appendingPathComponent("install-myapp.command")
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: tempURL, to: dest)
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
            NSWorkspace.shared.open(dest)
        }
    }.resume()
}
```

---

## 10. Install Script (.command) Pattern

Full template: `templates/install-template.command`

---

## 11. Interactive Drag-to-Applications GUI

Full template: `templates/InstallerGUI.swift`

---

## 12. build_app.sh — Local Build Script

Full template: `templates/build_app.sh`

---

## 13. GitHub Actions Auto-Release Workflow

Full template: `templates/auto-release.yml`

Triggers: `version.json` or `.github/**` push to main, plus `workflow_dispatch`.

---

## 14. README.md Template

Full template: `templates/README.template.md`

---

## 15. Landing Page (index.html) Pattern

Key elements:
- SEO meta (title, desc, keywords, OG, Twitter, JSON-LD)
- Dynamic version via `fetch('version.json')`
- Copy-to-clipboard install command
- Hero + badges + feature grid

---

## 16. Portfolio Integration

Add to `my-portfolio/index.html` macOS Utilities `<ul>`:

```html
<li class="glitch-accordion">
    <details>
        <summary><span class="flex items-center">__APP_NAME__
            <img src="assets/__app___logo.svg" class="w-7 h-7 rounded-full ml-2"></span>
            <span class="arrow">▸</span>
        </summary>
        <div class="glitch-accordion-content">
            <p>Description. <br><a href="https://github.com/arunofhyd/__APP__">Visit.</a></p>
        </div>
    </details>
</li>
```

---

## 17. Homebrew Cask Tap (Optional)

Full template: `templates/homebrew-cask.rb`

---

## 18. Version Bumping Checklist

1. Edit `version.json` → bump version, add changelog at TOP
2. If Pattern B: update `let appVersion` in Swift
3. `git add . && git commit -m "Release vX.Y.Z" && git push`
4. GitHub Actions auto-builds + publishes release
5. Verify: `https://github.com/USERNAME/APPNAME/releases/latest`

---

## Quick Reference: Placeholders

| Placeholder | Example | Description |
|---|---|---|
| `__APP_NAME__` | ClipLocal | App display name & binary |
| `com.aoh.__appname__` | `com.aoh.cliplocal` | Standard Bundle ID (persists permissions) |
| `USERNAME` | arunofhyd | GitHub username |
| `APPNAME` | ClipLocal | GitHub repo name |
| Brand Color | Blue (#0A84FF) / Orange (#F97316) | Accent theme |

---

*Blueprint by Arun Thomas — extracted from [ClipLocal](https://github.com/arunofhyd/ClipLocal) and [HTML2PPTX](https://github.com/arunofhyd/HTML2PPTX).*
