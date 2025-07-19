#!/bin/bash

set -e

echo "[INFO] Updating package index..."
sudo apt-get update

echo "[INFO] Installing prerequisites..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Check if Docker GPG keyring exists
KEYRING_PATH="/usr/share/keyrings/docker-archive-keyring.gpg"
if [[ -f "$KEYRING_PATH" ]]; then
  echo "[INFO] Docker GPG keyring already exists, skipping import."
else
  echo "[INFO] Adding Docker's official GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes --batch -o "$KEYRING_PATH"
fi

# Check if docker.list repo file exists
REPO_FILE="/etc/apt/sources.list.d/docker.list"
if [[ -f "$REPO_FILE" ]]; then
  echo "[INFO] Docker repository list already exists, skipping."
else
  echo "[INFO] Setting up the Docker repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING_PATH] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee "$REPO_FILE" > /dev/null
fi

echo "[INFO] Updating package index again..."
sudo apt-get update

echo "[INFO] Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "[INFO] Verifying Docker installation..."
if sudo docker --version >/dev/null 2>&1; then
  echo "[INFO] Docker installed successfully: $(sudo docker --version)"
else
  echo "[ERROR] Docker installation failed."
  exit 1
fi

echo "[INFO] Downloading latest Docker Compose binary..."
DOCKER_COMPOSE_LATEST=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
if [[ -z "$DOCKER_COMPOSE_LATEST" ]]; then
  echo "[WARN] Could not determine latest Docker Compose version, using default 2.20.2"
  DOCKER_COMPOSE_LATEST="v2.20.2"
fi

COMPOSE_BIN="/usr/local/bin/docker-compose"
if [[ -x "$COMPOSE_BIN" ]]; then
  echo "[INFO] Docker Compose binary already exists, skipping download."
else
  sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_LATEST}/docker-compose-$(uname -s)-$(uname -m)" -o "$COMPOSE_BIN"
  sudo chmod +x "$COMPOSE_BIN"
fi

echo "[INFO] Verifying Docker Compose installation..."
if docker-compose --version >/dev/null 2>&1; then
  echo "[INFO] Docker Compose installed successfully: $(docker-compose --version)"
else
  echo "[ERROR] Docker Compose installation failed."
  exit 1
fi

echo "[INFO] Installation complete."
