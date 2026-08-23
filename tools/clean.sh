#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../settings.conf"

DIST_DIR="$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME"

echo "Cleaning EmulationStation build artifacts in $DIST_DIR..."

if [ -d "$DIST_DIR" ]; then
    # Entfernt alle Buildroot-Ordner, die zu emulationstation gehören (egal ob custom, git-Versionen oder Verzweigungen)
    rm -rf "$DIST_DIR"/output/*/build/knulli-emulationstation*
    echo "EmulationStation build directories have been successfully cleared. 🧹"
else
    echo "Distribution directory not found at $DIST_DIR. Nothing to clean."
fi

echo
echo "Clean complete. 🔥"
echo
