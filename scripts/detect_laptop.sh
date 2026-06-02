#!/bin/bash
# QXPal - Laptop Profile Mapping Script
# Aggregates hardware and codec details, matching them against vendor-specific profiles.
set -euo pipefail

# Log colors
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*" >&2; }

# Locate directory of current script to find profiles relative to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
    log_info "Running profile mapping engine..."
    
    # 1. Run detection scripts and capture their output
    local hw_info
    hw_info=$("$SCRIPT_DIR/detect_hardware.sh" 2>/dev/null)
    
    local codec_info
    codec_info=$("$SCRIPT_DIR/detect_codec.sh" 2>/dev/null)
    
    # Eval the outputs to load variables into current shell
    eval "$hw_info"
    eval "$codec_info"
    
    local vendor="${QXPAL_DETECTED_VENDOR:-unknown}"
    local model="${QXPAL_DETECTED_MODEL:-unknown}"
    local codec="${QXPAL_DETECTED_CODEC:-unknown}"
    
    # 2. Match vendor to profile directory name
    local mapped_profile="generic"
    
    if [[ "$vendor" =~ "lenovo" ]]; then
        mapped_profile="lenovo"
    elif [[ "$vendor" =~ "dell" ]]; then
        mapped_profile="dell"
    elif [[ "$vendor" =~ "hp" ]] || [[ "$vendor" =~ "hewlett-packard" ]]; then
        mapped_profile="hp"
    elif [[ "$vendor" =~ "asus" ]] || [[ "$vendor" =~ "asustek" ]]; then
        mapped_profile="asus"
    elif [[ "$vendor" =~ "acer" ]]; then
        mapped_profile="acer"
    elif [[ "$vendor" =~ "msi" ]] || [[ "$vendor" =~ "micro-star" ]]; then
        mapped_profile="msi"
    else
        mapped_profile="generic"
    fi
    
    local profile_path="$BASE_DIR/profiles/$mapped_profile/profile.conf"
    if [ ! -f "$profile_path" ]; then
        log_warn "Profile for '$mapped_profile' not found. Falling back to generic."
        mapped_profile="generic"
        profile_path="$BASE_DIR/profiles/generic/profile.conf"
    fi
    
    # Output variables for parent script ingestion
    echo "QXPAL_MAPPED_PROFILE=\"$mapped_profile\""
    echo "QXPAL_PROFILE_PATH=\"$profile_path\""
    
    log_success "Mapped system to profile: '$mapped_profile' ($profile_path)"
}

# Source helpers if they exist
if [ -f "$SCRIPT_DIR/detect_hardware.sh" ]; then
    # Ensure helper scripts have execution bits set
    chmod +x "$SCRIPT_DIR/detect_hardware.sh" "$SCRIPT_DIR/detect_codec.sh"
fi

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
