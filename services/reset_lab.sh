#!/usr/bin/env bash
set -euo pipefail

echo "[*] 停止相關服務..."
sudo systemctl stop isc-dhcp-server || true
sudo systemctl stop nginx || true
sudo systemctl stop vsftpd || true
sudo systemctl stop nfs-server || sudo systemctl stop nfs-kernel-server || true
sudo systemctl stop smbd || true

echo "[*] 清空 HTTP / NFS / SMB 的測試資料 (保留目錄本身)..."
sudo rm -rf /srv/http_root/* 2>/dev/null || true
sudo rm -rf /srv/nfs_share/* 2>/dev/null || true
sudo rm -rf /srv/smb_share/* 2>/dev/null || true

echo "[*] Reset 完成。若需要完全移除設定，請手動檢查："
echo "    /etc/dhcp/dhcpd.conf"
echo "    /etc/nginx/sites-available/default"
echo "    /etc/vsftpd.conf"
echo "    /etc/exports"
echo "    /etc/samba/smb.conf"
