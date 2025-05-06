#!/bin/bash

set -e  # Exit on error

CRIO_VERSION="v1.31"

echo "[INFO] Upgrading CRI-O to version $CRIO_VERSION..."

# Remove old CRI-O v1.30 repository and key
sudo rm -f /etc/apt/sources.list.d/cri-o.list
sudo rm -f /etc/apt/keyrings/cri-o-apt-keyring.gpg

# Add CRI-O v1.31 repository and key
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/cri-o.list

# Update APT cache and upgrade CRI-O package
sudo apt-get update
sudo apt-get install -y cri-o

# Restart CRI-O to apply the updated version
sudo systemctl restart crio

# Confirm version
echo "[INFO] CRI-O upgraded to:"
crio --version
