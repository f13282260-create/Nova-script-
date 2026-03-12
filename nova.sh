#!/bin/bash

BLUE="\033[1;34m"
RESET="\033[0m"

clear

echo -e "${BLUE}"
echo "==============================================="
echo "        Nova Cloud Official Script"
echo "==============================================="
echo -e "${RESET}"

echo "1) Install Pterodactyl Panel"
echo "2) Install Wings"
echo "3) Install SSL Certificate"
echo "4) Exit"

read -p "Select an option: " option

# PANEL INSTALL
if [ "$option" == "1" ]; then
    read -p "Enter Panel Domain: " DOMAIN

    echo "Installing dependencies..."
    apt update -y
    apt install -y nginx mysql-server curl tar unzip git

    echo "Downloading panel..."
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz

    echo "Panel files installed."

    echo "Creating admin user..."
    php artisan p:user:make

fi

# WINGS INSTALL
if [ "$option" == "2" ]; then

    echo "Installing Docker..."
    curl -sSL https://get.docker.com | sh

    echo "Installing Wings..."
    curl -L https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 -o /usr/local/bin/wings

    chmod +x /usr/local/bin/wings

    mkdir -p /etc/pterodactyl

    echo "Installing service..."

cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable wings

    echo "Wings installed."

fi

# SSL INSTALL
if [ "$option" == "3" ]; then

    read -p "Enter Domain for SSL: " DOMAIN

    apt install certbot python3-certbot-nginx -y

    certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN

fi
