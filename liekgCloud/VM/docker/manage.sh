
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

# --- DOKO GRID RENDERER ---
render_grid() {
    echo -e "  ${CYAN}  ACTIVE DOKO CONTAINERS${NC}"
    echo -e "  ${GRAY}┌──┬──────────┬──────────────┬──────────────┬────────────┐${NC}"
    echo -e "  ${GRAY}│${NC}${WHITE}ID${NC}${GRAY}│${NC} ${WHITE}NAME${NC}      ${GRAY}│${NC} ${WHITE}LOCAL IP${NC}     ${GRAY}│${NC} ${WHITE}HOST:CONT${NC}    ${GRAY}│${NC} ${WHITE}STATUS${NC}     ${GRAY}│${NC}"
    echo -e "  ${GRAY}├──┼──────────┼──────────────┼──────────────┼────────────┤${NC}"

    mapfile -t C_LIST < <(docker ps -a --format "{{.Names}}")
    
    local count=0
    docker ps -a --format "{{.Names}}|{{.Status}}|{{.Ports}}" | while read -r line; do
        ((count++))
        IFS='|' read -r name status ports <<< "$line"
        ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$name")
        [ -z "$ip" ] && ip="0.0.0.0"
        mapping=$(echo "$ports" | grep -oP '\d+->\d+' | head -n1 | sed 's/->/:/')
        [ -z "$mapping" ] && mapping="---"
        
        # Power Status Logic
        if [[ "$status" == *"Up"* ]]; then p_stat="${GREEN}ON  ●${NC}"; else p_stat="${RED}OFF ○${NC}"; fi

        printf "  ${GRAY}│${NC}${PURPLE}%-2d${NC}${GRAY}│${NC} %-8.8s ${GRAY}│${NC} %-12.12s ${GRAY}│${NC} %-12.12s ${GRAY}│${NC} %-10b ${GRAY}│${NC}\n" \
            "$count" "$name" "$ip" "$mapping" "$p_stat"
    done
    echo -e "  ${GRAY}└──┴──────────┴──────────────┴──────────────┴────────────┘${NC}"
}

# --- MANAGEMENT SUB-MENU (WITH ON/OFF TOGGLE) ---
manage_container() {
    local cname=$1
    while true; do
        clear
        # Get live status and stats
        local raw_stat=$(docker inspect -f '{{.State.Status}}' "$cname")
        local stats=$(docker stats "$cname" --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" 2>/dev/null || echo "0%|0B")
        
        if [[ "$raw_stat" == "running" ]]; then 
            power_ui="${GREEN}● SYSTEM ONLINE (ON)${NC}"
        else 
            power_ui="${RED}○ SYSTEM OFFLINE (OFF)${NC}"
        fi

        echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${CYAN}🛠️  MANAGE:${NC} ${WHITE}$cname${NC}                             ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
        
        echo -e "  ${GOLD}POWER STATUS :${NC} $power_ui"
        echo -e "  ${GRAY}├─ CPU Load :${NC} ${WHITE}$(echo $stats | cut -d'|' -f1)${NC}"
        echo -e "  ${GRAY}└─ RAM Used :${NC} ${WHITE}$(echo $stats | cut -d'|' -f2)${NC}"
        echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"

        echo -e "  ${GREEN}[1] POWER ON${NC}      ${RED}[2] POWER OFF${NC}     ${PURPLE}[3] RESTART${NC}"
        echo -e "  ${GRAY}────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${PURPLE}[4]${NC} Rebuild      ${PURPLE}[5]${NC} Terminal     ${PURPLE}[6]${NC} ${GOLD}Edit Config${NC}"
        echo -e "  ${PURPLE}[7]${NC} Login Info   ${PURPLE}[8]${NC} Logs Stream   ${PURPLE}[0]${NC} Back"
        echo ""
        echo -ne "  ${CYAN}λ${NC} ${WHITE}Action:${NC} "
        read m_opt

        case $m_opt in
            1) docker start "$cname" ;;
            2) docker stop "$cname" ;;
            3) docker restart "$cname" ;;
            4) docker stop "$cname" && docker start "$cname" ;;
            5) docker exec -it "$cname" /bin/bash || docker exec -it "$cname" /bin/sh ;;
            6) 
                echo -e "${GOLD}Edit Config...${NC}"
                read -p "  New Name: " nn && [ -n "$nn" ] && docker rename "$cname" "$nn" && cname="$nn"
                read -p "  CPU Shares (e.g. 512): " nc && [ -n "$nc" ] && docker update --cpu-shares "$nc" "$cname"
                ;;
            7) docker inspect "$cname" | grep -iE 'user|pass|env'; read -p "Press Enter..." ;;
            8) journalctl -u docker -f --grep="$cname" || docker logs -f "$cname" ;;
            0) break ;;
        esac
    done
}

# --- MAIN DASHBOARD ---
while true; do
    clear
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}🛰️  DOKO POWER-GRID MASTER${NC} ${GRAY}v22.0${NC}             ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────────┘${NC}"
    render_grid
    
    echo -e "\n  ${GOLD}  SYSTEM OPERATIONS${NC}"
    echo -e "  ${GRAY}├─ [1]${NC} Deploy New       ${GRAY}[4]${NC} ${GREEN}24/7 Autostart ON${NC}"
    echo -e "  ${GRAY}├─ [2]${NC} ${WHITE}Manage ID${NC}         ${GRAY}[5]${NC} ${RED}Delete ID${NC}"
    echo -e "  ${GRAY}└─ [3]${NC} Prune System     ${GRAY}[0]${NC} Shutdown Manager"
    echo ""
    echo -ne "  ${CYAN}λ${NC} ${WHITE}Master Command:${NC} "
    read option

    case $option in
        1) echo "Launching creator...";
           bash <(curl -fsSL https://raw.githubusercontent.com/lie-kg1/hub/refs/heads/main/Codinghub/VM/docker/install.sh)
           sleep 1 ;;
        2) 
            echo -ne "  ${WHITE}Select ID to Manage:${NC} "
            read id
            target="${C_LIST[$((id-1))]}"
            [ -n "$target" ] && manage_container "$target" || { echo "Invalid ID"; sleep 1; } ;;
        3) docker system prune -f; sleep 1 ;;
        4) 
            echo -ne "  ${WHITE}Select ID for 24/7:${NC} "
            read id
            target="${C_LIST[$((id-1))]}"
            docker update --restart always "$target"
            echo -e "${GREEN}✔ Autostart Active for $target${NC}"; sleep 1 ;;
        5) 
            echo -ne "  ${RED}Select ID to DELETE:${NC} "
            read id
            target="${C_LIST[$((id-1))]}"
            docker stop "$target" && docker rm "$target"
            echo -e "${RED}✔ Purged $target${NC}"; sleep 1 ;;
        0) exit 0 ;;
    esac
done
