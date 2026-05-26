#!/bin/bash

# --- CONFIGURATION & PATHS ---
CPU_FILE="/etc/cpu_name"
PROTECTED_USERS=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc")

# --- MODERN COLOR PALETTE ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

# --- UI COMPONENTS ---
draw_bar() {
    local percent=$1
    local width=25
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))
    local color=$GREEN
    [ "$percent" -gt 60 ] && color=$GOLD
    [ "$percent" -gt 85 ] && color=$RED
    printf "${GRAY}[${NC}${color}%0.s#${NC}" $(seq 1 $filled)
    [ $empty -gt 0 ] && printf "${GRAY}%0.s-${NC}" $(seq 1 $empty)
    printf "${GRAY}]${NC} ${WHITE}${percent}%%${NC}"
}

# --- SYSTEM LOGIC ---
get_net() {
    local interface=$(ip route get 8.8.8.8 | awk '{print $5}' | head -n1)
    if [ -d "/sys/class/net/$interface" ]; then
        read rx_old < "/sys/class/net/$interface/statistics/rx_bytes"
        read tx_old < "/sys/class/net/$interface/statistics/tx_bytes"
        echo "$((rx_old / 1024 / 1024))MB ↓ / $((tx_old / 1024 / 1024))MB ↑"
    else
        echo "Net Offline"
    fi
}

# --- MAIN DASHBOARD ---
while true; do
    clear
    # Data Gathering
    HOST=$(hostname)
    IP=$(curl -s --max-time 2 ifconfig.me || echo "Offline")
    OS=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)
    UP=$(uptime -p | sed 's/up //')
    
    # RAM & Disk Stats
    RAM_TOTAL_M=$(free -m | awk '/Mem:/ {print $2}')
    RAM_USED_M=$(free -m | awk '/Mem:/ {print $3}')
    RAM_P=$(( RAM_USED_M * 100 / RAM_TOTAL_M ))
    
    DISK_P=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    NET_STAT=$(get_net)
    
    CPU_REAL=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d ':' -f2 | xargs)
    [ -f "$CPU_FILE" ] && CPU=$(cat $CPU_FILE) || CPU=$CPU_REAL

    # --- HEADER ---
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}🛰️  ULTIMATE VPS OVERLORD${NC} ${GRAY}v5.1${NC}        ${GRAY}$(date +"%H:%M:%S")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"

    # --- SYSTEM INFO ALL ---
    echo -e "  ${CYAN}IDENTIFIER${NC}          ${GRAY}├─ Host :${NC} ${WHITE}$HOST${NC}"
    echo -e "  ${WHITE}$IP${NC}             ${GRAY}└─ OS   :${NC} ${WHITE}$OS${NC}"
    echo -e ""
    echo -ne "  ${CYAN}RAM USAGE ${NC}  " ; draw_bar $RAM_P ; echo -e "  ${GRAY}$((RAM_USED_M))MB / $((RAM_TOTAL_M))MB${NC}"
    echo -ne "  ${CYAN}DISK SPACE${NC}  " ; draw_bar $DISK_P ; echo -e "  ${GRAY}$(df -h / | awk 'NR==2 {print $3 "/" $2}')${NC}"
    echo -e ""
    echo -e "  ${CYAN}NETWORK   ${NC}  ${WHITE}$NET_STAT${NC}    ${GRAY}Uptime:${NC} ${WHITE}$UP${NC}"
    echo -e "  ${CYAN}HARDWARE  ${NC}  ${GOLD}${CPU:0:42}${NC}"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"

    # --- MASTER MENU (Option 5 Removed) ---
    echo -e "  ${PURPLE}[1]${NC} ${WHITE}Security & SSH${NC}        ${PURPLE}[4]${NC} ${WHITE}User Management${NC}"
    echo -e "  ${PURPLE}[2]${NC} ${WHITE}Network/Hostname${NC}"
    echo -e "  ${PURPLE}[3]${NC} ${GOLD}CPU Spoofing${NC}          ${PURPLE}[5]${NC} ${RED}Reboot System${NC}"
    echo -e "  ${PURPLE}[0]${NC} ${GRAY}Exit Terminal${NC}"
    echo ""
    echo -ne "  ${CYAN}λ${NC} ${WHITE}Master Command:${NC} "
    read opt

    case $opt in
        1) # SSH Menu
            clear
            echo -e "${CYAN}» SSH SECURITY${NC}"
            echo -e "1) Enable Root  2) Disable Root  3) Password  0) Back"
            read -p "Choice: " sopt
            case $sopt in
                1) sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config; systemctl restart sshd 2>/dev/null || systemctl restart ssh ;;
                2) sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config; systemctl restart sshd 2>/dev/null || systemctl restart ssh ;;
                3) passwd root ;;
            esac ;;
        
        2) # Hostname
            clear
            echo -e "${CYAN}» NETWORK IDENTITY${NC}"
            read -p "New Hostname: " nhost
            [ -n "$nhost" ] && hostnamectl set-hostname "$nhost" && echo "Done." ; sleep 1 ;;

        3) # CPU Menu
            clear
            echo -e "${GOLD}» CPU ARCHITECTURE SELECTION${NC}"
            echo -e "1) Ryzen 9 7950X  2) Core i9-14900K  3) Apple M3 Max  4) Custom"
            read -p "Selection: " copt
            case $copt in
                1) echo "AMD Ryzen 9 7950X 16-Core Processor" > $CPU_FILE ;;
                2) echo "14th Gen Intel(R) Core(TM) i9-14900K" > $CPU_FILE ;;
                3) echo "Apple M3 Max" > $CPU_FILE ;;
                4) read -p "Name: " cn && echo "$cn" > $CPU_FILE ;;
            esac ;;

        4) # User Management
            while true; do
                clear
                echo -e "${CYAN}» USER MANAGEMENT${NC}"
                awk -F: '$3 >= 1000 && $1 != "nobody" {printf "  ID: %s | User: %s\n", $3, $1}' /etc/passwd
                echo -e "\n1) Create  2) Delete  3) Password  0) Back"
                read -p "Choice: " uopt
                [ "$uopt" == "0" ] && break
                case $uopt in
                    1) read -p "Name: " un; useradd -m "$un"; passwd "$un" ;;
                    2) read -p "Name: " un; userdel -r "$un" ;;
                    3) read -p "Name: " un; passwd "$un" ;;
                esac
            done ;;

        5) # Reboot (Moved to position 5)
            echo -ne "${RED}Reboot System? (y/n): ${NC}"; read confirm; [[ "$confirm" == "y" ]] && reboot ;;
            
        0) exit 0 ;;
    esac
done
