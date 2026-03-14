#!/bin/bash

# root check
if [ "$EUID" -ne 0 ]; then
  echo "Run this script as root (sudo)"
  exit
fi

# colors
BLUE="\033[1;34m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RESET="\033[0m"

banner() {
clear
echo -e "$BLUE"

cat << "EOF

echo "======================================"

███╗   ██╗ ██████╗ ██╗   ██╗ █████╗
████╗  ██║██╔═══██╗██║   ██║██╔══██╗
██╔██╗ ██║██║   ██║██║   ██║███████║
██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║
██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║
╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝

echo "======================================"

       Nova Cloud Official Installer

EOF

echo -e "$RESET"
}

menu() {
echo -e "$RED"
echo "=================================="
echo -e "$BLUE"
echo " 1) Install Panel"
echo " 2) Install Wings"
echo " 3) Install SSL Certificate"
echo " 4) Install Cloudflare Tunnel"
echo " 5) Exit"
echo -e "$RED"
echo "=================================="
}

install_panel() {

echo -e "${CYAN}Installing panel dependencies...${RESET}"

apt update -y
apt install -y nginx mysql-server curl tar unzip git php php-cli php-fpm php-mysql php-zip php-gd php-mbstring php-curl php-xml composer

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz

tar -xzvf panel.tar.gz

cp .env.example .env

composer install --no-dev --optimize-autoloader

php artisan key:generate --force

echo -e "${GREEN}Create admin user:${RESET}"

php artisan p:user:make

echo -e "${GREEN}Panel installation finished.${RESET}"
}

install_wings() {

echo -e "${CYAN}Installing Docker...${RESET}"

curl -sSL https://get.docker.com | sh

systemctl enable docker
systemctl start docker

echo -e "${CYAN}Installing Wings...${RESET}"

curl -L https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 -o /usr/local/bin/wings

chmod +x /usr/local/bin/wings

mkdir -p /etc/pterodactyl

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

echo "Paste your node config now"

nano /etc/pterodactyl/config.yml

systemctl start wings

echo -e "${GREEN}Wings installed successfully.${RESET}"
}

install_ssl() {

read -p "Enter your domain: " DOMAIN

apt install certbot python3-certbot-nginx -y

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

echo -e "${GREEN}SSL installed successfully.${RESET}"
}

install_tunnel() {

echo "1) Connect using token"
echo "2) Run full command"

read -p "Select option: " cf

curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared

chmod +x /usr/local/bin/cloudflared

if [ "$cf" == "1" ]; then

read -p "Enter Cloudflare Tunnel Token: " TOKEN

cloudflared service install $TOKEN

systemctl enable cloudflared
systemctl start cloudflared

fi

if [ "$cf" == "2" ]; then

read -p "Paste full tunnel command: " CMD

$CMD

fi

echo -e "${GREEN}Cloudflare tunnel connected.${RESET}"
}

while true
do

banner
menu

read -p "Select an option: " option

case $option in

1)
install_panel
;;

2)
install_wings
;;

3)
install_ssl
;;

4)
install_tunnel
;;

5)
exit
;;

*)
echo "Invalid option"
;;

esac

read -p "Press Enter to continue..."

done
