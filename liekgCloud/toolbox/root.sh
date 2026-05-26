#!/bin/bash
# ==================================================
# SSH SENTINEL v27.0 | SEMA ACCESS CONTROL
# DATE: 2026-03-13 | UI-TYPE: MASTER-SENTINEL
# ==================================================

# --- CONFIG & SEMA UI COLORS ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;220m'
BG_SHADE='\033[48;5;236m'
NC='\033[0m'

CONFIG_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.bak"

# --- SYSTEM ANALYTICS (Nubar) ---
get_nubar() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}')
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}')
    UPT=$(uptime -p | sed 's/up //')
    echo -e " ${PURPLE}${NC}${BG_SHADE}${WHITE}  CPU: $CPU% ${NC}${PURPLE}${NC}  ${CYAN}${NC}${BG_SHADE}${WHITE}  RAM: $RAM% ${NC}${CYAN}${NC}  ${GOLD}${NC}${BG_SHADE}${WHITE}  $UPT ${NC}${GOLD}${NC}"
}

get_conf_status() {
    local param=$1
    local val=$(grep -E "^${param}" "$CONFIG_FILE" | tail -n 1 | awk '{print $2}')
    if [[ "$val" == "yes" ]]; then echo -e "${GREEN}ENABLED${NC}"; else echo -e "${RED}DISABLED${NC}"; fi
}

# --- HEADER RENDERER ---
show_header() {
    clear
    get_nubar
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    local srv_stat=$(systemctl is-active --quiet ssh && echo -e "${GREEN}ONLINE${NC}" || echo -e "${RED}OFFLINE${NC}")
    local port=$(grep -E "^Port" "$CONFIG_FILE" | head -n 1 | awk '{print $2}')
    [ -z "$port" ] && port="22"

    echo -e "\n${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}🛡️  SSH SENTINEL COMMANDER${NC} ${GRAY}v27.0${NC}       ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "  ${CYAN}ACCESS DIAGNOSTICS${NC}"
    echo -e "  ${GRAY}├─ Hostname :${NC} ${WHITE}$hostname${NC}  ${GRAY}IP :${NC} ${WHITE}$ip${NC}"
    echo -e "  ${GRAY}├─ Status   :${NC} $srv_stat     ${GRAY}Port :${NC} ${GOLD}$port${NC}"
    echo -e "  ${GRAY}├─ Root Login :${NC} $(get_conf_status "PermitRootLogin")"
    echo -e "  ${GRAY}└─ Pass Auth  :${NC} $(get_conf_status "PasswordAuthentication")"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
}

# --- ACTION LOGIC ---
apply_config() {
    echo -e "\n  ${GOLD}⏳ APPLIYING PROTOCOL...${NC}"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    sed -i '/^PermitRootLogin/d; /^PasswordAuthentication/d' "$CONFIG_FILE"
    echo "PermitRootLogin $1" >> "$CONFIG_FILE"
    echo "PasswordAuthentication $2" >> "$CONFIG_FILE"
    systemctl restart ssh
    echo -e "  ${GREEN}✔ Configuration Hardened.${NC}"
    sleep 1.5
}

# --- MAIN LOOP ---
if [ "$EUID" -ne 0 ]; then echo -e "${RED}✘ Please run as root${NC}"; exit 1; fi

while true; do
    show_header
    echo -e "  ${GOLD}  SECURITY CONTROLS${NC}"
    echo -e "  ${GRAY}┌──────────────────────────┬──────────────────────────┐${NC}"
    echo -e "  ${GRAY}│${NC} ${GREEN}[1]${NC} Open Access (R/P)   ${GRAY}│${NC} ${RED}[2]${NC} Lockdown (Key)    ${GRAY}│${NC}"
    echo -e "  ${GRAY}│${NC} ${PURPLE}[3]${NC} Set Root Pass       ${GRAY}│${NC} ${CYAN}[4]${NC} Restore Backup    ${GRAY}│${NC}"
    echo -e "  ${GRAY}└──────────────────────────┴──────────────────────────┘${NC}"
    echo -e "  ${GRAY}[0] Terminate Sentinel${NC}"
    echo ""
    echo -ne "  ${CYAN}λ${NC} ${WHITE}Sentinel Command:${NC} "
    read option

    case $option in
        1) apply_config "yes" "yes" ;;
        2) 
            echo -ne "  ${RED}⚠ Confirm Lockdown (y/n)?${NC} "
            read confirm
            [[ "$confirm" =~ ^[Yy]$ ]] && apply_config "no" "no" ;;
        3) echo -e "\n  ${GOLD}🔑 Resetting Credentials...${NC}"; passwd root; sleep 1 ;;
        4) 
            if [ -f "$BACKUP_FILE" ]; then
                cp "$BACKUP_FILE" "$CONFIG_FILE" && systemctl restart ssh
                echo -e "  ${GREEN}✔ Backup Restored.${NC}"
            else
                echo -e "  ${RED}✘ No Backup Found.${NC}"
            fi
            sleep 1 ;;
        0) exit 0 ;;
        *) echo -e "  ${RED}⚠ Invalid Selection${NC}"; sleep 1 ;;
    esac
done
