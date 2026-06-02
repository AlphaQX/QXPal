# QXPal Troubleshooting Guide

This document lists common audio issues, explanation of causes, and recovery steps.

---

## 1. Speaker Crackling or Popping When Audio Starts

### Cause
Many modern Linux distributions enable HDA power-saving by default. The sound card goes to sleep after a few seconds of silence, causing a popping or clicking noise when it wakes up to play sound.

### Solution
Ensure QXPal's ALSA optimization has run successfully:
```bash
sudo qxpal optimize
```
Verify that power save is disabled:
```bash
cat /sys/module/snd_hda_intel/parameters/power_save
```
This should return `0`. If it returns `1` or `2`, check that `/etc/modprobe.d/qxpal.conf` exists and matches the configuration in `configs/alsa/qxpal-alsa.conf`.

---

## 2. EasyEffects Presets are Not Loading or Inactive

### Cause
EasyEffects runs in the user session. Running `qxpal` as root (`sudo`) will not configure EasyEffects for your local user session because root does not have access to your local user's home directory configurations.

### Solution
Apply user-space configurations by running `qxpal optimize` **without** `sudo`:
```bash
qxpal optimize
```
This will copy the presets to `~/.config/easyeffects/output/qxpal.json` and start the EasyEffects daemon for the current desktop user.

---

## 3. Total Loss of Sound

### Cause
Sometimes ALSA channels are muted by default or conflicted during stack reload.

### Solution
1. Run diagnostics to check card index and master volume status:
   ```bash
   qxpal diagnose
   ```
2. Check if channels are muted in `alsamixer`:
   - Open terminal and run `alsamixer`.
   - Press `F6` to select your primary card (usually HDA Intel or SOF).
   - Ensure "Master", "Speaker", and "PCM" channels are not showing `MM` (Muted). Press `M` to unmute.
3. If issues persist, revert all QXPal configurations:
   ```bash
   qxpal restore
   sudo qxpal restore
   ```
   This will completely restore the system to its pre-optimized state.
