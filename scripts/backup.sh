#!/bin/bash
# QXPal - Backup Engine
# Backs up existing audio stack files before optimization runs to preserve pristine state.
set -euo pipefail

# Log colors
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }

# Define paths
SYS_BACKUP_DIR="/var/lib/qxpal/backups"
USER_BACKUP_DIR="$HOME/.config/qxpal/backups"

backup_file() {
    local src="$1"
    local dest_dir="$2"
    
    if [ -f "$src" ]; then
        log_info "Backing up: $src -> $dest_dir/"
        mkdir -p "$dest_dir"
        cp "$src" "$dest_dir/"
    fi
}

backup_system_files() {
    log_info "Backing up system-wide configurations..."
    local backup_target="$SYS_BACKUP_DIR/system_$(date +%Y%m%d_%H%M%S)"
    
    # Check if a pristine backup already exists
    if [ -d "$SYS_BACKUP_DIR" ] && [ "$(ls -A "$SYS_BACKUP_DIR")" ]; then
        log_info "A system backup already exists under $SYS_BACKUP_DIR. Skipping to preserve initial system state."
        return 0
    fi
    
    mkdir -p "$backup_target"
    
    # Files we potentially override
    backup_file "/etc/modprobe.d/qxpal.conf" "$backup_target"
    backup_file "/etc/pipewire/pipewire.conf.d/qxpal.conf" "$backup_target"
    backup_file "/etc/wireplumber/main.lua.d/50-qxpal.lua" "$backup_target"
    backup_file "/etc/wireplumber/wireplumber.conf.d/qxpal.conf" "$backup_target"
    
    # Store backup timestamp/metadata
    echo "Backup created at $(date)" > "$SYS_BACKUP_DIR/pristine_backup.info"
    # Copy files into primary backup
    cp -r "$backup_target"/* "$SYS_BACKUP_DIR/" 2>/dev/null || true
    
    log_success "System backup successfully stored in $SYS_BACKUP_DIR"
}

backup_user_files() {
    log_info "Backing up user-session configurations..."
    local backup_target="$USER_BACKUP_DIR/user_$(date +%Y%m%d_%H%M%S)"
    
    if [ -d "$USER_BACKUP_DIR" ] && [ "$(ls -A "$USER_BACKUP_DIR")" ]; then
        log_info "A user-level backup already exists under $USER_BACKUP_DIR. Skipping to preserve initial configuration."
        return 0
    fi
    
    mkdir -p "$backup_target"
    
    # Files we potentially override
    backup_file "$HOME/.config/easyeffects/output/qxpal.json" "$backup_target"
    backup_file "$HOME/.config/easyeffects/autoload.json" "$backup_target"
    backup_file "$HOME/.config/pipewire/pipewire.conf.d/qxpal.conf" "$backup_target"
    backup_file "$HOME/.config/wireplumber/main.lua.d/50-qxpal.lua" "$backup_target"
    backup_file "$HOME/.config/wireplumber/wireplumber.conf.d/qxpal.conf" "$backup_target"
    
    # Copy files into primary backup
    cp -r "$backup_target"/* "$USER_BACKUP_DIR/" 2>/dev/null || true
    echo "Backup created at $(date)" > "$USER_BACKUP_DIR/pristine_backup.info"
    
    log_success "User-space backup successfully stored in $USER_BACKUP_DIR"
}

main() {
    if [ "$EUID" -eq 0 ]; then
        backup_system_files
    else
        backup_user_files
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
