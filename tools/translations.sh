#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../settings.conf"

# Construct paths dynamically from settings.conf variables
ES_DIR="$BASE_DIR/$LOCAL_EMULATIONSTATION_DIR_NAME"
LOCALE_DIR="$ES_DIR/locale"
POT_FILE="$LOCALE_DIR/emulationstation2.pot"

echo "==> 1. Changing to EmulationStation directory: $ES_DIR"
cd "$ES_DIR"

echo "==> 2. Generating current emulationstation2.pot from C++ source code..."
xgettext --default-domain=emulationstation2 \
         --keyword=_ \
         --keyword=N_ \
         --from-code=UTF-8 \
         --add-comments=TRANSLATORS \
         --no-location \
         --output="$POT_FILE" \
         $(find . -name "*.cpp" -o -name "*.h")

echo "==> 3. Updating all language PO files via msgmerge..."
cd "$LOCALE_DIR/lang"

for p in */LC_MESSAGES/emulationstation2.po; do
    if [ -f "$p" ]; then
        echo "   -> Merging: $p"
		msgmerge --update --backup=none "$p" "../emulationstation2.pot"
		echo "   -> Removing obsolete translations from: $p"
		msgattrib --no-obsolete -o "$p" "$p"
    fi
done

echo "==> Done! All POT and PO files have been successfully updated."
