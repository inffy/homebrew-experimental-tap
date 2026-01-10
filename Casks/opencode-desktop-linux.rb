cask "opencode-desktop-linux" do
  arch arm: "aarch64", intel: "x86_64"

  version "1.1.11"
  sha256 arm: "ff204628c97a0185fe50acdd82b18ca8a61496edf16e89b0d3986ec41ac026ec",
       intel: "bf5b6fe3e58ab7de152c5a54e300d97d38f8f5c3b870c872882c369a9e0aeb03"

  url "https://github.com/anomalyco/opencode/releases/download/v#{version}/opencode-desktop-linux-#{arch}.rpm",
      verified: "github.com/anomalyco/opencode/"
  name "OpenCode"
  desc "The open source AI coding agent desktop client"
  homepage "https://opencode.ai/"

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest/download/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
  depends_on formula: "rpm2cpio"

  binary "usr/bin/OpenCode", target: "opencode-desktop"
  binary "usr/bin/opencode-cli", target: "opencode-cli"
  artifact "usr/share/icons/hicolor/32x32/apps/OpenCode.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/32x32/apps/OpenCode.png"
  artifact "usr/share/icons/hicolor/128x128/apps/OpenCode.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/128x128/apps/OpenCode.png"
  artifact "usr/share/icons/hicolor/256x256@2/apps/OpenCode.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/256x256@2/apps/OpenCode.png"

  preflight do
    system "sh", "-c", "rpm2cpio '#{staged_path}/opencode-desktop-linux-#{arch}.rpm' | cpio -idm --quiet",
           chdir: staged_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    File.write("#{staged_path}/OpenCode.desktop", <<~EOS)
      [Desktop Entry]
      Name=OpenCode
      Comment=The open source AI coding agent desktop client
      Exec=#{HOMEBREW_PREFIX}/bin/opencode-desktop %U
      Icon=#{Dir.home}/.local/share/icons/hicolor/256x256@2/apps/OpenCode.png
      Terminal=false
      Type=Application
      Categories=Development;
      MimeType=x-scheme-handler/opencode;
      StartupWMClass=OpenCode
    EOS
  end

  artifact "OpenCode.desktop",
           target: "#{Dir.home}/.local/share/applications/OpenCode.desktop"

  zap trash: [
    "~/.config/ai.opencode.desktop",
    "~/.cache/ai.opencode.desktop",
    "~/.local/share/ai.opencode.desktop",
  ]
end
