# QXPal Developer Guide

Welcome to the QXPal developer guide! This document describes the structure of the project, development instructions, testing processes, and coding style.

---

## Codebase Organization

The framework components are structured as follows:

```
QXPal/
├── Makefile                # Automation commands (test, lint, install)
├── install.sh              # Installation runner
├── uninstall.sh            # Uninstallation runner
├── qxpal                   # Main CLI script
├── configs/                # Static config files
├── profiles/               # Laptop profile configurations
├── scripts/                # Modular logic scripts called by CLI
├── systemd/                # systemd services configuration
├── docs/                   # Markdown documentation files
└── tests/                  # Automated test scripts
```

---

## Development Workflow

### 1. Code Style and Linting
We enforce strict style checks on all Bash scripts using **ShellCheck**. Before submitting a pull request, run:
```bash
make lint
```
Fix any warnings reported by ShellCheck.

### 2. Testing Your Changes
QXPal includes an automated unit test suite.
To run all tests locally:
```bash
make test
```
The test suite consists of:
- **test_detection.sh**: Verifies that the hardware detection logic parses sysfs and codec files correctly.
- **test_profiles.sh**: Sources and parses all profiles under `profiles/` to ensure syntax validity.
- **test_install.sh**: Simulates an installation script execution inside a mock filesystem environment and checks if files are placed in their correct locations.

### 3. Adding New Features
- If adding a script, write it inside the `scripts/` directory and ensure it has executable permissions (`chmod +x`).
- Keep scripts focused on a single task (e.g. `scripts/apply_alsa.sh` only handles ALSA configuration).
- Reference the script in the main `qxpal` CLI router with appropriate argument routing.
