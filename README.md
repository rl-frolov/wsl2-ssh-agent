# wsl-ssh-agent

_Forward your Windows OpenSSH agent to WSL2 seamlessly._

Tired of typing in passphrases for your SSH keys, despite never needing to in your Windows environment? Maybe you know how to share your Windows ssh-agent with WSL, but always wanted to simplify the process or get some user friendly interface? Then you will find `wsl-ssh-agent` incredibly useful!

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Credits](#credits)
- [A Note on Development](#a-note-on-development)
- [Support the Creator](#support-the-creator)

## Features

- **Single source of truth** – Keys are stored in Windows (registry), survive reboots, and are shared automatically
- **WSL2 native** – Uses systemd user services for automatic start, restart on failure and clean shutdown
- **Simple setup and cleanup** – One command to install, one command to uninstall. No manual configuration required
- **Flexible** – Works as a systemd service (recommended) or as a standalone foreground process
- **XDG and FHS compliant** – after installation, all the files are exactly where you expect them to be 
- **Tested** – Designed for Ubuntu 22.04 but should work on any systemd‑based distribution (under WSL2).

## Prerequisites

> [!IMPORTANT]
> In order to use the tool, ensure that all of the requirements are met!

### You are running WSL2

While the end result is still achievable in WSL1, the approach is entirely different, and `wsl-ssh-agent` does not support it.

To check, which version of WSL you have installed run the following:

```lang-powershell
#Powershell
wsl --version
```

### Your Windows OpenSSH version is greater than WSL

To check this run the following (syntax is the same for both bash and Powershell):

```lang-shell
ssh -V
```

The tool was developed and tested under following versions (although any combination is expected to work)

```lang-shell
OpenSSH_for_Windows_9.8p1 Win32-OpenSSH-GitHub, LibreSSL 3.9.2
OpenSSH_8.9p1 Ubuntu-3ubuntu0.14, OpenSSL 3.0.2 15 Mar 2022
```

> [!TIP]
> To upgrade/install OpenSSH for Windows, consult with [this wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki)

### Your Windows OpenSSH agent is set up

To check this, run:

```lang-powershell
# Powershell
ssh-add -l
# Expected result: list of your added ssh-keys
```

> [!TIP]
> If you have an error when running the command above, consult with [this wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki)

### `socat` installed in WSL

```lang-bash
sudo apt update && sudo apt install socat
```

### `npiperelay`

Download the latest release from [jstarks/npiperelay](https://github.com/jstarks/npiperelay/releases) and **place it on your Windows partition**.
By default, both installer and agent look for the `npiperelay.exe` at `~/winhome/.wsl/npiperelay.exe`
(assuming you symlink `winhome` to your Windows user home):

```lang-bash
# Add a symlink to Windows user's home to WSL user's home
ln -s "$(powershell.exe -Command 'cd $env:USERPROFILE; wsl --exec pwd' | tr -d '\r')" ~/winhome
```

If you want to choose another location, you can find all relevant info in [Configuration](#configuration)

## Quick start

### Download

Clone the repository:

```lang-bash
git clone https://github.com/rl-frolov/wsl2-ssh-agent.git
```

### Install

> [!NOTE]
> While the recommended way to use the tool is to install it first, you can skip this step.
> There will be less functionality and QOL, but this way you have the ultimate control on how to handle things.

Run the [install script](scripts/install.sh):

```lang-bash
./wsl2-ssh-agent/scripts/install.sh
```

The installer will:
- Copy the agent to `~/.local/bin/wsl-ssh-agent`
- Copy the systemd service file to `~/.config/systemd/user/wsl-ssh-agent.service`
- Enable and start the service
- Add ~/.local/bin to your PATH (if not already present)
- Add the necessary environment variables to your .bashrc
- Test the connection and report success or warnings

> [!TIP]
> The install script can be safely used to re-install the agent.

### Test

Open a new terminal (or run `source ~/.bashrc`) and test:

```bash
# Test that the agent is installed and is on PATH
wsl-ssh-agent --version
# List keys in the agent
ssh-add -l
# Expected output: all the keys that are added to your Windows SSH agent
```

## Configuration

> [!CAUTION]
> This chapter is intended for experienced users.

In order to change filepaths that the tool uses (both agent and its installer/deinstaller) edit [config.sh](scripts/config.sh).

If you intend to place `npiperelay` in a non-default location, edit [this line](service/wsl-ssh-agent#L6)
of the agent's script.

> [!WARNING]
> `npiperelay.exe` must be placed on your Windows partition and be accessible (executable) from WSL!

You can also configure the `systemd` service that will be installed, by editing [wsl-ssh-agent.service](service/wsl-ssh-agent.service)

Finally, if you want to change the configuration of the service **after** installing it, you can find the same `.service` file at
[this location](scripts/config.sh#L11) (`~/.config/systemd/user/wsl-ssh-agent.service` by default). After editing this file,
run the following to introduce changes:

```lang-bash
wsl-ssh-agent reload
```

OR

```lang-bash
systemctl --user daemon-reload
```

## Usage

### CLI help

`wsl-ssh-agent` provides a unified interface. Run it with no arguments to see the basic usage syntax, or use the `--help` option to
get more information:

```lang-bash
wsl-ssh-agent --help
```

### Available commands

While having a just-enough interface in portable mode, when installed, agent also provides a useful
wrappers for `systemctl` and `journalctl`. The full list of available commands is presented below:

Command|Description|Available in portable mode?
-|-|-
`foreground` |	Run the agent in the foreground (manual mode) |	✅ Always
`debug`      |	Run with verbose `socat` output               |	✅ Always
`print-env`  |	Output export `SSH_AUTH_SOCK=...`             |	✅ Always
`start`      | Start the agent service                       | ❌ Only when installed
`stop`       | Stop the agent service                        |	❌ Only when installed
`restart`    |	Restart the agent service                     | ❌ Only when installed
`status`     |	Show service status                           |	❌ Only when installed
`autorun`    |	Enable automatic start on login               |	❌ Only when installed
`no-autorun` |	Disable automatic start                       |	❌ Only when installed
`journal`    |	View logs (supports `-f`, `--since`, etc.)    |	❌ Only when installed
`reload`     |	Reload systemd user daemon	                   | ❌ Only when installed

### Manual (portable) mode

Whether you prefer not to use systemd, or just want to have maximum control on handling - you can run
the agent directly, without ever installing it:

```lang-bash
wsl-ssh-agent foreground
```

This will keep the communication channel opened indefinetely, until you send an interrupt (`Ctrl+C`). When you open
another terminal (or send the process background), use the following syntax to share windows keys with WSL:

```lang-bash
eval $(wsl-ssh-agent print-env)
```

## Troubleshooting

### Could not open a connection to your authentication agent

**Cause:** The Windows OpenSSH agent is not running, or no keys have been added.

**Fix:** Start the Windows agent and add your keys:

```lang-powershell
# Powershell
Start-Service ssh-agent
ssh-add C:\Users\YourName\.ssh\id_rsa
```

### Socket already exists

**Cause:** Another instance of the agent is already running.

**Fix:** Stop the existing service:

```lang-bash
wsl-ssh-agent stop
```

If you are running manually (portable mode), kill the socat process.

```lang-bash
# Identify the PID
ps -aux | grep wsl-ssh-agent
# Your process will have a following command:
# socat UNIX-LISTEN:/path/to/socket.sock,fork EXEC:/path/to/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent
# Kill it
kill <your PID here>
```

## Uninstallation

Note: this step can be safely omitted, if you did not [install](#installation) the tool in the first place

From the repository directory:

```lang-bash
./scripts/uninstall.sh
```

This will:
  - Stop and disable the systemd service
  - Remove the service file and the script
  - Remove the persistent configuration directory
  - Remove the `.bashrc` block (backup saved as `.bashrc.bak`)

Attention: After uninstallation, restart your shell to clear the environment.

## Credits

This project would not be possible, if not for the great work done by theese people:

- [jstarks](https://github.com/jstarks) – `npiperelay`, which makes the magic possible
- [rupor-github](https://github.com/rupor-github) – for the original inspiration and
  [wsl-ssh-agent](https://github.com/rupor-github/wsl-ssh-agent) that showed how to integrate everything
- The authors of this gists:
  - [Jaykul - Agent Passthru](https://gist.github.com/Jaykul/19e9f18b8a68f6ab854e338f9b38ca7b)
  - [strarsis - howto.md](https://gist.github.com/strarsis/e533f4bca5ae158481bbe53185848d49)

## A Note on Development

This project represents a **human-led**, AI-accelerated development workflow. I began with a hand-written prototype to establish the core architecture and design patterns, ensuring the foundation was solid and intentional. From there, I leveraged large language models as a sophisticated pair-programming tool—automating boilerplate, suggesting implementations, and accelerating iteration cycles. However, every line of code got my attention: refactoring, debugging, testing. The result is a production-ready tool that benefits from the speed of modern AI while maintaining the quality, consistency, and craftsmanship of a hand-built application.

Assisted by: Deepseek V3.2

## Support the Creator

This project is strictly non-commercial. If you find this tool useful, consider giving it a ⭐ - it helps others discover it too.

**Happy coding!**

## License

This project is licensed under the [GPL-3.0 License](LICENSE).

Copyright (c) 2026 Rostislav Frolov
