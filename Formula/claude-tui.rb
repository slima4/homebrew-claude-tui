class ClaudeTui < Formula
  desc "Real-time statusline, live monitor, and session analytics for Claude Code"
  homepage "https://slima4.github.io/claude-tui/"
  url "https://github.com/slima4/claude-tui/archive/refs/tags/v0.8.3.tar.gz"
  sha256 "24f23cfd6865d09f4eb1f994252d351669d74c36d40951d9ac443f4a5c658fd4"
  license "MIT"
  revision 4

  depends_on "python@3"

  # Fallback list of shared Python packages (underscored) imported by every
  # tool via PYTHONPATH. Used only when the source tarball doesn't ship a
  # `.brew-manifest.json` (true for v0.8.3 and earlier). v0.8.4+ ships the
  # manifest; this fallback should be deleted once we no longer support
  # rolling back to v0.8.3.
  FALLBACK_SHARED_PACKAGES = %w[claude_tui_core claude_tui_components].freeze

  def install
    require "json"

    # Read shared-package list from the source tarball's manifest. The source
    # repo's CI (manifest-check.yml) enforces that the manifest stays in sync
    # with the actual claude_tui_* directories — see issue #6 for the regression
    # class this prevents (silently dropping a shared package from packaging).
    manifest_path = Pathname.pwd/".brew-manifest.json"
    shared_packages = if manifest_path.exist?
      JSON.parse(manifest_path.read).fetch("shared_packages")
    else
      FALLBACK_SHARED_PACKAGES
    end

    # Tool directories
    libexec.install Dir["claude-code-*"]
    libexec.install Dir["claude_tui_*"]
    libexec.install "widgets" if File.directory?("widgets")
    libexec.install "install.sh"
    libexec.install "uninstall.sh" if File.exist?("uninstall.sh")
    libexec.install "claude-ui-mode.py" if File.exist?("claude-ui-mode.py")
    libexec.install "claudetui.py" if File.exist?("claudetui.py")
    # Persist the manifest (or write a synthetic one from fallback) so the test
    # block can read the canonical list without re-deriving it.
    if manifest_path.exist?
      libexec.install ".brew-manifest.json"
    else
      (libexec/".brew-manifest.json").write(
        JSON.generate("shared_packages" => FALLBACK_SHARED_PACKAGES),
      )
    end

    # Fail the build if a shared package was dropped during install — every
    # subcommand imports these and would ModuleNotFoundError at runtime.
    shared_packages.each do |pkg|
      odie "Required shared package '#{pkg}' missing after install (issue #6)" \
        unless (libexec/pkg).directory?
    end

    # Patch fallback version to match formula version (for non-git installs)
    inreplace libexec/"claudetui.py", /_FALLBACK_VERSION = ".*"/, "_FALLBACK_VERSION = \"#{version}\""

    # Primary CLI command — pin to the declared python@3 dependency so we
    # don't drift to whatever `python3` happens to be first in PATH on the
    # user's machine. The dispatcher's `os.execvpe(sys.executable, ...)`
    # then propagates this Python to every Python subcommand.
    #
    # IMPORTANT: use the unversioned alias path `opt/python@3/bin/python3`,
    # NOT `Formula["python@3"].opt_bin/"python3"`. The latter resolves to a
    # versioned Cellar path at install time (e.g. /opt/.../python@3.14/...)
    # and breaks when Homebrew rotates Python (3.14 → 3.15) — `brew cleanup`
    # removes the old Cellar entry and the wrapper hits "bad interpreter"
    # until the user `brew reinstall claude-tui`. The alias symlink lives
    # at HOMEBREW_PREFIX/opt/python@3 and brew updates it on rotation.
    python = HOMEBREW_PREFIX/"opt/python@3/bin/python3"
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
    # Use the same Python the wrapper uses (alias path that survives Python
    # version rotation). See the comment in `install` for the rationale.
    python = HOMEBREW_PREFIX/"opt/python@3/bin/python3"

    # Read the canonical shared-package list from the manifest the install
    # block persisted into libexec.
    require "json"
    shared_packages = JSON.parse((libexec/".brew-manifest.json").read).fetch("shared_packages")

    # Basic CLI dispatcher
    assert_match "claudetui", shell_output("#{bin}/claudetui --version 2>&1")

    # Regression test for issue #6: every shared package must be importable.
    # Mirrors the dispatcher's PYTHONPATH=libexec injection. shell_output
    # raises on non-zero exit, and assert_match verifies the marker — so a
    # failed import surfaces as an explicit test failure instead of a silent
    # `system` returning false.
    shared_packages.each do |pkg|
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
