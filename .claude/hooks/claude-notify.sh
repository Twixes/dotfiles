#!/bin/bash
# Local macOS notifications for Claude Code, on two events:
#
#   Stop          the main agent finished a turn – says what it did
#   Notification  Claude wants permission or has gone idle – says what it needs
#
# The built-in inputNeededNotifEnabled does not produce a local alert, so the
# Notification event is the only way to hear about a blocked turn.
#
# Stays silent while the terminal app is frontmost, because then you are already
# looking at it. Override the app with CLAUDE_NOTIFY_TERM_BUNDLE.

INPUT=$(cat)
IFS=$'\t' read -r EVENT TRANSCRIPT CWD STOP_ACTIVE ASK < <(
  echo "$INPUT" | jq -r '[.hook_event_name // "Stop", .transcript_path // "",
    .cwd // "", .stop_hook_active // false, (.message // "")] | @tsv')

# Already inside a Stop-hook-continued turn – do not notify twice.
[ "$STOP_ACTIVE" = "true" ] && exit 0

# macOS sets __CFBundleIdentifier for anything launched from a .app, and it
# survives Ghostty -> shell -> claude -> hook. Deriving it keeps the check
# working from iTerm or VS Code; the literal is only a last resort.
TERM_BUNDLE=${CLAUDE_NOTIFY_TERM_BUNDLE:-${__CFBundleIdentifier:-com.mitchellh.ghostty}}

# Skip the notification when the terminal is already frontmost.
#
# LaunchServices is used rather than `System Events`, because the AppleScript
# route needs Accessibility permission and hangs on the consent dialog when it
# is missing. `lsappinfo` needs no permission.
#
# If detection fails for any reason, fall through and notify. A stray alert is
# better than a silently lost one. A locked screen reports `loginwindow`, which
# correctly counts as "not focused".
FRONT_ASN=$(lsappinfo front 2>/dev/null)
if [ -n "$FRONT_ASN" ]; then
  FRONT_BUNDLE=$(lsappinfo info -only bundleID "$FRONT_ASN" 2>/dev/null | sed -n 's/.*"CFBundleIdentifier"="\(.*\)"/\1/p')
  [ "$FRONT_BUNDLE" = "$TERM_BUNDLE" ] && exit 0
fi

# A Notification already says what it needs, so the transcript is only read for
# the Stop case, where the answer has to be dug out of it.
if [ "$EVENT" = Notification ]; then
  TITLE="Claude Code – needs you"
  MESSAGE="${ASK:-Waiting on you.}"
  SOUND=Ping
  SLOT=needs-you
else
  TITLE="Claude Code – done"
  SOUND=Glass
  SLOT=done
  [ -f "$TRANSCRIPT" ] || exit 0
fi

# Newest-first scan for the two things the alert needs: how long the turn took,
# and the last thing Claude said. The turn started at the last REAL user prompt
# – `type: "user"` entries also carry tool_results, which are not prompts.
#
# One jq over a bounded window. Scanning line-by-line instead costs ~2 jq forks
# per line, which measured 8.5s on the longest turn in this transcript history –
# close to the hook timeout, on exactly the long turns worth notifying about.
# 500 lines covers p99 of observed turns; past that the duration is dropped but
# the message still resolves, since it sits ~4 lines from the end.
[ "$EVENT" = Notification ] || IFS=$'\t' read -r ELAPSED MESSAGE < <(
  tac "$TRANSCRIPT" 2>/dev/null | head -n 500 | jq -rs '
    def prompt:
      select(.type == "user")
      | select([.message.content[]? | select(.type == "tool_result")] | length == 0);
    def answer:
      select(.type == "assistant")
      | [.message.content[]? | select(.type == "text") | .text]
      | join(" ")
      | select(. != "");
    [ (first(.[] | prompt | .timestamp | sub("\\.[0-9]+Z$"; "Z")
             | now - fromdateiso8601 | floor) // ""),
      ((first(.[] | answer) // "") | gsub("\\s+"; " ") | .[0:220]) ]
    | @tsv' 2>/dev/null)

DIR="${CWD:-$PWD}"
# `${DIR/#$HOME/~}` looks right but is a no-op: bash tilde-expands the
# replacement back to $HOME. Quoting the ~ keeps it literal.
case "$DIR" in "$HOME" | "$HOME"/*) DIR="~${DIR#"$HOME"}" ;; esac
SUBTITLE="$DIR"
if [ -n "$ELAPSED" ]; then
  if [ "$ELAPSED" -ge 60 ]; then
    SUBTITLE="$SUBTITLE · $((ELAPSED / 60))m $((ELAPSED % 60))s"
  else
    SUBTITLE="$SUBTITLE · ${ELAPSED}s"
  fi
fi

# macOS takes a notification's icon from the bundle that posts it, so the alert
# goes out through a copy of terminal-notifier.app wearing Claude's icon.
# `-appIcon` would be the obvious flag, but it drives a private API that Big Sur
# removed, and `-sender` hangs forever – fatal in a hook the session waits on.
NOTIFIER="$HOME/Applications/Claude Code Notifier.app/Contents/MacOS/terminal-notifier"
[ -x "$NOTIFIER" ] || NOTIFIER=terminal-notifier

"$NOTIFIER" \
  -title "$TITLE" \
  -subtitle "$SUBTITLE" \
  -message "${MESSAGE:-Turn finished.}" \
  -sound "$SOUND" \
  -group "claude-$SLOT-$DIR" \
  -activate "$TERM_BUNDLE"
