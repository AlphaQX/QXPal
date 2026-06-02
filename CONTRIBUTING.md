# Contributing to QXPal

We are thrilled that you want to help make QXPal better! As an open-source project, we rely on community contributions to expand hardware profile support and refine DSP tuning.

---

## Coding Standards

### Bash Style Guide
All bash scripts must follow these guidelines:
- **ShellCheck**: All scripts must pass ShellCheck without errors. Run `shellcheck <script>` before committing.
- **Strict Error Handling**: Use `set -euo pipefail` where applicable to ensure scripts fail early.
- **Formatting**: Keep code clean and indented with 4 spaces (no tabs).
- **Functions**: Write modular, reusable functions. Localize variables with the `local` keyword.
- **Colors**: Use the provided log functions in scripts for consistent, colored output.

---

## Adding a Laptop Profile

If QXPal does not currently optimize your specific laptop or if you have a better profile configuration, you can contribute a new profile.

1. **Locate Profile Folder**: Profiles are organized by vendor under `profiles/<vendor>/`.
2. **Create/Edit `profile.conf`**: Add or modify variables. For example:
   ```bash
   # Vendor Profile Configuration for Lenovo
   PROFILE_NAME="Lenovo Speaker Optimizer"
   ALSA_POWER_SAVE=0
   EASYEFFECTS_PRESET="qxpal.json"
   
   # Custom ALSA Mixer commands
   apply_custom_alsa() {
       log_info "Applying Lenovo-specific mixer controls..."
       # Example: unmute smart amplifier boost
       amixer -c "$CARD_INDEX" sset "Speaker" unmute || true
       amixer -c "$CARD_INDEX" sset "Auto-Mute Mode" Disabled || true
   }
   ```
3. **Test Your Changes**: Verify using `./qxpal optimize` or the test suite under `tests/test_profiles.sh`.

---

## Submission Process

1. **Fork the Repository**: Create a fork of QXPal on GitHub.
2. **Create a Feature Branch**:
   ```bash
   git checkout -b profile/my-new-laptop-model
   ```
3. **Commit Your Changes**: Ensure your commit message is descriptive.
4. **Run Tests**:
   ```bash
   make test
   ```
5. **Open a Pull Request**: Provide a detailed description of your changes, including the laptop vendor, model, and diagnostic information from `qxpal diagnose`.
