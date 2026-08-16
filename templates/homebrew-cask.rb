cask "__appname__" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_FROM_GITHUB_ACTIONS"

  url "https://github.com/USERNAME/APPNAME/releases/download/v#{version}/__APP_NAME__.zip"
  name "__APP_NAME__"
  desc "__TAGLINE__"
  homepage "https://github.com/USERNAME/APPNAME"

  depends_on macos: ">= :ventura"

  app "__APP_NAME__.app"

  zap trash: [
    "~/Library/Application Support/__APP_NAME__",
    "~/Library/Caches/com.arunthomas.__appname__",
    "~/Library/Preferences/com.arunthomas.__appname__.plist",
  ]
end
