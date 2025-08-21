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

# List of nix files to copy
NIX_FILES=("configuration.nix" "hardware-configuration.nix")

for FILE in "${NIX_FILES[@]}"; do
    SRC="/etc/nixos/${FILE}"
    DEST="${SCRIPT_DIR}/${FILE}"

    if [ -f "$SRC" ]; then
        echo "Copying ${FILE} from /etc/nixos/ to ${SCRIPT_DIR}..."
        if ! sudo cp "$SRC" "$DEST"; then
            echo "Error: Failed to copy ${FILE}"
            exit 2
        fi

        echo "Setting secure permissions on ${FILE}..."
        if ! sudo chmod 644 "$DEST"; then
            echo "Error: Failed to set permissions on ${FILE}"
            exit 3
        fi

        echo "Updating ownership of ${FILE}..."
        if ! sudo chown "$(id -u):$(id -g)" "$DEST"; then
            echo "Error: Failed to update ownership on ${FILE}"
            exit 4
        fi
    else
        echo "Note: ${FILE} not found in /etc/nixos/, skipping..."
    fi
done

# Change to the script's directory
echo "Changing to directory: ${SCRIPT_DIR}"
cd "${SCRIPT_DIR}" || {
    echo "Error: Failed to change to ${SCRIPT_DIR}"
    exit 5
}

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
if ! git commit -m "Update configuration and hardware configuration"; then
    echo "Note: No changes to commit or commit failed"
    # Not exiting here, as no changes to commit is not a fatal error
fi

echo "Pushing changes to remote repository..."
if ! git push; then
    echo "Error: git push failed"
    exit 8
fi

echo "Successfully updated NixOS configuration files!"
