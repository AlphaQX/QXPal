# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-02

### Added
- Core QXPal CLI utility with subcommands: `install`, `optimize`, `diagnose`, `benchmark`, `backup`, `restore`, `uninstall`, `version`.
- Robust hardware detection engine identifying laptop vendor, model, audio codec, and PipeWire stack components.
- Modular, vendor-specific tuning profiles for `lenovo`, `dell`, `hp`, `asus`, `acer`, `msi`, and a `generic` fallback.
- ALSA tuning script supporting mixer control adjustments and disabling of Intel HDA power saving.
- PipeWire/WirePlumber low-latency configuration templates.
- EasyEffects preset loaded with EQ, DSP, and limiter optimizations tailored for laptop speakers.
- Comprehensive safety framework creating automated snapshots with robust full-restore functionality.
- Unit testing suites for detection, install, and profile logic.
- Systemd service template for applying adjustments on boot.
- Detailed architecture, profile configuration, and troubleshooting documentation.
