# .files

The ideal workstation setup.

## Installation

```bash
git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
rsync --exclude ".git/" \
    --exclude ".gitignore" \
    --exclude ".DS_Store" \
    --exclude "README.md" \
    -avh --no-perms ~/Developer/dotfiles/ ~
# If on macOS, also run the configuration script
~/.macos
```
