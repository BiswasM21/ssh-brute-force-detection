#!/bin/bash
###############################################################################
# IP Blocking Script
# Blocks malicious IPs detected by SSH brute-force alerts
###############################################################################

set -e

# Configuration
IPTABLES_CHAIN="SSH-BLACKLIST"
LOGFILE="/var/log/splunk/ip_block.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    echo "Usage: $0 <IP_ADDRESS> [--remove]"
    echo "Example: $0 192.168.1.100"
    echo "         $0 192.168.1.100 --remove"
    exit 1
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

init_chain() {
    # Create chain if it doesn't exist
    if ! iptables -L "$IPTABLES_CHAIN" >/dev/null 2>&1; then
        iptables -N "$IPTABLES_CHAIN"
        iptables -I INPUT -j "$IPTABLES_CHAIN"
        log "Created iptables chain: $IPTABLES_CHAIN"
    fi
}

block_ip() {
    local ip="$1"

    # Validate IP format
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}Error: Invalid IP address format: $ip${NC}"
        exit 1
    fi

    # Check if already blocked
    if iptables -C "$IPTABLES_CHAIN" -s "$ip" -j DROP 2>/dev/null; then
        echo -e "${RED}IP $ip is already blocked${NC}"
        return 1
    fi

    # Block the IP
    iptables -A "$IPTABLES_CHAIN" -s "$ip" -j DROP

    # Also block entire subnet (optional - uncomment if needed)
    # local subnet=$(echo "$ip" | cut -d. -f1-3)
    # iptables -A "$IPTABLES_CHAIN" -s "$subnet.0/24" -j DROP

    echo -e "${GREEN}Blocked IP: $ip${NC}"
    log "BLOCKED: $ip"
}

unblock_ip() {
    local ip="$1"

    if ! iptables -C "$IPTABLES_CHAIN" -s "$ip" -j DROP 2>/dev/null; then
        echo -e "${RED}IP $ip is not blocked${NC}"
        return 1
    fi

    iptables -D "$IPTABLES_CHAIN" -s "$ip" -j DROP
    echo -e "${GREEN}Unblocked IP: $ip${NC}"
    log "UNBLOCKED: $ip"
}

# Main execution
if [ $# -lt 1 ]; then
    usage
fi

IP="$1"
REMOVE=false

if [ "$2" = "--remove" ]; then
    REMOVE=true
fi

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

init_chain

if [ "$REMOVE" = true ]; then
    unblock_ip "$IP"
else
    block_ip "$IP"
fi
