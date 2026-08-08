#!/usr/bin/env bash

# Close any open System Preferences panes to prevent them from overriding settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

### SYSTEM SETTINGS ###

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Minimize springing delay in Finder
defaults write -g com.apple.springing.delay -float 0.1

# Remove dock showing delay
defaults write com.apple.dock autohide-delay -float 0

# Restart dock to apply settings
killall Dock

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Disable line marks
defaults write com.apple.Terminal ShowLineMarks -int 0

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Turn off login banner
touch ~/.hushlogin

### PACKAGES ###

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install packages with Homebrew based on the Brewfile
brew bundle --file ./Brewfile

### SETAPP ###

# Setapp ships no CLI and no documented install URL, so its apps cannot be
# installed from a script the way casks can. The `setapp` cask in the Brewfile
# gets the client; this only reports what is still missing after you sign in.
missing=""
while IFS= read -r app; do
    [ -n "$app" ] || continue
    [ -d "/Applications/Setapp/$app.app" ] || missing="$missing  $app"$'\n'
done <./Setappfile
if [ -n "$missing" ]; then
    printf 'Setapp apps still to install from the Setapp client:\n%s' "$missing" >&2
fi

### CLAUDE CODE NOTIFICATIONS ###

# Below brew bundle, which is where terminal-notifier comes from. The rest of
# the Claude Code setup is OS-neutral and lives back in init.sh.
./.claude/hooks/install-notifier-app.sh

### GIT ###

# Recreate the git-lfs filter block rather than tracking it in .gitconfig
git lfs install

# The signing key moves through 1Password, never through this repo – see
# ./gpg-key.sh. Read the id from .gitconfig so there is one copy of it.
signingkey=$(git config --file ./.gitconfig --get user.signingkey)
gpg --list-secret-keys "$signingkey" >/dev/null 2>&1 \
    || echo "WARNING: signing key $signingkey missing – run ./gpg-key.sh restore, or commits will fail" >&2
