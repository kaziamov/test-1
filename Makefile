ADDRESS = 10.0.0.1/24
PORT = 51830

PUBLIC_ADDRESS = 192.168.4.31
DNS = 8.8.8.8


install-vpn:
	@echo "Installing WireGuard"
	@sudo apt-get update -y
	@sudo apt-get install -y wireguard
	@echo "WireGuard installed"

generate_server_config_from_env:
	@echo "Generating server configuration"
	@wg genkey | tee privatekey | wg pubkey > publickey
	@touch server.conf
	@echo "[Interface]" > server.conf
	@echo "PrivateKey = `cat privatekey`" >> server.conf
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

setup_autostart:
	@sudo systemctl enable wg-quick@wg0.service
	@echo "Autostart enabled"

start_vpn:
	@sudo systemctl start wg-quick@wg0.service
	@echo "VPN started"

check_status:
	@sudo systemctl status wg-quick@wg0.service


make-magic: install-vpn generate_server_config_from_env setup_forwarding setup_autostart
	@echo "VPN was installed and configured"


# Client configuration
# [Interface]
# PrivateKey = <CLIENT-PRIVATE-KEY> #Клиентский приватный ключ. В нашем случае katkov_privetkey.
# Address = 10.0.0.2/32 #IP-адрес клиента, который настроен на WG сервере
# DNS = 8.8.8.8 #DNS, который будет использовать при подключении

# [Peer]
# PublicKey = <SERVER-PUBKEY> #Публичный ключ сервера
# Endpoint = <SERVER-IP>:51830 #IP адрес удалённого сервера и порт прослушивания
# AllowedIPs = 0.0.0.0/0 #Если указаны все нули — весь трафик клиента будет проходить через WG сервер
# PersistentKeepalive = 20 #Интервал проверки соединения между клиентом и сервером (сек).

generate_client_config_from_env:
	@echo "Generating client configuration"
	# Generate client keys by name
	@wg genkey | tee client_privatekey | wg pubkey > client_publickey
	@touch client.conf
	@echo "[Interface]" > client.conf
	@echo "PrivateKey = `cat client_privatekey`" >> client.conf
	@echo "Address = ${ADDRESS}" >> client.conf
	@echo "DNS = ${DNS}" >> client.conf
	@echo "" >> client.conf
	@echo "[Peer]" >> client.conf
	@echo "PublicKey = `cat client_publickey`" >> client.conf
	@echo "Endpoint = ${ADDRESS}:${PORT}" >> client.conf
	@echo "AllowedIPs = 0.0.0.0/0" >> client.conf
	@echo "PersistentKeepalive = 20" >> client.conf
	@echo "Generating client configuration done"
