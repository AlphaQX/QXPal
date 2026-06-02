#!/bin/bash
# QXPal - Restore Engine
# Reverts system config changes to their exact pre-installation states.
set -euo pipefail

# Log colors
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SYS_BACKUP_DIR="/var/lib/qxpal/backups"
USER_BACKUP_DIR="$HOME/.config/qxpal/backups"

restore_file() {
    local target="$1"
    local backup_src="$2"
    
    if [ -f "$backup_src" ]; then
        log_info "Restoring file: $backup_src -> $target"
        # ensure parent dir exists
        mkdir -p "$(dirname "$target")"
        cp "$backup_src" "$target"
    else
        if [ -f "$target" ]; then
            log_info "Removing file created by QXPal: $target"
            rm -f "$target"
        fi
    fi
}

restore_system() {
    log_info "Reverting system-wide optimizations..."
    if [ ! -d "$SYS_BACKUP_DIR" ]; then
        log_error "No system backup found at $SYS_BACKUP_DIR. Cannot automate rollback."
        exit 1
    fi
    
    restore_file "/etc/modprobe.d/qxpal.conf" "$SYS_BACKUP_DIR/qxpal.conf"
    restore_file "/etc/pipewire/pipewire.conf.d/qxpal.conf" "$SYS_BACKUP_DIR/qxpal.conf"
    restore_file "/etc/wireplumber/main.lua.d/50-qxpal.lua" "$SYS_BACKUP_DIR/50-qxpal.lua"
    restore_file "/etc/wireplumber/wireplumber.conf.d/qxpal.conf" "$SYS_BACKUP_DIR/qxpal.conf"
    
    # Reload kernel audio modules if desired, or inform user reboot is recommended
    log_info "Tuning removal completed. Please reboot or reload ALSA modules (e.g. sudo alsa force-reload)"
    
    # Restart services
    systemctl restart pipewire.service 2>/dev/null || true
    
    # Clean up backups
    rm -rf "$SYS_BACKUP_DIR"
    log_success "System restoration finished. Backups cleared."
}

restore_user() {
    log_info "Reverting user-space optimizations..."
    if [ ! -d "$USER_BACKUP_DIR" ]; then
        log_error "No user-level backup found at $USER_BACKUP_DIR. Cannot automate rollback."
        exit 1
    fi
    
    restore_file "$HOME/.config/easyeffects/output/qxpal.json" "$USER_BACKUP_DIR/qxpal.json"
    restore_file "$HOME/.config/easyeffects/autoload.json" "$USER_BACKUP_DIR/autoload.json"
    restore_file "$HOME/.config/pipewire/pipewire.conf.d/qxpal.conf" "$USER_BACKUP_DIR/qxpal.conf"
    restore_file "$HOME/.config/wireplumber/main.lua.d/50-qxpal.lua" "$USER_BACKUP_DIR/50-qxpal.lua"
    restore_file "$HOME/.config/wireplumber/wireplumber.conf.d/qxpal.conf" "$USER_BACKUP_DIR/qxpal.conf"
    
    # Stop/Restart EasyEffects to load original preset
    easyeffects -q || true
    sleep 0.5
    if command -v easyeffects >/dev/null 2>&1; then
        easyeffects --gapplication-service >/dev/null 2>&1 &
        log_info "EasyEffects restarted."
    fi
    
    # Clean up backups
    rm -rf "$USER_BACKUP_DIR"
    log_success "User-space restoration finished. Backups cleared."
}

main() {
    if [ "$EUID" -eq 0 ]; then
        restore_system
    else
        restore_user
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
