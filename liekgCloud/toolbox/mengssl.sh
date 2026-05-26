#!/bin/bash

DIR="/etc/nginx/sites-available"

# colors
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'

show_sites() {

echo -e "${C}╔════════════════════════════════════╗${NC}"
echo -e "${C}║         NGINX SSL SITES            ║${NC}"
echo -e "${C}╚════════════════════════════════════╝${NC}"

i=1
for f in $DIR/*.conf; do
    [ -e "$f" ] || { echo -e "${R}No sites found${NC}"; return; }

    name=$(basename "$f")
    echo -e "${Y}$i${NC}) ${G}$name${NC}"

    arr[$i]=$f
    ((i++))
done

}

while true
do

clear

echo -e "${B}╔════════════════════════════════════╗${NC}"
echo -e "${B}║          SSL PANEL MENU            ║${NC}"
echo -e "${B}╚════════════════════════════════════╝${NC}"

count=$(ls $DIR/*.conf 2>/dev/null | wc -l)

echo -e "${W}Total Sites:${NC} ${G}$count${NC}"

show_sites

echo ""
echo -e "${C}════════ MENU ════════${NC}"

echo -e "${G}1${NC}) Create SSL Panel"
echo -e "${G}2${NC}) Manage Panel"
echo -e "${G}3${NC}) Delete Panel"
echo -e "${G}4${NC}) Edit Panel"
echo -e "${R}0${NC}) Exit"

echo -e "${C}══════════════════════${NC}"

read -p "Select option: " opt

case $opt in

1)
bash <(curl -s https://raw.githubusercontent.com/lie-kg1/hub/refs/heads/main/liekgCloud/toolbox/cssl.sh)
read -p "Press enter..."
;;

2)

show_sites
read -p "Select site number: " num
file=${arr[$num]}

echo ""
echo -e "${G}1${NC}) Start"
echo -e "${G}2${NC}) Stop"
echo -e "${G}3${NC}) Restart"
echo -e "${G}4${NC}) Enable"
echo -e "${G}5${NC}) Disable"

read -p "Choose: " m

case $m in
1) systemctl start nginx ;;
2) systemctl stop nginx ;;
3) systemctl restart nginx ;;
4) systemctl enable nginx ;;
5) systemctl disable nginx ;;
esac

;;

3)

show_sites
read -p "Select site number to delete: " num
rm -f ${arr[$num]}
rm -f /etc/nginx/sites-available/${arr[$num]}
rm -f /etc/nginx/sites-enabled/${arr[$num]}
nginx -t && systemctl reload nginx
echo -e "${R}Site deleted${NC}"
sleep 1
;;

4)

show_sites
read -p "Select site number to edit: " num
nano ${arr[$num]}
;;

0)
exit
;;

*)
echo -e "${R}Invalid option${NC}"
sleep 1
;;

esac

done
