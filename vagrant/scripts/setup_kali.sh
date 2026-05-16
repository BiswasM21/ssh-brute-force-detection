#!/bin/bash
###############################################################################
# Kali Linux Attacker Setup Script
###############################################################################

set -e

echo "========================================"
echo "Setting up Kali Linux Attacker"
echo "========================================"

# Update Kali
apt-get update -qq

# Install attack tools
echo "Installing attack tools..."
apt-get install -y -qq \
    metasploit-framework \
    nmap \
    hydra \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    net-tools \
    dnsutils

# Install additional Python tools
pip3 install --no-cache-dir paramiko colorama

# Install SSH tools
apt-get install -y -qq openssh-client

# Copy attack scripts
cp -r /vagrant/attack-scripts /root/

# Make scripts executable
chmod +x /root/attack-scripts/**/*.sh 2>/dev/null || true
chmod +x /root/attack-scripts/**/*.rb 2>/dev/null || true

echo "========================================"
echo "Kali Attacker setup complete!"
echo "========================================"
