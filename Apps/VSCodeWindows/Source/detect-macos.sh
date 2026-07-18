#!/bin/bash
#
# Detection script for VS Code Policies on macOS
# Checks if UpdateMode and TelemetryLevel policies are configured correctly
#

EXPECTED_UPDATE="default"
EXPECTED_TELEMETRY="off"

# Check if preferences exist and have correct values
CURRENT_UPDATE=$(defaults read /Library/Preferences/com.microsoft.VSCode UpdateMode 2>/dev/null)
CURRENT_TELEMETRY=$(defaults read /Library/Preferences/com.microsoft.VSCode TelemetryLevel 2>/dev/null)

if [ "$CURRENT_UPDATE" = "$EXPECTED_UPDATE" ] && [ "$CURRENT_TELEMETRY" = "$EXPECTED_TELEMETRY" ]; then
    echo "All VS Code policies are configured correctly"
    exit 0
else
    echo "VS Code policies are not configured correctly"
    echo "UpdateMode: $CURRENT_UPDATE (expected: $EXPECTED_UPDATE)"
    echo "TelemetryLevel: $CURRENT_TELEMETRY (expected: $EXPECTED_TELEMETRY)"
    exit 1
fi
