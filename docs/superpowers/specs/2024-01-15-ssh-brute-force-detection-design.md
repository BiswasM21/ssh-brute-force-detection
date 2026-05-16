# SSH Brute-Force Detection Grid - Design Specification

## Overview

A production-grade SSH brute-force attack detection system designed for security researchers, SOC analysts, and penetration testers. The system provides real-time detection, alerting, and visualization using Splunk as the SIEM platform.

## Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| SIEM | Splunk Enterprise | Centralized logging and analysis |
| Attack Simulation | Metasploit, Nmap, Hydra | Realistic attack generation |
| Targets | Docker containers | SSH honeypots with logging |
| Detection | Splunk alerts + correlation | Pattern-based detection |
| Dashboards | Splunk Simple XML | Visual analytics |
| Hardening | fail2ban, iptables | Response automation |

## Architecture

The system follows a three-tier architecture:

1. **Collection Layer**: SSH auth logs collected via Splunk Forwarders
2. **Processing Layer**: Splunk indexes and parses events
3. **Detection Layer**: Saved searches and correlation rules detect attacks

## Deployment Modes

1. **Docker Compose**: All-in-one for quick testing
2. **Vagrant**: Full VM isolation for production-like environments
3. **Manual**: Custom enterprise deployments

## Detection Rules

- Threshold-based alerts (>5 failed attempts/minute)
- Correlation rules (failed + success patterns)
- Behavioral analysis (slow brute force detection)
- MITRE ATT&CK aligned

## Success Criteria

- Real-time detection of SSH brute-force attacks
- < 1 minute latency from attack to alert
- Visual dashboards with attack analytics
- Automated response capability
