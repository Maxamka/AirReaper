# AirReaper ☠️

**AirReaper** is a Bash-powered Wi-Fi attack automation tool designed for WPA/WPA2 handshake capturing and cracking. It wraps around the `aircrack-ng` suite for easy scanning, targeting, deauth attacks, and password cracking — all with a user-friendly terminal interface.

---

## ✨ Features

- Automated scan and target selection
- Channel lock and BSSID filter
- Deauthentication flood attack
- WPA/WPA2 handshake capture
- Optional password cracking with dictionary
- Auto-cleanup with option to save or delete handshake
- Toolchain checker and setup suggestions

---

## 📦 Requirements

- `aircrack-ng`
- `hcxpcapngtool` (for .hc22000 conversion)
- Bash (Linux environment)
- `sudo` permissions

You can use the provided script to check and install requirements:

```bash
./check_requirements.sh
