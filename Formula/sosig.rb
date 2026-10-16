class Sosig < Formula
  include Language::Python::Virtualenv

  desc "Analyze GitHub repositories and calculate social-signal metrics"
  homepage "https://github.com/will-wright-eng/social-signals"
  url "https://files.pythonhosted.org/packages/4f/b7/bf2c3edb703b96de1d908744678a79ee226707bb3055dc7ffd7eee18f072/sosig-0.3.1.tar.gz"
  sha256 "d39a1972cecb59b3cdd6c81ce750318dfb588ec5f14f6d78f9142ba482e00b7d"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    strategy :pypi
  end

  # pip runs with --no-binary=:all:, so pydantic-core is built from Rust source.
  depends_on "rust" => :build
  depends_on "gh"
  depends_on "python@3.14"

  resource "annotated-doc" do
    url "https://files.pythonhosted.org/packages/5a/8e/38aa427ed5402449e226975b649c5dc73ccadfefeb95e6aecb8f8ea4b6b6/annotated_doc-0.0.5.tar.gz"
    sha256 "c7e58ce09192557605d8bbd92836d7e1d520ac9580096042c0bfd197efacf1bb"
  end

  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/5f/56/a8120250d128bed162cd73c76d45f6ef9991f3e068f62a8ee060afa3104a/annotated_types-0.8.0.tar.gz"
    sha256 "13b2beaad985e05e2d6407ee4c4f35590b11f8d693a258a561055cac8f64cab7"
  end

  resource "markdown-it-py" do
    url "https://files.pythonhosted.org/packages/06/ff/7841249c247aa650a76b9ee4bbaeae59370dc8bfd2f6c01f3630c35eb134/markdown_it_py-4.2.0.tar.gz"
    sha256 "04a21681d6fbb623de53f6f364d352309d4094dd4194040a10fd51833e418d49"
  end

  resource "mdurl" do
    url "https://files.pythonhosted.org/packages/d6/54/cfe61301667036ec958cb99bd3efefba235e65cdeb9c84d24a8293ba1d90/mdurl-0.1.2.tar.gz"
    sha256 "bb413d29f5eea38f31dd4754dd7377d4465116fb207585f97bf925588687c1ba"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/7c/0b/8e10b2e693af8ec54346a14caf36221334775975a747c9ceaa3f8371d96d/pydantic-2.14.1.tar.gz"
    sha256 "94f478203dd03404682a1ada216965651dd74b1d2d5ffd62e00e0837caab5c26"
  end

  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/a6/24/af4ec4be49fbc810f35b0bdcacc3d433b56bbfa469fd3bfd4ae116cd9bf1/pydantic_core-2.50.1.tar.gz"
    sha256 "e50d7b94baac6c7d09927fa5ca5800a0c7ee5015c7fcff65beb3a1931b5a6e09"
  end

  resource "pygments" do
    url "https://files.pythonhosted.org/packages/49/2e/ced460408999b33da6b31b0021b0f37d329e202d4169aeb164493778f25b/pygments-2.21.0.tar.gz"
    sha256 "610ca751c9bc2492b38eb9a38a7fbc93edbbb2d7182edaf34e66ae493dee5c8c"
  end

  resource "rich" do
    url "https://files.pythonhosted.org/packages/c0/8f/0722ca900cc807c13a6a0c696dacf35430f72e0ec571c4275d2371fca3e9/rich-15.0.0.tar.gz"
    sha256 "edd07a4824c6b40189fb7ac9bc4c52536e9780fbbfbddf6f1e2502c31b068c36"
  end

  resource "shellingham" do
    url "https://files.pythonhosted.org/packages/58/15/8b3609fd3830ef7b27b655beb4b4e9c62313a4e8da8c676e142cc210d58e/shellingham-1.5.4.tar.gz"
    sha256 "8dbca0739d487e5bd35ab3ca4b36e11c4078f3a234bfce294b0a0291363404de"
  end

  resource "sqlalchemy" do
    url "https://files.pythonhosted.org/packages/1f/44/311bac6b6ef81e4dfd0287d04900108b1f5c00c9761dd3c0a2b7b9d0f86b/sqlalchemy-2.1.4.tar.gz"
    sha256 "7bd7ad604487daa7eab8716471c29a7185f17b5287ce73bb7bc79fea050d8cfd"
  end

  resource "sqlmodel" do
    url "https://files.pythonhosted.org/packages/dd/67/b2c0b771c89c023262dd8fb6ba2cdc6a004e5ff75dd5763051b38ccd133a/sqlmodel-0.0.48.tar.gz"
    sha256 "5582e87e845e23bb1179a7d8b11a4f5e441b4494528a41ee2fe1d129ffe91543"
  end

  resource "typer" do
    url "https://files.pythonhosted.org/packages/03/51/d33db42cc72ffd8c30777547b42d01f0cbf9d95a770457698d0174b3ed71/typer-0.27.3.tar.gz"
    sha256 "d0396f770a560ab1b0a8504e13b5f254b728cedb05c61cf0359e944e50ce8901"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "typing-inspection" do
    url "https://files.pythonhosted.org/packages/a3/26/b09b8010994eccc3c09092e6b34058f36a460eea2d4c3e8b910c695975a0/typing_inspection-0.4.4.tar.gz"
    sha256 "547274fa6b0a561ccf549cc9524b999a578e737d015d8709d021f9d0d13bea47"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "Usage", shell_output("#{bin}/sosig --help")
  end
end
