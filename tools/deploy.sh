#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../settings.conf"

echo "Deploying to $DEVICE_LOGIN... 🤞"

ssh "$DEVICE_LOGIN" "mkdir -p ~/backup && cp /usr/bin/emulationstation ~/backup/emulationstation.lastversion && /etc/init.d/S31emulationstation stop"
scp "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME/output/$TARGET/build/knulli-emulationstation/emulationstation" "$DEVICE_LOGIN:~/backup/emulationstation.newversion"
ssh "$DEVICE_LOGIN" "cp ~/backup/emulationstation.newversion /usr/bin/emulationstation && batocera-save-overlay ; knulli-save-overlay ; reboot && exit"

echo
echo "Deployment complete. 🔥"
echo
