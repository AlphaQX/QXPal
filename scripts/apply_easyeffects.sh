#!/bin/bash
# QXPal - EasyEffects DSP Preset Applier
# Deploys optimized speaker DSP profiles and starts EasyEffects service.
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

# Detect if EasyEffects is installed natively or via Flatpak
IS_FLATPAK=0
EE_PRESET_DIR="$HOME/.config/easyeffects/output"
EE_AUTOLOAD_FILE="$HOME/.config/easyeffects/autoload.json"

if ! command -v easyeffects >/dev/null 2>&1; then
    if command -v flatpak >/dev/null 2>&1 && flatpak list --columns=application | grep -q "com.github.wwmm.easyeffects"; then
        log_info "EasyEffects Flatpak installation detected."
        IS_FLATPAK=1
        EE_PRESET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/output"
        EE_AUTOLOAD_FILE="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects/autoload.json"
    fi
fi

EE_PRESET_NAME="qxpal.json"
EE_SRC_PRESET="$BASE_DIR/configs/easyeffects/qxpal.json"

deploy_preset() {
    log_info "Deploying EasyEffects EQ preset..."
    mkdir -p "$EE_PRESET_DIR"
    
    if [ -f "$EE_SRC_PRESET" ]; then
        cp "$EE_SRC_PRESET" "$EE_PRESET_DIR/$EE_PRESET_NAME"
        log_success "DSP preset copied to $EE_PRESET_DIR/$EE_PRESET_NAME"
    else
        log_error "Source DSP preset not found at $EE_SRC_PRESET"
        exit 1
    fi
}

configure_autoload() {
    log_info "Configuring EasyEffects autoload rules..."
    mkdir -p "$(dirname "$EE_AUTOLOAD_FILE")"
    
    cat << 'EOF' > "$EE_AUTOLOAD_FILE"
{
  "output": {
    "preset": "qxpal"
  }
}
EOF
    log_success "Configured autoload file: $EE_AUTOLOAD_FILE"
}

restart_easyeffects() {
    log_info "Starting/restarting EasyEffects daemon..."
    
    if [ "$IS_FLATPAK" -eq 1 ]; then
        # Quit Flatpak instance
        flatpak run com.github.wwmm.easyeffects -q 2>/dev/null || true
        sleep 0.5
        flatpak run com.github.wwmm.easyeffects --gapplication-service >/dev/null 2>&1 &
        log_success "EasyEffects Flatpak background service launched."
    else
        # Quit native instance
        easyeffects -q 2>/dev/null || true
        sleep 0.5
        if command -v easyeffects >/dev/null 2>&1; then
            easyeffects --gapplication-service >/dev/null 2>&1 &
            log_success "EasyEffects background service launched."
        else
            log_warn "easyeffects command not found. Please install it."
        fi
    fi
}

main() {
    if [ "$EUID" -eq 0 ]; then
        log_warn "EasyEffects is a user-session daemon and cannot be run as root."
        log_warn "Skipping user-specific EasyEffects configuration during root execution."
        exit 0
    fi
    
    # Check if we have either native or flatpak installed
    if ! command -v easyeffects >/dev/null 2>&1 && [ "$IS_FLATPAK" -eq 0 ]; then
        log_warn "EasyEffects is not installed (natively or via Flatpak) on this system. DSP filters will not be active."
        exit 0
    fi
    
    deploy_preset
    configure_autoload
    restart_easyeffects
    
    log_success "EasyEffects tuning successfully completed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
