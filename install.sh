#!/bin/bash

echo "[*] Checking dependencies..."

deps=("aircrack-ng" "hcxpcapngtool")

for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "[+] Installing $dep..."
        sudo apt update
        sudo apt install -y "$dep"
    else
        echo "[✔] $dep is installed"
    fi
done

echo "[✓] All dependencies are ready!"
