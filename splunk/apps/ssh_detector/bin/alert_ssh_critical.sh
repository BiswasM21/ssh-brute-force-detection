#!/bin/bash
###############################################################################
# SSH Critical Brute Force Alert Script
# Triggers when critical (high-volume) brute force attack is detected
###############################################################################

LOGFILE="/var/log/splunk/ssh_alerts.log"
ALERT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Alert data
ALERT_NAME="$1"
SRC_IP="$2"
FAILED_COUNT="$3"

RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_critical() {
    echo "[$ALERT_TIME] [CRITICAL] [$ALERT_NAME] SRC_IP: $SRC_IP FAILED: $FAILED_COUNT" >> "$LOGFILE"
}

block_ip_aggressive() {
    if [ "$(id -u)" = "0" ]; then
        # Block with iptables
        iptables -I INPUT -s "$SRC_IP" -j DROP 2>/dev/null

        # Also block entire /24 range if needed
        # IP_SUBNET=$(echo "$SRC_IP" | cut -d. -f1-3)
        # iptables -A INPUT -s "$IP_SUBNET.0/24" -j DROP

        # Log block action
        echo "[$ALERT_TIME] CRITICAL: Blocked IP: $SRC_IP (critical brute force)" >> "$LOGFILE"
    fi
}

notify_pagerduty() {
    # PagerDuty integration
    local routing_key="${PAGERDUTY_ROUTING_KEY}"

    if [ -n "$routing_key" ]; then
        curl -s -X POST "https://events.pagerduty.com/v2/enqueue" \
            -H 'Content-Type: application/json' \
            -d "{
                \"routing_key\": \"$routing_key\",
                \"event_action\": \"trigger\",
                \"payload\": {
                    \"summary\": \"CRITICAL: SSH Brute Force from $SRC_IP\",
                    \"source\": \"splunk-ssh-detector\",
                    \"severity\": \"critical\",
                    \"custom_details\": {
                        \"source_ip\": \"$SRC_IP\",
                        \"failed_attempts\": \"$FAILED_COUNT\",
                        \"alert_time\": \"$ALERT_TIME\"
                    }
                }
            }" > /dev/null 2>&1
    fi
}

send_critical_alert() {
    local subject="🚨 [CRITICAL] SSH Brute Force Attack from $SRC_IP"
    local body="CRITICAL SECURITY ALERT

Attack Type: SSH Brute Force (Critical Volume)
Source IP: $SRC_IP
Failed Attempts: $FAILED_COUNT
Time: $ALERT_TIME

This is a CRITICAL alert indicating a high-volume brute force attack.
Automated blocking has been triggered.

Immediate Actions Required:
1. Check for successful authentication
2. Review all recent SSH sessions
3. Consider network-level blocking
4. Escalate to security team"

    echo "$body" | mail -s "$subject" security-oncall@example.com 2>/dev/null
}

main() {
    log_critical

    echo -e "${RED}[CRITICAL ALERT]${NC} SSH Brute Force Attack"
    echo -e "  ${RED}Source IP: $SRC_IP${NC}"
    echo -e "  ${RED}Failed Count: $FAILED_COUNT${NC}"
    echo -e "  ${CYAN}Auto-blocking enabled${NC}"

    # Auto-block critical attacks
    block_ip_aggressive

    # Notify via PagerDuty for critical alerts
    notify_pagerduty

    # Send critical email
    send_critical_alert
}

main "$@"
