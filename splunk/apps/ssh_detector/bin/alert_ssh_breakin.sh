#!/bin/bash
###############################################################################
# SSH Break-in Alert Script
# Triggers when successful login follows brute force attempt
###############################################################################

LOGFILE="/var/log/splunk/ssh_alerts.log"
ALERT_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Alert data
ALERT_NAME="$1"
SRC_IP="$2"
USER="$3"
ATTEMPT_COUNT="$4"

RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_incident() {
    echo "[$ALERT_TIME] [BREAK-IN] SRC_IP: $SRC_IP USER: $USER ATTEMPTS: $ATTEMPT_COUNT" >> "$LOGFILE"
}

investigate_session() {
    # Log session investigation details
    echo "[$ALERT_TIME] INCIDENT: Investigating session from $SRC_IP for user $USER" >> "$LOGFILE"

    # Check if user session is still active
    # This would query Splunk for active sessions
    echo "[$ALERT_TIME] ACTION: Check active sessions for user $USER" >> "$LOGFILE"
}

lock_account() {
    local target_user="$USER"

    if [ "$(id -u)" = "0" ]; then
        # Lock the compromised account
        passwd -l "$target_user" 2>/dev/null
        echo "[$ALERT_TIME] ACTION: Locked account $target_user" >> "$LOGFILE"
    fi
}

escalate_incident() {
    local subject="🚨 [BREAK-IN CONFIRMED] SSH Access from $SRC_IP as $USER"
    local body="SECURITY INCIDENT - CONFIRMED BREACH

Alert: SSH Break-in Detected
Severity: CRITICAL
Source IP: $SRC_IP
Compromised User: $USER
Failed Attempts Before Success: $ATTEMPT_COUNT
Time: $ALERT_TIME

IMMEDIATE ACTIONS REQUIRED:

1. ISOLATE - Disconnect any sessions from $SRC_IP
2. LOCK - Lock account $USER immediately
3. INVESTIGATE - Check for:
   - Data exfiltration
   - Privilege escalation
   - Lateral movement
   - Persistence mechanisms
4. ERADICATE - Block $SRC_IP at network level
5. NOTIFY - Escalate to security leadership

This is a confirmed security incident. Follow incident response procedures."

    # Send to security team
    echo "$body" | mail -s "$subject" security-incident@example.com 2>/dev/null

    # Send to Slack security channel
    local webhook_url="${SLACK_WEBHOOK_URL}"
    if [ -n "$webhook_url" ]; then
        local message="🚨 *SSH BREAK-IN CONFIRMED*\n\n*Source IP:* $SRC_IP\n*User:* $USER\n*Attempts:* $ATTEMPT_COUNT\n*Time:* $ALERT_TIME\n\n:rotating_light: IMMEDIATE ACTION REQUIRED"
        curl -s -X POST "$webhook_url" \
            -H 'Content-Type: application/json' \
            -d "{\"text\": \"$message\", \"channel\": \"#security-incidents\"}" > /dev/null 2>&1
    fi
}

main() {
    log_incident

    echo -e "${RED}[BREAK-IN DETECTED]${NC} SSH Access Compromised"
    echo -e "  Source IP: $SRC_IP"
    echo -e "  User: $MAGENTA$USER$NC"
    echo -e "  Attempts: $ATTEMPT_COUNT"
    echo ""
    echo "Escalating incident to security team..."

    # Investigate the session
    investigate_session

    # Lock compromised account
    lock_account

    # Escalate incident
    escalate_incident
}

main "$@"
