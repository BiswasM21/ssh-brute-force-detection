#!/bin/bash
###############################################################################
# SSH Nmap Scan Campaign
# Automated SSH reconnaissance and scanning campaign
###############################################################################

set -e

# Configuration
TARGET="${TARGET_NET:-192.168.56.0/24}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/nmap_ssh_scans}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run basic SSH scan
basic_ssh_scan() {
    log_info "Running basic SSH port scan..."
    nmap -p 22 -oA "$OUTPUT_DIR/ssh_ports" "$TARGET" 2>&1 | tee "$OUTPUT_DIR/nmap_basic.log"
    log_success "Basic scan complete"
}

# SSH version detection
ssh_version_scan() {
    log_info "Running SSH version detection..."
    nmap -p 22 -sV -oA "$OUTPUT_DIR/ssh_versions" "$TARGET" 2>&1 | tee "$OUTPUT_DIR/nmap_version.log"
    log_success "Version scan complete"
}

# SSH enumeration
ssh_enumeration() {
    log_info "Running SSH enumeration..."
    nmap -p 22 --script ssh2-enum-algos,ssh-hostkey,sshv1-main \
        -oA "$OUTPUT_DIR/ssh_enum" "$TARGET" 2>&1 | tee "$OUTPUT_DIR/nmap_enum.log"
    log_success "Enumeration complete"
}

# SSH brute force
ssh_brute_force() {
    log_info "Running SSH brute force scan..."
    nmap -p 22 \
        --script ssh-brute \
        --script-args ssh-brute.userdb=/tmp/users.txt,ssh-brute.passdb=/tmp/passwords.txt \
        -oA "$OUTPUT_DIR/ssh_brute" "$TARGET" 2>&1 | tee "$OUTPUT_DIR/nmap_brute.log"
    log_success "Brute force scan complete"
}

# SSH authentication methods
ssh_auth_methods() {
    log_info "Checking SSH authentication methods..."
    nmap -p 22 --script ssh-auth-methods \
        -oA "$OUTPUT_DIR/ssh_auth_methods" "$TARGET" 2>&1 | tee "$OUTPUT_DIR/nmap_auth.log"
    log_success "Auth methods check complete"
}

# Full SSH audit
ssh_full_audit() {
    log_info "Running full SSH security audit..."
    nmap -p 22 \
        --script "ssh2-enum-algos or sshv1 or ssh-hostkey or ssh-auth-methods or ssh-brute" \
        -oA "$OUTPUT_DIR/ssh_full_audit" "$TARGET" 2>&1 | tee "$OUTPUT_DIR/nmap_full.log"
    log_success "Full audit complete"
}

# Parse and summarize results
summarize_results() {
    log_info "Summarizing scan results..."

    echo ""
    echo "=========================================="
    echo "  SSH Scan Campaign Results"
    echo "=========================================="
    echo ""

    # Count open SSH ports
    if [ -f "$OUTPUT_DIR/ssh_ports.gnmap" ]; then
        local open_hosts=$(grep "22/open" "$OUTPUT_DIR/ssh_ports.gnmap" | wc -l)
        echo "Open SSH Ports: $open_hosts"
    fi

    # List discovered hosts
    if [ -f "$OUTPUT_DIR/ssh_ports.xml" ]; then
        echo ""
        echo "Discovered SSH Servers:"
        grep -A1 "22/open" "$OUTPUT_DIR/ssh_versions.gnmap" 2>/dev/null || echo "  (See XML output for details)"
    fi

    echo ""
    echo "Results saved to: $OUTPUT_DIR"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║   SSH NMAP SCAN CAMPAIGN                 ║"
    echo "║   For Educational/Testing Purposes Only  ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    log_info "Target network: $TARGET"
    log_info "Output directory: $OUTPUT_DIR"
    echo ""

    basic_ssh_scan
    ssh_version_scan
    ssh_enumeration
    ssh_auth_methods
    ssh_full_audit
    summarize_results
}

main "$@"
