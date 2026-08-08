#!/usr/bin/env bash
# Builds ~/Applications/Claude Code Notifier.app – a copy of terminal-notifier.app
# wearing Claude's icon.
#
# macOS takes a notification's icon from the bundle that posts it, and there is
# no way to override that from the command line: `-appIcon` drives a private API
# that Big Sur removed, and `-sender` hangs forever, which is fatal inside a hook
# the session waits on. Posting through our own bundle is what is left.
#
# Idempotent. Safe to skip – notify-done.sh falls back to plain terminal-notifier
# when this bundle is absent, just without the icon.

set -euo pipefail

DST="$HOME/Applications/Claude Code Notifier.app"

SRC="$(brew --prefix terminal-notifier 2>/dev/null)/terminal-notifier.app"
if [ ! -d "$SRC" ]; then
  echo "skipping notifier app: terminal-notifier.app not found (brew install terminal-notifier)" >&2
  exit 0
fi

# Electron keeps the default filename, but this is the real Claude icon.
ICON=/Applications/Claude.app/Contents/Resources/electron.icns
if [ ! -f "$ICON" ]; then
  echo "skipping notifier app: Claude.app not installed" >&2
  exit 0
fi

mkdir -p "$HOME/Applications"
rm -rf "$DST"
cp -R "$SRC" "$DST"
cp "$ICON" "$DST/Contents/Resources/Terminal.icns"

# Own bundle id, so upgrading the terminal-notifier formula cannot clobber this.
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.twixes.claude-code-notifier" "$DST/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName Claude Code" "$DST/Contents/Info.plist"

# Copying invalidates the original signature; without an ad-hoc re-sign macOS
# refuses to launch the bundle.
codesign --force --deep --sign - "$DST"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DST"

echo "built $DST"
