#!/bin/bash

# --- CONFIG & COLORS ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

CONTAINERS=("convoy-caddy-1" "convoy-php-1" "convoy-workers-1" "convoy-workspace-1" "convoy-redis-1" "convoy-database-1")
IMAGES=("convoy-caddy" "convoy-php" "convoy-workers" "convoy-workspace" "redis" "mysql")
DB_NAME="convoy"
DB_USER="convoy_user"
PANEL_DIR="/var/www/convoy"

# --- HEADER ---
clear
echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${PURPLE}│${NC}  ${RED}☢️  CONVOY FULL SYSTEM PURGE${NC} ${GRAY}v9.1${NC}            ${PURPLE}│${NC}"
echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"

# --- SAFETY CHECK (y/n ONLY) ---
echo -e "  ${RED}CRITICAL WARNING:${NC} This will delete ALL containers, images,"
echo -e "  databases, and the entire panel directory: ${GOLD}$PANEL_DIR${NC}"
echo ""
echo -ne "  ${WHITE}Continue with uninstall? (y/n):${NC} "
read confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "\n  ${CYAN}Operation aborted.${NC}"
    exit 0
fi

# 1. Stop & Remove Containers
echo -e "\n  ${CYAN}DOCKER CONTAINER OPERATIONS${NC}"
for c in "${CONTAINERS[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
        echo -ne "  ${GRAY}├─ Purging ${NC}$c... "
        docker stop $c &>/dev/null
        docker rm $c &>/dev/null
        echo -e "${GREEN}✔ Removed${NC}"
    else
        echo -e "  ${GRAY}├─ $c :${NC} ${GRAY}Not found${NC}"
    fi
done

# 2. Remove Images
echo -e "\n  ${CYAN}DOCKER IMAGE PURGE${NC}"
for i in "${IMAGES[@]}"; do
    if docker images --format '{{.Repository}}' | grep -q "^${i}$"; then
        echo -ne "  ${GRAY}├─ Deleting ${NC}$i... "
        docker rmi $i -f &>/dev/null
        echo -e "${GREEN}✔ Deleted${NC}"
    else
        echo -e "  ${GRAY}├─ $i :${NC} ${GRAY}Not found${NC}"
    fi
done

# 3. Database Cleanup
echo -e "\n  ${CYAN}DATABASE OPERATIONS${NC}"
echo -ne "  ${GRAY}├─ Dropping ${DB_NAME} & ${DB_USER}... "
if mariadb -e "status" &>/dev/null; then
    mariadb -e "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null
    mariadb -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';" 2>/dev/null
    mariadb -e "FLUSH PRIVILEGES;" 2>/dev/null
    echo -e "${GREEN}✔ Purged${NC}"
else
    echo -e "${RED}✘ DB Engine Offline${NC}"
fi

# 4. File System Cleanup
echo -e "\n  ${CYAN}FILE SYSTEM OPERATIONS${NC}"
if [ -d "$PANEL_DIR" ]; then
    echo -ne "  ${GRAY}└─ Deleting ${PANEL_DIR}... "
    rm -rf "$PANEL_DIR"
    echo -e "${GREEN}✔ Deleted${NC}"
else
    echo -e "  ${GRAY}└─ Panel directory not found.${NC}"
fi

# --- FINAL SUMMARY ---
echo -e "\n${GREEN}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│${NC}  ${WHITE}UNINSTALLATION COMPLETED SUCCESSFULLY${NC}           ${GREEN}│${NC}"
echo -e "${GREEN}└──────────────────────────────────────────────────────────┘${NC}"
echo -e "  ${GRAY}All requested data has been wiped from the system.${NC}"
echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
