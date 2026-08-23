#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../settings.conf"

apply_git_settings() {
    git config user.name "$GIT_USER"
    git config user.email "$GIT_EMAIL"
    git config push.autoSetupRemote true
}

echo "Installing essential build dependencies..."
sudo apt update && sudo apt install -y build-essential gettext rsync

mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit
apply_git_settings

# Distribution setup (clean & simple)
if [ -d "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" ]; then
    echo "Distribution directory already exists - pulling latest changes..."
    cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit
    apply_git_settings
    git pull origin "$DISTRO_DEFAULT_BRANCH"
else
    echo "Cloning distribution repository..."
    git clone --recursive "$DISTRIBUTION_FORK_REPO.git" "$LOCAL_DISTRIBUTION_DIR_NAME"
    cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit
    apply_git_settings
    git checkout "$DISTRO_DEFAULT_BRANCH"
fi

# Define local EmulationStation path relatively
LOCAL_ES_ABS_PATH="$BASE_DIR/$LOCAL_EMULATIONSTATION_DIR_NAME"
MK_FILE="$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME/package/emulationstation/knulli-emulationstation/knulli-emulationstation.mk"

if [ -f "$MK_FILE" ]; then
    echo "Configuring EmulationStation package for local build via SED..."
    
    # Comment out version and git submodules
    sed -i 's/^KNULLI_EMULATIONSTATION_VERSION/#KNULLI_EMULATIONSTATION_VERSION/' "$MK_FILE"
    sed -i 's/^KNULLI_EMULATIONSTATION_GIT_SUBMODULES/#KNULLI_EMULATIONSTATION_GIT_SUBMODULES/' "$MK_FILE"
    
    # Set site to local path
    if grep -q "KNULLI_EMULATIONSTATION_SITE =" "$MK_FILE"; then
        sed -i "s|^KNULLI_EMULATIONSTATION_SITE = .*|KNULLI_EMULATIONSTATION_SITE = $LOCAL_ES_ABS_PATH|" "$MK_FILE"
    else
        echo "KNULLI_EMULATIONSTATION_SITE = $LOCAL_ES_ABS_PATH" >> "$MK_FILE"
    fi

    # Set site method to local
    if grep -q "KNULLI_EMULATIONSTATION_SITE_METHOD =" "$MK_FILE"; then
        sed -i "s|^KNULLI_EMULATIONSTATION_SITE_METHOD = .*|KNULLI_EMULATIONSTATION_SITE_METHOD = local|" "$MK_FILE"
    else
        echo "KNULLI_EMULATIONSTATION_SITE_METHOD = local" >> "$MK_FILE"
    fi
else
    echo "Error: EmulationStation mk file not found at $MK_FILE ☹️"
    exit 1
fi

# Optional info for the user regarding current local ES branch
if [ -d "$LOCAL_ES_ABS_PATH" ]; then
    LOCAL_ES_BRANCH="$(cd "$LOCAL_ES_ABS_PATH" && git branch --show-current)"
    echo "Building using local EmulationStation from branch: $LOCAL_ES_BRANCH"
fi

# Docker build environment & compilation
echo "Creating Docker build environment..."
cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME"
./getPoFromWebsite.sh
make build-docker-image || { echo "Docker image build failed. ☹️"; exit 1; }

echo "Downloading all required sources..."
make "$TARGET-source" || { echo "Downloading sources failed. ☹️"; exit 1; }

echo "Building EmulationStation package locally..."
make "$TARGET-pkg" PKG=knulli-emulationstation || { echo "Build failed. ☹️"; exit 1; }

echo
echo "Build Complete... 🔥"
echo
