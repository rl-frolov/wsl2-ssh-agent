#!/usr/bin/env bash
set -euo pipefail

# Try to load persistent config first, then fallback to repo config
CONFIG_FILE="$HOME/.config/wsl-ssh-agent/config.sh"
[[ ! -f "$CONFIG_FILE" ]] && CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Could not find configuration file." >&2
    exit 1
fi

source "$CONFIG_FILE"

echo -e "${YELLOW}[WARN]${NC} This will remove wsl-ssh-agent and its configuration."
read -p "Are you sure? (y/N) " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

if systemctl --user is-active --quiet wsl-ssh-agent.service 2>/dev/null; then
    log_info "Stopping service..."
    systemctl --user stop wsl-ssh-agent.service || true
fi

if systemctl --user is-enabled --quiet wsl-ssh-agent.service 2>/dev/null; then
    log_info "Disabling service..."
    systemctl --user disable wsl-ssh-agent.service || true
fi

log_info "Removing $SERVICE_DEST"
rm -f "$SERVICE_DEST"
rm -f "$USER_CONFIG_DIR/default.target.wants/$SERVICE_NAME"
systemctl --user daemon-reload
systemctl --user reset-failed "$SERVICE_NAME" || true

log_info "Removing $SCRIPT_DEST"
rm -f "$SCRIPT_DEST"

log_info "Removing persistent config $USER_SHARE_DIR"
rm -rf "$USER_SHARE_DIR"

if grep -q "$GUARD_START" "$BASHRC" 2>/dev/null; then
    log_info "Removing wsl-ssh-agent block from .bashrc"
    cp "$BASHRC" "$BASHRC.bak"
    sed -i "/$GUARD_START/,/$GUARD_END/d" "$BASHRC"
    log_info "Backup saved as $BASHRC.bak"
else
    log_info "No .bashrc block found; skipping."
fi

rmdir "/run/user/$(id -u)/wsl-ssh-agent" 2>/dev/null || true

echo -e "
${GREEN}Uninstall complete.${NC}
Restart your shell to clear environment variables.
"
