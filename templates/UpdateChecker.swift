// =============================================================================
//  UpdateChecker.swift — In-App Update Checker + Auto-Updater
//  Template extracted from ClipLocal & HTML2PPTX by Arun Thomas
//
//  USAGE: Paste these functions into your app's main Swift file.
//  Replace __PLACEHOLDERS__ with your actual values.
// =============================================================================

import Foundation
import AppKit
import SwiftUI

// MARK: - Constants (set these at file scope)
// let appVersion     = "1.0.0"  // or read from Bundle
// let updateCheckURL = "https://raw.githubusercontent.com/USERNAME/APPNAME/main/version.json"
// let githubRepoURL  = "https://github.com/USERNAME/APPNAME"

// MARK: - Update Checker

/// Call with silentIfCurrent: true on app launch (24h rate-limited, silent if up-to-date)
/// Call with silentIfCurrent: false when user clicks "Check for Updates" (always shows result)
func checkForUpdates(silentIfCurrent: Bool) {
    let defaults = UserDefaults.standard
    let now = Date()

    // Rate-limit: only check once per 24 hours on silent/automatic checks
    if silentIfCurrent {
        if let lastCheck = defaults.object(forKey: "lastUpdateCheckDate") as? Date,
           now.timeIntervalSince(lastCheck) < 86400 {
            return
        }
    }
    defaults.set(now, forKey: "lastUpdateCheckDate")

    // Cache-bust to bypass GitHub CDN caching
    URLCache.shared.removeAllCachedResponses()
    let ts = Int(now.timeIntervalSince1970)
    let urlStr = updateCheckURL.contains("?") ? "\(updateCheckURL)&t=\(ts)" : "\(updateCheckURL)?t=\(ts)"
    guard let url = URL(string: urlStr) else { return }

    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.addValue("no-cache", forHTTPHeaderField: "Pragma")

    URLSession.shared.dataTask(with: request) { data, _, _ in
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let remote = json["version"] as? String else {
            if !silentIfCurrent {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Couldn't check for updates"
                    alert.informativeText = "Please check your internet connection and try again."
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
            return
        }

        let downloadURL = (json["downloadURL"] as? String) ?? githubRepoURL

        // Build multi-version changelog from all unread entries
        var notes = ""
        if let logs = json["changelog"] as? [[String: Any]] {
            let unread = logs.filter { entry in
                guard let v = entry["version"] as? String else { return false }
                return isNewer(v, than: appVersion)
            }
            notes = unread.compactMap { entry -> String? in
                guard let v = entry["version"] as? String,
                      let changes = entry["changes"] as? [String] else { return nil }
                return "Version \(v):\n" + changes.map { "•  \($0)" }.joined(separator: "\n")
            }.joined(separator: "\n\n")
        }

        let newer = isNewer(remote, than: appVersion)
        DispatchQueue.main.async {
            if newer {
                showUpdateAlert(remote: remote, changelog: notes, downloadURL: downloadURL)
            } else if !silentIfCurrent {
                let alert = NSAlert()
                alert.messageText = "You're up to date"
                alert.informativeText = "__APP_NAME__ v\(appVersion) is the latest version."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }.resume()
}

// MARK: - Semver Comparison

/// Returns true if `remote` is strictly newer than `current`
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

// MARK: - Update Available Alert

struct UpdateChangelogView: View {
    let changelog: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(changelog)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .frame(width: 340, height: 140)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

func showUpdateAlert(remote: String, changelog: String, downloadURL: String) {
    let alert = NSAlert()
    NSApp.activate(ignoringOtherApps: true)
    alert.messageText = "__APP_NAME__ \(remote) is available"
    alert.informativeText = "You have v\(appVersion). Here's what's new:"
    if !changelog.isEmpty {
        let hosting = NSHostingView(rootView: UpdateChangelogView(changelog: changelog))
        hosting.frame = NSRect(x: 0, y: 0, width: 340, height: 140)
        alert.accessoryView = hosting
    }
    alert.addButton(withTitle: "Update Now")
    alert.addButton(withTitle: "Later")
    if alert.runModal() == .alertFirstButtonReturn {
        downloadAndInstallUpdate()
    }
}

// MARK: - Auto-Update Downloader

/// Downloads the install script and opens it in Terminal
func downloadAndInstallUpdate() {
    let commandURL = "https://raw.githubusercontent.com/USERNAME/APPNAME/main/install-__appname__.command"
    guard let url = URL(string: commandURL) else { return }

    URLSession.shared.downloadTask(with: url) { tempURL, _, error in
        DispatchQueue.main.async {
            if let error = error {
                let err = NSAlert()
                err.alertStyle = .warning
                err.messageText = "Download Failed"
                err.informativeText = "Could not download the update:\n\(error.localizedDescription)"
                err.addButton(withTitle: "OK")
                err.runModal()
                return
            }

            guard let tempURL = tempURL else { return }

            let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destURL = downloadsDir.appendingPathComponent("install-__appname__.command")

            try? FileManager.default.removeItem(at: destURL)
            do {
                try FileManager.default.copyItem(at: tempURL, to: destURL)
                try FileManager.default.setAttributes(
                    [.posixPermissions: NSNumber(value: 0o755)],
                    ofItemAtPath: destURL.path
                )
                NSWorkspace.shared.open(destURL)  // Opens in Terminal automatically
            } catch {
                let err = NSAlert()
                err.alertStyle = .warning
                err.messageText = "Could Not Save Installer"
                err.informativeText = "The installer was downloaded but couldn't be saved:\n\(error.localizedDescription)"
                err.addButton(withTitle: "OK")
                err.runModal()
            }
        }
    }.resume()
}
