#!/bin/bash
###############################################################################
# Blackhole Route Alert
# Adds malicious IPs to routing blackhole for null routing
###############################################################################

# Requires root privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

BLACKHOLE_LOG="/var/log/splunk/blackhole.log"

log_blackhole() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLACKHOLE: $1" >> "$BLACKHOLE_LOG"
}

add_blackhole() {
    local ip="$1"
    local subnet_mask="${2:-32}"

    # Add null route (blackhole)
    ip route add blackhole "$ip/$subnet_mask" 2>/dev/null

    log_blackhole "ADDED: $ip/$subnet_mask"
    echo "Added blackhole route for $ip/$subnet_mask"
}

remove_blackhole() {
    local ip="$1"
    local subnet_mask="${2:-32}"

    # Remove null route
    ip route del blackhole "$ip/$subnet_mask" 2>/dev/null

    log_blackhole "REMOVED: $ip/$subnet_mask"
    echo "Removed blackhole route for $ip/$subnet_mask"
}

case "$1" in
    add)
        add_blackhole "$2" "$3"
        ;;
    remove)
        remove_blackhole "$2" "$3"
        ;;
    *)
        echo "Usage: $0 {add|remove} <IP> [MASK]"
        ;;
esac
