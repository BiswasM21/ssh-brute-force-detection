#!/bin/bash
###############################################################################
# SSH Target Setup Script (Ubuntu/Debian)
###############################################################################

set -e

echo "========================================"
echo "Setting up SSH Target"
echo "========================================"

# Update system
apt-get update -qq

# Install OpenSSH server and fail2ban
apt-get install -y -qq openssh-server fail2ban rsyslog

# Configure SSH
echo "Configuring SSH server..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "MaxAuthTries 10" >> /etc/ssh/sshd_config
echo "LogLevel VERBOSE" >> /etc/ssh/sshd_config
echo "UseDNS no" >> /etc/ssh/sshd_config

# Create test user
echo "Creating test user..."
useradd -m -s /bin/bash testuser
echo 'testuser:TestPass123!' | chpasswd

# Configure fail2ban
echo "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
findtime = 300
bantime = 3600
banaction = iptables-multiport
action = iptables[name=sshd, port=ssh, protocol=tcp]
EOF

# Enable and start services
systemctl enable ssh fail2ban rsyslog
systemctl start ssh fail2ban rsyslog

# Configure firewall
ufw allow ssh 2>/dev/null || true

echo "========================================"
echo "SSH Target setup complete!"
echo "========================================"
