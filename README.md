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

🚀 Usage

chmod +x airreaper.sh
sudo ./airreaper.sh

📁 Output

Captured .cap and .hc22000 files will be stored in the current directory:

    /cap for raw captures

    /hc for converted files

🛠️ License

This project is licensed under the MIT License.

    ⚠️ Educational use only. Do not use against networks you don’t own or have explicit permission to test.
