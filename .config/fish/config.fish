eval "$(/opt/homebrew/bin/brew shellenv)"
pyenv init - | source
pyenv virtualenv-init - | source

status --is-interactive
and starship init fish | source
