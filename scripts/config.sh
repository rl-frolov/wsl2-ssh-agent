#!/usr/bin/env bash
# Shared configuration for wsl-ssh-agent installer/uninstaller

USER_BIN_DIR="$HOME/.local/bin"
USER_CONFIG_DIR="$HOME/.config/systemd/user"
USER_SHARE_DIR="$HOME/.config/wsl-ssh-agent"

SCRIPT_NAME="wsl-ssh-agent"
SCRIPT_DEST="$USER_BIN_DIR/$SCRIPT_NAME"
SERVICE_NAME="wsl-ssh-agent.service"
SERVICE_DEST="$USER_CONFIG_DIR/$SERVICE_NAME"

BASHRC="$HOME/.bashrc"
GUARD_START="# ============================= wsl-ssh-agent start ==============================="
GUARD_END="# =============================  wsl-ssh-agent end  ==============================="

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
    GREEN=''; RED=''; YELLOW=''; NC=''
fi

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }
