#!/bin/bash

# Root check
if [ "$EUID" -ne 0 ]; then
echo "Please run as root"
exit
fi

# Colors
BLUE="\033[1;34m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RESET="\033[0m"

banner(){
clear
echo -e "$BLUE"
cat << "EOF"

███╗   ██╗ ██████╗ ██╗   ██╗ █████╗
████╗  ██║██╔═══██╗██║   ██║██╔══██╗
██╔██╗ ██║██║   ██║██║   ██║███████║
██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║
██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║
╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝

     Nova Cloud Official Installer

EOF
echo -e "$RESET"
}

menu(){
echo "================================"
echo "1) Install Panel"
echo "2) Install Wings"
echo "3) Install SSL"
echo "4) Install Cloudflare Tunnel"
echo "5) Exit"
echo "================================"
}

install_panel(){

echo -e "${CYAN}Installing Panel...${RESET}"

apt update -y
apt install -y nginx mysql-server curl tar unzip git php php-cli php-fpm php-mysql php-zip php-gd php-mbstring php-curl php-xml composer

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz

tar -xzvf panel.tar.gz

cp .env.example .env

composer install --no-dev --optimize-autoloader

php artisan key:generate --force

echo "Create admin user"

php artisan p:user:make

echo -e "${GREEN}Panel Installed${RESET}"
}

install_wings(){

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

echo "Go To Admin/Nodes then go to your node/configuration then click on generate token copy panel link and token and also check the node id"

sudo wings configure

systemctl start wings

echo -e "${GREEN}Wings Installed${RESET}"
}

install_ssl(){

read -p "Enter domain: " DOMAIN

apt install -y certbot python3-certbot-nginx

certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

echo -e "${GREEN}SSL Installed${RESET}"
}

install_tunnel(){

echo "1) Connect with Token"
echo "2) Run Full Command"

read -p "Select: " opt

curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared

chmod +x /usr/local/bin/cloudflared

if [ "$opt" == "1" ]; then

read -p "Enter Tunnel Token: " TOKEN

cloudflared service install $TOKEN

systemctl enable cloudflared
systemctl start cloudflared

fi

if [ "$opt" == "2" ]; then

read -p "Paste command: " CMD

$CMD

fi

echo -e "${GREEN}Cloudflare Tunnel Installed${RESET}"
}

while true
do

banner
menu

read -p "Select option: " choice

case $choice in

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
