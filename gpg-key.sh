#!/usr/bin/env bash
# Move the GPG signing key between machines through 1Password.
#
#   ./gpg-key.sh backup    export the secret key + ownertrust into 1Password
#   ./gpg-key.sh restore   import them onto a new machine
#
# The key is piped straight between gpg and op, so it never lands on disk, never
# appears in a process argument, and never reaches shell history.
#
# .gitconfig sets commit.gpgsign, so a machine without this key cannot commit at
# all. Run backup before wiping the old machine.
#
# The exported key is passphrase-protected. Keep the passphrase in the same
# vault, or you arrive holding a key you cannot open.

set -euo pipefail

KEY_ID=1ABB63188149D508
FINGERPRINT=31A139D941FC9277E012499F1ABB63188149D508

# Pin the account, not just the vault. `op` spans three accounts here, and the
# personal vault in a business account is called Employee, not Private – so
# `--vault Private` alone silently lands the key in an employer's account.
ACCOUNT=my.1password.com
VAULT=Private
KEY_TITLE="GPG signing key $KEY_ID"
TRUST_TITLE="GPG ownertrust"

# Create the document the first time, replace its contents after that. The
# lookup reads from /dev/null, so it cannot swallow the key on its way through
# the pipe to the write below.
stash() {
    local title=$1 filename=$2
    if op document get "$title" --account "$ACCOUNT" --vault "$VAULT" >/dev/null 2>&1 </dev/null; then
        op document edit "$title" - --file-name "$filename" --account "$ACCOUNT" --vault "$VAULT" >/dev/null
        echo "  updated: $title"
    else
        op document create - --title "$title" --file-name "$filename" --account "$ACCOUNT" --vault "$VAULT" >/dev/null
        echo "  created: $title"
    fi
}

case "${1:-}" in
backup)
    gpg --list-secret-keys "$KEY_ID" >/dev/null || {
        echo "no secret key $KEY_ID on this machine" >&2
        exit 1
    }
    gpg --export-secret-keys --armor "$KEY_ID" | stash "$KEY_TITLE" gpg-signing-key.asc
    gpg --export-ownertrust | stash "$TRUST_TITLE" gpg-ownertrust.txt

    # Read it back and confirm it parses as the key we meant, without importing.
    echo "verifying:"
    if op document get "$KEY_TITLE" --account "$ACCOUNT" --vault "$VAULT" \
        | gpg --import-options show-only --import 2>/dev/null \
        | grep -q "$FINGERPRINT"; then
        echo "  stored key matches $FINGERPRINT"
    else
        echo "  STORED KEY DID NOT VERIFY – do not wipe this machine" >&2
        exit 1
    fi
    ;;
restore)
    op document get "$KEY_TITLE" --account "$ACCOUNT" --vault "$VAULT" | gpg --import
    op document get "$TRUST_TITLE" --account "$ACCOUNT" --vault "$VAULT" | gpg --import-ownertrust
    echo "verifying:"
    if echo test | gpg --clearsign --local-user "$KEY_ID" >/dev/null 2>&1; then
        echo "  signing works"
    else
        echo "  cannot sign – if there was no passphrase prompt, check ~/.gnupg/gpg-agent.conf" >&2
        exit 1
    fi
    ;;
*)
    echo "usage: $0 {backup|restore}" >&2
    exit 1
    ;;
esac
