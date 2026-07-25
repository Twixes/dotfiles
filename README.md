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
