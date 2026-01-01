#!/bin/bash

# Diagnostic script to check the systemd service configuration

echo "=== Checking Service File ==="
cat /etc/systemd/system/digital-thermal-right-lcd.service

echo -e "\n=== Checking Python Virtual Environment ==="
VENV_PATH="/mnt/archive/peerless/Peerless_assassin_and_CLI_UI/.venv/bin/python"
if [ -f "$VENV_PATH" ]; then
    echo "✓ Python virtual environment exists"
    ls -la "$VENV_PATH"
else
    echo "✗ Python virtual environment NOT FOUND at: $VENV_PATH"
fi

echo -e "\n=== Checking Controller Script ==="
CONTROLLER_PATH="/mnt/archive/peerless/Peerless_assassin_and_CLI_UI/src/controller.py"
if [ -f "$CONTROLLER_PATH" ]; then
    echo "✓ Controller script exists"
    ls -la "$CONTROLLER_PATH"
else
    echo "✗ Controller script NOT FOUND at: $CONTROLLER_PATH"
fi

echo -e "\n=== Checking Working Directory ==="
WORK_DIR="/mnt/archive/peerless/Peerless_assassin_and_CLI_UI"
if [ -d "$WORK_DIR" ]; then
    echo "✓ Working directory exists"
    ls -la "$WORK_DIR"
else
    echo "✗ Working directory NOT FOUND at: $WORK_DIR"
fi

echo -e "\n=== Testing Manual Execution ==="
echo "Attempting to run the command as specified in the service..."
sudo -u $SUDO_USER "$VENV_PATH" "$CONTROLLER_PATH"
