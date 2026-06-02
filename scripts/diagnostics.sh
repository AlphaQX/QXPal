#!/bin/bash
# QXPal - Diagnostics Engine
# Scans and prints a detailed, colored report of audio components, state, and active profiles.
set -euo pipefail

# Log colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

log_header() {
    echo -e "${CYAN}┌────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${WHITE}                      QXPal System Diagnostics Report                       ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────────────────────┘${NC}"
}

print_row() {
    local label="$1"
    local value="$2"
    printf "${CYAN}│${NC} %-30s : %-40s ${CYAN}│${NC}\n" "$label" "$value"
}

print_divider() {
    echo -e "${CYAN}├────────────────────────────────────────────────────────────────────────────┤${NC}"
}

print_footer() {
    echo -e "${CYAN}└────────────────────────────────────────────────────────────────────────────┘${NC}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
    log_header
    
    # 1. Gather hardware detection
    local hw_out
    hw_out=$("$SCRIPT_DIR/detect_hardware.sh" 2>/dev/null)
    eval "$hw_out"
    
    local codec_out
    codec_out=$("$SCRIPT_DIR/detect_codec.sh" 2>/dev/null)
    eval "$codec_out"
    
    # 2. Gather profile mapping
    local map_out
    map_out=$("$SCRIPT_DIR/detect_laptop.sh" 2>/dev/null)
    eval "$map_out"
    
    # System Details
    print_row "DMI Laptop Vendor" "${QXPAL_DETECTED_VENDOR:-Unknown}"
    print_row "DMI Laptop Model" "${QXPAL_DETECTED_MODEL:-Unknown}"
    print_row "Detected Audio Codec" "${QXPAL_DETECTED_CODEC:-Unknown}"
    print_row "Sound Open Firmware (SOF)" "$([ "${QXPAL_DETECTED_SOF:-false}" = "true" ] && echo -e "${GREEN}Loaded${NC}" || echo -e "${YELLOW}Not Loaded / Standard Legacy${NC}")"
    
    print_divider
    
    # Audio Services Status
    local pw_status
    local wp_status
    local ee_status
    
    pw_status=$([ "${QXPAL_DETECTED_PIPEWIRE:-false}" = "true" ] && echo -e "${GREEN}Running (OK)${NC}" || echo -e "${RED}Not Running${NC}")
    wp_status=$([ "${QXPAL_DETECTED_WIREPLUMBER:-false}" = "true" ] && echo -e "${GREEN}Running (OK)${NC}" || echo -e "${RED}Not Running${NC}")
    ee_status=$([ "${QXPAL_DETECTED_EASYEFFECTS:-false}" = "true" ] && echo -e "${GREEN}Daemon Active${NC}" || echo -e "${YELLOW}Inactive / Standby${NC}")
    
    print_row "PipeWire Daemon" "$pw_status"
    print_row "WirePlumber Session Mgr" "$wp_status"
    print_row "EasyEffects DSP Engine" "$ee_status"
    
    print_divider
    
    # Profile information
    print_row "Mapped Profile" "${QXPAL_MAPPED_PROFILE:-generic}"
    print_row "Profile Config Path" "${QXPAL_PROFILE_PATH:-N/A}"
    
    print_divider
    
    # ALSA Card Mixer Info
    local card_idx="${QXPAL_DETECTED_CARD_INDEX:- -1}"
    if [ "$card_idx" = "-1" ]; then
        print_row "Primary ALSA Card Index" "${RED}No soundcard detected${NC}"
    else
        print_row "Primary ALSA Card Index" "card $card_idx"
        
        # Check volume/mute status of Master if available
        local master_vol="Unknown"
        local master_mute="Unknown"
        if command -v amixer >/dev/null 2>&1; then
            local amixer_master
            amixer_master=$(amixer -c "$card_idx" sget "Master" 2>/dev/null || true)
            if [ -n "$amixer_master" ]; then
                # parse volume percent e.g. [80%]
                master_vol=$(echo "$amixer_master" | grep -o -E "\[[0-9]+%\]" | head -n 1 | tr -d '[]' || echo "N/A")
                # parse mute status e.g. [on] or [off]
                master_mute=$(echo "$amixer_master" | grep -o -E "\[(on|off)\]" | head -n 1 | tr -d '[]' || echo "N/A")
                if [ "$master_mute" = "on" ]; then
                    master_mute="${GREEN}Unmuted${NC}"
                else
                    master_mute="${RED}Muted${NC}"
                fi
            fi
        fi
        print_row "Master Mixer Volume" "$master_vol ($master_mute)"
    fi
    
    # Verify optimization state files
    local is_opt="${RED}Not Applied${NC}"
    if [ -f "/etc/modprobe.d/qxpal.conf" ] || [ -f "$HOME/.config/easyeffects/output/qxpal.json" ]; then
        is_opt="${GREEN}Active / Optimized${NC}"
    fi
    
    print_row "QXPal Optimization Status" "$is_opt"
    
    print_footer
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
