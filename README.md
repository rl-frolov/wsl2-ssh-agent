# Share Windows ssh-agent with WSL2

## Abstract

Windows' ssh-agent stores all keys in registry, so they persist between reboots. On the other hand,
WSL' ssh-agent identities won't persist even between terminal sessions without additional efforts
from users.

This project aims to solve both issues, while being easy to use and install

## Prerequisites

1. `socat`. To install use the following:
   ```sudo apt update && sudo apt install socat```
2. `npiperelay.exe` **on windows partition, accessible from WSL**  
   Comes pre-built with this repo for convenience. Can be built from [source](https://github.com/jstarks/npiperelay)
3. Windows' version of `OpenSSH` **must be greater or equal** to the WSL'. To check currently installed version:  
   ```ssh -V```
   To update, refer to [official OpenSSH for windows repository](https://github.com/PowerShell/Win32-OpenSSH)

### Plug and play

```shell
git clone git@github.com:rl-frolov/wsl2-ssh-agent.git
cd wsl2-ssh-agent
ln -s $(powershell.exe -Command "cd \$env:USERPROFILE; wsl --exec pwd") ~/winhome
mkdir -p ~/winhome/.wsl
cp npiperelay.exe ~/winhome/.wsl/
mkdir -p ~/.local/bin
cp wsl-ssh-agent ~/.local/bin/
echo -e "\neval \$(~/.local/bin/wsl-ssh-agent start)" >> ~/.bashrc
```

## Usage

### Available commands
- `start` Starts the daemon. Outputs environment export command, just like vanilla `ssh-agent`.
  All runtime files are stored in `/tmp` by default
- `stop` Stops the daemon. Cleans runtime files. Removes corresponding directory in `/tmp` by default
- `status` Get status of the daemon
- `foreground` Runs the actual code in foreground. When using `start` (see above) it actually starts background daemon
  with this command, so it could be useful to debug

### Available flags

None, as of now

### Configuration

All paths can be changed by editing the top lines of the script

## Credits

This project is heavily inspired by [rupor-github](https://github.com/rupor-github/wsl-ssh-agent)
