#!/usr/bin/env bash
# setup_cluster_ssh_trust.sh
# 目的：從任意節點執行，建立完整 SSH 互信，包括當前 client 自身

set -euo pipefail

PASS="abcdef"
IP_FILE="os_ip.txt"
TMP_DIR="/tmp/all_keys"

echo "------------------------------------------------------------"
echo "🤝 全自動 SSH 互信交換程序（含本機 client）"
echo "------------------------------------------------------------"

# === 0️⃣ 環境檢查 ===
if [[ ! -f "$IP_FILE" ]]; then
  echo "[X] 找不到 $IP_FILE，請確保該檔案存在於當前目錄。"
  exit 1
fi
if ! command -v sshpass >/dev/null 2>&1; then
  echo "[X] 未安裝 sshpass，請先安裝：apt install -y sshpass 或 yum install -y sshpass"
  exit 1
fi

mkdir -p "$TMP_DIR"
rm -f "$TMP_DIR"/*.pub "$TMP_DIR/authorized_keys" >/dev/null 2>&1 || true

# === 1️⃣ 各節點生成自己的公鑰 ===
echo "[1/6] 建立各節點的金鑰並收集公鑰..."
while IFS= read -r ip; do
  [[ -z "$ip" ]] && continue
  echo "  ↳ 生成 $ip 公鑰"
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@"$ip" "
    mkdir -p /root/.ssh && chmod 700 /root/.ssh
    if [[ ! -f /root/.ssh/id_rsa.pub ]]; then
      ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa >/dev/null
    fi
    cat /root/.ssh/id_rsa.pub
  " > "$TMP_DIR/$ip.pub" < /dev/null
done < "$IP_FILE"

# === 2️⃣ 加入 client 自身的金鑰 ===
echo "[2/6] 檢查並加入本機 client 的金鑰..."
if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
  echo "  ↳ 本機未有金鑰，正在生成..."
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa >/dev/null
fi
cp ~/.ssh/id_rsa.pub "$TMP_DIR/client_$(hostname).pub"
echo "  ↳ 已加入 $(hostname) 公鑰"

# === 3️⃣ 合併所有公鑰 ===
echo "[3/6] 合併所有公鑰..."
cat "$TMP_DIR"/*.pub | sort | uniq > "$TMP_DIR/authorized_keys"

# === 4️⃣ 發佈 authorized_keys 至所有節點 ===
echo "[4/6] 同步 authorized_keys 至所有節點..."
while IFS= read -r ip; do
  [[ -z "$ip" ]] && continue
  echo "  → 部署 $ip"
  sshpass -p "$PASS" scp -q -o StrictHostKeyChecking=no "$TMP_DIR/authorized_keys" root@"$ip":/root/.ssh/authorized_keys < /dev/null
  sshpass -p "$PASS" ssh -n -o StrictHostKeyChecking=no root@"$ip" "
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    grep -q '^PasswordAuthentication' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
    systemctl restart ssh || systemctl restart sshd
  " < /dev/null
done < "$IP_FILE"

# === 5️⃣ 建立 known_hosts（fingerprint 信任）===
echo "[5/6] 建立所有節點 fingerprint（known_hosts）..."
SCRIPT_DIR=$(pwd)
IP_LIST=$(cat "$IP_FILE")

while IFS= read -r ip1; do
  [[ -z "$ip1" ]] && continue
  echo "  ↳ $ip1 掃描 fingerprint"
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@"$ip1" bash -s <<EOF
    set -e
    mkdir -p /root/.ssh
    rm -f /root/.ssh/known_hosts
    touch /root/.ssh/known_hosts
$(for ip2 in $IP_LIST; do
  echo "    ssh-keyscan -H $ip2 >> /root/.ssh/known_hosts 2>/dev/null"
done)
EOF
done < "$IP_FILE"

# === 6️⃣ 驗證免密登入（包含 client）===
echo "[6/6] 驗證免密登入..."
fail=0
for ip in $(cat "$IP_FILE"); do
  if ssh -o BatchMode=yes -o ConnectTimeout=2 root@"$ip" "hostname" >/dev/null 2>&1; then
    echo "  ✅ $ip"
  else
    echo "  ❌ $ip"
    ((fail++))
  fi
done

echo "------------------------------------------------------------"
if ((fail==0)); then
  echo "🎉 全部節點 + client 互信 + fingerprint 已完成"
else
  echo "⚠️ 有節點未成功，請檢查網路或密碼"
fi
echo "------------------------------------------------------------"
