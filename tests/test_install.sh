#!/bin/bash
# QXPal Unit Test - Installer & Uninstaller
# Simulates full deployment/reversion inside a local sandbox to ensure no file drift.
set -euo pipefail

# Log colors
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'

log_info() { echo -e "${BLUE}[TEST INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[TEST PASS]${NC} $*"; }
log_error() { echo -e "${RED}[TEST FAIL]${NC} $*"; }

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$TEST_DIR/.." && pwd)"
MOCK_ROOT="$BASE_DIR/test_root"

main() {
    log_info "Initiating install sandboxed unit tests..."
    
    # 1. Clean and setup target prefix
    rm -rf "$MOCK_ROOT"
    mkdir -p "$MOCK_ROOT"
    
    # 2. Run install.sh with prefix
    export QXPAL_INSTALL_PREFIX="$MOCK_ROOT"
    log_info "Running install.sh with mock prefix $QXPAL_INSTALL_PREFIX..."
    bash "$BASE_DIR/install.sh"
    
    # 3. Assert installed files exist
    log_info "Asserting deployed components..."
    local files=(
        "usr/local/bin/qxpal"
        "usr/local/share/qxpal/configs/pipewire/qxpal-pw.conf"
        "usr/local/share/qxpal/configs/easyeffects/qxpal.json"
        "usr/local/share/qxpal/configs/alsa/qxpal-alsa.conf"
        "usr/local/share/qxpal/profiles/generic/profile.conf"
        "usr/local/share/qxpal/profiles/lenovo/profile.conf"
        "usr/local/share/qxpal/profiles/dell/profile.conf"
        "usr/local/share/qxpal/profiles/hp/profile.conf"
        "usr/local/share/qxpal/profiles/asus/profile.conf"
        "usr/local/share/qxpal/profiles/acer/profile.conf"
        "usr/local/share/qxpal/profiles/msi/profile.conf"
        "usr/local/share/qxpal/scripts/detect_hardware.sh"
        "usr/local/share/qxpal/scripts/detect_codec.sh"
        "usr/local/share/qxpal/scripts/detect_laptop.sh"
        "usr/local/share/qxpal/scripts/apply_alsa.sh"
        "usr/local/share/qxpal/scripts/apply_pipewire.sh"
        "usr/local/share/qxpal/scripts/apply_easyeffects.sh"
        "usr/local/share/qxpal/scripts/backup.sh"
        "usr/local/share/qxpal/scripts/restore.sh"
        "usr/local/share/qxpal/scripts/diagnostics.sh"
        "usr/local/share/qxpal/scripts/benchmark.sh"
        "etc/systemd/system/qxpal.service"
    )
    
    for f in "${files[@]}"; do
        if [ ! -f "$MOCK_ROOT/$f" ]; then
            log_error "Asset missing from destination: $f"
            exit 1
        fi
    done
    
    # Assert execution permissions on binary
    if [ ! -x "$MOCK_ROOT/usr/local/bin/qxpal" ]; then
        log_error "Target binary is not executable."
        exit 1
    fi
    
    log_success "All assets deployed with proper layout and permissions."
    
    # Create a mock backup to prevent restore.sh warnings during uninstall
    local mock_backup_dir="$HOME/.config/qxpal/backups"
    mkdir -p "$mock_backup_dir/native"
    mkdir -p "$mock_backup_dir/flatpak"
    echo "test" > "$mock_backup_dir/pristine_backup.info"
    
    # 4. Run uninstall.sh
    log_info "Running uninstall.sh to revert changes..."
    bash "$BASE_DIR/uninstall.sh"
    
    # 5. Assert files are removed
    log_info "Checking post-uninstall cleanup status..."
    if [ -f "$MOCK_ROOT/usr/local/bin/qxpal" ]; then
        log_error "Target binary not cleaned up: usr/local/bin/qxpal"
        exit 1
    fi
    if [ -d "$MOCK_ROOT/usr/local/share/qxpal" ]; then
        log_error "Target share folder not cleaned up: usr/local/share/qxpal"
        exit 1
    fi
    if [ -f "$MOCK_ROOT/etc/systemd/system/qxpal.service" ]; then
        log_error "Target service file not cleaned up: etc/systemd/system/qxpal.service"
        exit 1
    fi
    
    log_success "All assets successfully cleaned up during uninstall."
    
    # Clean up mock directories
    rm -rf "$MOCK_ROOT"
    log_success "Sandboxed installation tests passed successfully."
}

main
