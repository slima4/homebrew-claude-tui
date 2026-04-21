# Homebrew Tap for ClaudeTUI

[![Test formula](https://github.com/slima4/homebrew-claude-tui/actions/workflows/test-formula.yml/badge.svg?branch=main)](https://github.com/slima4/homebrew-claude-tui/actions/workflows/test-formula.yml)

Real-time statusline, live monitor, and session analytics for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Install

```bash
brew tap slima4/claude-tui
brew install claude-tui
```

Then run the setup to configure statusline, hooks, and slash commands:

```bash
claudetui setup
```

## What's included

- **claudetui monitor** — live session dashboard
- **claudetui stats** — post-session analytics
- **claudetui sessions** — browse, compare, resume, export sessions
- **Statusline** — real-time status bar (configured via `claudetui setup`)
- **Hooks** — file hotspots, dependency warnings, churn alerts
- **Slash commands** — `/tui:session`, `/tui:cost`, `/tui:perf`, `/tui:context`

## More info

- [Website](https://slima4.github.io/claude-tui/)
- [Repository](https://github.com/slima4/claude-tui)
