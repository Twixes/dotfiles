# dotfiles

The ideal workstation setup.

## Installation

```bash
git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./init.sh
```

## Claude Code skills

`.claude/skills/` holds personal skills, symlinked into `~/.claude/skills/` by `init.sh` so they stay editable in place.

- `mm-review`: pull request review answering one question: would I merge this? Weighs the product bet first, then blast radius, then craft. Read-only, never posts to GitHub. Invoke with `/mm-review [PR number, URL, or branch]`.
  Each perspective is a reference file grounded in a named book or principle. Per-repo memory lives in `~/.claude/mm-review/<slug>.md`, so environment and convention discovery happens once.

## Claude Code hooks

`.claude/hooks/` is symlinked into `~/.claude/hooks/` the same way. macOS only.

- `notify-done.sh`: a `Stop` hook that posts a macOS notification when a turn ends, showing the elapsed time, the working directory, and the last thing Claude said. Stays quiet while the terminal is frontmost, since you are already looking at the answer — frontmost detection goes through `lsappinfo`, because the AppleScript route needs Accessibility permission and hangs on the consent dialog without it. Override the terminal with `CLAUDE_NOTIFY_TERM_BUNDLE`; it otherwise derives from `__CFBundleIdentifier`, so it follows you to iTerm or VS Code.
- `install-notifier-app.sh`: builds `~/Applications/Claude Code Notifier.app`, a copy of `terminal-notifier.app` wearing Claude's icon, because macOS takes a notification's icon from the posting bundle and neither `-appIcon` nor `-sender` is usable. Run by `init-macos.sh`; the hook degrades to a plain, icon-less notification if it is missing.

`init-macos.sh` registers the hook by merging one entry into `~/.claude/settings.json`, which is otherwise left alone — the rest of that file is machine-specific state that has no business in git.
