#!/usr/bin/env bash

set -e

echo "===== Ubuntu Server Installer ====="

# Detect OS
. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
    echo "Error: This script supports Ubuntu only."
    exit 1
fi

echo "Detected Ubuntu: $VERSION_CODENAME"

# Fix apt issues
echo "Fixing APT issues..."

rm -f /var/lib/dpkg/lock-frontend || true
rm -f /var/lib/apt/lists/lock || true
rm -f /var/cache/apt/archives/lock || true

dpkg --configure -a || true
apt --fix-broken install -y || true

# Update system
apt update -y

# Install base packages
apt install -y \
software-properties-common \
curl \
apt-transport-https \
ca-certificates \
gnupg \
lsb-release

# Add PHP PPA
echo "Adding PHP repository..."
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

# Add Redis repo
echo "Adding Redis repository..."

curl -fsSL https://packages.redis.io/gpg | gpg --dearmor \
-o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/redis.list

# Update again
apt update -y

# Install server stack
echo "Installing server packages..."

apt install -y \
php8.3 \
php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} \
mariadb-server \
nginx \
git \
redis-server

# Enable services
systemctl enable nginx
systemctl enable mariadb
systemctl enable redis-server
systemctl enable php8.3-fpm

systemctl start nginx
systemctl start mariadb
systemctl start redis-server
systemctl start php8.3-fpm

echo ""
echo "----------------------------------"
echo "Installation Complete 🚀"
echo "Stack Installed:"
echo "Nginx + PHP 8.3 + MariaDB + Redis"
echo "Ubuntu Supported:"
echo "20 / 22 / 24 / 25"
echo "Web root: /var/www/html"
echo "----------------------------------"
