#!/usr/bin/env bash
set -euo pipefail

SHARE_DIR=/srv/smb_share
SMB_CONF=/etc/samba/smb.conf

echo "[*] 建立 Samba 分享目錄 $SHARE_DIR ..."
sudo mkdir -p "$SHARE_DIR"
sudo chown -R "$USER:$USER" "$SHARE_DIR"

echo "[*] 備份原本的 smb.conf ..."
sudo cp "$SMB_CONF" "${SMB_CONF}.bak.$(date +%Y%m%d%H%M%S)"

echo "[*] 在 smb.conf 加入一個簡單的 share [bkshare] ..."
sudo tee -a "$SMB_CONF" >/dev/null << EOC

[bkshare]
   path = $SHARE_DIR
   browseable = yes
   read only = no
   guest ok = yes
EOC

echo "[*] 設定 SMB 使用者密碼 (請輸入兩次密碼)..."
sudo smbpasswd -a "$USER" || true

echo "[*] 重新啟動 smbd ..."
sudo systemctl enable smbd
sudo systemctl restart smbd
sudo systemctl status smbd --no-pager
