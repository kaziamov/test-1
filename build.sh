sudo apt update -y && sudo apt upgrade -y
sudo apt install -y wireguard
cd /etc/wireguard/
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey

