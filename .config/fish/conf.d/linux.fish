# Linux-only shell setup (devboxes). Sourced before config.fish, which matters:
# config.fish only enables starship if it is on the PATH, and on Linux it lives
# in ~/.local/bin (see init-linux.sh). A no-op on macOS.
test (uname) = Linux; or exit

# Devboxes are shared hosts: keep new files private by default.
umask 077

# ~/.local/bin goes first so wrappers there shadow system binaries – on the
# Zeta devbox that is how `claude`/`codex` pick up team secrets.
fish_add_path -g -m ~/.local/bin
# Debian keeps fortune and cowsay here, off the default PATH.
fish_add_path -g /usr/games

# Cows that Debian's cowsay does not ship (init-linux.sh copies them here).
set -gx COWPATH ~/.local/share/cows:/usr/share/cowsay/cows

# Same prompt as the Mac, with one difference: a purple username instead of the
# default yellow, so a devbox shell is telling apart from a local one at a
# glance. Derived from the tracked starship.toml on every change to it, so the
# rest of the prompt never drifts between machines.
set -l base ~/.config/starship.toml
set -l derived ~/.config/starship-linux.toml
if test -r $base; and begin; not test -e $derived; or test $base -nt $derived; end
    sed -e '/^\[username\]/a style_user = "bold purple"' $base > $derived
end
set -gx STARSHIP_CONFIG $derived
