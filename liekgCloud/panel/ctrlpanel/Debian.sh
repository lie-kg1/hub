#!/usr/bin/env bash

set -e

echo "----- Debian Universal Installer -----"

# Fix dpkg / apt locks
echo "Fixing package manager issues..."
rm -f /var/lib/dpkg/lock-frontend || true
rm -f /var/cache/apt/archives/lock || true
rm -f /var/lib/apt/lists/lock || true

dpkg --configure -a || true
apt --fix-broken install -y || true

# Detect Debian codename
if [ -f /etc/os-release ]; then
    . /etc/os-release
    CODENAME=$VERSION_CODENAME
else
    CODENAME=$(lsb_release -cs)
fi

echo "Detected Debian codename: $CODENAME"

# Fix Debian repository
echo "Setting Debian repositories..."

cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian $CODENAME main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $CODENAME-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
EOF

# Update system
echo "Updating system..."
apt clean
apt update -y

# Install base packages
echo "Installing base utilities..."
apt install -y \
curl \
wget \
gnupg \
ca-certificates \
apt-transport-https \
lsb-release

# Add PHP repository
echo "Adding PHP repo..."
mkdir -p /usr/share/keyrings

wget -qO /usr/share/keyrings/php.gpg https://packages.sury.org/php/apt.gpg || true

echo "deb [signed-by=/usr/share/keyrings/php.gpg] https://packages.sury.org/php $CODENAME main" \
> /etc/apt/sources.list.d/php.list

# Add Redis repo
echo "Adding Redis repo..."

curl -fsSL https://packages.redis.io/gpg | gpg --dearmor \
-o /usr/share/keyrings/redis.gpg || true

echo "deb [signed-by=/usr/share/keyrings/redis.gpg] https://packages.redis.io/deb $CODENAME main" \
> /etc/apt/sources.list.d/redis.list

# Update again
apt update -y || true

# Install server stack
echo "Installing Nginx + PHP + MariaDB + Redis..."

apt install -y \
nginx \
mariadb-server \
redis-server \
git \
php \
php-cli \
php-fpm \
php-mysql \
php-gd \
php-mbstring \
php-bcmath \
php-xml \
php-curl \
php-zip \
php-intl \
php-redis

# Enable services
echo "Starting services..."

systemctl enable nginx
systemctl enable mariadb
systemctl enable redis-server

systemctl start nginx
systemctl start mariadb
systemctl start redis-server

# Final fix
dpkg --configure -a || true
apt --fix-broken install -y || true

echo ""
echo "----------------------------------"
echo "Server installation complete 🚀"
echo "Installed:"
echo "Nginx + PHP + MariaDB + Redis"
echo "Web root: /var/www/html"
echo "Compatible: Debian 10 / 11 / 12 / 13"
echo "----------------------------------"
