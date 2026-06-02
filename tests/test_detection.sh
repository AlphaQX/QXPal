#!/bin/bash
# QXPal Unit Test - Detection Engine
# Mocks DMI tables, procfs cards, HDA codecs, and verifies scanner parsing logic.
set -euo pipefail

# Log colors
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'

log_info() { echo -e "${BLUE}[TEST INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[TEST PASS]${NC} $*"; }
log_error() { echo -e "${RED}[TEST FAIL]${NC} $*"; }

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$TEST_DIR/.." && pwd)"
MOCK_ROOT="$BASE_DIR/test_root"

setup_mock_sysfs() {
    log_info "Setting up mock sysfs and procfs..."
    rm -rf "$MOCK_ROOT"
    
    # Create target folders
    mkdir -p "$MOCK_ROOT/sys/class/dmi/id"
    mkdir -p "$MOCK_ROOT/proc/asound/card0"
    
    # Write mock DMI variables
    echo "Lenovo" > "$MOCK_ROOT/sys/class/dmi/id/sys_vendor"
    echo "ThinkPad T14 Gen 2" > "$MOCK_ROOT/sys/class/dmi/id/product_name"
    
    # Write mock ALSA cards
    cat << 'EOF' > "$MOCK_ROOT/proc/asound/cards"
 0 [PCH            ]: HDA-Intel - HDA Intel PCH
                      HDA Intel PCH at 0xfb320000 irq 145
 1 [HDMI           ]: HDA-Intel - HDA Intel HDMI
                      HDA Intel HDMI at 0xfb324000 irq 146
EOF

    # Write mock Codec details
    cat << 'EOF' > "$MOCK_ROOT/proc/asound/card0/codec#0"
Codec: Realtek ALC287
Address: 0
Function Id: 0x1
Vendor Id: 0x10ec0287
EOF
}

cleanup_mock_sysfs() {
    log_info "Cleaning up mock environments..."
    rm -rf "$MOCK_ROOT"
}

run_tests() {
    # Export mock environment paths
    export QXPAL_TEST_SYS_PREFIX="$MOCK_ROOT"
    export QXPAL_TEST_PROC_PREFIX="$MOCK_ROOT"
    
    log_info "1. Testing detect_hardware.sh..."
    local hw_out
    hw_out=$("$BASE_DIR/scripts/detect_hardware.sh" 2>/dev/null)
    eval "$hw_out"
    
    if [ "${QXPAL_DETECTED_VENDOR}" != "lenovo" ]; then
        log_error "Expected vendor 'lenovo', got '${QXPAL_DETECTED_VENDOR}'"
        exit 1
    fi
    if [ "${QXPAL_DETECTED_MODEL}" != "thinkpad t14 gen 2" ]; then
        log_error "Expected model 'thinkpad t14 gen 2', got '${QXPAL_DETECTED_MODEL}'"
        exit 1
    fi
    if [ "${QXPAL_DETECTED_CARD_INDEX}" -ne 0 ]; then
        log_error "Expected primary card index 0, got '${QXPAL_DETECTED_CARD_INDEX}'"
        exit 1
    fi
    log_success "detect_hardware.sh parsed correctly."
    
    log_info "2. Testing detect_codec.sh..."
    local codec_out
    codec_out=$("$BASE_DIR/scripts/detect_codec.sh" 2>/dev/null)
    eval "$codec_out"
    
    if [ "${QXPAL_DETECTED_CODEC}" != "Realtek ALC287" ]; then
        log_error "Expected codec 'Realtek ALC287', got '${QXPAL_DETECTED_CODEC}'"
        exit 1
    fi
    log_success "detect_codec.sh parsed correctly."
    
    log_info "3. Testing detect_laptop.sh (Profile Mapping)..."
    local map_out
    map_out=$("$BASE_DIR/scripts/detect_laptop.sh" 2>/dev/null)
    eval "$map_out"
    
    if [ "${QXPAL_MAPPED_PROFILE}" != "lenovo" ]; then
        log_error "Expected profile 'lenovo', got '${QXPAL_MAPPED_PROFILE}'"
        exit 1
    fi
    log_success "detect_laptop.sh resolved 'lenovo' profile correctly."
}

main() {
    setup_mock_sysfs
    
    local test_result=0
    run_tests || test_result=$?
    
    cleanup_mock_sysfs
    
    if [ "$test_result" -eq 0 ]; then
        log_success "All detection tests passed successfully."
    else
        log_error "Detection tests failed."
        exit "$test_result"
    fi
}

main
