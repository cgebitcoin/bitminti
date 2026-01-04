#!/bin/bash
set -e

echo "=== Installing Docker on Ubuntu EC2 ==="

# 1. Remove conflicting packages
echo "Removing old packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove $pkg || true
done

# 2. Add Docker's official GPG key
echo "Setting up repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Add the repository to Apt sources
echo \
  "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Install Docker packages
echo "Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Post-installation steps (Non-root usage)
echo "Configuring user permissions..."
sudo groupadd docker || true
sudo usermod -aG docker $USER

echo "=== Installation Complete! ==="
echo "IMPORTANT: You must log out and log back in for group changes to take effect."
echo "Alternatively, run: newgrp docker"
