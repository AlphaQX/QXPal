#!/bin/bash
# QXPal - Audio Codec Detection Script
# Locates and parses HDA/ALSA codec logs from procfs to determine specific audio chips.
set -euo pipefail

# Log colors
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[0;34m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Mock prefixes for testing
SYS_PREFIX="${QXPAL_TEST_SYS_PREFIX:-}"
PROC_PREFIX="${QXPAL_TEST_PROC_PREFIX:-}"

detect_codec() {
    local codecs=()
    
    # Check procfs codec files (standard HDA chips)
    if ls "${PROC_PREFIX}"/proc/asound/card*/codec#* >/dev/null 2>&1; then
        for codec_file in "${PROC_PREFIX}"/proc/asound/card*/codec#*; do
            if [ -f "$codec_file" ]; then
                local name
                name=$(grep -i "^Codec:" "$codec_file" | cut -d':' -f2 | xargs || true)
                if [ -n "$name" ]; then
                    codecs+=("$name")
                fi
            fi
        done
    fi
    
    # If no HDA codec files, check for ASoC/SOF platforms (e.g. AMD ACP, Intel SOF)
    if [ ${#codecs[@]} -eq 0 ]; then
        if [ -d "${SYS_PREFIX}/sys/class/sound" ]; then
            # Search in sysfs for driver or component names
            local sys_codec
            sys_codec=$(find "${SYS_PREFIX}/sys/class/sound" -name "device" -exec cat {}/uevent 2>/dev/null | grep -i "DRIVER=" | cut -d'=' -f2 | sort -u | xargs || true)
            if [ -n "$sys_codec" ]; then
                codecs+=("$sys_codec")
            fi
        fi
    fi
    
    # Final fallback: query from aplay
    if [ ${#codecs[@]} -eq 0 ]; then
        local aplay_out
        aplay_out=$(aplay -l 2>/dev/null | grep -i "card" | head -n 1 || true)
        if [ -n "$aplay_out" ]; then
            codecs+=("Generic ALSA Device ($aplay_out)")
        else
            codecs+=("Unknown Codec")
        fi
    fi
    
    # Print out unique found codecs
    printf "%s\n" "${codecs[@]}" | sort -u | head -n 1
}

main() {
    log_info "Detecting audio codec..."
    local codec
    codec=$(detect_codec)
    echo "QXPAL_DETECTED_CODEC=\"$codec\""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
