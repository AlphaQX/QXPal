#!/bin/bash
# QXPal - ALSA Tuning Applier
# Adjusts mixer settings, unmutes amplifiers, and disables kernel power saving.
set -euo pipefail

# Log colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Verify root permissions for kernel tweaks
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Root privileges are required to write ALSA configs and kernel overrides."
        log_error "Please run this script with sudo."
        exit 1
    fi
}

apply_runtime_power_save() {
    log_info "Disabling runtime hardware power saving (pop-prevention)..."
    
    # Intel HDA parameters
    if [ -f /sys/module/snd_hda_intel/parameters/power_save ]; then
        echo 0 > /sys/module/snd_hda_intel/parameters/power_save || log_warn "Failed to set power_save"
    fi
    if [ -f /sys/module/snd_hda_intel/parameters/power_save_controller ]; then
        echo N > /sys/module/snd_hda_intel/parameters/power_save_controller || log_warn "Failed to set power_save_controller"
    fi
    
    # AC97/Other controllers if applicable
    if [ -f /sys/module/snd_ac97_codec/parameters/power_save ]; then
        echo 0 > /sys/module/snd_ac97_codec/parameters/power_save || true
    fi
}

apply_persistent_power_save() {
    log_info "Installing persistent ALSA power save options under modprobe.d..."
    local src_conf="$BASE_DIR/configs/alsa/qxpal-alsa.conf"
    local dest_conf="/etc/modprobe.d/qxpal.conf"
    
    if [ -f "$src_conf" ]; then
        cp "$src_conf" "$dest_conf"
        log_success "Saved ALSA configuration to $dest_conf"
    else
        log_error "Source ALSA configuration $src_conf not found!"
        exit 1
    fi
}

main() {
    check_root
    
    # 1. Map profile
    local map_out
    map_out=$("$SCRIPT_DIR/detect_laptop.sh")
    eval "$map_out"
    
    local hw_out
    hw_out=$("$SCRIPT_DIR/detect_hardware.sh")
    eval "$hw_out"
    
    local card_idx="${QXPAL_DETECTED_CARD_INDEX:- -1}"
    if [ "$card_idx" = "-1" ]; then
        log_error "Could not find a valid primary audio card."
        exit 1
    fi
    
    log_info "Tuning primary card index: $card_idx"
    
    # 2. Source the mapped profile
    if [ -n "${QXPAL_PROFILE_PATH:-}" ] && [ -f "$QXPAL_PROFILE_PATH" ]; then
        log_info "Loading profile configuration: $QXPAL_PROFILE_PATH"
        # Source profile functions and vars
        # shellcheck source=/dev/null
        source "$QXPAL_PROFILE_PATH"
    else
        log_warn "Profile path invalid or empty. Loading generic."
        # shellcheck source=../profiles/generic/profile.conf
        source "$BASE_DIR/profiles/generic/profile.conf"
    fi
    
    # 3. Apply power saving tweaks
    apply_runtime_power_save
    apply_persistent_power_save
    
    # 4. Invoke profile-specific ALSA rules
    if declare -f apply_custom_alsa > /dev/null; then
        apply_custom_alsa "$card_idx"
        log_success "Custom ALSA mixer settings applied."
    else
        log_warn "No custom ALSA mixer configuration defined in profile."
    fi
    
    log_success "ALSA optimization completed successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
