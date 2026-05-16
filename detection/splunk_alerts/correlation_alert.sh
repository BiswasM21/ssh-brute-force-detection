#!/bin/bash
###############################################################################
# Correlation Alert Script
# Triggered when correlation rules detect attack patterns
###############################################################################

ALERT_LOG="/var/log/splunk/correlation_alerts.log"

log_correlation() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CORRELATION: $1" >> "$ALERT_LOG"
}

# Alert data
ALERT_TYPE="$1"
SRC_IP="$2"
PATTERN="$3"
CONFIDENCE="$4"

log_correlation "Type: $ALERT_TYPE, IP: $SRC_IP, Pattern: $PATTERN, Confidence: $CONFIDENCE"

case "$ALERT_TYPE" in
    "port_scan+ssh_brute")
        echo "CORRELATED ALERT: Port scan detected before SSH brute force"
        echo "  Source IP: $SRC_IP"
        echo "  Pattern: $PATTERN"
        echo "  Confidence: $CONFIDENCE"
        ;;
    "credential_stuffing")
        echo "CORRELATED ALERT: Credential stuffing detected"
        echo "  Source IP: $SRC_IP"
        echo "  Pattern: Same credentials across multiple targets"
        ;;
    "slow_brute_force")
        echo "CORRELATED ALERT: Slow brute force (stealth attack)"
        echo "  Source IP: $SRC_IP"
        echo "  Pattern: Low and slow attempts to evade detection"
        ;;
    *)
        echo "CORRELATED ALERT: Unknown pattern"
        echo "  Source IP: $SRC_IP"
        echo "  Pattern: $PATTERN"
        ;;
esac

# Send to Splunk
send_to_splunk() {
    local hec_token="${SPLUNK_HEC_TOKEN}"
    curl -k -X POST "https://localhost:8088/services/collector" \
        -H "Authorization: Splunk ${hec_token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"event\": \"correlation_alert\",
            \"alert_type\": \"${ALERT_TYPE}\",
            \"src_ip\": \"${SRC_IP}\",
            \"pattern\": \"${PATTERN}\",
            \"confidence\": \"${CONFIDENCE}\"
        }" 2>/dev/null
}

send_to_splunk

exit 0
