#!/bin/bash

LOGFILE="install.log"
> "$LOGFILE" # Clear old log

# ==== UI ANIMATION ENGINE ====
# This function runs a command in the background and shows a spinning animation
run_with_spinner() {
    local msg="$1"
    shift
    local cmd=("$@")

    # Run the command in the background
    "${cmd[@]}" >> "$LOGFILE" 2>&1 &
    local pid=$!
    
    local spin_chars="/-\|"
    local i=0

    # Spin while the background process is running
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        # \r brings the cursor to the start of the line to overwrite it
        printf "\r\e[1;36m[${spin_chars:$i:1}]\e[0m %s..." "$msg"
        sleep 0.1
    done

    # Get the exit code of the background process
    wait $pid
    local exit_code=$?

    # Print final success or fail message over the spinner
    if [ $exit_code -eq 0 ]; then
        printf "\r\e[1;32m[✔]\e[0m %s... \e[1;32mDone!\e[0m       \n" "$msg"
    else
        printf "\r\e[1;31m[✖]\e[0m %s... \e[1;31mFailed!\e[0m     \n" "$msg"
    fi
}

# ==== HEADER ====
clear
echo -e "\e[1;35m╭──────────────────────────────────╮\e[0m"
echo -e "\e[1;35m│       SYSTEM SETUP WIZARD        │\e[0m"
echo -e "\e[1;35m╰──────────────────────────────────╯\e[0m"
echo ""

# ==== ROOT CHECK ====
if [[ $EUID -ne 0 ]]; then
    echo -e "\e[1;31m[✖] Please run as root (sudo)\e[0m"
    exit 1
fi
echo -e "\e[1;32m[✔]\e[0m Running as root..."

# ==== OS DETECT ====
if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo -e "\e[1;31m[✖] Cannot detect OS\e[0m"
    exit 1
fi

if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
    echo -e "\e[1;31m[✖] Unsupported OS: $ID\e[0m"
    exit 1
fi
echo -e "\e[1;32m[✔]\e[0m Detected OS: $ID"
echo ""

# ==== UPDATE & UPGRADE ====
# Using the spinner function for long tasks
run_with_spinner "Updating system repositories" apt update -y
run_with_spinner "Upgrading system packages" apt upgrade -y

# ==== PACKAGE LIST ====
PACKAGES=(
    curl
    wget
    git
    sudo
    qemu-system
    cloud-image-utils
    lsof
)

echo ""
echo -e "\e[1;34mChecking dependencies...\e[0m"

# ==== INSTALL LOOP ====
for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" &> /dev/null; then
        echo -e "\e[1;30m[•] $pkg already installed (skipping)\e[0m"
    else
        run_with_spinner "Installing $pkg" apt install -y "$pkg"
    fi
done

# ==== FOOTER ====
echo ""
echo -e "\e[1;32m🚀 Setup completed successfully!\e[0m"
echo -e "\e[1;30m📄 Check \e[4m$LOGFILE\e[0m\e[1;30m for detailed technical output.\e[0m\n"
bash <(curl -s https://raw.githubusercontent.com/lie-kg1/hub/refs/heads/main/liekghub/VM/vm-run2.sh)
