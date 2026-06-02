#!/bin/bash
# QXPal - Audio Stack Latency & Performance Benchmark
# Checks RT scheduling, measures system clock drift/latency parameters, and reports ALSA underruns (xruns).
set -euo pipefail

# Log colors
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

log_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}                 QXPal Audio Latency Benchmark                  ${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

check_rt_scheduling() {
    log_info "1. Checking Real-Time (RT) scheduling capabilities..."
    
    # Check if RTKit daemon is active (highly recommended for PipeWire RT scheduling)
    if pgrep rtkit-daemon >/dev/null; then
        log_success "  - RTKit daemon is running. Real-time priorities are available."
    else
        log_warn "  - RTKit daemon is not running. Audio service scheduling may experience delays."
    fi
    
    # Check limits.conf for rtprio limits
    local rtprio_limit
    rtprio_limit=$(ulimit -r)
    log_info "  - Current maximum real-time priority limit (ulimit -r): $rtprio_limit"
    if [ "$rtprio_limit" -eq 0 ]; then
        log_warn "  - RT priority limit is 0. Standard users cannot run threads with RT priority."
    else
        log_success "  - User-space RT limits are correctly enabled (limit > 0)."
    fi
}

check_pipewire_performance() {
    log_info "2. Querying PipeWire latency settings..."
    
    if command -v pw-metadata >/dev/null 2>&1; then
        local pw_settings
        pw_settings=$(pw-metadata -n settings 2>/dev/null || true)
        if [ -n "$pw_settings" ]; then
            local clock_rate
            clock_rate=$(echo "$pw_settings" | grep -o -E "clock.rate = [0-9]+" || echo "Unknown")
            local quantum
            quantum=$(echo "$pw_settings" | grep -o -E "clock.quantum = [0-9]+" || echo "Unknown")
            log_success "  - Active settings: $clock_rate, $quantum"
        else
            log_warn "  - Unable to pull metadata from active PipeWire instance."
        fi
    else
        log_warn "  - pw-metadata command not found. Skipping dynamic settings query."
    fi
}

count_xruns() {
    log_info "3. Analyzing system logs for ALSA underruns (xruns)..."
    local xrun_count=0
    
    if command -v journalctl >/dev/null 2>&1; then
        # Check system logs for pipewire xruns in the last 2 hours
        xrun_count=$(journalctl --since "2 hours ago" --unit user@*.service 2>/dev/null | grep -i -c "xrun" || true)
        if [ "$xrun_count" -gt 0 ]; then
            log_warn "  - Found $xrun_count audio underruns (xruns) in journalctl logs in the last 2 hours."
            log_warn "    This could mean system load is causing audio drops/pops."
        else
            log_success "  - No recent audio xruns detected in system logs."
        fi
    else
        # Fallback to checking dmesg
        xrun_count=$(dmesg 2>/dev/null | grep -i -c "xrun" || true)
        log_info "  - Checked dmesg: found $xrun_count references to xruns."
    fi
}

run_latency_sim() {
    log_info "4. Running 5-second simulated audio path latency benchmark..."
    # Simulate a small workloads or latency measurements
    local start_time
    start_time=$(date +%s%N)
    
    # Doing small loops to simulate calculations/timer resolution
    for i in {1..20}; do
        sleep 0.1
    done
    
    local end_time
    end_time=$(date +%s%N)
    local diff=$((end_time - start_time))
    local diff_ms=$((diff / 1000000))
    
    # We expected 20 * 100ms = 2000ms. The drift tells us the kernel scheduling precision.
    local drift=$((diff_ms - 2000))
    log_info "  - Simulated scheduling drift: ${drift}ms"
    if [ "$drift" -lt 50 ]; then
        log_success "  - System timer precision is excellent (drift < 50ms)."
    else
        log_warn "  - High scheduling drift detected (${drift}ms). High power-save state or CPU governor might cause latency spikes."
    fi
}

main() {
    log_header
    check_rt_scheduling
    check_pipewire_performance
    count_xruns
    run_latency_sim
    log_success "Benchmark complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
