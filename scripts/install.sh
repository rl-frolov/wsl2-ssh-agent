#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(dirname $(dirname ${BASH_SOURCE[0]}))"
CONFIG_FILE="$REPO_DIR/scripts/config.sh"
source "$CONFIG_FILE"

UNATTENDED=false
[[ "${1:-}" == "--unattended" ]] && UNATTENDED=true

SCRIPT_SRC="$REPO_DIR/service/wsl-ssh-agent"
SERVICE_SRC="$REPO_DIR/service/wsl-ssh-agent.service"

mkdir -p "$USER_BIN_DIR" "$USER_CONFIG_DIR" "$USER_SHARE_DIR"

log_info "Installing $SCRIPT_DEST"
install -m 755 "$SCRIPT_SRC" "$SCRIPT_DEST"

log_info "Installing $SERVICE_DEST"
sed "s|@SCRIPT_PATH@|$SCRIPT_DEST|g" "$SERVICE_SRC" > "$SERVICE_DEST"
chmod 644 "$SERVICE_DEST"

log_info "Installing shared config to $USER_SHARE_DIR/config.sh"
install -m 644 "$CONFIG_FILE" "$USER_SHARE_DIR/config.sh"

log_info "Reloading systemd user daemon"
systemctl --user daemon-reload

log_info "Enabling and starting service"
systemctl --user enable wsl-ssh-agent.service
systemctl --user start wsl-ssh-agent.service
systemctl --user reset-failed wsl-ssh-agent.service || true

sleep 1

if grep -q "$GUARD_START" "$BASHRC" 2>/dev/null; then
    log_info ".bashrc already contains wsl-ssh-agent block. Skipping."
else
    log_info "Adding configuration to $BASHRC"
    cat >> "$BASHRC" <<EOF

$GUARD_START
if [[ ":\$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="\$HOME/.local/bin:\$PATH"
fi
eval "\$( $SCRIPT_DEST print-env )"
$GUARD_END
EOF
    if ! $UNATTENDED; then
        log_info "Added. Restart your shell or run 'source ~/.bashrc'."
    fi
fi

if ! $UNATTENDED; then
    SOCKET=$("$SCRIPT_DEST" print-env 2>/dev/null | cut -d'=' -f2- | tr -d '"')
    if [[ -S "$SOCKET" ]]; then
        if SSH_AUTH_SOCK="$SOCKET" ssh-add -l &>/dev/null; then
            log_info "Agent is working! Keys are available."
        else
            log_warn "Socket exists but no keys found (or agent not ready)."
        fi
    else
        log_warn "Socket not yet available. Service may still be starting."
    fi
fi

echo -e "
${GREEN}Installation complete!${NC}
Service is enabled and started.
To apply changes immediately, restart your shell
To uninstall, run scripts/uninstall.sh
"
