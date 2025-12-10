#!/usr/bin/env bash
set -euo pipefail

EXPORT_DIR=/srv/nfs_share
EXPORTS=/etc/exports

echo "[*] 建立 NFS 分享目錄 $EXPORT_DIR ..."
sudo mkdir -p "$EXPORT_DIR"
sudo chown nobody:nogroup "$EXPORT_DIR"

echo "[*] 新增 NFS export 設定 (192.168.100.0/24 可讀寫)..."
LINE="$EXPORT_DIR 192.168.100.0/24(rw,sync,no_subtree_check,no_root_squash)"
if ! grep -q "^$LINE" "$EXPORTS" 2>/dev/null; then
  echo "$LINE" | sudo tee -a "$EXPORTS"
fi

echo "[*] 重新載入 NFS 設定..."
sudo exportfs -ra
sudo systemctl enable nfs-server || sudo systemctl enable nfs-kernel-server || true
sudo systemctl restart nfs-server || sudo systemctl restart nfs-kernel-server
sudo systemctl status nfs-server --no-pager || sudo systemctl status nfs-kernel-server --no-pager
