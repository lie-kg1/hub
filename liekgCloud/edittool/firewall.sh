#!/bin/bash

# --- CONFIG & PATHS ---
DEFAULT_PORTS="22 80 443"
WHITELIST_FILE="/etc/firewall_whitelist"
BLACKLIST_FILE="/etc/firewall_blacklist"
GEOIP_DB="/usr/share/xt_geoip"
FAIL2BAN_JAIL="/etc/fail2ban/jail.local"
CPU_FILE="/etc/cpu_name"

# --- COLORS (Cyberpunk / Modern Palette) ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
BLUE='\033[38;5;39m'
NC='\033[0m'

# --- ASCII ART HEADER ---
show_header() {
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}███████╗███████╗███╗   ███╗ █████╗ ██╗   ██╗${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}██╔════╝██╔════╝████╗ ████║██╔══██╗██║   ██║${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}███████╗█████╗  ██╔████╔██║███████║██║   ██║${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}╚════██║██╔══╝  ██║╚██╔╝██║██╔══██║██║   ██║${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}███████║███████╗██║ ╚═╝ ██║██║  ██║╚██████╔╝${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ${NC}      ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
}

# --- LOGIC FUNCTIONS ---
detect_firewall() {
    if systemctl is-active --quiet ufw 2>/dev/null; then 
        echo "UFW (Active)"
    elif systemctl is-active --quiet firewalld 2>/dev/null; then 
        echo "Firewalld (Active)"
    elif iptables -L -n >/dev/null 2>&1; then
        echo "IPTables (Active)"
    else
        echo "No Firewall Detected"
    fi
}

save_rules_persistent() {
    echo -e "${GOLD}Saving persistence...${NC}"
    
    # Detect OS and save rules accordingly
    if [ -f /etc/debian_version ]; then
        apt install -y iptables-persistent netfilter-persistent >/dev/null 2>&1
        netfilter-persistent save
        echo -e "${GREEN}✓ Rules saved persistently${NC}"
    elif [ -f /etc/redhat-release ]; then
        service iptables save
        echo -e "${GREEN}✓ Rules saved persistently${NC}"
    else
        # Fallback - create restore script
        iptables-save > /etc/iptables.rules
        echo -e "${GREEN}✓ Rules saved to /etc/iptables.rules${NC}"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root!${NC}"
        exit 1
    fi
}

install_geoip() {
    echo -e "${GOLD}Installing GeoIP support...${NC}"
    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y xtables-addons-common libtext-csv-perl unzip
    elif [ -f /etc/redhat-release ]; then
        yum install -y xtables-addons perl-Text-CSV_XS unzip
    fi
    
    mkdir -p /usr/share/xt_geoip
    /usr/lib/xtables-addons/xt_geoip_dl
    /usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip *.csv
    echo -e "${GREEN}✓ GeoIP database installed${NC}"
}

# --- SUB-MENUS ---

ufw_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${CYAN}🛡️  UFW SHIELD INTERFACE${NC}                          ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        ufw status numbered | head -n 10 | sed 's/^/  /'
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${PURPLE}[1]${NC} Enable (22,80,443)    ${PURPLE}[5]${NC} Enable Logging"
        echo -e "  ${PURPLE}[2]${NC} Disable Firewall      ${PURPLE}[6]${NC} Disable Logging"
        echo -e "  ${PURPLE}[3]${NC} Open Custom Port      ${PURPLE}[7]${NC} Status Verbose"
        echo -e "  ${PURPLE}[4]${NC} Close Port            ${PURPLE}[8]${NC} Reset to Defaults"
        echo -e "  ${PURPLE}[0]${NC} Back to Main"
        echo -ne "\n  ${CYAN}λ${NC} ${WHITE}UFW Command:${NC} "
        read opt
        case $opt in
            1) 
                apt install -y ufw >/dev/null 2>&1
                ufw --force disable
                ufw allow OpenSSH
                for p in $DEFAULT_PORTS; do 
                    ufw allow $p/tcp
                    echo -e "${GREEN}✓ Port $p opened${NC}"
                done
                ufw --force enable
                echo -e "${GREEN}✓ UFW enabled with default ports${NC}"
                sleep 2
                ;;
            2) 
                ufw --force disable
                echo -e "${GREEN}✓ UFW disabled${NC}"
                sleep 2
                ;;
            3) 
                read -p "Enter port number: " p
                read -p "Protocol (tcp/udp/both): " proto
                case $proto in
                    tcp) ufw allow $p/tcp ;;
                    udp) ufw allow $p/udp ;;
                    both) ufw allow $p ;;
                esac
                echo -e "${GREEN}✓ Port $p opened${NC}"
                sleep 2
                ;;
            4) 
                read -p "Enter port to close: " p
                ufw delete allow $p
                echo -e "${GREEN}✓ Port $p closed${NC}"
                sleep 2
                ;;
            5) ufw logging on && echo -e "${GREEN}✓ Logging enabled${NC}" && sleep 2 ;;
            6) ufw logging off && echo -e "${GREEN}✓ Logging disabled${NC}" && sleep 2 ;;
            7) ufw status verbose | less ;;
            8) 
                echo -e "${RED}Resetting UFW...${NC}"
                ufw --force reset
                sleep 2
                ;;
            0) break ;;
        esac
    done
}

iptables_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${RED}🔥 IPTABLES DEEP SECURITY${NC}                        ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${GOLD}ACTIVE RULES SUMMARY${NC}"
        echo -e "  ${GRAY}INPUT Chain Policy:${NC} $(iptables -L INPUT -n | head -1 | awk '{print $4}')"
        echo -e "  ${GRAY}Total Rules:${NC} $(iptables -L INPUT -n | grep -c "ACCEPT\|DROP\|REJECT")"
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${GOLD}SECURITY MODULES${NC}"
        echo -e "  ${PURPLE}[1]${NC} ${WHITE}Recommended Secure Setup${NC}     ${PURPLE}[8]${NC} ${WHITE}Auto-Ban Suspicious${NC}"
        echo -e "  ${PURPLE}[2]${NC} ${WHITE}Flush / Disable All${NC}           ${PURPLE}[9]${NC} ${WHITE}GeoIP Country Block${NC}"
        echo -e "  ${PURPLE}[3]${NC} ${WHITE}Port Scan Detection${NC}           ${PURPLE}[10]${NC} ${WHITE}Whitelist System${NC}"
        echo -e "  ${PURPLE}[4]${NC} ${WHITE}SSH Brute-force Protection${NC}    ${PURPLE}[11]${NC} ${WHITE}Blacklist System${NC}"
        echo -e "  ${PURPLE}[5]${NC} ${WHITE}SYN Flood Shield${NC}              ${PURPLE}[12]${NC} ${WHITE}Show Current Rules${NC}"
        echo -e "  ${PURPLE}[6]${NC} ${WHITE}Rate Limit HTTP/HTTPS${NC}         ${PURPLE}[13]${NC} ${WHITE}Save Persistent${NC}"
        echo -e "  ${PURPLE}[7]${NC} ${WHITE}ICMP/Ping Protection${NC}          ${PURPLE}[14]${NC} ${WHITE}Install GeoIP${NC}"
        echo -e "  ${PURPLE}[0]${NC} Back"
        echo -ne "\n  ${CYAN}λ${NC} ${WHITE}IPT-Command:${NC} "
        read opt
        case $opt in
            1) 
                # Basic secure setup
                iptables -P INPUT DROP
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                for p in 22 80 443; do
                    iptables -A INPUT -p tcp --dport $p -j ACCEPT
                done
                echo -e "${GREEN}✓ Basic secure setup applied${NC}"
                sleep 2
                ;;
            2) 
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                iptables -F
                iptables -X
                echo -e "${GREEN}✓ All rules flushed${NC}"
                sleep 2
                ;;
            3) 
                iptables -N PORTSCAN 2>/dev/null
                iptables -A PORTSCAN -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A PORTSCAN -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -j PORTSCAN
                echo -e "${GREEN}✓ Port scan detection enabled${NC}"
                sleep 2
                ;;
            4) 
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP
                echo -e "${GREEN}✓ SSH brute-force protection enabled${NC}"
                sleep 2
                ;;
            5) 
                iptables -A INPUT -p tcp --syn -m limit --limit 2/s --limit-burst 5 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP
                echo -e "${GREEN}✓ SYN flood protection enabled${NC}"
                sleep 2
                ;;
            6) 
                iptables -A INPUT -p tcp --dport 80 -m limit --limit 30/minute --limit-burst 50 -j ACCEPT
                iptables -A INPUT -p tcp --dport 443 -m limit --limit 30/minute --limit-burst 50 -j ACCEPT
                echo -e "${GREEN}✓ Rate limiting enabled for HTTP/HTTPS${NC}"
                sleep 2
                ;;
            7) 
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second -j ACCEPT
                echo -e "${GREEN}✓ ICMP rate limiting enabled${NC}"
                sleep 2
                ;;
            8) 
                echo -e "${GOLD}Scanning logs for suspicious IPs...${NC}"
                if [ -f /var/log/auth.log ]; then
                    for ip in $(grep "Failed password" /var/log/auth.log 2>/dev/null | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > 5 {print $2}'); do
                        iptables -A INPUT -s $ip -j DROP
                        echo $ip >> $BLACKLIST_FILE
                        echo -e "${RED}✓ Blocked: $ip${NC}"
                    done
                fi
                sleep 3
                ;;
            9) 
                read -p "Enter country code to block (e.g., CN, RU): " cc
                iptables -A INPUT -m geoip --src-cc $cc -j DROP
                echo -e "${RED}✓ All traffic from $cc blocked${NC}"
                sleep 2
                ;;
            10) 
                read -p "Enter IP to whitelist: " ip
                echo $ip >> $WHITELIST_FILE
                iptables -I INPUT -s $ip -j ACCEPT
                echo -e "${GREEN}✓ $ip whitelisted${NC}"
                sleep 2
                ;;
            11) 
                read -p "Enter IP to blacklist: " ip
                echo $ip >> $BLACKLIST_FILE
                iptables -A INPUT -s $ip -j DROP
                echo -e "${RED}✓ $ip blacklisted${NC}"
                sleep 2
                ;;
            12) 
                iptables -L -n -v | less
                ;;
            13) 
                save_rules_persistent
                sleep 2
                ;;
            14) 
                install_geoip
                sleep 2
                ;;
            0) break ;;
        esac
    done
}

firewalld_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${GREEN}🔥 FIREWALLD MANAGER${NC}                           ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        firewall-cmd --list-all 2>/dev/null | head -n 10 | sed 's/^/  /'
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${PURPLE}[1]${NC} Start/Enable Firewalld"
        echo -e "  ${PURPLE}[2]${NC} Stop/Disable Firewalld"
        echo -e "  ${PURPLE}[3]${NC} Add Service (http, ssh, etc)"
        echo -e "  ${PURPLE}[4]${NC} Add Port"
        echo -e "  ${PURPLE}[5]${NC} Remove Port/Service"
        echo -e "  ${PURPLE}[6]${NC} Make Rules Persistent"
        echo -e "  ${PURPLE}[7]${NC} Switch to IPTables Mode"
        echo -e "  ${PURPLE}[0]${NC} Back"
        echo -ne "\n  ${CYAN}λ${NC} ${WHITE}Firewalld Command:${NC} "
        read opt
        case $opt in
            1) 
                systemctl enable --now firewalld
                echo -e "${GREEN}✓ Firewalld started${NC}"
                sleep 2
                ;;
            2) 
                systemctl disable --now firewalld
                echo -e "${GREEN}✓ Firewalld stopped${NC}"
                sleep 2
                ;;
            3) 
                read -p "Service name (ssh, http, https): " svc
                firewall-cmd --add-service=$svc --permanent
                firewall-cmd --reload
                echo -e "${GREEN}✓ Service $svc added${NC}"
                sleep 2
                ;;
            4) 
                read -p "Port number: " p
                read -p "Protocol (tcp/udp): " proto
                firewall-cmd --add-port=$p/$proto --permanent
                firewall-cmd --reload
                echo -e "${GREEN}✓ Port $p/$proto opened${NC}"
                sleep 2
                ;;
            5) 
                read -p "Port number to remove: " p
                firewall-cmd --remove-port=$p/tcp --permanent 2>/dev/null
                firewall-cmd --remove-port=$p/udp --permanent 2>/dev/null
                firewall-cmd --reload
                echo -e "${GREEN}✓ Port $p closed${NC}"
                sleep 2
                ;;
            6) 
                firewall-cmd --runtime-to-permanent
                echo -e "${GREEN}✓ Rules made persistent${NC}"
                sleep 2
                ;;
            7) 
                systemctl stop firewalld
                systemctl disable firewalld
                echo -e "${GREEN}✓ Switched to IPTables mode${NC}"
                sleep 2
                ;;
            0) break ;;
        esac
    done
}

http_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${CYAN}🌐 HTTP FILTER & RATE LIMITS${NC}                     ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${GOLD}CURRENT HTTP RULES${NC}"
        iptables -L INPUT -n -v | grep -E ":80|:443" | head -n 5 | sed 's/^/  /'
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${PURPLE}[1]${NC} Enable Rate Limiting (HTTP)"
        echo -e "  ${PURPLE}[2]${NC} Enable Rate Limiting (HTTPS)"
        echo -e "  ${PURPLE}[3]${NC} Block Bad Bots (curl/wget)"
        echo -e "  ${PURPLE}[4]${NC} Block Common Attack Patterns"
        echo -e "  ${PURPLE}[5]${NC} Enable Connection Limiting"
        echo -e "  ${PURPLE}[6]${NC} Block SQL Injection Attempts"
        echo -e "  ${PURPLE}[7]${NC} Block XSS Attempts"
        echo -e "  ${PURPLE}[8]${NC} Show HTTP Traffic Stats"
        echo -e "  ${PURPLE}[0]${NC} Back"
        echo -ne "\n  ${CYAN}λ${NC} ${WHITE}Filter Choice:${NC} "
        read opt
        case $opt in
            1) 
                iptables -A INPUT -p tcp --dport 80 -m limit --limit 30/minute --limit-burst 50 -j ACCEPT
                echo -e "${GREEN}✓ HTTP rate limiting enabled${NC}"
                sleep 2
                ;;
            2) 
                iptables -A INPUT -p tcp --dport 443 -m limit --limit 30/minute --limit-burst 50 -j ACCEPT
                echo -e "${GREEN}✓ HTTPS rate limiting enabled${NC}"
                sleep 2
                ;;
            3) 
                iptables -A INPUT -p tcp --dport 80 -m string --string "curl" --algo bm -j DROP
                iptables -A INPUT -p tcp --dport 80 -m string --string "Wget" --algo bm -j DROP
                echo -e "${GREEN}✓ Bad bots blocked${NC}"
                sleep 2
                ;;
            4) 
                iptables -A INPUT -p tcp --dport 80 -m string --string "nikto" --algo bm -j DROP
                iptables -A INPUT -p tcp --dport 80 -m string --string "nmap" --algo bm -j DROP
                echo -e "${GREEN}✓ Attack tools blocked${NC}"
                sleep 2
                ;;
            5) 
                iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 20 -j DROP
                echo -e "${GREEN}✓ Connection limiting enabled${NC}"
                sleep 2
                ;;
            6) 
                iptables -A INPUT -p tcp --dport 80 -m string --string "union" --algo bm -j DROP
                iptables -A INPUT -p tcp --dport 80 -m string --string "select" --algo bm -j DROP
                echo -e "${GREEN}✓ SQL injection protection enabled${NC}"
                sleep 2
                ;;
            7) 
                iptables -A INPUT -p tcp --dport 80 -m string --string "<script" --algo bm -j DROP
                echo -e "${GREEN}✓ XSS protection enabled${NC}"
                sleep 2
                ;;
            8) 
                echo -e "${GOLD}HTTP Traffic Statistics:${NC}"
                iptables -L INPUT -n -v | grep -E ":80|:443"
                echo ""
                read -p "Press Enter to continue"
                ;;
            0) break ;;
        esac
    done
}

fail2ban_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}  ${GREEN}🔒 FAIL2BAN INTEGRATION${NC}                         ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        if systemctl is-active --quiet fail2ban; then
            echo -e "  ${GREEN}✓ Fail2ban is ACTIVE${NC}"
            echo -e "  ${GRAY}Currently banned:${NC} $(fail2ban-client banned 2>/dev/null | wc -l) IPs"
        else
            echo -e "  ${RED}✗ Fail2ban is INACTIVE${NC}"
        fi
        echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${PURPLE}[1]${NC} Install & Configure Fail2ban"
        echo -e "  ${PURPLE}[2]${NC} Start/Enable Fail2ban"
        echo -e "  ${PURPLE}[3]${NC} Stop/Disable Fail2ban"
        echo -e "  ${PURPLE}[4]${NC} Show Banned IPs"
        echo -e "  ${PURPLE}[5]${NC} Unban IP"
        echo -e "  ${PURPLE}[6]${NC} Configure SSH Protection"
        echo -e "  ${PURPLE}[7]${NC} Configure Web Protection"
        echo -e "  ${PURPLE}[8]${NC} View Fail2ban Log"
        echo -e "  ${PURPLE}[0]${NC} Back"
        echo -ne "\n  ${CYAN}λ${NC} ${WHITE}Fail2ban Choice:${NC} "
        read opt
        case $opt in
            1) 
                apt-get update
                apt-get install -y fail2ban
                cat > $FAIL2BAN_JAIL << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[apache-auth]
enabled = true
logpath = /var/log/apache2/error.log

[nginx-http-auth]
enabled = true
logpath = /var/log/nginx/error.log
EOF
                systemctl enable --now fail2ban
                echo -e "${GREEN}✓ Fail2ban installed and configured${NC}"
                sleep 2
                ;;
            2) 
                systemctl enable --now fail2ban
                echo -e "${GREEN}✓ Fail2ban started${NC}"
                sleep 2
                ;;
            3) 
                systemctl disable --now fail2ban
                echo -e "${GREEN}✓ Fail2ban stopped${NC}"
                sleep 2
                ;;
            4) 
                fail2ban-client status
                fail2ban-client banned
                read -p "Press Enter to continue"
                ;;
            5) 
                read -p "Enter IP to unban: " ip
                fail2ban-client set sshd unbanip $ip
                echo -e "${GREEN}✓ IP $ip unbanned${NC}"
                sleep 2
                ;;
            6) 
                echo -e "${GOLD}Configuring SSH protection...${NC}"
                fail2ban-client set sshd enabled true
                fail2ban-client set sshd maxretry 3
                echo -e "${GREEN}✓ SSH protection configured${NC}"
                sleep 2
                ;;
            7) 
                echo -e "${GOLD}Configuring web protection...${NC}"
                fail2ban-client set apache-auth enabled true
                fail2ban-client set nginx-http-auth enabled true
                echo -e "${GREEN}✓ Web protection configured${NC}"
                sleep 2
                ;;
            8) 
                tail -f /var/log/fail2ban.log
                ;;
            0) break ;;
        esac
    done
}

# --- MAIN DASHBOARD ---
check_root

while true; do
    clear
    show_header
    
    HOST=$(hostname)
    IP=$(curl -s --max-time 2 ifconfig.me || curl -s --max-time 2 icanhazip.com || echo "Offline")
    FW_ACTIVE=$(detect_firewall)
    UPTIME=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    LOAD=$(uptime | awk -F'load average:' '{print $2}')

    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}🛡️  ULTIMATE FIREWALL SUITE${NC} ${GRAY}v8.0${NC}       ${GRAY}$(date +"%H:%M:%S")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────────────────────┤${NC}"
    
    echo -e "  ${CYAN}SYSTEM STATUS${NC}"
    echo -e "  ${GRAY}├─ Firewall :${NC} ${GOLD}$FW_ACTIVE${NC}"
    echo -e "  ${GRAY}├─ IP       :${NC} ${WHITE}$IP${NC}"
    echo -e "  ${GRAY}├─ Hostname :${NC} ${WHITE}$HOST${NC}"
    echo -e "  ${GRAY}├─ Uptime   :${NC} ${WHITE}$UPTIME${NC}"
    echo -e "  ${GRAY}└─ Load     :${NC} ${WHITE}$LOAD${NC}"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"

    echo -e "  ${PURPLE}[1]${NC} ${WHITE}UFW Management${NC}        ${GRAY}(Simple & Fast)${NC}"
    echo -e "  ${PURPLE}[2]${NC} ${WHITE}IPTables Security${NC}     ${GRAY}(Pro/Advanced)${NC}"
    echo -e "  ${PURPLE}[3]${NC} ${WHITE}Firewalld${NC}             ${GRAY}(CentOS/RHEL Style)${NC}"
    echo -e "  ${PURPLE}[4]${NC} ${WHITE}HTTP Web Filter${NC}       ${GRAY}(Layer 7 Blocking)${NC}"
    echo -e "  ${PURPLE}[5]${NC} ${GREEN}Fail2ban Integration${NC}  ${GRAY}(Brute-force Shield)${NC}"
    echo -e "  ${PURPLE}[6]${NC} ${WHITE}View Firewall Status${NC}  ${GRAY}(Current Rules)${NC}"
    echo -e "  ${PURPLE}[7]${NC} ${WHITE}Network Statistics${NC}    ${GRAY}(Traffic Analysis)${NC}"
    echo -e "  ${PURPLE}[0]${NC} ${GRAY}Exit Manager${NC}"
    echo ""
    echo -ne "  ${CYAN}λ${NC} ${WHITE}Action:${NC} "
    read main

    case $main in
        1) ufw_menu ;;
        2) iptables_menu ;;
        3) firewalld_menu ;;
        4) http_menu ;;
        5) fail2ban_menu ;;
        6) 
            clear
            echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
            echo -e "${PURPLE}│${NC}  ${CYAN}📊 CURRENT FIREWALL STATUS${NC}                     ${PURPLE}│${NC}"
            echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
            iptables -L -n -v | head -n 30
            echo ""
            read -p "Press Enter to continue"
            ;;
        7) 
            clear
            echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
            echo -e "${PURPLE}│${NC}  ${CYAN}📈 NETWORK STATISTICS${NC}                          ${PURPLE}│${NC}"
            echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
            netstat -i
            echo ""
            echo -e "${GOLD}Active Connections:${NC}"
            ss -tunap | head -n 20
            echo ""
            read -p "Press Enter to continue"
            ;;
        0) 
            clear
            echo -e "${GREEN}Thank you for using Ultimate Firewall Suite!${NC}"
            exit 0 
            ;;
    esac
done
