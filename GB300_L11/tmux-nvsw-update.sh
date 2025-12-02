#!/bin/bash
set -Eeuo pipefail

# ===== 基本參數 =====
SESSION_NAME="nvsw_update_$(date +%Y%m%d_%H%M%S)"

# 目標 Switch 登入
NVFW_USER="admin"
NVSW_PASS="Admin1@admin"   # ← 這個變數名才是正確的

# 來源 SCP 伺服器
SCP_USER='scpuser'
SCP_PASS='scpuser'
SCP_HOST='192.168.0.1'
SCP_PATH='/home/scpuser/SwitchTray/nvsw_110'   # 不要結尾再加 '/'

# 檔名（確定與 SCP_PATH 底下實際存在一致）
BMC_FILE='nvfw_GB200-P4978_0004_250608.1.0_prod-signed.fwpkg'
BIOS_FILE='nvfw_GB200-P4978_0006_250710.1.1_prod-signed.fwpkg'
CPLD_FILE='CPLD_Prod_000370_REV0600_000377_REV1300_000373_REV1000_000390_REV0400_80728430_image.bin'
NVOS_FILE='nvos-amd64-25.02.2344.bin'          # ← 修正拼字

# ===== 視窗/Pane 設定 =====
read -rp "Enter number of panes per window (e.g. 4, 9): " MAX_PANES
if ! [[ "$MAX_PANES" =~ ^[0-9]+$ ]] || (( MAX_PANES <= 0 )); then
  echo "Invalid number. Exiting."
  exit 1
fi

# ===== 讀取 IP 清單（只取每行第一欄） =====
if [[ ! -f nvos_ip.txt ]]; then
  echo "Error: nvos_ip.txt not found!"
  exit 1
fi
mapfile -t hosts < <(awk '{print $1}' nvos_ip.txt | sed '/^$/d')
if [[ ${#hosts[@]} -eq 0 ]]; then
  echo "Error: No IPs found in nvos_ip.txt"
  exit 1
fi

# ===== tmux session 準備 =====
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
tmux new-session -d -s "$SESSION_NAME" -n "win_0"

echo "[INFO] tmux session: $SESSION_NAME"

# ===== 產生每台機器要跑的指令 =====
generate_tmux_command() {
  local ip=$1
  cat <<'EOSWITCH' | sed "s/__IP__/$ip/g; s#__SCP_PATH__#$SCP_PATH#g; s#__SCP_HOST__#$SCP_HOST#g; s/__SCP_USER__/$SCP_USER/g; s/__SCP_PASS__/$SCP_PASS/g; s/__BMC_FILE__/$BMC_FILE/g; s/__BIOS_FILE__/$BIOS_FILE/g; s/__CPLD_FILE__/$CPLD_FILE/g; s/__NVOS_FILE__/$NVOS_FILE/g;"
sshpass -p "__NVSW_PASS__" ssh -o StrictHostKeyChecking=no __NVFW_USER__@__IP__ '
set -Eeuo pipefail

echo "== __IP__ =="
nv show system info || true

# 1) 取回 & 安裝 BMC/FPGA/EROT 同包（依你的習慣用 echo N；若需自動確認用 y）
nv action fetch platform firmware BMC  scp://__SCP_USER__:%21__SCP_PASS__@__SCP_HOST____SCP_PATH__/__BMC_FILE__
echo N | nv action install platform firmware BMC  files __BMC_FILE__
echo N | nv action install platform firmware FPGA files __BMC_FILE__
echo N | nv action install platform firmware EROT files __BMC_FILE__

# 2) BIOS
nv action fetch platform firmware BIOS scp://__SCP_USER__:%21__SCP_PASS__@__SCP_HOST____SCP_PATH__/__BIOS_FILE__
echo N | nv action install platform firmware BIOS files __BIOS_FILE__

# 3) CPLD
nv action fetch platform firmware CPLD1 scp://__SCP_USER__:%21__SCP_PASS__@__SCP_HOST____SCP_PATH__/__CPLD_FILE__
echo N | nv action install platform firmware CPLD1 files __CPLD_FILE__

# 4) NVOS System Image
nv action fetch system image scp://__SCP_USER__:%21__SCP_PASS__@__SCP_HOST____SCP_PATH__/__NVOS_FILE__
nv action uninstall system image || true
echo y | nv action install system image files __NVOS_FILE__
nv show system image

echo "== __IP__ done =="
'
EOSWITCH
}

# 將需要替換的變數值放進 sed 使用（避免 HereDoc 內被本機殼展開）
export SCP_PATH SCP_HOST SCP_USER SCP_PASS BMC_FILE BIOS_FILE CPLD_FILE NVOS_FILE
export NVSW_PASS NVFW_USER

# ===== 佈局並送入指令 =====
current_window=0
current_pane=0

for ip in "${hosts[@]}"; do
  pane_cmd=$(generate_tmux_command "$ip")
  # 補上密碼、使用者（避免 HereDoc 內字面字串）
  pane_cmd="${pane_cmd/__NVSW_PASS__/$NVSW_PASS}"
  pane_cmd="${pane_cmd/__NVFW_USER__/$NVFW_USER}"

  if (( current_window == 0 && current_pane == 0 )); then
    tmux send-keys -t "${SESSION_NAME}:${current_window}" "$pane_cmd" C-m
  elif (( current_pane == 0 )); then
    tmux new-window -t "$SESSION_NAME" -n "win_${current_window}"
    tmux send-keys -t "${SESSION_NAME}:${current_window}" "$pane_cmd" C-m
  else
    tmux split-window -t "${SESSION_NAME}:${current_window}" -h
    tmux select-layout -t "${SESSION_NAME}:${current_window}" tiled
    tmux send-keys -t "${SESSION_NAME}:${current_window}" "$pane_cmd" C-m
  fi

  ((current_pane++))
  if (( current_pane >= MAX_PANES )); then
    current_pane=0
    ((current_window++))
  fi
done

tmux select-layout -t "$SESSION_NAME" tiled
tmux attach -t "$SESSION_NAME"
