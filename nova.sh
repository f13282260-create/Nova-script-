#!/bin/bash

# root check
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit
fi

# colors
BLUE="\033[1;34m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

while true
do

clear

echo -e "${BLUE}"

cat << "EOF"

███╗   ██╗ ██████╗ ██╗   ██╗ █████╗      ██████╗██╗      ██████╗ ██╗   ██╗██████╗ 
████╗  ██║██╔═══██╗██║   ██║██╔══██╗    ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
██╔██╗ ██║██║   ██║██║   ██║███████║    ██║     ██║     ██║   ██║██║   ██║██║  ██║
██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║    ██║     ██║     ██║   ██║██║   ██║██║  ██║
██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║    ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝     ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝

EOF

echo -e "${RESET}"
echo "================================================"
echo "        Nova Cloud Official Installer"
echo "================================================"
echo ""
echo "1) ${red}Install Pterodactyl Panel"
echo "2) Install Wings Node"
echo "3) Install SSL Certificate"
echo "4) Exit"
echo ""

read -p "Select an option: " option

# PANEL INSTALL
if [ "$option" == "1" ]; then

read -p "Enter Panel Domain: " DOMAIN

echo -e "${CYAN}Updating system...${RESET}"
apt update -y

echo -e "${CYAN}Installing dependencies...${RESET}"
apt install -y nginx mysql-server curl tar unzip git php php-cli php-fpm php-mysql php-zip php-gd php-mbstring php-curl php-xml composer

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

echo -e "${CYAN}Downloading panel...${RESET}"
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz

tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

cp .env.example .env

composer install --no-dev --optimize-autoloader

php artisan key:generate --force

echo -e "${GREEN}Create admin user:${RESET}"
php artisan p:user:make

echo -e "${GREEN}Panel installation finished.${RESET}"
read -p "Press enter to continue"

fi

# WINGS INSTALL
if [ "$option" == "2" ]; then

echo -e "${CYAN}Installing Docker...${RESET}"
curl -sSL https://get.docker.com | sh

systemctl enable docker
systemctl start docker

echo -e "${CYAN}Installing Wings...${RESET}"
curl -L https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 -o /usr/local/bin/wings

chmod +x /usr/local/bin/wings

mkdir -p /etc/pterodactyl

echo -e "${CYAN}Creating wings service...${RESET}"

cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
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

echo -e "${GREEN}Paste node config now:${RESET}"

nano /etc/pterodactyl/config.yml

systemctl start wings

echo -e "${GREEN}Wings installed successfully.${RESET}"

read -p "Press enter to continue"

fi

# SSL INSTALL
if [ "$option" == "3" ]; then

read -p "Enter Domain for SSL: " DOMAIN

echo -e "${CYAN}Installing Certbot...${RESET}"

apt install certbot python3-certbot-nginx -y

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

echo -e "${GREEN}SSL Installed Successfully.${RESET}"

read -p "Press enter to continue"

fi

# EXIT
if [ "$option" == "4" ]; then
exit
fi

done
