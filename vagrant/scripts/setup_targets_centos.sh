#!/bin/bash
###############################################################################
# SSH Target Setup Script (CentOS/RedHat)
###############################################################################

set -e

echo "========================================"
echo "Setting up SSH Target (CentOS)"
echo "========================================"

# Install OpenSSH server and fail2ban
dnf install -y -q openssh-server openssh-clients fail2ban rsyslog

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
logpath = /var/log/secure
maxretry = 5
findtime = 300
bantime = 3600
banaction = iptables-multiport
EOF

# Enable and start services
systemctl enable sshd fail2ban rsyslog
systemctl start sshd fail2ban rsyslog

echo "========================================"
echo "SSH Target (CentOS) setup complete!"
echo "========================================"
