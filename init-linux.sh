#!/usr/bin/env bash
# Linux counterpart of init-macos.sh, written for shared devboxes where the
# account may have no sudo: everything that can live under $HOME does, and the
# few root-only steps are done when sudo works and listed for an admin when not.

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
have_sudo=${HAVE_SUDO:-0}
admin_todo=()

### PACKAGES ###

# fish is the shell, jq and rsync are used by init.sh, the rest is the greeting.
packages=(fish jq rsync fortune-mod fortunes cowsay)
missing=()
for package in "${packages[@]}"; do
    dpkg -s "$package" >/dev/null 2>&1 || missing+=("$package")
done
if [ ${#missing[@]} -gt 0 ]; then
    if [ "$have_sudo" = 1 ]; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "${missing[@]}"
    else
        admin_todo+=("apt-get install -y ${missing[*]}")
    fi
fi

### USER-LOCAL TOOLS ###

mkdir -p ~/.local/bin ~/.local/share/cows ~/.terminfo

# Starship is not packaged by Debian; the official installer drops a single
# binary wherever it is told.
if ! [ -x ~/.local/bin/starship ]; then
    curl -sS --proto '=https' --tlsv1.2 -fL https://starship.rs/install.sh \
        | sh -s -- -y -b ~/.local/bin
fi

# Ghostty's terminfo is not in ncurses-base yet. Without it every ssh session
# from Ghostty warns and falls back to xterm-256color. The source file is
# regenerated on the Mac with `infocmp -x xterm-ghostty`.
tic -x -o ~/.terminfo "$repo_dir/terminfo/xterm-ghostty.ti"

# Cows missing from Debian's cowsay, found through COWPATH (set in
# .config/fish/conf.d/linux.fish).
cp "$repo_dir"/cows/*.cow ~/.local/share/cows/

### GIT ###

# The tracked .gitconfig signs every commit with a key that gpg-key.sh restores
# from 1Password – on a Mac. A box without that key would fail every commit,
# so turn signing off there through the optional local include.
if ! gpg --list-secret-keys 1ABB63188149D508 >/dev/null 2>&1; then
    cat > ~/.gitconfig-local <<'EOF'
# Written by init-linux.sh: no signing key on this machine.
[commit]
	gpgsign = false
EOF
fi

### HAND-OFF ###

if [ ${#admin_todo[@]} -gt 0 ]; then
    echo "No sudo here. An admin still needs to run:"
    printf '  %s\n' "${admin_todo[@]}"
fi
