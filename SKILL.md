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
3. [version.json — Single Source of Truth](#3-versionjson--single-source-of-truth)
4. [Info.plist Template](#4-infoplist-template)
5. [Swift App Constants & Version Loading](#5-swift-app-constants--version-loading)
6. [In-App Update Checker (Swift)](#6-in-app-update-checker-swift)
7. [Auto-Update Downloader (Swift)](#7-auto-update-downloader-swift)
8. [Install Script (.command) Pattern](#8-install-script-command-pattern)
9. [Interactive Drag-to-Applications GUI (Swift)](#9-interactive-drag-to-applications-gui-swift)
10. [build_app.sh — Local Build Script](#10-build_appsh--local-build-script)
11. [GitHub Actions Auto-Release Workflow](#11-github-actions-auto-release-workflow)
12. [README.md Template](#12-readmemd-template)
13. [Landing Page (index.html) Pattern](#13-landing-page-indexhtml-pattern)
14. [Portfolio Integration Pattern](#14-portfolio-integration-pattern)
15. [Homebrew Cask Tap (Optional)](#15-homebrew-cask-tap-optional)
16. [Version Bumping Checklist](#16-version-bumping-checklist)

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

---

## 2. Repository File Structure

```
MyApp/
├── .github/
│   └── workflows/
│       └── auto-release.yml        # GitHub Actions: build + release on version bump
├── MyApp.swift                      # Main Swift source (single-file app)
├── Info.plist                       # macOS app bundle metadata
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

## 3. version.json — Single Source of Truth

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

### Rules
- `version` field is the current latest version (semver: `MAJOR.MINOR.PATCH`).
- `downloadURL` points to the GitHub releases page or a landing page install section.
- `changelog` array ordered **newest first**. Each entry: `version`, `date`, `changes[]`.
- The Swift app fetches this at runtime for update checks.
- GitHub Actions reads it to create release tags and notes.
- The install script reads it to stamp Info.plist at build time.

---

## 4. Info.plist Template

See full template: `templates/Info.plist`

### Version Stamping (at build time via PlistBuddy)
```bash
VERSION=$(python3 -c "import json; print(json.load(open('version.json'))['version'])")
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
```

---

## 5. Swift App Constants & Version Loading

### Pattern A: Read from Bundle (preferred — zero duplication)

```swift
let appVersion: String = {
    if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !v.isEmpty { return v }
    return "1.0.0"
}()
let updateCheckURL = "https://raw.githubusercontent.com/USERNAME/APPNAME/main/version.json"
let githubRepoURL  = "https://github.com/USERNAME/APPNAME"
```

### Pattern B: Hardcoded constant (simpler single-file apps like ClipLocal)

```swift
let appVersion     = "1.3.7"
let updateCheckURL = "https://raw.githubusercontent.com/USERNAME/APPNAME/main/version.json"
let downloadPageURL = "https://myapp.vercel.app/#install"
```

**Warning**: Pattern B requires updating the Swift constant AND version.json on every release.

---

## 6. In-App Update Checker (Swift)

Full production code in `templates/UpdateChecker.swift`. Key design:

- **24-hour rate limit** on silent checks to avoid pestering
- **Cache-busting** timestamp `?t=` param + `no-cache` headers to defeat GitHub CDN
- **Multi-release changelog**: Shows ALL unread versions between current and latest
- **Silent vs manual**: `silentIfCurrent: true` = app launch, `false` = user-triggered

### Semver Comparison

```swift
func isNewer(_ remote: String, than current: String) -> Bool {
    let r = remote.split(separator: ".").compactMap { Int($0) }
    let c = current.split(separator: ".").compactMap { Int($0) }
    for i in 0..<max(r.count, c.count) {
        let rv = i < r.count ? r[i] : 0
        let cv = i < c.count ? c[i] : 0
        if rv > cv { return true }
        if rv < cv { return false }
    }
    return false
}
```

---

## 7. Auto-Update Downloader (Swift)

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

## 8. Install Script (.command) Pattern

Full template: `templates/install-template.command`

Steps:
1. Check Xcode CLT (`xcode-select -p`)
2. Check dependencies (Python, Node, etc.)
3. Download source or use local clone
4. `swiftc -O -parse-as-library MyApp.swift -o Build/MyApp`
5. Assemble .app bundle
6. PlistBuddy version stamp
7. If `CI=true` → exit. Else → open GUI.

---

## 9. Interactive Drag-to-Applications GUI

Full template: `templates/InstallerGUI.swift`

Embedded as heredoc in install script. Components:
- `DragIcon` — draggable app icon
- `DropZone` — Applications folder drop target
- `GradientArrowView` — brand-colored arrow
- `OrangeInstallButton` — 1-click install
- `performInstallation()` — copy to /Applications + alert

---

## 10. build_app.sh — Local Build Script

Full template: `templates/build_app.sh`

---

## 11. GitHub Actions Auto-Release Workflow

Full template: `templates/auto-release.yml`

Triggers: `version.json` or `.github/**` push to main, plus `workflow_dispatch`.

---

## 12. README.md Template

Full template: `templates/README.template.md`

---

## 13. Landing Page (index.html) Pattern

Key elements:
- SEO meta (title, desc, keywords, OG, Twitter, JSON-LD)
- Dynamic version via `fetch('version.json')`
- Copy-to-clipboard install command
- Hero + badges + feature grid

---

## 14. Portfolio Integration

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

## 15. Homebrew Cask Tap (Optional)

Full template: `templates/homebrew-cask.rb`

---

## 16. Version Bumping Checklist

1. Edit `version.json` → bump version, add changelog at TOP
2. If Pattern B: update `let appVersion` in Swift
3. `git add . && git commit -m "Release vX.Y.Z" && git push`
4. GitHub Actions auto-builds + publishes release
5. Verify: `https://github.com/USERNAME/APPNAME/releases/latest`

---

## Quick Reference: Placeholders

| Placeholder | ClipLocal | HTML2PPTX |
|---|---|---|
| `__APP_NAME__` | ClipLocal | HTML2PPTX |
| `__BUNDLE_ID__` | com.aoh.cliplocal | com.arunthomas.html2pptx |
| `USERNAME` | arunofhyd | arunofhyd |
| Brand Color | Blue (#0A84FF) | Orange (#F97316) |

---

*Blueprint by Arun Thomas — extracted from [ClipLocal](https://github.com/arunofhyd/ClipLocal) and [HTML2PPTX](https://github.com/arunofhyd/HTML2PPTX).*
