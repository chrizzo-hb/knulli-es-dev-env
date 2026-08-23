#!/bin/bash
source ./settings.conf

# Function definitions
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

# DISTRIBUTION SETUP >>>>>
if [ -d "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" ]; then
    echo "Distribution directory $LOCAL_DISTRIBUTION_DIR_NAME already exists - skipping clone."
    cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit
    apply_git_settings
    git fetch origin
else
    echo "Cloning distribution repository..."
    git clone --recursive "$DISTRIBUTION_FORK_REPO.git" "$LOCAL_DISTRIBUTION_DIR_NAME"
    cd "$BASE_DIR/$LOCAL_DISTRIBUTION_DIR_NAME" || exit
    apply_git_settings
    git checkout "$DISTRO_DEFAULT_BRANCH"
fi
# DISTRIBUTION <<<<<

# EMULATIONSTATION SETUP >>>>>
cd "$BASE_DIR"

if [ -d "$BASE_DIR/$LOCAL_EMULATIONSTATION_DIR_NAME" ]; then
    echo "EmulationStation directory $LOCAL_EMULATIONSTATION_DIR_NAME already exists - skipping clone."
    cd "$BASE_DIR/$LOCAL_EMULATIONSTATION_DIR_NAME" || exit
    apply_git_settings
    git fetch origin
else
    echo "Cloning EmulationStation repository..."
    git clone --recursive "$EMULATIONSTATION_FORK_REPO.git" "$LOCAL_EMULATIONSTATION_DIR_NAME"
    cd "$BASE_DIR/$LOCAL_EMULATIONSTATION_DIR_NAME" || exit
    apply_git_settings
    git checkout main
fi
# EMULATIONSTATION <<<<<

echo
echo "Installation and environment setup complete! You are ready to start building via 'tools/build.sh'. 🔥"
echo
