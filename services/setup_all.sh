#!/usr/bin/env bash
set -euo pipefail

echo "[*] 更新套件清單..."
sudo apt update

echo "[*] 安裝 DHCP / HTTP / FTP / NFS / SMB 相關套件..."
sudo apt install -y isc-dhcp-server nginx vsftpd nfs-kernel-server samba

echo
echo "[*] 套件安裝完成，請依序執行各服務的 setup："
echo "    services/dhcp/setup_dhcp.sh"
echo "    services/http/setup_http.sh"
echo "    services/ftp/setup_ftp.sh"
echo "    services/nfs/setup_nfs.sh"
echo "    services/smb/setup_smb.sh"
