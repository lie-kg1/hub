#!/usr/bin/env bash

set -e

echo "🔎 Detecting OS..."

if command -v apt >/dev/null 2>&1; then
    PM="apt"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
else
    echo "❌ Unsupported OS"
    exit 1
fi

install_pkg() {
    if [ "$PM" = "apt" ]; then
        apt update -y
        apt install -y "$@"
    else
        $PM install -y "$@"
    fi
}

echo "📦 Installing Redis..."
install_pkg redis-server || install_pkg redis

echo "📦 Installing MariaDB..."
install_pkg mariadb-server

echo "📦 Installing MySQL..."
install_pkg mysql-server || true

echo "🚀 Starting services..."

systemctl enable redis --now 2>/dev/null || systemctl enable redis-server --now
systemctl enable mariadb --now 2>/dev/null || true
systemctl enable mysql --now 2>/dev/null || true

echo "✅ Installation complete"
