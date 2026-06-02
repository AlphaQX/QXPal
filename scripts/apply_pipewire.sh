#!/bin/bash
# QXPal - PipeWire Stack Applier
# Deploys latency and suspend-on-idle disable rules for PipeWire and WirePlumber.
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

# Target configuration directories
SYS_PW_DIR="/etc/pipewire"
SYS_WP_DIR="/etc/wireplumber"

USER_PW_DIR="$HOME/.config/pipewire"
USER_WP_DIR="$HOME/.config/wireplumber"

apply_pipewire_configs() {
    local target_pw_dir="$1"
    log_info "Deploying PipeWire config to $target_pw_dir/pipewire.conf.d/qxpal.conf"
    
    mkdir -p "$target_pw_dir/pipewire.conf.d"
    cp "$BASE_DIR/configs/pipewire/qxpal-pw.conf" "$target_pw_dir/pipewire.conf.d/qxpal.conf"
}

apply_wireplumber_configs() {
    local target_wp_dir="$1"
    log_info "Deploying WirePlumber settings to $target_wp_dir"
    
    # 1. WirePlumber 0.4 (Lua based - e.g. Ubuntu 24.04)
    mkdir -p "$target_wp_dir/main.lua.d"
    cat << 'EOF' > "$target_wp_dir/main.lua.d/50-qxpal.lua"
-- QXPal override to disable node suspension (pops/clicks prevention)
local qxpal_rule = {
  matches = {
    {
      { "node.name", "matches", "alsa_output.*" },
    },
  },
  apply_properties = {
    ["session.suspend-on-idle"] = false,
  },
}
if alsa_monitor and alsa_monitor.rules then
  table.insert(alsa_monitor.rules, qxpal_rule)
end
EOF

    # 2. WirePlumber 0.5+ (JSON/SPA-config based - e.g. Fedora 42+)
    mkdir -p "$target_wp_dir/wireplumber.conf.d"
    cat << 'EOF' > "$target_wp_dir/wireplumber.conf.d/qxpal.conf"
# QXPal override to disable node suspension
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      update-props = {
        session.suspend-on-idle = false
      }
    }
  }
]
EOF
}

restart_audio_services() {
    # If root, restarting systemd service isn't direct for user-session pipewire.
    # We should restart using systemctl --user if not root, or print user instructions.
    if [ "$EUID" -eq 0 ]; then
        log_info "Audio Stack configs deployed at system level. Reloading system-wide pipewire..."
        systemctl restart pipewire.service 2>/dev/null || true
    else
        log_info "Restarting user-space PipeWire & WirePlumber services..."
        systemctl --user daemon-reload || true
        systemctl --user restart pipewire.service wireplumber.service 2>/dev/null || {
            log_warn "Could not restart services automatically. Please run: systemctl --user restart pipewire wireplumber"
        }
    fi
}

main() {
    # Determine target directories depending on privileges
    if [ "$EUID" -eq 0 ]; then
        log_info "Running in System-Wide Mode (Root)..."
        apply_pipewire_configs "$SYS_PW_DIR"
        apply_wireplumber_configs "$SYS_WP_DIR"
    else
        log_info "Running in User Mode (Non-Root)..."
        apply_pipewire_configs "$USER_PW_DIR"
        apply_wireplumber_configs "$USER_WP_DIR"
    fi
    
    restart_audio_services
    log_success "PipeWire and WirePlumber optimizations applied successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
