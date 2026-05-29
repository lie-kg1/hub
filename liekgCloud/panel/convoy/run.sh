#!/bin/bash

# --- CONFIG & COLORS ---
PANEL_DIR="/var/www/convoy"
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

# --- STATUS DETECTOR ---
get_status() {
    if [ -d "$PANEL_DIR" ] && docker ps | grep -q "convoy"; then
        echo -e "${GREEN}ONLINE${NC}"
    elif [ -d "$PANEL_DIR" ]; then
        echo -e "${GOLD}STOPPED${NC}"
    else
        echo -e "${RED}NOT INSTALLED${NC}"
    fi
}

while true; do
    clear
    STATUS=$(get_status)
    
    # --- HEADER ---
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}🛰️  CONVOY PANEL MANAGER${NC} ${GRAY}v10.0${NC}         ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "  ${CYAN}SYSTEM STATUS${NC}"
    echo -e "  ${GRAY}├─ Panel State :${NC} $STATUS"
    echo -e "  ${GRAY}└─ Directory   :${NC} ${WHITE}$PANEL_DIR${NC}"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"

    # --- MENU OPTIONS ---
    echo -e "  ${PURPLE}[1]${NC} ${WHITE}Install Convoy Panel${NC}    ${GRAY}(Full Auto-Setup)${NC}"
    echo -e "  ${PURPLE}[2]${NC} ${WHITE}Create Admin User${NC}       ${GRAY}(CLI Wizard)${NC}"
    echo -e "  ${PURPLE}[3]${NC} ${WHITE}Restart & Optimize${NC}      ${GRAY}(Force Rebuild)${NC}"
    echo -e "  ${PURPLE}[4]${NC} ${RED}Uninstall Panel${NC}         ${GRAY}(Purge Everything)${NC}"
    echo -e "  ${PURPLE}[0]${NC} ${GRAY}Exit Manager${NC}"
    echo ""
    echo -ne "  ${CYAN}λ${NC} ${WHITE}Action:${NC} "
    read OPTION

    case $OPTION in
        1)
            echo -e "\n${CYAN}🚀 Initializing Remote Installer...${NC}"
            bash <(curl -s https://raw.githubusercontent.com/nobita329/hub/refs/heads/main/Codinghub/panel/convoy/install.sh)
            read -p "Press Enter to return..."
            ;;

        2)
            if [ -d "$PANEL_DIR" ]; then
                echo -e "\n${CYAN}👤 Opening Admin Creation Wizard...${NC}"
                cd $PANEL_DIR || exit
                docker compose exec workspace php artisan c:user:make
            else
                echo -e "\n${RED}✘ Error: Panel directory not found!${NC}"
            fi
            read -p "Press Enter to return..."
            ;;

        3)
            if [ -d "$PANEL_DIR" ]; then
                echo -e "\n${GOLD}🔄 Performing Panel Maintenance...${NC}"
                cd $PANEL_DIR || exit
                echo -e "  ${GRAY}├─ Stopping containers...${NC}"
                docker compose down &>/dev/null
                echo -e "  ${GRAY}├─ Rebuilding & Starting...${NC}"
                docker compose up -d --build &>/dev/null
                echo -e "  ${GRAY}├─ Optimizing caches...${NC}"
                docker compose exec workspace bash -c "php artisan optimize" &>/dev/null
                echo -e "  ${GRAY}└─ Final restart...${NC}"
                docker compose restart &>/dev/null
                echo -e "${GREEN}✔ Panel Restarted & Optimized.${NC}"
            else
                echo -e "\n${RED}✘ Error: Cannot restart a non-existent panel.${NC}"
            fi
            read -p "Press Enter to return..."
            ;;

        4)
            echo -e "\n${RED}🧨 Initializing Remote Uninstaller...${NC}"
            bash <(curl -s https://raw.githubusercontent.com/nobita329/hub/refs/heads/main/Codinghub/panel/convoy/uninstall.sh)
            read -p "Press Enter to return..."
            ;;

        0)
            echo -e "\n${CYAN}Closing Manager. Goodbye!${NC}"
            exit 0
            ;;

        *)
            echo -e "\n${RED}⚠ Invalid Selection.${NC}"
            sleep 1
            ;;
    esac
done
