# SSH Brute-Force Detection Grid - Architecture

## System Overview

The SSH Brute-Force Detection Grid is a comprehensive security monitoring system designed to detect, analyze, and alert on SSH brute-force attacks in real-time.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DETECTION GRID ARCHITECTURE                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ╔═══════════════════════════════════════════════════════════════════════╗   │
│  ║                          ATTACK LAYER                                    ║   │
│  ║  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   ║   │
│  ║  │   Metasploit│  │    Nmap     │  │ Hydra/Medusa│ │ Custom Tools│   ║   │
│  ║  │  Framework  │  │   Scanner   │  │   Attackers │  │   (Python)  │   ║   │
│  ║  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   ║   │
│  ╚══════════╪══════════════╪══════════════╪══════════════╪════════════╝   │
│              │              │              │              │                 │
│              └──────────────┴───────┬──────┴──────────────┘                 │
│                                     │                                        │
│                                     ▼                                        │
│  ╔═══════════════════════════════════════════════════════════════════════╗   │
│  ║                          TARGET LAYER                                   ║   │
│  ║  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   ║   │
│  ║  │ Ubuntu SSH  │  │ CentOS SSH  │  │  Debian SSH │  │ Kali SSH    │   ║   │
│  ║  │  Target 1   │  │  Target 2   │  │  Target 3   │  │  (Self)     │   ║   │
│  ║  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   ║   │
│  ╚══════════╪══════════════╪══════════════╪══════════════╪════════════╝   │
│              │              │              │              │                 │
│              └──────────────┴───────┬──────┴──────────────┘                 │
│                                     │                                        │
│                                     ▼                                        │
│  ╔═══════════════════════════════════════════════════════════════════════╗   │
│  ║                       LOGGING LAYER                                    ║   │
│  ║  ┌─────────────────────────────────────────────────────────────────┐ ║   │
│  ║  │                    /var/log/auth.log                             │ ║   │
│  ║  │                    /var/log/secure                               │ ║   │
│  ║  │                    /var/log/sshd.log                              │ ║   │
│  ║  └─────────────────────────────────────────────────────────────────┘ ║   │
│  ╚══════════════════════════════════════════════════════════════════════╝   │
│                                     │                                        │
│                                     ▼                                        │
│  ╔═══════════════════════════════════════════════════════════════════════╗   │
│  ║                      COLLECTION LAYER                                  ║   │
│  ║  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                   ║   │
│  ║  │ Splunk UF   │  │   Syslog    │  │    API      │                   ║   │
│  ║  │ (Forwarder) │  │   (rsyslog) │  │  (Custom)   │                   ║   │
│  ║  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                   ║   │
│  ╚══════════╪══════════════╪══════════════╪════════════════════════════╝   │
│              │              │              │                                │
│              └──────────────┴───────┬──────┘                                │
│                                     │                                        │
│                                     ▼                                        │
│  ╔═══════════════════════════════════════════════════════════════════════╗   │
│  ║                          SIEM LAYER                                     ║   │
│  ║  ┌─────────────────────────────────────────────────────────────────┐ ║   │
│  ║  │                      SPLUNK ENTERPRISE                          │ ║   │
│  ║  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐      │ ║   │
│  ║  │  │   Search Head │  │    Indexer    │  │    License    │      │ ║   │
│  ║  │  │  (Dashboards) │  │   (Storage)   │  │   Manager    │      │ ║   │
│  ║  │  └───────────────┘  └───────────────┘  └───────────────┘      │ ║   │
│  ║  │                                                                  │ ║   │
│  ║  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │ ║   │
│  ║  │  │    Alerts      │  │   Reports      │  │   Lookups     │    │ ║   │
│  ║  │  │  (Real-time)   │  │  (Scheduled)   │  │   (Threats)   │    │ ║   │
│  ║  │  └───────────────┘  └───────────────┘  └───────────────┘      │ ║   │
│  ║  └─────────────────────────────────────────────────────────────────┘ ║   │
│  ╚══════════════════════════════════════════════════════════════════════╝   │
│                                     │                                        │
│                                     ▼                                        │
│  ╔═══════════════════════════════════════════════════════════════════════╗   │
│  ║                      OUTPUT LAYER                                       ║   │
│  ║  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ║   │
│  ║  │    Email     │  │   Slack     │  │    PagerDuty│  │    Webhook   │ ║   │
│  ║  │  (SMTP)     │  │  (Webhook)  │  │  (Alert)    │  │   (Custom)  │ ║   │
│  ║  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ ║   │
│  ╚═══════════════════════════════════════════════════════════════════════╝   │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Attack Simulation Layer

| Component | Purpose | Configuration |
|-----------|---------|----------------|
| Metasploit Framework | SSH brute-force modules | `modules/auxiliary/scanner/ssh/` |
| Nmap + NSE | SSH enumeration and scanning | `nmap/ssh_enum.nse` |
| Custom Scripts | Automated attack campaigns | `attack-scripts/` |

### 2. Target Layer

| Target | OS | SSH Config | Hardening |
|--------|-----|------------|----------|
| Target 1 | Ubuntu 22.04 | OpenSSH 8.9 | fail2ban, PAM |
| Target 2 | CentOS 9 | OpenSSH 8.0 | firewalld, auditd |
| Target 3 | Debian 12 | OpenSSH 9.2 | iptables, logwatch |

### 3. Collection Layer

| Method | Protocol | Port | Data Type |
|--------|----------|------|-----------|
| Splunk Forwarder | TCP/HEC | 8088/9997 | Auth logs |
| Syslog | UDP/TCP | 514/6514 | Auth logs |
| File Monitor | Local | - | /var/log/* |

### 4. SIEM Layer (Splunk)

#### Index Configuration
```
index=ssh_security
  └─ indexed fields: src_ip, dest_ip, user, action, auth_method
  └─ retention: 30 days (configurable)
```

#### Search-Time Fields
```
sourcetype=sshd_auth
  └─ extracted: timestamp, src_ip, dest_port, user, status, auth_method
```

### 5. Detection Engine

#### Correlation Searches

| Search Name | Logic | Alert Level |
|-------------|-------|-------------|
| `ssh_brute_force_threshold` | `failed_attempts > 5 per minute` | High |
| `ssh_brute_force_critical` | `failed_attempts > 20 per minute` | Critical |
| `ssh_successful_after_brute` | `success events following >10 failures` | Critical |
| `ssh_slow_brute_force` | `failed_attempts 1-3 per minute for 10+ minutes` | Medium |
| `ssh_password_spray` | `unique_users > 5 from same IP in 1 hour` | High |

## Data Flow

```
1. ATTACK INITIATED
   Metasploit/Nmap/Hydra → SSH Target

2. LOG GENERATION
   SSH Server logs → /var/log/auth.log (Debian/Ubuntu)
                    → /var/log/secure (RHEL/CentOS)

3. LOG COLLECTION
   Splunk Forwarder reads logs
   OR Syslog daemon forwards to Splunk
   OR Files are monitored directly

4. LOG INDEXING
   Splunk parses → extracts fields → stores in index

5. SEARCH EXECUTION
   Scheduled searches run every minute
   Real-time searches monitor incoming data

6. DETECTION
   Pattern match OR threshold exceeded
   → Alert triggered

7. NOTIFICATION
   Alert → Email/Slack/Webhook
   → Dashboard updated
   → Incident created (optional)

8. RESPONSE (OPTIONAL)
   Firewall block (fail2ban)
   IP reputation update
   Ticket creation
```

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        NETWORK TOPOLOGY                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  [192.168.56.0/24] - Attack Network                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                                                          │    │
│  │   [Kali Attacker] ◀──── Attacks ────▶ [SSH Targets]    │    │
│  │   192.168.56.10                      192.168.56.20-22    │    │
│  │                                                          │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                     │
│                            │ SSH Logs (Port 9997)               │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [Splunk Server]                                        │    │
│  │  192.168.56.100                                          │    │
│  │  - Search Head                                          │    │
│  │  - Indexer                                              │    │
│  │  - Forwarder (on targets)                               │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Security Zones

| Zone | Purpose | Access Control |
|------|---------|----------------|
| Attack Zone | Attack simulation | Isolated VLAN |
| Target Zone | Honeypots | Restricted access |
| Management Zone | Splunk admin | VPN only |
| Monitoring Zone | Analyst access | Read-only |

## Scalability

### Single Instance (Current)
- Handles up to 10,000 events/minute
- 1-week retention at full load

### Distributed Deployment
- 1 Search Head + 3 Indexers
- Handles 100,000+ events/minute
- 90-day retention

## Failure Modes

| Component | Failure Impact | Mitigation |
|-----------|---------------|-----------|
| Forwarder down | No new logs | Local buffering |
| Indexer down | Search unavailable | Clustering |
| Disk full | No new indexing | Auto-rollover |
| Network split | Isolated segments | Local processing |

## Performance Tuning

| Parameter | Default | Recommended | Purpose |
|-----------|---------|------------|---------|
| `MAX_THROTTLE_RATE` | 100/sec | 1000/sec | Event processing |
| `BATCH_SIZE` | 500 | 5000 | Network efficiency |
| `QUEUE_SIZE` | 1000 | 10000 | Burst handling |

## Deployment Modes

### 1. Docker Compose (Development)
- All-in-one container
- Quick testing
- Limited scale

### 2. Vagrant (Lab)
- Full VM isolation
- Production-like
- Resource intensive

### 3. Manual (Production)
- Distributed deployment
- Maximum control
- Complex setup

## Next Steps

- See [Setup Guide](setup-guide.md) for installation
- See [User Guide](user-guide.md) for operations
- Review `splunk/` for detection configurations
