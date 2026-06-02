#!/bin/bash
# QXPal Framework Uninstaller
# Reverts active optimizations, removes files, and stops the boot service.
set -euo pipefail

# Log colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Locations (supports non-privileged testing via QXPAL_INSTALL_PREFIX)
PREFIX="${QXPAL_INSTALL_PREFIX:-}"
INSTALL_BIN="$PREFIX/usr/local/bin/qxpal"
SHARE_DIR="$PREFIX/usr/local/share/qxpal"
SYSTEMD_SERVICE="$PREFIX/etc/systemd/system/qxpal.service"

check_root() {
    if [ -n "$PREFIX" ]; then
        log_info "Running in mock test prefix environment: Skip root check."
        return 0
    fi
    if [ "$EUID" -ne 0 ]; then
        log_error "This uninstallation script must be run as root (sudo)."
        exit 1
    fi
}

remove_files() {
    log_info "Removing QXPal files..."
    
    # 1. Run restore script to clean up configs
    if [ -f "$SHARE_DIR/scripts/restore.sh" ]; then
        log_info "Running restore logic before cleanup..."
        # If in test mode, we might want to tell it where to restore or stub
        # For simplicity, we run restore but wrap in standard execution
        bash "$SHARE_DIR/scripts/restore.sh" || log_warn "Failed to execute restore script."
    fi
    
    # 2. Disable and delete systemd service
    if [ -f "$SYSTEMD_SERVICE" ]; then
        log_info "Disabling systemd service..."
        if [ -z "$PREFIX" ]; then
            systemctl disable qxpal.service 2>/dev/null || true
            systemctl stop qxpal.service 2>/dev/null || true
            systemctl daemon-reload
        fi
        rm -f "$SYSTEMD_SERVICE"
    fi
    
    # 3. Clean binary and share folders
    rm -f "$INSTALL_BIN"
    rm -rf "$SHARE_DIR"
    
    log_success "Files successfully removed."
}

main() {
    check_root
    remove_files
    log_success "QXPal uninstallation completed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
