#!/bin/bash

SSH_DIR="$HOME/.ssh"

if [ ! -d "$SSH_DIR" ]; then
    echo "Error: $SSH_DIR does not exist."
    exit 1
fi

echo "Setting ownership to $USER..."
chown -R "$USER":"$USER" "$SSH_DIR"

echo "Setting directory permissions (700)..."
chmod 700 "$SSH_DIR"

echo "Setting all files to 600 (private)..."
find "$SSH_DIR" -type f -exec chmod 600 {} \;

echo "Setting public keys and known_hosts to 644 (world‑readable)..."
find "$SSH_DIR" -type f \( -name '*.pub' -o -name 'known_hosts' \) -exec chmod 644 {} \;

echo "Done. Verify with: ls -la $SSH_DIR"
