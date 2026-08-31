#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../settings.conf"

apply_git_settings() {
    git config user.name "$GIT_USER"
    git config user.email "$GIT_EMAIL"
    git config push.autoSetupRemote true
}

mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1
apply_git_settings

# Distribution setup
if [ -d "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" ]; then
    echo "Distribution directory already exists - pulling latest changes..."
    cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit 1
    apply_git_settings
    git pull origin "$DISTRO_DEFAULT_BRANCH"
else
    echo "Cloning distribution repository..."
    git clone --recursive "$DISTRIBUTION_FORK_REPO.git" "$LOCAL_DISTRIBUTION_DIR_NAME"
    cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit 1
    apply_git_settings
    git checkout "$DISTRO_DEFAULT_BRANCH"
fi

# Local EmulationStation path
LOCAL_ES_ABS_PATH="$BASE_DIR/$LOCAL_EMULATIONSTATION_DIR_NAME"

MK_FILE="$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME/package/emulationstation/knulli-emulationstation/knulli-emulationstation.mk"

if [ -f "$MK_FILE" ]; then
    echo "Configuring EmulationStation package for local build..."

    # Disable remote version and git submodule handling
    sed -i 's/^KNULLI_EMULATIONSTATION_VERSION/#KNULLI_EMULATIONSTATION_VERSION/' "$MK_FILE"
    sed -i 's/^KNULLI_EMULATIONSTATION_GIT_SUBMODULES/#KNULLI_EMULATIONSTATION_GIT_SUBMODULES/' "$MK_FILE"

    # Set local source path
    if grep -q "^KNULLI_EMULATIONSTATION_SITE =" "$MK_FILE"; then
        sed -i "s|^KNULLI_EMULATIONSTATION_SITE = .*|KNULLI_EMULATIONSTATION_SITE = $LOCAL_ES_ABS_PATH|" "$MK_FILE"
    else
        echo "KNULLI_EMULATIONSTATION_SITE = $LOCAL_ES_ABS_PATH" >> "$MK_FILE"
    fi

    # Use Buildroot local site method
    if grep -q "^KNULLI_EMULATIONSTATION_SITE_METHOD =" "$MK_FILE"; then
        sed -i "s|^KNULLI_EMULATIONSTATION_SITE_METHOD = .*|KNULLI_EMULATIONSTATION_SITE_METHOD = local|" "$MK_FILE"
    else
        echo "KNULLI_EMULATIONSTATION_SITE_METHOD = local" >> "$MK_FILE"
    fi
else
    echo "Error: EmulationStation mk file not found at:"
    echo "  $MK_FILE"
    exit 1
fi

# Verify local ES checkout exists
if [ ! -d "$LOCAL_ES_ABS_PATH" ]; then
    echo "Error: Local EmulationStation directory not found:"
    echo "  $LOCAL_ES_ABS_PATH"
    exit 1
fi

# Show current branch
LOCAL_ES_BRANCH="$(cd "$LOCAL_ES_ABS_PATH" && git branch --show-current)"
echo "Building using local EmulationStation from branch: $LOCAL_ES_BRANCH"

# Make local ES source available inside Docker at the same absolute path
DOCKER_OPTS="-v $LOCAL_ES_ABS_PATH:$LOCAL_ES_ABS_PATH"
export DOCKER_OPTS

echo "Docker mount for local EmulationStation:"
echo "  $LOCAL_ES_ABS_PATH -> $LOCAL_ES_ABS_PATH"

# Docker build environment & compilation
echo "Creating Docker build environment..."

cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit 1

./getPoFromWebsite.sh

make build-docker-image || {
    echo "Docker image build failed. ☹️"
    exit 1
}

echo "Downloading all required sources..."

make "$TARGET-source" || {
    echo "Downloading sources failed. ☹️"
    exit 1
}

echo "Building EmulationStation package locally..."

make "$TARGET-pkg" PKG=knulli-emulationstation || {
    echo "Build failed. ☹️"
    exit 1
}

echo
echo "Build Complete... 🔥"
echo
