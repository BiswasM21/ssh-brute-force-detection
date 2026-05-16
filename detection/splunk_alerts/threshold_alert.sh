#!/bin/bash
###############################################################################
# Threshold Alert Script
# Triggered when SSH brute-force threshold is exceeded
###############################################################################

ALERT_LOG="/var/log/splunk/threshold_alerts.log"

log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] THRESHOLD_ALERT: $1" >> "$ALERT_LOG"
}

# Get alert parameters
THRESHOLD="$1"
CURRENT_COUNT="$2"
SRC_IP="$3"
TIME_WINDOW="$4"

log_alert "Threshold: $THRESHOLD, Current: $CURRENT_COUNT, IP: $SRC_IP, Window: $TIME_WINDOW"

# Calculate attack rate
RATE=$(echo "scale=2; $CURRENT_COUNT / $TIME_WINDOW" | bc)

echo "ALERT: Brute force threshold exceeded"
echo "  Source IP: $SRC_IP"
echo "  Attempts: $CURRENT_COUNT"
echo "  Rate: $RATE attempts/minute"

# Send to Splunk via HEC
send_to_splunk() {
    local hec_token="${SPLUNK_HEC_TOKEN}"
    local splunk_host="${SPLUNK_HOST:-localhost}"
    local splunk_port="${SPLUNK_HEC_PORT:-8088}"

    curl -k -X POST "https://${splunk_host}:${splunk_port}/services/collector" \
        -H "Authorization: Splunk ${hec_token}" \
        -H "Content-Type: application/json" \
        -d "{
            \"event\": \"threshold_alert\",
            \"src_ip\": \"${SRC_IP}\",
            \"threshold\": ${THRESHOLD},
            \"current_count\": ${CURRENT_COUNT},
            \"rate\": ${RATE},
            \"severity\": \"high\"
        }" 2>/dev/null
}

send_to_splunk

exit 0
