#!/bin/bash
###############################################################################
# Splunk Forwarder Setup Script
###############################################################################

set -e

UF_VERSION="9.0.0"
UF_USER="splunk"
SPLUNK_SERVER="192.168.56.100"
SPLUNK_SERVER_PORT="9997"

echo "========================================"
echo "Setting up Splunk Forwarder"
echo "========================================"

# Update system
apt-get update -qq

# Install prerequisites
apt-get install -y -qq wget curl net-tools

# Download Universal Forwarder
echo "Downloading Splunk Universal Forwarder..."
cd /tmp
wget -q "https://download.splunk.com/products/universalforwarder/releases/${UF_VERSION}/linux/splunkforwarder-${UF_VERSION}-linux-amd64.tgz"

# Extract and install
echo "Installing Universal Forwarder..."
tar -xzf "splunkforwarder-${UF_VERSION}-linux-amd64.tgz" -C /opt
ln -sf /opt/splunkforwarder/bin/splunk /usr/local/bin/splunk

# Create Splunk user
useradd -m -s /bin/bash $UF_USER 2>/dev/null || true
chown -R $UF_USER:$UF_USER /opt/splunkforwarder

# Accept license and configure
echo "Configuring forwarder..."
su - $UF_USER -c "/opt/splunkforwarder/bin/splunk start --accept-license --no-prompt"

# Set deployment server
su - $UF_USER -c "/opt/splunkforwarder/bin/splunk set deploy-poll ${SPLUNK_SERVER}:${SPLUNK_SERVER_PORT} --accept-license"

# Enable receiving on Splunk server (on Splunk server itself, this is for remote forwarders)
# This would be run on the targets, not the Splunk server

# Add inputs to monitor
echo "Adding log inputs..."
/opt/splunkforwarder/bin/splunk add monitor /var/log/auth.log -sourcetype sshd_auth -auth admin:SplunkPass123!
/opt/splunkforwarder/bin/splunk add monitor /var/log/secure -sourcetype sshd_auth -auth admin:SplunkPass123!

# Restart forwarder
/opt/splunkforwarder/bin/splunk restart

echo "========================================"
echo "Forwarder setup complete!"
echo "Forwarding to: ${SPLUNK_SERVER}:${SPLUNK_SERVER_PORT}"
echo "========================================"
