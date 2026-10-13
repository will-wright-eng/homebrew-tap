class Loch < Formula
  desc "Per-commit LOC history via gix and tokei, without a working tree"
  homepage "https://github.com/will-wright-eng/loch"
  url "https://github.com/will-wright-eng/loch/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "ad0765eb9fc73b304e8efae00a1eb4bd6ab4ad5a2d43b2cc0fbbc4126be7ce2a"
  license "GPL-3.0-or-later"
  head "https://github.com/will-wright-eng/loch.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/loch --version")
    system bin/"loch", "--help"
  end
end
