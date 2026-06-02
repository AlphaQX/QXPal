# QXPal Architecture Documentation

This document explains the internal design, component structure, and workflow execution of the QXPal Audio Optimization Framework.

---

## Process Flow Diagram

When `qxpal optimize` is called, the following execution flow takes place:

```
[CLI Invocation] -> [backup.sh] -> [detect_laptop.sh] -> [Source profile.conf]
                                                                  |
         +------------------------+-------------------------------+
         |                        |                               |
         v                        v                               v
  [apply_alsa.sh]        [apply_pipewire.sh]           [apply_easyeffects.sh]
  - Sysfs power_save     - Buffer latency              - DSP presettings
  - Mixer controls       - Suspend-on-idle             - Daemon relaunch
```

---

## Core Components

### 1. The CLI Wrapper (`qxpal`)
The CLI frontend maps user arguments directly to the core scripts directory. It wraps execution states, performs standard root privilege validation checks where necessary (like `optimize`), and acts as a central coordinator.

### 2. Hardware Detection Engine (`scripts/detect_*`)
- **detect_hardware.sh**: Resolves vendor name, machine model, primary ALSA card index, and checks whether system-wide user-space components (PipeWire, WirePlumber, EasyEffects) are running.
- **detect_codec.sh**: Inspects HDA driver files inside the ALSA proc directory (`/proc/asound/card*/codec#*`) to pinpoint the specific hardware codec.
- **detect_laptop.sh**: Maps vendor names to vendor profiles.

### 3. Tuning Scripts (`scripts/apply_*`)
- **apply_alsa.sh**: Operates system-wide. Disables hardware-level power saving via standard modprobe profiles and `/sys/` parameters. It also queries the sourced vendor profile for custom `amixer` commands.
- **apply_pipewire.sh**: Deploys latency and click-prevention configuration files to either the system (`/etc/pipewire`, `/etc/wireplumber`) or user-level directories.
- **apply_easyeffects.sh**: Loads targeted JSON DSP presets (equalizer, limiter, filter) directly to the user session.

### 4. Safety & Rollback (`scripts/backup.sh` & `scripts/restore.sh`)
These scripts create an immutable backup directory (`/var/lib/qxpal/backups/` and `~/.config/qxpal/backups/`) during the very first run. This guarantees that original setups are not overwritten on subsequent runs and can be restored using the `restore` subcommand.
