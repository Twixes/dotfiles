#!/usr/bin/env bash

mkdir -p ~/.config
rsync -avh --no-perms ./.config/ ~/.config/
if [[ $(uname) == 'Darwin' ]]; then
    ./init-macos.sh
fi
