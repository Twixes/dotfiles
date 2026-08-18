#!/usr/bin/env bash

### UP FRONT ###
# init.sh has already asked for the sudo password and keeps the timestamp warm,
# so nothing below has to ask again. What is left that needs a human is here
# rather than scattered through the installs, in the order that gets all the
# asking done before the first long download starts. Homebrew comes first only
# because none of the rest can run without it.

# Homebrew's installer stops to have you confirm unless told not to
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# The installer does not touch the PATH of the shell it was started from
eval "$(/opt/homebrew/bin/brew shellenv)"

# The Brewfile below stays the list of record. These four are pulled ahead of it
# only because the two steps that follow cannot run without them.
brew bundle --file - <<'EOF'
brew "gnupg"
brew "mas"
brew "pinentry-mac"
cask "1password-cli"
EOF

# .gitconfig sets commit.gpgsign, so a machine without the signing key cannot
# commit at all. Restoring it wants a human twice, for 1Password and then for
# the key's own passphrase, so it belongs here rather than being discovered the
# first time a commit is refused. Read the id from .gitconfig, so there is one
# copy of it; the key itself moves through 1Password, never through this repo.
signingkey=$(git config --file ./.gitconfig --get user.signingkey)
if ! gpg --list-secret-keys "$signingkey" >/dev/null 2>&1; then
    ./gpg-key.sh restore \
        || echo "WARNING: no signing key $signingkey – commits keep failing until ./gpg-key.sh restore does" >&2
fi

# mas installs only what the signed-in Apple Account already owns. Nothing can
# sign in on its behalf, and it offers no way to ask whether anyone is signed in
# – so the check is an install attempt. Xcode is the right one to attempt, since
# it has to be in place before `brew bundle` anyway. Apps already installed exit
# 0 without downloading, so a machine that is set up never sees the prompt.
xcode_id=$(sed -n 's/^mas "Xcode", id: //p' ./Brewfile)
while ! mas install "$xcode_id"; do
    open -a "App Store"
    read -rp 'Sign in to the App Store, then press Return to retry – or type "skip": ' answer
    [ "$answer" = skip ] && break
done

# Homebrew formulas that build from source shell out to xcodebuild, and
# xcodebuild refuses to run until its licence is accepted. Left alone that is a
# full-screen interactive prompt in the middle of a build, so get it over with
# here rather than after `brew bundle` has already failed on it.
if [ -d /Applications/Xcode.app ]; then
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
fi

### SYSTEM SETTINGS ###

# Close any open System Preferences panes to prevent them from overriding settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Minimize springing delay in Finder
defaults write -g com.apple.springing.delay -float 0.1

# Repeat keys as fast as the Keyboard pane allows, and start repeating sooner
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Substitutions that mangle anything technical – a path typed after a sentence
# becomes capitalised, two spaces become a period, quotes become curly ones that
# no shell or compiler accepts
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Get the dock out of the way
defaults write com.apple.dock autohide -bool true

# Remove dock showing delay
defaults write com.apple.dock autohide-delay -float 0

# Keep the dock to what I actually put there
defaults write com.apple.dock show-recents -bool false

# Scale rather than genie on minimise
defaults write com.apple.dock mineffect -string scale

# Restart dock to apply settings
killall Dock

# Show every extension, not just the ones macOS deems unfamiliar
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Search the current folder rather than the whole Mac
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# Show where the selected item actually is
defaults write com.apple.finder ShowPathbar -bool true

# Restart Finder to apply settings
killall Finder

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

# Install packages with Homebrew based on the Brewfile
brew bundle --file ./Brewfile

### WALLPAPER ###

# Below brew bundle, which is where the wallpaper CLI comes from – macOS itself
# has offered no way to do this since Sonoma. The .madesktop file is only a stub
# naming an asset macOS downloads on demand, so nothing has to travel in here.
wallpaper set "/System/Library/Desktop Pictures/Radial Yellow.madesktop"

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
