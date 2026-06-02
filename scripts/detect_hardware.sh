#!/bin/bash
# QXPal - Hardware Detection Script
# Detects system vendor, product, audio cards, and active audio stack.
set -euo pipefail

# Output format: shell variables for easy sourcing by other scripts.
# Can also be run directly for diagnostic printout.

# Log colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Mock prefixes for testing
SYS_PREFIX="${QXPAL_TEST_SYS_PREFIX:-}"
PROC_PREFIX="${QXPAL_TEST_PROC_PREFIX:-}"

detect_vendor() {
    local vendor="Unknown"
    if [ -f "${SYS_PREFIX}/sys/class/dmi/id/sys_vendor" ]; then
        vendor=$(cat "${SYS_PREFIX}/sys/class/dmi/id/sys_vendor")
    elif [ -f "${SYS_PREFIX}/sys/devices/virtual/dmi/id/sys_vendor" ]; then
        vendor=$(cat "${SYS_PREFIX}/sys/devices/virtual/dmi/id/sys_vendor")
    fi
    # Normalize vendor string to lowercase
    echo "$vendor" | tr '[:upper:]' '[:lower:]' | xargs
}

detect_model() {
    local model="Unknown"
    if [ -f "${SYS_PREFIX}/sys/class/dmi/id/product_name" ]; then
        model=$(cat "${SYS_PREFIX}/sys/class/dmi/id/product_name")
    elif [ -f "${SYS_PREFIX}/sys/devices/virtual/dmi/id/product_name" ]; then
        model=$(cat "${SYS_PREFIX}/sys/devices/virtual/dmi/id/product_name")
    fi
    echo "$model" | tr '[:upper:]' '[:lower:]' | xargs
}

detect_sof() {
    # Check if Sound Open Firmware modules are loaded
    if lsmod | grep -q "^snd_sof"; then
        echo "true"
    else
        echo "false"
    fi
}

detect_pipewire() {
    # Check if PipeWire process is running for current active sessions
    if pgrep -x "pipewire" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

detect_wireplumber() {
    if pgrep -x "wireplumber" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

detect_easyeffects() {
    if pgrep -f "easyeffects" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

detect_primary_card() {
    # Parse /proc/asound/cards to find a primary Intel, AMD, or SOF audio card.
    # Exclude HDMI-only cards, digital outputs if possible, or USB mics.
    local primary_card_idx="-1"
    
    if [ -f "${PROC_PREFIX}/proc/asound/cards" ]; then
        # Find first card that is not HDMI-only or loopback
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*([0-9]+)[[:space:]]+\[.*\]:[[:space:]]+(.*)$ ]]; then
                local idx="${BASH_REMATCH[1]}"
                local desc="${BASH_REMATCH[2]}"
                
                # Check for analog devices, HDA, ACP, or generic codecs
                if [[ "$desc" =~ (HDA|HDA-Intel|Realtek|sof|AMD|PCH|Codec|Analog) ]] && [[ ! "$desc" =~ (HDMI|DisplayPort|Loopback) ]]; then
                    primary_card_idx="$idx"
                    break
                fi
            fi
        done < "${PROC_PREFIX}/proc/asound/cards"
        
        # Fallback to card 0 if no card matches the filter
        if [ "$primary_card_idx" = "-1" ] && [ -d "${PROC_PREFIX}/proc/asound/card0" ]; then
            primary_card_idx="0"
        fi
    fi
    echo "$primary_card_idx"
}

main() {
    log_info "Scanning system hardware..."
    
    local sys_vendor
    sys_vendor=$(detect_vendor)
    
    local sys_model
    sys_model=$(detect_model)
    
    local is_sof
    is_sof=$(detect_sof)
    
    local is_pw
    is_pw=$(detect_pipewire)
    
    local is_wp
    is_wp=$(detect_wireplumber)
    
    local is_ee
    is_ee=$(detect_easyeffects)
    
    local card_idx
    card_idx=$(detect_primary_card)
    
    # Export detection variables to stdout (for sourcing)
    echo "QXPAL_DETECTED_VENDOR=\"$sys_vendor\""
    echo "QXPAL_DETECTED_MODEL=\"$sys_model\""
    echo "QXPAL_DETECTED_SOF=$is_sof"
    echo "QXPAL_DETECTED_PIPEWIRE=$is_pw"
    echo "QXPAL_DETECTED_WIREPLUMBER=$is_wp"
    echo "QXPAL_DETECTED_EASYEFFECTS=$is_ee"
    echo "QXPAL_DETECTED_CARD_INDEX=$card_idx"
    
    log_success "Hardware scan complete."
}

# If the script is run directly, execute detection. If sourced, do nothing.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
