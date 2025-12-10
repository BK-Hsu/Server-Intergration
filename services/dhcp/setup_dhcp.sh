#!/usr/bin/env bash
set -euo pipefail

CFG=/etc/dhcp/dhcpd.conf
INTF_FILE=/etc/default/isc-dhcp-server

echo "[*] 設定 DHCP 介面 (請依實際 NIC 名稱修改 INTERFACESv4)..."
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' "$INTF_FILE" || true

echo "[*] 寫入簡易 DHCP 設定到 $CFG ..."
sudo tee "$CFG" >/dev/null << 'EOC'
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.100.0 netmask 255.255.255.0 {
  range 192.168.100.100 192.168.100.200;
  option routers 192.168.100.1;
  option subnet-mask 255.255.255.0;
  option domain-name-servers 8.8.8.8, 1.1.1.1;
}
EOC

echo "[*] 重新啟動 DHCP 服務..."
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server --no-pager
