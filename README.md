# dotfiles

My personal workstation setup.

## How to apply

Install 1Password, sign in, then set Settings → Developer → "Integrate with 1Password CLI" & "Use the SSH agent" to on.

Then, run:

```bash
git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./init.sh
```

`init.sh` asks for three things, all in the first couple of minutes: your
password, the signing key out of 1Password, and a sign-in to the App Store,
because `mas` can only install apps the signed-in Apple Account already owns.
After that the long tail of installing can be walked away from – except for the
casks that ship a vendor installer or a system extension, which ask for
themselves whatever the script does.

Before erasing a machine, run:
```bash
./gpg-key.sh backup
```

## Linux devboxes

The same `init.sh` works on a Debian/Ubuntu box, including one where the
account has no sudo (the Zeta devbox, for instance). Everything that can live
under `$HOME` does – starship, the Ghostty terminfo, extra cows, the Fisher
plugins – and the prompt gets a purple username so a devbox shell is telling
apart from a local one. Signing is turned off through `~/.gitconfig-local` when
the GPG key is not on the machine.

```bash
git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./init.sh
```

Without sudo the script ends with the short list an admin still has to run:
the apt packages (`fish`, `jq`, `rsync`, `fortune-mod`, `fortunes`, `cowsay`),
the login shell (`usermod -s /usr/bin/fish <user>`), and the custom fortunes.
The SSH and GPG configs are macOS-only and are left alone on Linux.
