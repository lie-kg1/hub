#!/bin/bash

# --- CONFIG & SEMA UI COLORS ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;220m'
NC='\033[0m'

# --- HELPER FUNCTIONS ---
pause() {
    echo -e ""
    echo -ne "  ${GRAY}Press any key to return to grid...${NC}"
    read -n 1 -s -r
}

get_metrics() {
    UPT=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
}

show_header() {
    get_metrics
    clear
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}🛰️  SERVER PANEL MANAGER${NC} ${GRAY}v15.0${NC}         ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${CYAN}SYSTEM STATUS${NC}"
    echo -e "  ${GRAY}├─ Uptime :${NC} ${WHITE}$UPT${NC}"
    echo -e "  ${GRAY}└─ Load   :${NC} ${WHITE}$LOAD${NC}"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
}

# --- OMNI-GRID MENU ---
panel_menu() {
    while true; do
        show_header
        
        echo -e "  ${GOLD}  AVAILABLE DEPLOYMENTS${NC}"
        echo -e "  ${GRAY}┌──────────────────────────┬──────────────────────────┐${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[1]${NC} Ptero                ${GRAY}│${NC} ${PURPLE}[7]${NC}  Convoy              ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[2]${NC} Jexactyl             ${GRAY}│${NC} ${PURPLE}[8]${NC}  FeatherPanel        ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[3]${NC} JexPanel             ${GRAY}│${NC} ${PURPLE}[9]${NC}  Mythicaldash        ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[4]${NC} Reviactyl            ${GRAY}│${NC} ${PURPLE}[10]${NC} Mythicaldashv3      ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[5]${NC} CtrlPanel            ${GRAY}│${NC} ${PURPLE}[11]${NC} VPS Panel           ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[6]${NC} Paymenter            ${GRAY}│${NC} ${RED}[0]${NC} Exit                 ${GRAY}│${NC}"
        echo -e "  ${GRAY}└──────────────────────────┴──────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${CYAN}λ${NC} ${WHITE}Select Module [1-11]:${NC} "
        read p

        case $p in
            1)  echo -e "  ${CYAN}➜ Executing Pterodactyl Routine...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/lie-kg1/lie-kg-Cloud/refs/heads/main/panel/pterodactyl/run.sh) 
                pause ;;
            2)  echo -e "  ${CYAN}➜ Executing [] Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            3)  echo -e "  ${CYAN}➜ Executing [] Routine...${NC}"
                bash <(curl -s )
                pause ;;
            4)  echo -e "  ${CYAN}➜ Executing [] Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            5)  echo -e "  ${CYAN}➜ Executing [] Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            6)  echo -e "  ${CYAN}➜ Executing paymenter Routine...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/lie-kg1/lie-kg-Cloud/refs/heads/main/panel/paymenter/run.sh) 
                pause ;;
            7)  echo -e "  ${CYAN}➜ Executing Convoy Routine...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/lie-kg1/hub/refs/heads/main/liekgCloud/panel/convoy/run.sh) 
                pause ;;
            8)  echo -e "  ${CYAN}➜ Executing [] Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            9)  echo -e "  ${CYAN}➜ Executing [] Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            10) echo -e "  ${CYAN}➜ Executing Tools Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            11) echo -e "  ${CYAN}➜ Executing Tools Routine...${NC}"
                bash <(curl -s ) 
                pause ;;
            0)  echo -e "\n  ${RED}Shutting down Uplink. Goodbye!${NC}"
                exit 0 ;;
            *)  echo -e "  ${RED}⚠ Invalid Selection${NC}"
                sleep 1 ;;
        esac
    done
}

# Run the menu
panel_menu
