#!/usr/bin/env bash

# Put config files in place
mkdir -p ~/.config
rsync -avh --no-perms ./.config/ ~/.config/
cp .gitconfig ~/.gitconfig

# Run OS-specific init
if [[ $(uname) == 'Darwin' ]]; then
    ./init-macos.sh
fi

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

# Install Fisher packages
fish -c 'fisher update && fisher install jorgebucaran/nvm.fish'
