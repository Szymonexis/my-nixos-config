#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"

# Copy configuration.nix to the script's directory
sudo cp /etc/nixos/configuration.nix "$SCRIPT_DIR/"

# Change to the script's directory for git operations
cd "$SCRIPT_DIR" || exit 1

# Update permissions and ownership
sudo chmod 666 ./configuration.nix && \
sudo chown $USER:users ./configuration.nix

# Git operations
git add --all && \
git commit -m "Update configuration.nix" && \
git push
