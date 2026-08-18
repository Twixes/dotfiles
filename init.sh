#!/usr/bin/env bash

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

### UP FRONT ###
# Everything a human has to answer is at the top of this script and the top of
# init-macos.sh, so the hour of installing that follows can be walked away from.

# Ask for the administrator password once
sudo -v

# Then keep the timestamp warm for the rest of the run, including the shell
# change at the bottom of this script and every Homebrew cask that ships a pkg
# and shells out to sudo on its own. Each expiry would be another prompt.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Put config files in place
mkdir -p ~/.config
rsync -avh --no-perms ./.config/ ~/.config/
cp .gitconfig ~/.gitconfig
# Pulled in by .gitconfig, but only for repos owned by the work org
cp .gitconfig-zetalabs-ai ~/.gitconfig-zetalabs-ai

### CLAUDE CODE ###

# Symlink rather than copy, so skills stay editable in place and every tweak is already in git
mkdir -p ~/.claude/skills
for skill in "$repo_dir"/.claude/skills/*/; do
    ln -sfn "${skill%/}" ~/.claude/skills/
done

mkdir -p ~/.claude/hooks
for hook in "$repo_dir"/.claude/hooks/*.sh; do
    ln -sfn "$hook" ~/.claude/hooks/
done

ln -sfn "$repo_dir"/.claude/CLAUDE.md ~/.claude/CLAUDE.md

### SSH ###

# No keys here – they live in the 1Password agent. But that agent is only used
# because of the IdentityAgent line in this config, so the config has to travel.
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp .ssh/config ~/.ssh/config
chmod 600 ~/.ssh/config

### GPG ###

# Without this, gpg-agent falls back to a pinentry that cannot prompt from a
# terminal, and every signed commit fails at the passphrase step. The key itself
# comes down in the OS-specific init below, which is where gpg and op come from.
mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
cp .gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf

# Run OS-specific init
if [[ $(uname) == 'Darwin' ]]; then
    ./init-macos.sh
fi

### CLAUDE CODE, PART TWO ###
# Below the OS-specific init, which is where jq comes from.

# Fold a tracked file into one the tool also writes to at runtime. The tracked
# side wins on every key it defines; keys it says nothing about survive, so
# machine-local state accumulates without git fighting it.
merge_json() { # $1 = live file, $2 = tracked file
    mkdir -p "$(dirname "$1")"
    [ -f "$1" ] || echo '{}' >"$1"
    jq -s '.[0] * .[1]' "$1" "$2" >"$1.tmp" && mv "$1.tmp" "$1"
}

merge_json ~/.claude/settings.json ./.claude/settings.base.json
# Personal MCP servers. Work ones are deliberately absent – they belong to
# whichever employer issued the credentials.
merge_json ~/.claude.json ./.claude/mcp-servers.json

# Skills with a real upstream are installed rather than vendored
./install-skills.sh

### FORTUNES ###

fortunes_dir=$(dirname $(dirname $(readlink -f $(which fortune))))/share/games/fortunes
# Remove dumb fortunes
rm -f $fortunes_dir/men-women.dat
# Compile fortunes to strfiles
for file in ./fortunes/*; do
    # scientific-quotes are from https://reddit.com/r/unixporn/comments/3620un/is_there_a_less_sexist_version_of_fortune/i00htra/
    strfile "$file" "$file.dat"
done
# Copy fortunes to the system
rsync -avh --no-perms --exclude .gitignore ./fortunes/ $fortunes_dir/

### SHELL ###

# Mark fish as a valid shell
echo '/opt/homebrew/bin/fish' | sudo tee -a /etc/shells

# Switch to fish as the default shell
sudo chsh -s /opt/homebrew/bin/fish $USER

# Install Fisher
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'

# Install Fisher packages. The list lives in .config/fish/fish_plugins, rsynced
# into place above, so adding a plugin here is one line in that file.
fish -c 'fisher update'
