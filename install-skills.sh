#!/usr/bin/env bash
# Installs Claude Code skills from their upstreams, so they are not vendored
# into this repo and cannot go stale.
#
# Found with `npx skills find <name>`, which resolves a skill name to
# owner/repo@skill on skills.sh. Worth remembering: nothing on disk records
# where a globally installed skill came from – `skills list` calls them all
# "local" – so that registry search is the way back to a source.
#
# Idempotent; re-running updates in place.

set -euo pipefail

SKILLS="npx -y skills@latest"

# The marketing / SEO / API-wrapper / bot pack: 67 of the skills here came from
# this one repo. Installed whole, so additions to the pack arrive too.
$SKILLS add openclaudia/openclaudia-skills --skill '*' -a claude-code -g -y

# Nine threejs-* skills. MIT.
$SKILLS add majidmanzarpour/threejs-game-skills --skill '*' -a claude-code -g -y

# Simplified Technical English, referenced from CLAUDE.md. A standalone skill
# repo rather than a pack, so a plain clone.
ste=~/.claude/skills/asd-ste100
if [ -d "$ste/.git" ]; then
    git -C "$ste" pull --ff-only
else
    rm -rf "$ste"
    git clone --depth 1 https://github.com/danyuchn/asd-ste100-skill "$ste"
fi
