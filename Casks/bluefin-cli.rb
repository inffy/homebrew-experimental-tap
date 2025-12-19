cask "bluefin-cli" do
  version "0.0.1"

  on_arm do
    on_linux do
      sha256 "8ba6aa87ef00a3f0d05051d143e625227cbb7dec720804364e8cc8f5402a3449"
      url "https://github.com/hanthor/bluefin-cli/releases/download/v#{version}/bluefin-cli_#{version}_linux_arm64.tar.gz"
    end
    on_macos do
      sha256 "c930feab1acd0fb6bfc632356acb54f56428ee980455f2e358e79f9880a8dca7"
      url "https://github.com/hanthor/bluefin-cli/releases/download/v#{version}/bluefin-cli_#{version}_darwin_arm64.tar.gz"
    end
  end
  on_intel do
    on_linux do
      sha256 "edd352b9de6bd05d5248b63daecb6d0bc6252eb0ad500fdb3d7d790083a429d5"
      url "https://github.com/hanthor/bluefin-cli/releases/download/v#{version}/bluefin-cli_#{version}_linux_amd64.tar.gz"
    end
    on_macos do
      sha256 "fcfd4bcf9723ad03b9fe1591da286242cf7651ea7b9f7c20f5ec087201cf3815"
      url "https://github.com/hanthor/bluefin-cli/releases/download/v#{version}/bluefin-cli_#{version}_darwin_amd64.tar.gz"
    end
  end

  name "Bluefin CLI"
  desc "Bluefin's CLI tool"
  homepage "https://github.com/hanthor/bluefin-cli"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  binary "bluefin-cli"
end
