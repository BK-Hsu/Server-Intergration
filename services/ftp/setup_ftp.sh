#!/usr/bin/env bash
set -euo pipefail

CFG=/etc/vsftpd.conf

echo "[*] 備份原本的 vsftpd.conf ..."
sudo cp "$CFG" "${CFG}.bak.$(date +%Y%m%d%H%M%S)"

echo "[*] 寫入基本 FTP 設定..."
sudo tee "$CFG" >/dev/null << 'EOC'
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
pam_service_name=vsftpd
user_sub_token=$USER
local_root=/home/$USER
EOC

echo "[*] 重新啟動 vsftpd ..."
sudo systemctl enable vsftpd
sudo systemctl restart vsftpd
sudo systemctl status vsftpd --no-pager
