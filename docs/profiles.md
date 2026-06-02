# QXPal Profiles Documentation

Profiles in QXPal define specific audio settings for different laptop vendors. This document explains the profile structure and variables.

---

## Profile Directory Structure

All profiles reside under the `profiles/` directory:

```
profiles/
├── generic/
│   └── profile.conf
├── lenovo/
│   └── profile.conf
├── dell/
│   └── profile.conf
├── hp/
│   └── profile.conf
├── asus/
│   └── profile.conf
├── acer/
│   └── profile.conf
└── msi/
    └── profile.conf
```

---

## Configuration Variables

Each `profile.conf` is a shell script containing configuration variables and functions:

| Variable / Function | Type | Description |
|:---|:---|:---|
| `PROFILE_NAME` | String | A descriptive name for the profile. |
| `ALSA_POWER_SAVE` | Integer | `0` to disable power saving, `1` to enable. Recommended: `0`. |
| `EASYEFFECTS_PRESET` | String | The EasyEffects preset file to load (e.g. `qxpal.json`). |
| `apply_custom_alsa()` | Function | A shell function that executes vendor-specific `amixer` commands. |

### Example Profile Configuration

```bash
# profiles/example/profile.conf
PROFILE_NAME="Example Laptop Optimizer"
ALSA_POWER_SAVE=0
EASYEFFECTS_PRESET="qxpal.json"

apply_custom_alsa() {
    local card_idx="$1"
    log_info "Applying Example-specific mixer controls..."
    # Set speaker channel to max volume and unmute
    amixer -c "$card_idx" sset "Speaker" 100% unmute 2>/dev/null || true
}
```

---

## Custom Profile Overrides

If you want to create a custom override for your specific laptop model:
1. You can modify the vendor profile corresponding to your laptop (e.g., `profiles/lenovo/profile.conf` for a Lenovo laptop).
2. Inside `apply_custom_alsa`, you can query the system model using `${QXPAL_DETECTED_MODEL:-}` to apply settings conditionally for a specific model line (e.g. "ThinkPad X1 Carbon").
