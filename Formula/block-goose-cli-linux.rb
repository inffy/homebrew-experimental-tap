class BlockGooseCliLinux < Formula
  desc "Open source, extensible AI agent that goes beyond code suggestions"
  homepage "https://block.github.io/goose/"
  url "https://github.com/block/goose/archive/refs/tags/v1.19.1.tar.gz"
  sha256 "c011f64e5505c91e77afdb4c09f3bc917677e3cd9391357accd93770133cdf67"
  license "Apache-2.0"
  head "https://github.com/block/goose.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/ublue-os/homebrew-experimental-tap/releases/download/block-goose-cli-linux-1.19.1"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "2637c7dcbf1ce93094ebdd880dc98f463d669b40e1a88782cfde02ee82b515e8"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "2e5e7a1b6ba5b503c294d720925abb9c9583b982219f48fb641a4687bb739b8b"
  end

  depends_on "pkgconf" => :build
  depends_on "protobuf" => :build
  depends_on "rust" => :build

  depends_on "dbus"
  depends_on "libxcb"
  depends_on :linux
  depends_on "zlib"

  conflicts_with "goose", because: "both install `goose` binaries"
  conflicts_with "block-goose-cli", because: "both install `goose` binaries"

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/goose-cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goose --version")
    output = shell_output("#{bin}/goose info")
    assert_match "Paths:", output
    assert_match "Config dir:", output
    assert_match "Sessions DB (sqlite):", output
  end
end
