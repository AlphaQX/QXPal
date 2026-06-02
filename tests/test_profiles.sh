#!/bin/bash
# QXPal Unit Test - Profiles Validator
# Validates profile syntax, imports required variables, and checks mixer hooks.
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

# Stub log_info to avoid noise during sourcing
log_info_stub() { :; }

validate_profile() {
    local profile_path="$1"
    log_info "Validating profile configuration: $profile_path"
    
    # Run verification in a subshell to avoid dirtying environment
    (
        # Set up a mock log_info inside the subshell to intercept output
        log_info() { log_info_stub "$@"; }
        
        # Source the profile
        # shellcheck source=/dev/null
        source "$profile_path"
        
        # 1. Check required variables
        if [ -z "${PROFILE_NAME:-}" ]; then
            log_error "PROFILE_NAME is empty or undefined in $profile_path"
            exit 1
        fi
        
        if [ -z "${ALSA_POWER_SAVE:-}" ]; then
            log_error "ALSA_POWER_SAVE is undefined in $profile_path"
            exit 1
        fi
        
        if [ -z "${EASYEFFECTS_PRESET:-}" ]; then
            log_error "EASYEFFECTS_PRESET is undefined in $profile_path"
            exit 1
        fi
        
        # 2. Check mixer hook function (if declared, must be a function)
        if declare -f apply_custom_alsa >/dev/null; then
            log_info "  - Custom ALSA mixer adjustment function detected (OK)."
        fi
    )
}

main() {
    local exit_code=0
    
    # Loop over all profile configs
    for conf_file in "$BASE_DIR"/profiles/*/profile.conf; do
        if [ -f "$conf_file" ]; then
            validate_profile "$conf_file" || exit_code=$?
        fi
    done
    
    if [ "$exit_code" -eq 0 ]; then
        log_success "All vendor profiles validated successfully (syntax & structure OK)."
    else
        log_error "Profile validations failed."
        exit "$exit_code"
    fi
}

main
