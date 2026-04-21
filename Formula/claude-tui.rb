class ClaudeTui < Formula
  desc "Real-time statusline, live monitor, and session analytics for Claude Code"
  homepage "https://slima4.github.io/claude-tui/"
  url "https://github.com/slima4/claude-tui/archive/refs/tags/v0.8.3.tar.gz"
  sha256 "24f23cfd6865d09f4eb1f994252d351669d74c36d40951d9ac443f4a5c658fd4"
  license "MIT"
  revision 3

  depends_on "python@3"

  # Shared Python packages (underscored) imported by every tool via PYTHONPATH.
  # Listed explicitly because the `claude-code-*` glob does not match them and
  # a missing package breaks every subcommand at runtime (issue #6).
  SHARED_PACKAGES = %w[claude_tui_core claude_tui_components].freeze

  def install
    # Tool directories
    libexec.install Dir["claude-code-*"]
    libexec.install Dir["claude_tui_*"]
    libexec.install "widgets" if File.directory?("widgets")
    libexec.install "install.sh"
    libexec.install "uninstall.sh" if File.exist?("uninstall.sh")
    libexec.install "claude-ui-mode.py" if File.exist?("claude-ui-mode.py")
    libexec.install "claudetui.py" if File.exist?("claudetui.py")

    # Fail the build if a shared package was dropped during install — every
    # subcommand imports these and would ModuleNotFoundError at runtime.
    SHARED_PACKAGES.each do |pkg|
      odie "Required shared package '#{pkg}' missing after install (issue #6)" \
        unless (libexec/pkg).directory?
    end

    # Patch fallback version to match formula version (for non-git installs)
    inreplace libexec/"claudetui.py", /_FALLBACK_VERSION = ".*"/, "_FALLBACK_VERSION = \"#{version}\""

    # Primary CLI command — pin to the declared python@3 dependency so we
    # don't drift to whatever `python3` happens to be first in PATH on the
    # user's machine. The dispatcher's `os.execvpe(sys.executable, ...)`
    # then propagates this Python to every subcommand.
    python = Formula["python@3"].opt_bin/"python3"
    (bin/"claudetui").write <<~EOS
      #!/bin/bash
      exec "#{python}" "#{libexec}/claudetui.py" "$@"
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
    # Use the same Python the wrapper uses, not whatever `python3` PATH resolves to.
    python = Formula["python@3"].opt_bin/"python3"

    # Basic CLI dispatcher
    assert_match "claudetui", shell_output("#{bin}/claudetui --version 2>&1")

    # Regression test for issue #6: every shared package must be importable.
    # Mirrors the dispatcher's PYTHONPATH=libexec injection. shell_output
    # raises on non-zero exit, and assert_match verifies the marker — so a
    # failed import surfaces as an explicit test failure instead of a silent
    # `system` returning false.
    SHARED_PACKAGES.each do |pkg|
      assert_match "ok", shell_output(
        "#{python} -c 'import sys; sys.path.insert(0, \"#{libexec}\"); " \
        "import #{pkg}; print(\"ok\")' 2>&1",
      )
    end

    # End-to-end: a subcommand whose entrypoint imports both shared
    # packages at module load. Succeeds only if PYTHONPATH plumbing and
    # both libs are wired up correctly.
    assert_match(/usage|Usage/,
                 shell_output("#{bin}/claudetui stats --help 2>&1"))
  end
end
