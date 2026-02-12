class Lofetch < Formula
  desc "Cross-platform system information display tool (neofetch-like)"
  homepage "https://github.com/jwuxan/lofetch"
  url "https://github.com/jwuxan/lofetch/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "" # Will be filled when release is created
  license "MIT"
  head "https://github.com/jwuxan/lofetch.git", branch: "main"

  def install
    bin.install "lofetch"
  end

  test do
    # Test basic execution
    system "#{bin}/lofetch", "--version"
  end
end
