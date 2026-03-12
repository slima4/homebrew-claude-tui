class ClaudeTui < Formula
  desc "Real-time statusline, live monitor, and session analytics for Claude Code"
  homepage "https://slima4.github.io/claude-tui/"
  url "https://github.com/slima4/claude-tui/archive/refs/tags/v0.3.7.tar.gz"
  sha256 "73ad634ccea78908d7ab7280d6354ca695a5b02a4a43fa32f653f6dd2fe018c5"
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
