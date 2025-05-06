#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# ------------------------------
# Disable swap (required by Kubernetes)
# ------------------------------
sudo swapoff -a

# ------------------------------
# Install dependencies for Kubernetes repo access
# ------------------------------
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# ------------------------------
# Add Kubernetes APT repository and GPG key
# ------------------------------
sudo mkdir -p -m 755 /etc/apt/keyrings
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# ------------------------------
# Install Kubernetes components
# ------------------------------
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl

# ------------------------------
# Enable required kernel modules for container networking
# 'overlay' enables overlay filesystem used by containers.
# 'br_netfilter' allows iptables to see bridged traffic, which is essential for Kubernetes networking.
# ------------------------------
sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load the kernel modules immediately
sudo modprobe overlay
sudo modprobe br_netfilter

# ------------------------------
# Set sysctl parameters for Kubernetes networking
# - Allow iptables to see bridged network traffic (used by most CNI plugins)
# - Enable IPv4 forwarding to allow routing between pods and services
# ------------------------------
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1        
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters without reboot
sudo sysctl --system

# ------------------------------
# Install CRI-O container runtime
# ------------------------------
CRIO_VERSION="v1.30"

# Add CRI-O repository and GPG key
sudo curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

sudo echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/cri-o.list

# Install CRI-O runtime
sudo apt-get update && sudo apt-get install -y cri-o

# auto completion 
echo "source <(kubectl completion bash) >> ~/.bashrc"
sudo "source ~/.bashrc"
# Start and enable CRI-O service
sudo systemctl enable --now crio
