#!/bin/bash
###############################################################################
# Health Check Script
# Verifies all components of the SSH BFD system are functioning
###############################################################################

set -e

SPLUNK_HOST="${SPLUNK_HOST:-localhost}"
SPLUNK_PORT="${SPLUNK_PORT:-8000}"
SPLUNK_USER="${SPLUNK_USER:-admin}"
SPLUNK_PASS="${SPLUNK_PASS:-SplunkPass123!}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; ((PASS_COUNT++)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; ((FAIL_COUNT++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "=========================================="
echo "  SSH BFD Health Check"
echo "=========================================="
echo ""

# Check Splunk connectivity
check_splunk() {
    log_info "Checking Splunk connectivity..."

    if curl -sk -u "$SPLUNK_USER:$SPLUNK_PASS" \
        "https://$SPLUNK_HOST:$SPLUNK_PORT/services/server/info" \
        > /dev/null 2>&1; then
        log_success "Splunk is reachable"
    else
        log_error "Splunk is not reachable"
    fi
}

# Check Splunk services
check_splunk_services() {
    log_info "Checking Splunk services..."

    # Check if splunkd is running
    if pgrep -x "splunkd" > /dev/null; then
        log_success "splunkd is running"
    else
        log_error "splunkd is not running"
    fi

    # Check if splunkweb is running
    if curl -sk "https://$SPLUNK_HOST:$SPLUNK_PORT/en-GB/account/login" \
        > /dev/null 2>&1; then
        log_success "splunkweb is running"
    else
        log_error "splunkweb is not running"
    fi
}

# Check index
check_index() {
    log_info "Checking SSH security index..."

    result=$(curl -sk -u "$SPLUNK_USER:$SPLUNK_PASS" \
        "https://$SPLUNK_HOST:$SPLUNK_PORT/services/data/indexes/ssh_security" \
        2>/dev/null)

    if echo "$result" | grep -q "ssh_security"; then
        log_success "Index 'ssh_security' exists"
    else
        log_warn "Index 'ssh_security' may not exist"
    fi
}

# Check forwarders
check_forwarders() {
    log_info "Checking forwarder connections..."

    result=$(curl -sk -u "$SPLUNK_USER:$SPLUNK_PASS" \
        "https://$SPLUNK_HOST:8089/services/server/introspection/forwarder" \
        2>/dev/null)

    connected=$(echo "$result" | grep -c "connected" || true)
    if [ "$connected" -gt 0 ]; then
        log_success "Forwarders connected: $connected"
    else
        log_warn "No forwarders connected"
    fi
}

# Check disk space
check_disk_space() {
    log_info "Checking disk space..."

    available=$(df -h /opt/splunk 2>/dev/null | tail -1 | awk '{print $4}' || echo "N/A")
    if [ "$available" != "N/A" ]; then
        log_success "Available disk space: $available"
    else
        log_warn "Could not check disk space"
    fi
}

# Check memory
check_memory() {
    log_info "Checking memory usage..."

    used=$(free -h 2>/dev/null | grep Mem | awk '{print $3}' || echo "N/A")
    total=$(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "N/A")
    if [ "$used" != "N/A" ]; then
        log_success "Memory usage: $used / $total"
    else
        log_warn "Could not check memory"
    fi
}

# Check recent alerts
check_alerts() {
    log_info "Checking recent alerts..."

    result=$(curl -sk -u "$SPLUNK_USER:$SPLUNK_PASS" \
        "https://$SPLUNK_HOST:$SPLUNK_PORT/services/alerts/fired_alerts?count=5" \
        2>/dev/null)

    if echo "$result" | grep -q "fired_alerts"; then
        log_success "Alert system is operational"
    else
        log_warn "Could not verify alerts"
    fi
}

# Check SSH service on targets
check_ssh_targets() {
    log_info "Checking SSH targets..."

    targets=("192.168.56.20" "192.168.56.21" "192.168.56.22")

    for target in "${targets[@]}"; do
        if timeout 2 bash -c "echo > /dev/tcp/$target/22" 2>/dev/null; then
            log_success "SSH target $target is reachable"
        else
            log_warn "SSH target $target is not reachable"
        fi
    done
}

# Main execution
main() {
    check_splunk
    check_splunk_services
    check_index
    check_forwarders
    check_disk_space
    check_memory
    check_alerts
    check_ssh_targets

    echo ""
    echo "=========================================="
    echo "  SUMMARY"
    echo "=========================================="
    echo -e "  Passed: ${GREEN}$PASS_COUNT${NC}"
    echo -e "  Failed: ${RED}$FAIL_COUNT${NC}"
    echo "=========================================="
    echo ""

    if [ "$FAIL_COUNT" -eq 0 ]; then
        log_success "All health checks passed!"
        exit 0
    else
        log_error "Some health checks failed"
        exit 1
    fi
}

main "$@"
