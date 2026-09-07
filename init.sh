#!/usr/bin/env bash

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

### UP FRONT ###
# Everything a human has to answer is at the top of this script and the top of
# init-macos.sh, so the hour of installing that follows can be walked away from.

# Ask for the administrator password once. On a shared devbox the account has
# no sudo at all (and a locked password, so asking would only hang): every
# root-only step below is then skipped, and init-linux.sh lists them for an
# admin at the end.
if sudo -n true 2>/dev/null || { id -Gn | grep -qwE 'admin|sudo|wheel' && sudo -v; }; then
    HAVE_SUDO=1
    # Then keep the timestamp warm for the rest of the run, including the shell
    # change at the bottom of this script and every Homebrew cask that ships a
    # pkg and shells out to sudo on its own. Each expiry would be another prompt.
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
else
    HAVE_SUDO=0
fi
export HAVE_SUDO

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

# Both of these point at macOS-only programs (the 1Password agent socket and
# pinentry-mac), so a Linux box keeps its defaults.
if [[ $(uname) == 'Darwin' ]]; then
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
fi

# Run OS-specific init
if [[ $(uname) == 'Darwin' ]]; then
    ./init-macos.sh
    # init-macos.sh is where Homebrew gets installed, but it ran as a child
    # process, so the PATH it set up went away with it. Everything below this
    # line – jq, strfile, fortune, fish – is brew-installed, and none of it is
    # on the PATH of the shell that started this script. Repeat the eval here.
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    ./init-linux.sh
    # Same idea: starship lands in ~/.local/bin, fortune and cowsay in /usr/games.
    export PATH="$HOME/.local/bin:$PATH:/usr/games"
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

# Compile fortunes to strfiles
for file in ./fortunes/*; do
    [[ $file == *.dat ]] && continue
    # scientific-quotes are from https://reddit.com/r/unixporn/comments/3620un/is_there_a_less_sexist_version_of_fortune/i00htra/
    strfile "$file" "$file.dat"
done
# fortune only searches its compiled-in directory, which is root-owned on
# Linux, so this is the one cosmetic step that needs sudo.
fortunes_dir=$(dirname $(dirname $(readlink -f $(which fortune))))/share/games/fortunes
if [[ $(uname) == 'Darwin' ]] || [ "$HAVE_SUDO" = 1 ]; then
    maybe_sudo=(); [[ $(uname) == 'Darwin' ]] || maybe_sudo=(sudo)
    # Remove dumb fortunes
    "${maybe_sudo[@]}" rm -f $fortunes_dir/men-women.dat
    # Copy fortunes to the system
    "${maybe_sudo[@]}" rsync -avh --no-perms --exclude .gitignore ./fortunes/ $fortunes_dir/
else
    echo "No sudo: custom fortunes not installed into $fortunes_dir"
fi

### SHELL ###

fish_path=$(command -v fish)
if [ "$HAVE_SUDO" = 1 ]; then
    # Mark fish as a valid shell (Debian's package already does)
    grep -qx "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells

    # Switch to fish as the default shell
    sudo chsh -s "$fish_path" $USER
elif [ "$(getent passwd "$USER" | cut -d: -f7)" != "$fish_path" ]; then
    echo "No sudo: ask an admin for \`usermod -s $fish_path $USER\`"
fi

# Install Fisher
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'

# Install Fisher packages. The list lives in .config/fish/fish_plugins, rsynced
# into place above, so adding a plugin here is one line in that file.
fish -c 'fisher update'
