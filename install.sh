#!/bin/bash
# QXPal Framework Installer
# Deploys QXPal binary, configs, profiles, systemd service, and sets execution flags.
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
SYSTEMD_DIR="$PREFIX/etc/systemd/system"

check_root() {
    # Skip root validation if testing in non-privileged local target
    if [ -n "$PREFIX" ]; then
        log_info "Running in mock test prefix environment: Skip root check."
        return 0
    fi
    if [ "$EUID" -ne 0 ]; then
        log_error "This installation script must be run as root (sudo)."
        exit 1
    fi
}

check_dependencies() {
    log_info "Verifying dependencies..."
    local missing=0
    
    # Check commands
    if ! command -v amixer >/dev/null 2>&1; then
        log_warn "Dependency 'alsa-utils' (amixer) is missing."
        missing=1
    fi
    if ! command -v pipewire >/dev/null 2>&1; then
        log_warn "Dependency 'pipewire' is missing."
        missing=1
    fi
    if ! command -v wireplumber >/dev/null 2>&1; then
        log_warn "Dependency 'wireplumber' is missing."
        missing=1
    fi
    if [ "$missing" -eq 1 ]; then
        if [ -n "$PREFIX" ]; then
            log_warn "Missing dependencies. Continuing anyway due to mock test environment."
        else
            log_error "Missing key audio stack dependencies. Please install pipewire, wireplumber, and alsa-utils first."
            exit 1
        fi
    else
        log_success "All critical dependencies found."
    fi
}

deploy_files() {
    log_info "Deploying QXPal files to system directories..."
    
    # Create target directories
    mkdir -p "$SHARE_DIR"
    mkdir -p "$(dirname "$INSTALL_BIN")"
    mkdir -p "$SYSTEMD_DIR"
    
    # Copy assets
    cp -r configs profiles scripts "$SHARE_DIR/"
    
    # Ensure all scripts are executable
    chmod +x "$SHARE_DIR/scripts"/*.sh
    
    # Install main binary wrapper
    cp qxpal "$INSTALL_BIN"
    chmod +x "$INSTALL_BIN"
    
    # Install systemd service
    if [ -f systemd/qxpal.service ]; then
        cp systemd/qxpal.service "$SYSTEMD_DIR/qxpal.service"
        if [ -z "$PREFIX" ]; then
            systemctl daemon-reload
            systemctl enable qxpal.service || log_warn "Could not enable systemd service."
            log_success "Systemd service installed and enabled."
        else
            log_info "Mock Target: skipped systemctl daemon-reload."
            log_success "Systemd service file placed at $SYSTEMD_DIR/qxpal.service."
        fi
    fi
    
    log_success "Files successfully deployed."
}

main() {
    check_root
    check_dependencies
    deploy_files
    log_success "QXPal installation completed. Run 'qxpal diagnose' to verify."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
