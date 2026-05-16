# SSH Brute-Force Detection Grid - User Guide

## Table of Contents

1. [Dashboard Overview](#dashboard-overview)
2. [Running Attack Simulations](#running-attack-simulations)
3. [Alert Configuration](#alert-configuration)
4. [Investigating Incidents](#investigating-incidents)
5. [Response Actions](#response-actions)
6. [Reporting](#reporting)
7. [Maintenance](#maintenance)

---

## Dashboard Overview

### Accessing Dashboards

1. Login to Splunk: `https://localhost:8000` (or your configured URL)
2. Navigate to **Apps** → **SSH Detector**
3. Select dashboard from the menu

### Main Dashboard Panels

| Panel | Description | Refresh Rate |
|-------|-------------|--------------|
| Attack Summary | Total attempts, success/fail ratio | Real-time |
| Top Attackers | Source IPs with most attempts | 1 minute |
| Geographic Map | Attack origins worldwide | 5 minutes |
| Timeline | Attacks over time | Real-time |
| Active Alerts | Current triggered alerts | Real-time |

### Dashboard Navigation

```
┌────────────────────────────────────────────────────────────────────┐
│                    SPLUNK SSH DETECTOR                              │
├────────────────────────────────────────────────────────────────────┤
│  [Overview]  [Attack Analysis]  [Timeline]  [Investigate]  [Reports]│
├────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │  Attack Summary │  │  Top Attackers  │  │  Alert Status   │    │
│  │                 │  │                 │  │                 │    │
│  │  Failed:  1,234 │  │  185.220.x.x   │  │  High:     2    │    │
│  │  Success:    5  │  │  45.227.x.x    │  │  Medium:   3    │    │
│  │  Blocked:  890  │  │  91.92.x.x     │  │  Low:      0    │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      GEOGRAPHIC MAP                          │  │
│  │                                                              │  │
│  │              🔴 China    🔴 Russia    🔴 N. Korea            │  │
│  │                   🔴 Brazil   🔴 USA                        │  │
│  │                                                              │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      TIMELINE                                │  │
│  │  ▁▂▃▅▇█▇▅▃▂▁▂▃▅▇█▇▅▃▂▁ (attacks per hour)                  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## Running Attack Simulations

### Prerequisites

```bash
# Ensure target is reachable
ping 192.168.56.20

# Verify SSH is running on target
nc -zv 192.168.56.20 22
```

### Method 1: Metasploit Framework

```bash
# Start Metasploit
msfconsole
```

#### Basic SSH Brute Force

```msf
# Load SSH scanner
use auxiliary/scanner/ssh/ssh_login

# Configure parameters
set RHOSTS 192.168.56.20
set USERNAME root
set PASS_FILE /usr/share/wordlists/metasploit/unix_passwords.txt
set THREADS 10
set VERBOSE true

# Run attack
run
```

#### SSH Login Scan (Multiple Users)

```msf
# Use login scanner with user file
use auxiliary/scanner/ssh/ssh_login

set RHOSTS 192.168.56.20
set USER_FILE /usr/share/wordlists/metasploit/users.txt
set PASS_FILE /usr/share/wordlists/metasploit/unix_passwords.txt
set THREADS 20
set STOP_ON_SUCCESS true

run
```

#### Credential Stuffing Attack

```msf
# Test known credential pairs
use auxiliary/scanner/ssh/ssh_login

set RHOSTS 192.168.56.20,192.168.56.21,192.168.56.22
set USER_FILE /tmp/breached_credentials.txt
set PASS_FILE /tmp/breached_passwords.txt
set THREADS 50
set BLANK_PASSWORDS false

run
```

### Method 2: Nmap SSH Scripts

```bash
# SSH enumeration
nmap -p 22 --script ssh-brute,ssh-auth-methods,sshv1 \
  192.168.56.20/24

# Detailed SSH audit
nmap -p 22 --script ssh2-enum-algos,ssh-hostkey,sshv1-main \
  192.168.56.20
```

#### Custom SSH NSE Script

```bash
# Run custom brute force script
nmap -p 22 --script ssh-brute \
  --script-args ssh-brute.userdb=/tmp/users.txt,ssh-brute.passdb=/tmp/passwords.txt \
  192.168.56.20
```

### Method 3: Hydra (Parallel Attack)

```bash
# Install Hydra
sudo apt install hydra

# SSH brute force
hydra -l root -P /usr/share/wordlists/rockyou.txt \
  ssh://192.168.56.20 -t 4 -V

# Multiple users
hydra -L /tmp/users.txt -P /usr/share/wordlists/rockyou.txt \
  ssh://192.168.56.20 -t 10 -V
```

### Method 4: Automated Attack Script

```bash
# Run the included attack campaign
cd attack-scripts/metasploit

# Execute attack campaign
./automate_attack.sh \
  --target 192.168.56.20 \
  --wordlist /usr/share/wordlists/metasploit/unix_passwords.txt \
  --rate 5
```

### Monitoring Attack Results

```bash
# View real-time logs
docker-compose logs -f ssh-target

# Check Splunk for alerts
# Search: index=main sourcetype=sshd_auth action=failed | stats count by src_ip
```

---

## Alert Configuration

### Alert Levels

| Level | Threshold | Action |
|-------|-----------|--------|
| **Critical** | >20 failures/min | Immediate notification |
| **High** | >5 failures/min | Alert + log |
| **Medium** | >3 failures/min | Log + dashboard |
| **Low** | >1 failure/min | Log only |

### Configuring Email Alerts

1. Navigate to **Settings** → **Alerts** → **Email Settings**
2. Configure SMTP server:

```
SMTP Server: smtp.gmail.com
Port: 587
TLS: Enabled
Username: your-email@gmail.com
Password: app-specific-password
```

3. Create alert with email action:

```spl
# Saved Search Configuration
| savedsearch "SSH Brute Force Alert"

# Alert Actions
| alert_actions
  - email: security-team@company.com
  - throttle: 5 minutes
```

### Configuring Slack Alerts

1. Create Slack webhook: https://api.slack.com/messaging/webhooks
2. Add webhook URL to Splunk:

```bash
# In Splunk UI
Settings > Alerts > Slack Integration
Paste webhook URL
```

3. Configure alert action:

```spl
| alert_actions
  - slack: webhook_url
  - channel: #security-alerts
  - message_color: danger
```

### Custom Alert Rules

#### Creating via Splunk UI

1. **Search** → Run detection search
2. **Save As** → **Alert**
3. Configure:

```
Name: SSH Brute Force Detected
Time Range: Last 5 minutes
Trigger Condition: Number of results > 0
Trigger Frequency: Every 1 minute
Actions: Email, Slack, Run Script
```

#### Creating via Configuration

```conf
# savedsearches.conf
[ssh_brute_force_detected]
search = index=ssh_security sourcetype=sshd_auth action=failed
        | stats count as failed_count by src_ip
        | where failed_count > 5
        | alert_actions = email,slack
cron_schedule = */1 * * * *
dispatch.earliest_time = -5m
dispatch.latest_time = now
```

---

## Investigating Incidents

### Step 1: Initial Assessment

```spl
# Get incident details
index=ssh_security
| search src_ip="ATTACKER_IP"
| sort -_time
| table _time src_ip dest_ip user action status
```

### Step 2: Timeline Analysis

```spl
# Attack timeline for specific IP
index=ssh_security
| search src_ip="ATTACKER_IP"
| timechart span=1m count by action
```

### Step 3: Geographic Investigation

```spl
# Get attacker location
| iplocation src_ip
| geostats count
```

### Step 4: Credential Analysis

```spl
# List attempted credentials
index=ssh_security action=failed
| search src_ip="ATTACKER_IP"
| stats values(user) as attempted_users by src_ip
```

### Step 5: Impact Assessment

```spl
# Check for successful logins
index=ssh_security action=success
| search src_ip="ATTACKER_IP"
| stats count, min(_time) as first_login, max(_time) as last_login
```

### Incident Investigation Checklist

- [ ] Identify attacker IP(s)
- [ ] Determine attack duration
- [ ] Count failed attempts
- [ ] Check for successful access
- [ ] Identify target accounts
- [ ] Assess geographic origin
- [ ] Review related network activity
- [ ] Document findings

---

## Response Actions

### Automatic Response (fail2ban)

```bash
# Install fail2ban
sudo apt install fail2ban

# Configure SSH protection
sudo nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
findtime = 300
bantime = 3600
action = iptables-allports
```

```bash
# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status
```

### Manual IP Blocking

```bash
# Block IP with iptables
sudo iptables -A INPUT -s ATTACKER_IP -j DROP

# Block IP with ufw
sudo ufw deny from ATTACKER_IP

# View current blocks
sudo iptables -L -n | grep DROP
```

### Automated Blocking Script

```bash
# Run block script
./detection/splunk_alerts/block_ip.sh ATTACKER_IP

# This script:
# 1. Adds IP to iptables block list
# 2. Updates Splunk blacklist lookup
# 3. Sends notification
```

---

## Reporting

### Generating Reports

#### Attack Summary Report

```spl
# Weekly Attack Summary
index=ssh_security
| timechart span=1d count by action
| addinfo
| eval week=strftime(now(), "%Y-W%V")
```

#### Top Attacker Report

```spl
# Monthly Top Attackers
index=ssh_security action=failed
| stats count as attempts by src_ip
| sort - attempts
| head 20
| iplocation src_ip
| table src_ip Country attempts
```

### Exporting Data

```bash
# Export to CSV
| outputcsv ssh_attacks_$(date +%Y%m%d).csv

# Export to JSON
| outputlookup ssh_attack_data.csv
```

### Scheduled Reports

```conf
# savedsearches.conf
[weekly_attack_report]
search = index=ssh_security
        | stats count, dc(src_ip) as unique_attackers
        | rangemap field=count low=0-100 elevated=101-500 severe=501-1000
cron_schedule = 0 9 * * 1
action.email = sendpdf
action.email.to = security-team@company.com
```

---

## Maintenance

### Log Rotation

```bash
# Configure log rotation
sudo nano /etc/logrotate.d/ssh-security
```

```text
/var/log/auth.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
```

### Disk Space Management

```bash
# Check Splunk disk usage
/opt/splunk/bin/splunk show disk-usage

# Clean old indexes
/opt/splunk/bin/splunk clean eventdata -index ssh_security -f

# Optimize index
/opt/splunk/bin/splunk _internal call /services/data/indexes/ssh_security/optimize
```

### Backup Configuration

```bash
# Backup Splunk app
tar -czf ssh_detector_backup_$(date +%Y%m%d).tar.gz \
  /opt/splunk/etc/apps/ssh_detector/

# Backup configurations
tar -czf splunk_configs_$(date +%Y%m%d).tar.gz \
  /opt/splunk/etc/system/local/
```

### Health Checks

```bash
# Run health check script
./tests/health_check.sh

# Expected output:
# ✓ Splunk running
# ✓ Forwarders connected: 3
# ✓ Index size: 5.2GB
# ✓ Last alert: 2 minutes ago
```

### Updating Detection Rules

```bash
# Pull latest rules
git pull origin main

# Reload Splunk app
/opt/splunk/bin/splunk reload app ssh_detector

# Verify new searches
/opt/splunk/bin/splunk search "| savedsearch _tests"
```

---

## Appendix: Common Splunk Searches

### Quick Reference

| Purpose | Search |
|---------|--------|
| All SSH events | `index=ssh_security` |
| Failed logins | `index=ssh_security action=failed` |
| Successful logins | `index=ssh_security action=success` |
| Top attackers | `index=ssh_security action=failed \| stats count by src_ip \| sort -count \| head 10` |
| User enumeration | `index=ssh_security user=invalid*` |
| Brute force | `index=ssh_security \| stats count by src_ip \| where count > 20` |

---

## Support

- **Documentation**: See `/docs/` directory
- **Issues**: Open GitHub issue
- **Logs**: Check `docker-compose logs`
