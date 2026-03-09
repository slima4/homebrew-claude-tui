class Claudeui < Formula
  desc "Real-time statusline, live monitor, and session analytics for Claude Code"
  homepage "https://slima4.github.io/claudeui/"
  url "https://github.com/slima4/claudeui/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "d19125dd9f54da39cc1043eeda3e52170ae5846403ac2c191cb14c551904e80f"
  license "MIT"

  depends_on "python@3"

  def install
    # Install all tool directories
    libexec.install Dir["claude-code-*"]
    libexec.install Dir["widgets"] if File.directory?("widgets")
    libexec.install "install.sh"
    libexec.install "uninstall.sh" if File.exist?("uninstall.sh")
    libexec.install "claude-ui-mode.sh" if File.exist?("claude-ui-mode.sh")

    # Create wrapper scripts
    (bin/"claude-ui-monitor").write <<~EOS
      #!/bin/bash
      exec python3 "#{libexec}/claude-code-monitor/monitor.py" "$@"
    EOS

    (bin/"claude-stats").write <<~EOS
      #!/bin/bash
      exec python3 "#{libexec}/claude-code-session-stats/session-stats.py" "$@"
    EOS

    (bin/"claude-sessions").write <<~EOS
      #!/bin/bash
      exec python3 "#{libexec}/claude-code-session-manager/session-manager.py" "$@"
    EOS

    (bin/"claude-ui-setup").write <<~EOS
      #!/bin/bash
      # Run the installer to configure statusline, hooks, and commands
      export INSTALL_DIR="#{HOMEBREW_PREFIX}/opt/claudeui/libexec"
      exec bash "#{libexec}/install.sh" "$@"
    EOS

    (bin/"claude-ui-uninstall").write <<~EOS
      #!/bin/bash
      # Clean Claude Code settings before brew uninstall
      export INSTALL_DIR="#{HOMEBREW_PREFIX}/opt/claudeui/libexec"
      exec bash "#{libexec}/uninstall.sh" "$@"
    EOS
  end

  def caveats
    <<~EOS
      To complete setup (configure statusline, hooks, and slash commands):

        claude-ui-setup

      Before uninstalling, clean Claude Code settings first:

        claude-ui-uninstall     # removes statusline, hooks, commands
        brew uninstall claudeui

      After setup:

        claude                  # statusline + hooks work automatically
        claude-ui-monitor       # live dashboard in a second terminal
        claude-stats            # post-session analytics
        claude-sessions list    # browse all sessions
    EOS
  end

  test do
    assert_match "usage", shell_output("#{bin}/claude-sessions 2>&1", 2)
  end
end
