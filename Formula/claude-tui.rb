class ClaudeTui < Formula
  desc "Real-time statusline, live monitor, and session analytics for Claude Code"
  homepage "https://slima4.github.io/claude-tui/"
  url "https://github.com/slima4/claude-tui/archive/refs/tags/v0.3.10.tar.gz"
  sha256 "c0e5e6ecb8dfaa8ead4ab85b0565d2bea5fb827762acbbcab908b38010d7f151"
  license "MIT"

  depends_on "python@3"

  def install
    # Install all tool directories
    libexec.install Dir["claude-code-*"]
    libexec.install Dir["widgets"] if File.directory?("widgets")
    libexec.install "install.sh"
    libexec.install "uninstall.sh" if File.exist?("uninstall.sh")
    libexec.install "claude-ui-mode.py" if File.exist?("claude-ui-mode.py")
    libexec.install "claudetui.py" if File.exist?("claudetui.py")

    # Patch fallback version to match formula version (for non-git installs)
    inreplace libexec/"claudetui.py", /_FALLBACK_VERSION = ".*"/, "_FALLBACK_VERSION = \"#{version}\""

    # Primary CLI command
    (bin/"claudetui").write <<~EOS
      #!/bin/bash
      exec python3 "#{libexec}/claudetui.py" "$@"
    EOS
  end

  def caveats
    <<~EOS
      To complete setup (configure statusline, hooks, and slash commands):

        claudetui setup

      Before uninstalling, clean Claude Code settings first:

        claudetui uninstall     # removes statusline, hooks, commands
        brew uninstall claude-tui

      After setup:

        claude                  # statusline + hooks work automatically
        claudetui monitor       # live dashboard in a second terminal
        claudetui stats         # post-session analytics
        claudetui sessions list # browse all sessions
        claudetui mode custom   # configure statusline components
    EOS
  end

  test do
    assert_match "claudetui", shell_output("#{bin}/claudetui --version 2>&1")
  end
end
