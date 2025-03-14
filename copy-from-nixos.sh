#!/usr/bin/env bash

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

# Store the script's directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
echo "Working directory: ${SCRIPT_DIR}"

# Check if running on NixOS
if [ ! -f /etc/nixos/configuration.nix ]; then
    echo "Error: /etc/nixos/configuration.nix not found. Are you running on NixOS?"
    exit 1
fi

echo "Copying configuration.nix from /etc/nixos/ to ${SCRIPT_DIR}..."
if ! sudo cp /etc/nixos/configuration.nix "${SCRIPT_DIR}/"; then
    echo "Error: Failed to copy configuration.nix"
    exit 2
fi

# Change to the script's directory
echo "Changing to directory: ${SCRIPT_DIR}"
cd "${SCRIPT_DIR}" || {
    echo "Error: Failed to change to ${SCRIPT_DIR}"
    exit 3
}

# Update permissions to a more secure setting (644 = rw-r--r--)
echo "Setting secure permissions on configuration.nix..."
if ! sudo chmod 644 ./configuration.nix; then
    echo "Error: Failed to set permissions"
    exit 4
fi

echo "Updating ownership of configuration.nix..."
if ! sudo chown "$(id -u):$(id -g)" ./configuration.nix; then
    echo "Error: Failed to update ownership"
    exit 5
fi

# Git operations with validation
echo "Checking git status..."
if ! git status &>/dev/null; then
    echo "Error: Not a git repository or git command failed"
    exit 6
fi

echo "Adding changes to git..."
if ! git add --all; then
    echo "Error: git add failed"
    exit 7
fi

echo "Committing changes..."
if ! git commit -m "Update configuration.nix"; then
    echo "Note: No changes to commit or commit failed"
    # Not exiting here, as no changes to commit is not a fatal error
fi

echo "Pushing changes to remote repository..."
if ! git push; then
    echo "Error: git push failed"
    exit 8
fi

echo "Successfully updated configuration.nix!"