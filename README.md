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
