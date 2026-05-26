#!/bin/bash
# ==================================================
# CLOUDFLARE SENTINEL v29.5 | SEMA UI (TUNNEL-ONLY)
# Style: Cyber-Grid / Glass-Pill / Clean-Core
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

# --- NUBAR ANALYTICS ---
get_nubar() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}')
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}')
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    UPT=$(uptime -p | sed 's/up //')
    echo -e " ${PURPLE}${NC}${BG_SHADE}${WHITE}  CPU: $CPU% ${NC}${PURPLE}${NC}  ${CYAN}${NC}${BG_SHADE}${WHITE}  RAM: $RAM% ${NC}${CYAN}${NC}  ${GREEN}${NC}${BG_SHADE}${WHITE}  DISK: $DISK ${NC}${GREEN}${NC}  ${GOLD}${NC}${BG_SHADE}${WHITE}  $UPT ${NC}${GOLD}${NC}"
}

# --- TUNNEL ANALYTICS GRID ---
render_tunnel_grid() {
    local srv="cloudflared"
    local s_status="${RED}OFFLINE${NC}"
    local s_pid="---"
    local s_up="---"
    local s_ver="---"

    if command -v cloudflared &>/dev/null; then
        s_ver=$(cloudflared --version | awk '{print $3}')
        if systemctl is-active --quiet "$srv"; then
            s_status="${GREEN}ONLINE${NC}"
            s_pid=$(pgrep -x "$srv" | head -n1)
            s_up=$(systemctl show -p ActiveEnterTimestamp "$srv" | cut -d'=' -f2 | awk '{print $2}')
        fi
    fi

    echo -e "  ${CYAN}☁️  TUNNEL ANALYTICS${NC}"
    echo -e "  ${GRAY}┌──────────────┬──────────────┬──────────────┬──────────────┐${NC}"
    echo -e "  ${GRAY}│${NC} ${WHITE}SERVICE${NC}      ${GRAY}│${NC} ${WHITE}STATUS${NC}       ${GRAY}│${NC} ${WHITE}PID${NC}          ${GRAY}│${NC} ${WHITE}LAST SYNC${NC}   ${GRAY}│${NC}"
    echo -e "  ${GRAY}├──────────────┼──────────────┼──────────────┼──────────────┤${NC}"
    printf "  ${GRAY}│${NC} %-12.12s ${GRAY}│${NC} %-18b ${GRAY}│${NC} %-12.12s ${GRAY}│${NC} %-12.12s ${GRAY}│${NC}\n" "$srv" "$s_status" "$s_pid" "$s_up"
    echo -e "  ${GRAY}└──────────────┴──────────────┴──────────────┴──────────────┘${NC}"
    echo -e "  ${GRAY}├─ Version :${NC} ${WHITE}$s_ver${NC}"
    echo -e "  ${GRAY}└─ Host IP :${NC} ${WHITE}$(curl -s ifconfig.me)${NC}"
}

show_header() {
    clear
    get_nubar
    echo -e "\n${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}☁️  CLOUDFLARE SENTINEL${NC} ${GRAY}v29.5${NC}          ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    render_tunnel_grid
}

# --- CORE LOGIC ---
install_cf() {
    echo -e "\n  ${GOLD}⏳ INITIATING DEPLOYMENT SEQUENCE...${NC}"
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
    
    sudo apt-get update -qq && sudo apt-get install -y cloudflared -qq
    
    echo -e "\n  ${CYAN}┌─[ TOKEN REQUIRED ]────────────────────────────────────┐${NC}"
    echo -ne "  ${CYAN}│${NC} Paste Tunnel Token: "
    read USER_TOKEN
    CLEAN_TOKEN=$(echo "$USER_TOKEN" | sed 's/sudo cloudflared service install //g' | sed 's/cloudflared service install //g' | xargs)

    if [[ -z "$CLEAN_TOKEN" ]]; then
        echo -e "  ${RED}✘ Error: Token Required.${NC}"; sleep 2; return
    fi

    sudo cloudflared service install "$CLEAN_TOKEN"
    echo -ne "  ${GOLD}➜ Syncing Tunnel... ${NC}"
    for i in {1..20}; do echo -ne "▓"; sleep 0.05; done
    echo -e "\n  ${GREEN}✔ Tunnel Operational.${NC}"
    sleep 2
}

uninstall_cf() {
    echo -e "\n  ${RED}☢ PURGE PROTOCOL INITIATED${NC}"
    echo -ne "  ${WHITE}Remove Tunnel & Binary? (y/n): ${NC}"
    read confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo cloudflared service uninstall &>/dev/null
        sudo apt-get remove -y cloudflared &>/dev/null
        sudo rm -f /etc/apt/sources.list.d/cloudflared.list /usr/share/keyrings/cloudflare-main.gpg
        echo -e "  ${GREEN}✔ All Assets Purged.${NC}"
    fi
    sleep 2
}

# --- MAIN MENU ---
while true; do
    show_header
    echo -e "\n  ${GOLD}  COMMAND GRID${NC}"
    echo -e "  ${GRAY}┌──────────────────────────┬──────────────────────────┐${NC}"
    echo -e "  ${GRAY}│${NC} ${GREEN}[1]${NC} Install/Update      ${GRAY}│${NC} ${RED}[2]${NC} Purge Tunnel      ${GRAY}│${NC}"
    echo -e "  ${GRAY}│${NC} ${PURPLE}[3]${NC} Restart Service     ${GRAY}│${NC} ${GOLD}[0]${NC} Exit Dashboard    ${GRAY}│${NC}"
    echo -e "  ${GRAY}└──────────────────────────┴──────────────────────────┘${NC}"
    echo ""
    echo -ne "  ${CYAN}λ${NC} ${WHITE}Master Action:${NC} "
    read choice

    case $choice in
        1) install_cf ;;
        2) uninstall_cf ;;
        3) sudo systemctl restart cloudflared; echo -e "  ${GREEN}✔ Restarted.${NC}"; sleep 1 ;;
        0) exit 0 ;;
        *) echo -e "  ${RED}⚠ Invalid Selection${NC}"; sleep 1 ;;
    esac
done
