# SSH Brute-Force Detection Grid

A production-grade SSH brute-force attack detection system using Splunk, Kali Linux, Metasploit, and Nmap.

## Overview

This project provides a complete, self-contained detection grid for identifying and analyzing SSH brute-force attacks. It includes:

- **Splunk SIEM** - Centralized logging, dashboards, and alerting
- **Attack Simulation** - Automated Metasploit and Nmap attack scripts
- **Detection Engine** - Pre-configured Splunk alerts and correlation rules
- **Hardened Targets** - SSH honeypots with fail2ban protection
- **Full Documentation** - Architecture, setup guides, and user manuals

## Features

- Real-time SSH brute-force detection
- Geographic attack visualization
- Timeline analysis dashboards
- Automated alerting (email, Slack, webhook)
- Correlation-based detection (threshold + behavioral)
- MITRE ATT&CK alignment
- Docker Compose for quick deployment
- Vagrant for VM-based lab environment

## Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ssh-brute-force-detection.git
cd ssh-brute-force-detection

# Start all services
docker-compose up -d

# Access Splunk
# URL: https://localhost:8000
# Username: admin
# Password: SplunkPass123!
```

### Option 2: Vagrant (Full VM Lab)

```bash
cd vagrant
vagrant up
vagrant ssh splunk
```

### Option 3: Manual Installation

See [Setup Guide](docs/setup-guide.md) for detailed instructions.

## Project Structure

```
ssh-brute-force-detection/
├── README.md
├── LICENSE
├── docs/                    # Documentation
│   ├── architecture.md      # System architecture
│   ├── setup-guide.md       # Installation guide
│   └── user-guide.md        # User manual
├── splunk/                  # Splunk configuration
│   ├── apps/ssh_detector/   # Custom Splunk app
│   ├── dashboards/           # Dashboard XML files
│   └── inputs/              # Data inputs
├── attack-scripts/          # Attack simulation tools
│   ├── metasploit/          # Metasploit modules
│   └── nmap/                # Nmap NSE scripts
├── detection/                # Detection configurations
│   ├── splunk_alerts/       # Splunk alert scripts
│   └── configs/             # Hardened configs
├── vagrant/                 # Vagrant setup
├── docker/                  # Docker setup
├── logs/                    # Sample logs
└── tests/                   # Test suites
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     SSH Brute-Force Detection Grid                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │ Kali Attacker│────▶│ SSH Target 1 │◀───│ SSH Target 2 │     │
│  │  (Attacker)  │     │  (Honeypot)  │     │  (Honeypot)  │     │
│  └──────────────┘     └──────┬───────┘     └──────────────┘     │
│         │                    │                                 │
│         │    SSH Logs        │   SSH Logs                     │
│         ▼                    ▼                                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │                    Splunk Forwarder                    │     │
│  │              (Collects SSH auth logs)                 │     │
│  └──────────────────────────┬───────────────────────────┘     │
│                             │                                   │
│                             ▼                                   │
│  ┌──────────────────────────────────────────────────────┐     │
│  │                   Splunk Instance                      │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │     │
│  │  │ Dashboards  │  │   Alerts    │  │  Reports    │  │     │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Detection Methods

### 1. Threshold-Based Detection
- Failed login attempts > 5 per minute
- Failed login attempts > 20 per hour from same source IP

### 2. Behavioral Detection
- Login success after many failures (credential stuffing)
- Unusual login times
- Multiple username enumeration

### 3. Correlation Rules
- Port scan + SSH brute-force combo
- Same source attacking multiple targets
- Brute-force + successful lateral movement

## Dashboards

### Overview Dashboard
- Total login attempts (success/failed)
- Attack distribution by country
- Top attacking IPs
- Real-time attack feed

### Attack Analysis Dashboard
- Brute-force patterns
- Credential analysis
- Attack velocity graphs
- Session analysis

### Timeline Dashboard
- Historical attack patterns
- Attack trend analysis
- Peak attack times

## Alerts

| Alert Name | Trigger Condition | Severity |
|------------|-------------------|----------|
| SSH Brute Force Detected | >5 failed logins/min | High |
| SSH Brute Force Critical | >20 failed logins/min | Critical |
| Successful Break-in | Success after >10 failures | Critical |
| Credential stuffing | Same credentials used across IPs | High |
| Slow Brute Force | Low and slow attempts | Medium |

## MITRE ATT&CK Mapping

| Technique ID | Technique Name | Detection |
|--------------|---------------|-----------|
| T1110.001 | Brute Force: Password Guessing | Alert + Dashboard |
| T1110.003 | Brute Force: Password Spraying | Correlation Alert |
| T1021.004 | Remote Services: SSH | Session Analysis |

## Requirements

### Docker Deployment
- Docker Engine 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- 50GB disk space

### Vagrant Deployment
- Vagrant 2.3+
- VirtualBox 7.0+ (or VMware Fusion)
- 16GB RAM recommended
- 100GB disk space

### Manual Deployment
- Splunk Enterprise 9.0+ (or Splunk Free)
- Metasploit Framework 6.3+
- Nmap 7.9+
- SSH server with log access

## Security Notice

This tool is for **authorized security testing only**. Ensure you have explicit permission before scanning or testing any systems you do not own.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Open a GitHub issue
- **Discussions**: GitHub Discussions
- **Documentation**: [docs/](docs/)

---

**Disclaimer**: This project is for educational and authorized testing purposes only. The developers are not responsible for any misuse of this tool.
