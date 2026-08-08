# dotfiles

My personal workstation setup.

## How to apply

Install 1Password, sign in, then set Settings → Developer → "Integrate with 1Password CLI" & "Use the SSH agent" to on.

Then, run:

```bash
git clone https://github.com/Twixes/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./init.sh
./gpg-key.sh restore
```

Before erasing a machine, run:
```bash
./gpg-key.sh backup
```
