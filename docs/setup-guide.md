# SSH Brute-Force Detection Grid - Setup Guide

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 8 GB | 16+ GB |
| Disk | 50 GB | 100+ GB SSD |
| Network | 1 Gbps | 10 Gbps |

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| Docker | 20.10+ | Container orchestration |
| Docker Compose | 2.0+ | Multi-container setup |
| Splunk | 9.0+ | SIEM platform |
| Metasploit | 6.3+ | Attack simulation |
| Nmap | 7.9+ | Network scanning |

---

## Method 1: Docker Compose (Recommended)

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/ssh-brute-force-detection.git
cd ssh-brute-force-detection
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Configuration options:**
```env
# Splunk Configuration
SPLUNK_USERNAME=admin
SPLUNK_PASSWORD=YourSecurePassword123!
SPLUNK_PORT=8000
SPLUNK_HEC_PORT=8088

# SSH Target Configuration
SSH_TARGET_PASSWORD=TargetPass456!
SSH_ALLOW_ATTACKS=true

# Network Configuration
NETWORK_SUBNET=172.20.0.0/16
```

### Step 3: Start Services

```bash
# Build and start all services
docker-compose up -d

# View service status
docker-compose ps

# View logs
docker-compose logs -f splunk
```

### Step 4: Access Splunk

1. Open browser: `https://localhost:8000`
2. Login with credentials from `.env`
3. Accept SSL certificate warning (first time)

### Step 5: Configure Data Inputs

```bash
# Run Splunk setup script
docker exec -it ssh-bfd-splunk /opt/splunk/bin/splunk \
  add monitor /var/log/auth.log -sourcetype sshd_auth

# Enable SSH detector app
docker exec -it ssh-bfd-splunk /opt/splunk/bin/splunk \
  install app /opt/splunk/etc/apps/ssh_detector
```

### Step 6: Verify Setup

```bash
# Check indexes
curl -k -u admin:YourSecurePassword123! \
  https://localhost:8089/services/server/indexes

# Check forwarder connection
docker exec -it ssh-bfd-splunk /opt/splunk/bin/splunk \
  list forwarder
```

---

## Method 2: Vagrant (Full VM Lab)

### Prerequisites

```bash
# Install Vagrant
brew install vagrant        # macOS
sudo apt install vagrant   # Linux

# Install VirtualBox
brew install --cask virtualbox  # macOS
```

### Step 1: Initialize Vagrant

```bash
cd vagrant
vagrant init
```

### Step 2: Configure Vagrantfile

```ruby
# vagrant/Vagrantfile
Vagrant.configure("2") do |config|
  # Splunk Server
  config.vm.define "splunk" do |splunk|
    splunk.vm.box = "ubuntu/jammy64"
    splunk.vm.network "private_network", ip: "192.168.56.100"
    splunk.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 2
    end
    splunk.vm.provision "shell", path: "scripts/setup_splunk.sh"
  end

  # Kali Attacker
  config.vm.define "kali" do |kali|
    kali.vm.box = "kalilinux/amd64"
    kali.vm.network "private_network", ip: "192.168.56.10"
    kali.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
    kali.vm.provision "shell", path: "scripts/setup_kali.sh"
  end

  # SSH Target
  config.vm.define "target" do |target|
    target.vm.box = "ubuntu/jammy64"
    target.vm.network "private_network", ip: "192.168.56.20"
    target.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
    target.vm.provision "shell", path: "scripts/setup_targets.sh"
  end
end
```

### Step 3: Provision VMs

```bash
# Start all VMs
vagrant up

# SSH into Splunk VM
vagrant ssh splunk

# SSH into Kali
vagrant ssh kali
```

### Step 4: Configure Splunk on VM

```bash
# On Splunk VM
sudo systemctl start splunk

# Access Splunk
# URL: https://192.168.56.100:8000
```

---

## Method 3: Manual Installation

### Step 1: Install Splunk

#### Ubuntu/Debian

```bash
# Download Splunk
wget -O splunk-9.0.0-linux-amd64.tgz \
  https://download.splunk.com/products/splunk/releases/9.0.0/linux/splunk-9.0.0-linux-amd64.tgz

# Extract and install
tar -xzf splunk-9.0.0-linux-amd64.tgz -C /opt
ln -s /opt/splunk/bin/splunk /usr/local/bin/splunk

# Start Splunk
/opt/splunk/bin/splunk start --accept-license
```

#### RHEL/CentOS

```bash
# Install dependencies
sudo yum install wget tar

# Download and install
sudo wget -O /tmp/splunk.rpm \
  https://download.splunk.com/products/splunk/releases/9.0.0/linux/splunk-9.0.0-linux-x86_64.rpm

sudo rpm -i /tmp/splunk.rpm

# Start Splunk
sudo /opt/splunk/bin/splunk start --accept-license
```

### Step 2: Install Splunk Forwarder on Targets

```bash
# Download forwarder
wget -O splunkforwarder.tgz \
  https://download.splunk.com/products/universalforwarder/releases/9.0.0/linux/splunkforwarder-9.0.0-linux-amd64.tgz

tar -xzf splunkforwarder.tgz -C /opt

# Configure forwarder
/opt/splunkforwarder/bin/splunk start --accept-license

# Set deployment server
/opt/splunkforwarder/bin/splunk set deploy-poll 192.168.56.100:8089

# Add monitoring
/opt/splunkforwarder/bin/splunk add monitor /var/log/auth.log
/opt/splunkforwarder/bin/splunk add monitor /var/log/secure

# Restart
/opt/splunkforwarder/bin/splunk restart
```

### Step 3: Install Metasploit

```bash
# Install dependencies
sudo apt update
sudo apt install -y ruby bundler postgresql libpq-dev

# Clone and setup
git clone https://github.com/rapid7/metasploit-framework.git
cd metasploit-framework
gem install bundler
bundle install

# Run Metasploit
./msfconsole
```

### Step 4: Install Nmap

```bash
# Ubuntu/Debian
sudo apt install nmap

# RHEL/CentOS
sudo yum install nmap

# macOS
brew install nmap
```

---

## Post-Installation Configuration

### 1. Create SSH Detector App

```bash
# Copy Splunk app
cp -r splunk/apps/ssh_detector /opt/splunk/etc/apps/

# Set permissions
chown -R splunk:splunk /opt/splunk/etc/apps/ssh_detector

# Restart Splunk
/opt/splunk/bin/splunk restart
```

### 2. Configure Alerts

```bash
# Copy alert scripts
cp -r detection/splunk_alerts/* /opt/splunk/etc/apps/ssh_detector/bin/

# Make executable
chmod +x /opt/splunk/etc/apps/ssh_detector/bin/*.sh
```

### 3. Import Dashboards

```bash
# Copy dashboard XML
cp splunk/dashboards/*.xml /opt/splunk/etc/apps/ssh_detector/dashboards/

# Reload app
/opt/splunk/bin/splunk reload app ssh_detector
```

### 4. Configure Saved Searches

```bash
# Copy saved searches config
cp splunk/apps/ssh_detector/default/savedsearches.conf \
   /opt/splunk/etc/apps/ssh_detector/default/

# Reload
/opt/splunk/bin/splunk reload
```

---

## Network Setup

### Configure Static IP (Targets)

```bash
# /etc/netplan/01-netcfg.yaml (Ubuntu)
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
        - 192.168.56.20/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

```bash
sudo netplan apply
```

### Configure Firewall

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow Splunk
sudo ufw allow 8000/tcp
sudo ufw allow 8089/tcp
sudo ufw allow 9997/tcp

# Enable firewall
sudo ufw enable
```

---

## Verification Tests

### Test 1: Log Generation

```bash
# On target, generate test logs
sudo sshd -d  # Debug mode for testing

# Attempt failed login
ssh invaliduser@localhost
```

### Test 2: Splunk Ingestion

```bash
# In Splunk, search for SSH logs
# Index: main, sourcetype: sshd_auth

| tstats count WHERE index=main BY sourcetype
```

### Test 3: Alert Testing

```bash
# Trigger brute force alert
for i in {1..10}; do
  ssh user@192.168.56.20 -o StrictHostKeyChecking=no 2>/dev/null
done
```

---

## Troubleshooting

### Common Issues

#### Splunk Won't Start

```bash
# Check logs
/opt/splunk/bin/splunk log

# Fix permissions
chown -R splunk:splunk /opt/splunk

# Check license
/opt/splunk/bin/splunk diag
```

#### Forwarder Not Connecting

```bash
# Verify network
netstat -tulpn | grep 9997

# Check firewall
sudo ufw status

# Test connectivity
nc -zv 192.168.56.100 9997
```

#### No SSH Logs

```bash
# Verify SSH logging
grep -i auth /etc/ssh/sshd_config

# Enable auth logging
echo "LogLevel VERBOSE" | sudo tee -a /etc/ssh/sshd_config

# Restart SSH
sudo systemctl restart sshd
```

---

## Next Steps

- Configure alerts in Splunk UI
- Set up notification channels (email/Slack)
- Run attack simulations
- Review dashboards

See [User Guide](user-guide.md) for operational procedures.
