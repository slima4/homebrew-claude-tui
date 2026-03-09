# Homebrew Tap for ClaudeUI

Real-time statusline, live monitor, and session analytics for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Install

```bash
brew tap slima4/claudeui
brew install claudeui
```

Then run the setup to configure statusline, hooks, and slash commands:

```bash
claude-ui-setup
```

## What's included

- **claude-ui-monitor** — live session dashboard
- **claude-stats** — post-session analytics
- **claude-sessions** — browse, compare, resume, export sessions
- **Statusline** — real-time status bar (configured via `claude-ui-setup`)
- **Hooks** — file hotspots, dependency warnings, churn alerts
- **Slash commands** — `/ui:session`, `/ui:cost`, `/ui:perf`, `/ui:context`

## More info

- [Website](https://slima4.github.io/claudeui/)
- [Repository](https://github.com/slima4/claudeui)
