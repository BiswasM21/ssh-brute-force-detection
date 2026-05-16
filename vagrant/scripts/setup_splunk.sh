#!/bin/bash
###############################################################################
# Splunk Server Setup Script
###############################################################################

set -e

SPLUNK_VERSION="9.0.0"
SPLUNK_USER="splunk"
ADMIN_PASSWORD="SplunkPass123!"

echo "========================================"
echo "Setting up Splunk Server"
echo "========================================"

# Update system
apt-get update -qq

# Install prerequisites
apt-get install -y -qq wget curl net-tools

# Download Splunk
echo "Downloading Splunk Enterprise..."
cd /tmp
wget -q "https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/linux/splunk-${SPLUNK_VERSION}-linux-amd64.tgz"

# Extract and install
echo "Installing Splunk..."
tar -xzf "splunk-${SPLUNK_VERSION}-linux-amd64.tgz" -C /opt
ln -sf /opt/splunk/bin/splunk /usr/local/bin/splunk

# Create Splunk user
useradd -m -s /bin/bash $SPLUNK_USER 2>/dev/null || true
chown -R $SPLUNK_USER:$SPLUNK_USER /opt/splunk

# Configure Splunk
cat > /opt/splunk/etc/system/local/web.conf <<EOF
[settings]
enableSplunkWeb = 1
startwebserver = 1
httpport = 8000
EOF

cat > /opt/splunk/etc/system/local/server.conf <<EOF
[general]
servername = ssh-bfd-splunk

[sslConfig]
enableSplunkdSSL = false

[indexing]
assureUTF8 = true
EOF

# Accept license and start Splunk
echo "Starting Splunk..."
su - $SPLUNK_USER -c "/opt/splunk/bin/splunk start --accept-license --no-prompt"

# Enable Splunk to start on boot
cat > /etc/systemd/system/splunk.service <<EOF
[Unit]
Description=Splunk Enterprise
After=network.target

[Service]
Type=simple
ExecStart=/opt/splunk/bin/splunk start
ExecStop=/opt/splunk/bin/splunk stop
User=$SPLUNK_USER
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable splunk.service 2>/dev/null || true

# Configure firewall
ufw allow 8000/tcp 2>/dev/null || true
ufw allow 8089/tcp 2>/dev/null || true
ufw allow 9997/tcp 2>/dev/null || true

echo "========================================"
echo "Splunk setup complete!"
echo "URL: https://192.168.56.100:8000"
echo "Username: admin"
echo "Password: $ADMIN_PASSWORD"
echo "========================================"
