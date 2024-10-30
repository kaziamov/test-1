include .env

install-vpn:
	@echo "Installing WireGuard"
	@sudo apt-get update -y
	@sudo apt-get install -y wireguard
	@echo "WireGuard installed"

generate_server_config_from_env:
	@echo "Generating server configuration"
	@wg genkey | tee server_privatekey | wg server_pubkey > publickey
	@touch server.conf
	@echo "[Interface]" > server.conf
	@echo "PrivateKey = `cat server_privatekey`" >> server.conf
	@echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE " >> server.conf
	@echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" >> server.conf
	@echo "Address = ${ADDRESS}" >> server.conf
	@echo "ListenPort = ${PORT}" >> server.conf
	@echo "Configuration generated"
	@sudo cp server.conf /etc/wireguard/wg0.conf

setup_forwarding:
	@sudo sh set_forwarding.sh
	@echo "Forwarding setup updated"
	@sudo sysctl -p

enable_autostart:
	@sudo systemctl enable wg-quick@wg0.service
	@echo "Autostart enabled"

restart_vpn:
	@sudo systemctl restart wg-quick@wg0.service

start_vpn:
	@sudo systemctl start wg-quick@wg0.service
	@echo "VPN started"

check_status:
	@sudo systemctl status wg-quick@wg0.service


magic: install-vpn generate_server_config_from_env setup_forwarding enable_autostart generate_client_config_from_env start_vpn
	@echo "VPN was installed and configured"


generate_client_config_from_env:
	@echo "Generating client configuration"
	# Generate client keys by name
	@wg genkey | tee client_privatekey | wg pubkey > client_publickey
	@touch client.conf
	@echo "[Interface]" > client.conf
	@echo "PrivateKey = `cat client_privatekey`" >> client.conf
	@echo "Address = ${CLIENT1_ADDRESS}" >> client.conf
	@echo "DNS = ${DNS}" >> client.conf
	@echo "" >> client.conf
	@echo "[Peer]" >> client.conf
	@echo "PublicKey = `cat server_publickey`" >> client.conf
	@echo "Endpoint = ${PUBLIC_ADDRESS}:${PORT}" >> client.conf
	@echo "AllowedIPs = 0.0.0.0/0" >> client.conf
	@echo "PersistentKeepalive = 20" >> client.conf

	@echo "[Peer]" >> /etc/wireguard/wg0.conf
	@echo "PublicKey = `cat client_publickey`" >> /etc/wireguard/wg0.conf
	@echo "AllowedIPs = ${CLIENT1_ADDRESS}" >> /etc/wireguard/wg0.conf

	@echo "Generating client configuration done"
