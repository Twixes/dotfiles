# dotfiles

The ideal workstation setup.

## Installation

```bash
git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./init.sh
```

## Claude Code skills

`.claude/skills/` holds every skill, symlinked into `~/.claude/skills/` by `init.sh` so they stay editable in place. Most were installed from marketplaces and carry no upstream reference, so they are vendored here rather than reinstalled — a wipe would otherwise lose them. `asd-ste100` came from [danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill) and keeps its LICENSE.

- `mm-review`: pull request review answering one question: would I merge this? Weighs the product bet first, then blast radius, then craft. Read-only, never posts to GitHub. Invoke with `/mm-review [PR number, URL, or branch]`.
  Each perspective is a reference file grounded in a named book or principle. Per-repo memory lives in `~/.claude/mm-review/<slug>.md`, so environment and convention discovery happens once.

## Claude Code hooks

`.claude/hooks/` is symlinked into `~/.claude/hooks/` the same way. macOS only.

- `claude-notify.sh`: posts a macOS notification on two events — `Stop`, when a turn finishes, showing elapsed time, working directory, and the last thing Claude said; and `Notification`, when Claude wants permission or has gone idle, showing what it is waiting for. The built-in `inputNeededNotifEnabled` does not produce a local alert, so the `Notification` hook is the only way to hear about a blocked turn. Both stay quiet while the terminal is frontmost, since you are already looking at it — frontmost detection goes through `lsappinfo`, because the AppleScript route needs Accessibility permission and hangs on the consent dialog without it. Override the terminal with `CLAUDE_NOTIFY_TERM_BUNDLE`; it otherwise derives from `__CFBundleIdentifier`, so it follows you to iTerm or VS Code.
- `install-notifier-app.sh`: builds `~/Applications/Claude Code Notifier.app`, a copy of `terminal-notifier.app` wearing Claude's icon, because macOS takes a notification's icon from the posting bundle and neither `-appIcon` nor `-sender` is usable. Run by `init-macos.sh`; the hook degrades to a plain, icon-less notification if it is missing.

## Claude Code config

- `.claude/settings.base.json` is merged into `~/.claude/settings.json` by `init.sh`, after the OS-specific init that provides `jq`. The baseline wins on every key it defines; keys it says nothing about survive, so machine-local state accumulates without git fighting it.
- `.claude/mcp-servers.json` holds **personal** MCP servers only. Work ones are deliberately absent — they belong to whichever employer issued the credentials.
- `.claude/CLAUDE.md` is the global instruction file, symlinked into `~/.claude/`. Kept free of employer specifics, since this repo is public – the role section is a placeholder to rewrite when the job changes.

## Applications

Everything installable lives in the `Brewfile`, casks included. `Setappfile` lists the apps that come from Setapp instead: Setapp ships no CLI and no documented install URL, so those cannot be scripted. The `setapp` cask installs the client, and `init-macos.sh` then prints which listed apps are still missing once you have signed in.

## Brewfile

Regenerate with `brew bundle dump --file=Brewfile --force`. Editor extensions stay out of it — Cursor and VS Code sync their own — via `HOMEBREW_BUNDLE_DUMP_NO_VSCODE`, exported in `config.fish`.

## Moving to a new machine

In order. The order matters — `op` cannot authorise before the desktop app is installed and told to allow it, and `gpg-key.sh` cannot run before `op` exists.

1. **Install 1Password and sign in** to `my.1password.com`, then turn on *Settings → Developer → Integrate with 1Password CLI* and *Use the SSH agent*. Nothing below works without this.
2. **Clone this repo.** It is public, so no key is needed yet:
   ```bash
   git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
   cd ~/Developer/dotfiles
   ```
   macOS will offer to install the Xcode command line tools if `git` is missing. Accept.
3. **`./init.sh`** — Homebrew, the `Brewfile` (including `gnupg`, `pinentry-mac`, `1password-cli`), config, Claude Code, `~/.gnupg/gpg-agent.conf`.
4. **`./gpg-key.sh restore`** — imports the signing key and signs a test message. Until this runs, every `git commit` fails, because `.gitconfig` sets `commit.gpgsign`.
5. **Check signing end to end:**
   ```bash
   git -C ~/Developer/dotfiles commit --allow-empty -m "signing check"
   git -C ~/Developer/dotfiles log --show-signature -1
   git -C ~/Developer/dotfiles reset --soft HEAD~1  # soft: never touch the working tree
   ```

Two things cannot live in a public repo:

- **SSH keys** need nothing beyond step 1 — they live in the 1Password agent and follow the 1Password login. The agent is only *used* because of the `IdentityAgent` line in `~/.ssh/config`, though, so that file is tracked here and installed by `init.sh`.
- **The GPG signing key** moves through 1Password, below.

### Carrying the GPG key across

Key `1ABB63188149D508`, through the `Private` vault of the **personal** 1Password account (`my.1password.com`). The script pins the account as well as the vault: `op` spans three accounts here, and a business account's personal vault is called `Employee`, not `Private` — so passing `--vault Private` alone silently lands the key in an employer's account. On the old machine, before it is wiped:

```bash
./gpg-key.sh backup
```

On the new machine, after `./init.sh` has installed `gnupg` and `pinentry-mac`:

```bash
./gpg-key.sh restore
```

`backup` pipes the secret key and the ownertrust file straight from `gpg` into `op`, so neither lands on disk or in shell history, then reads the stored key back and checks its fingerprint before reporting success. `restore` imports both and signs a test message. Both are idempotent.

Importing the ownertrust file is what avoids the interactive `gpg --edit-key … trust` dance.

The exported key is passphrase-protected, so keep the passphrase in the same vault — otherwise the new machine holds a key it cannot open. If the passphrase prompt never appears, `~/.gnupg/gpg-agent.conf` did not land — `gpgconf --kill gpg-agent` and retry.
