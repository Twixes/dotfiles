#!/usr/bin/env bash

# Put config files in place
mkdir -p ~/.config
rsync -avh --no-perms ./.config/ ~/.config/

# Run OS-specific init
if [[ $(uname) == 'Darwin' ]]; then
    ./init-macos.sh
fi

# Mark fish as a valid shell
echo '/opt/homebrew/bin/fish' | sudo tee -a /etc/shells

# Switch to fish as the default shell
sudo chsh -s /opt/homebrew/bin/fish $USER

# Install Fisher
fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'

# Install Fisher packages
fish -c 'fisher update && fisher install jorgebucaran/nvm.fish'
