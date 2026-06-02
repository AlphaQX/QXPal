# QXPal

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)

QXPal (Quantum Speaker Companion) is an open-source Linux audio optimization framework. It aims to make laptop speakers sound as good as or better than their Windows OEM audio configuration by automatically detecting hardware, applying ALSA tuning, PipeWire configuration, EasyEffects DSP presets, and laptop-specific sound profiles.

---

## Features

- **Automated Hardware Detection**: Scans DMI tables, PCI devices, and ALSA codecs to identify laptop vendor, model, and DSP/codec chips (Realtek, Cirrus Logic, Texas Instruments, etc.).
- **ALSA Mixer Tuning**: Unmutes hidden amplifiers, optimizes gain registers, and configures speaker coefficients.
- **Power Management Overrides**: Disables aggressive HDA/Intel power saving to eliminate annoying speaker popping and crackling.
- **Low-Latency PipeWire Configuration**: Optimizes quantum sizes and sample rates for responsive, glitch-free audio playback.
- **EasyEffects DSP Integration**: deploys professional presets featuring multi-band parametric equalizers, lifter compressors, limiters, and stereo expanders tailored for tiny laptop speakers.
- **Vendor-Specific Profiles**: Hand-tuned profiles for Lenovo, Dell, HP, ASUS, Acer, and MSI.
- **Safety Backups & One-Click Restore**: Automatic configuration backup during installation, allowing fully reversible restoration.
- **CLI Management**: Intuitive interface for optimization, diagnostics, benchmarking, and backup management.

---

## Architecture

```
                                  +------------+
                                  | QXPal CLI  |
                                  +-----+------+
                                        |
                 +----------------------+----------------------+
                 |                      |                      |
                 v                      v                      v
        +-----------------+    +-----------------+    +-----------------+
        |   Diagnostics   |    | Hardware Detect |    | Backup/Restore  |
        +-----------------+    +--------+--------+    +-----------------+
                                        |
                                        v
                               +-----------------+
                               | Profile Engine  |
                               +--------+--------+
                                        |
                 +----------------------+----------------------+
                 |                      |                      |
                 v                      v                      v
        +-----------------+    +-----------------+    +-----------------+
        |   ALSA Tuning   |    | PipeWire Config |    |  EasyEffects    |
        +-----------------+    +-----------------+    +-----------------+
```

---

## Installation

### Prerequisites

Ensure you have the required audio stack packages. QXPal targets system architectures using **PipeWire** and **WirePlumber**.

- **Ubuntu 24.04+ / Debian 13+**:
  ```bash
  sudo apt update
  sudo apt install pipewire wireplumber easyeffects alsa-utils systemd
  ```
- **Fedora 42+**:
  ```bash
  sudo dnf install pipewire-pulseaudio wireplumber easyeffects alsa-utils systemd
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -S pipewire pipewire-pulse wireplumber easyeffects alsa-utils systemd
  ```

### Steps

Clone the repository and run the installer:

```bash
git clone https://github.com/yourusername/QXPal.git
cd QXPal
sudo ./install.sh
```

---

## Usage

QXPal provides an intuitive CLI interface. Most hardware detection commands can run as normal user, while tuning requires superuser privileges.

### Commands

| Command | Description |
|:---|:---|
| `qxpal version` | Display QXPal version and details. |
| `qxpal diagnose` | Scan and output diagnostic details of the audio hardware and active framework state. |
| `qxpal optimize` | Detect laptop profile, backup existing files, and apply custom audio configurations. |
| `qxpal backup` | Manually take a backup of the current audio stack configuration. |
| `qxpal restore` | Rollback system to the original pre-optimized configuration. |
| `qxpal benchmark` | Run performance, RT latency, and Xrun tests on the active audio stack. |
| `qxpal uninstall` | Remove all configs, restore backups, and disable systemd service. |

### Examples

**Run Diagnostics:**
```bash
qxpal diagnose
```

**Apply Optimization:**
```bash
sudo qxpal optimize
```

**Perform Latency Benchmark:**
```bash
qxpal benchmark
```

---

## Screenshots

*Screenshots demonstrating the CLI layout and EasyEffects preset configurations will be added here.*

---

## Roadmap

- [ ] Support for customized sub-profiles for popular laptop lines (e.g. Lenovo ThinkPad X1 Carbon, ASUS ROG Zephyrus).
- [ ] GUI configuration tool for desktop integration.
- [ ] Auto-update client for profile improvements.
- [ ] Interactive sweep tool for speaker response measurement.

---

## Contributing

We welcome contributions! Please review the [CONTRIBUTING.md](CONTRIBUTING.md) guide for details on how to submit bug reports, feature requests, or new laptop-specific profiles.

## License

This project is licensed under the GPL-2.0 License. See the [LICENSE](LICENSE) file for details.
