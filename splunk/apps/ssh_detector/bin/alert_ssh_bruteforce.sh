#!/bin/bash
###############################################################################
# SSH Brute Force Alert Script
# Triggers when brute force attack is detected
###############################################################################

# Logging
LOGFILE="/var/log/splunk/ssh_alerts.log"
ALERT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Alert data from Splunk
ALERT_NAME="$1"
SRC_IP="$2"
FAILED_COUNT="$3"
USER="$4"

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_alert() {
    echo "[$ALERT_TIME] [$ALERT_NAME] SRC_IP: $SRC_IP FAILED: $FAILED_COUNT USER: $USER" >> "$LOGFILE"
}

send_slack() {
    local webhook_url="${SLACK_WEBHOOK_URL}"
    local message="🚨 *SSH Brute Force Detected*\n\n*Source IP:* $SRC_IP\n*Failed Attempts:* $FAILED_COUNT\n*Target User:* $USER\n*Time:* $ALERT_TIME"

    if [ -n "$webhook_url" ]; then
        curl -s -X POST "$webhook_url" \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \"$message\"}" > /dev/null 2>&1
    fi
}

block_ip() {
    # Add IP to fail2ban
    if command -v fail2ban-client &> /dev/null; then
        fail2ban-client set sshd banip "$SRC_IP" 2>/dev/null
    fi

    # Block with iptables
    if [ "$(id -u)" = "0" ]; then
        iptables -A INPUT -s "$SRC_IP" -j DROP 2>/dev/null
        echo "[$ALERT_TIME] Blocked IP: $SRC_IP via iptables" >> "$LOGFILE"
    fi
}

send_email() {
    local subject="[SECURITY ALERT] SSH Brute Force from $SRC_IP"
    local body="SSH brute force attack detected.

Alert: $ALERT_NAME
Source IP: $SRC_IP
Failed Attempts: $FAILED_COUNT
Target User: $USER
Time: $ALERT_TIME

Recommended Actions:
1. Investigate source IP
2. Check for successful access
3. Block IP if necessary
4. Review authentication logs"

    echo "$body" | mail -s "$subject" security@example.com 2>/dev/null
}

# Main execution
main() {
    log_alert

    echo -e "${RED}[ALERT]${NC} SSH Brute Force Detected"
    echo -e "  Source IP: $SRC_IP"
    echo -e "  Failed Count: $FAILED_COUNT"
    echo -e "  User: $USER"

    # Optional: Uncomment to enable auto-blocking
    # block_ip

    # Optional: Enable notifications
    # send_slack
    # send_email
}

main "$@"
