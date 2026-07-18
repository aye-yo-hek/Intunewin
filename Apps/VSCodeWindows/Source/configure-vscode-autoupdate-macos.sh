#!/bin/bash
#
# Configure VS Code Auto-Update on macOS
# This script sets the UpdateMode policy to enable automatic updates
#

PLIST_PATH="/Library/Preferences/com.microsoft.VSCode.plist"

echo "Configuring VS Code Policies for macOS..."
echo "Target: $PLIST_PATH"
echo ""

# Set UpdateMode to default (automatic updates)
echo "Setting UpdateMode to 'default'..."
defaults write /Library/Preferences/com.microsoft.VSCode UpdateMode -string "default"

# Disable telemetry
echo "Setting TelemetryLevel to 'off'..."
defaults write /Library/Preferences/com.microsoft.VSCode TelemetryLevel -string "off"

# Set permissions
chmod 644 "$PLIST_PATH" 2>/dev/null

# Verify the settings
UPDATE_VALUE=$(defaults read /Library/Preferences/com.microsoft.VSCode UpdateMode 2>/dev/null)
TELEMETRY_VALUE=$(defaults read /Library/Preferences/com.microsoft.VSCode TelemetryLevel 2>/dev/null)

if [ "$UPDATE_VALUE" = "default" ] && [ "$TELEMETRY_VALUE" = "off" ]; then
    echo ""
    echo "✓ VS Code policies successfully configured!"
    echo ""
    echo "Policy Details:"
    echo "  Auto-Updates:"
    echo "    - Updates will be checked automatically in the background"
    echo "    - New versions will be downloaded and installed automatically"
    echo "    - Users will be prompted to restart VS Code when updates are ready"
    echo ""
    echo "  Telemetry:"
    echo "    - All telemetry data collection is disabled"
    echo "    - No usage data, errors, or crash reports will be sent"
    exit 0
else
    echo "✗ Failed to configure VS Code policies"
    echo "UpdateMode: $UPDATE_VALUE (expected: default)"
    echo "TelemetryLevel: $TELEMETRY_VALUE (expected: off)"
    exit 1
fi
