#!/bin/bash
# Multi-host tmux monitor with optional custom command
# Examples:
#   ./test1.sh                 # default: top
#   ./test1.sh -m htop         # prefer htop
#   ./test1.sh -m batch        # non-interactive summary
#   ./test1.sh "ps -aux"       # RUN THIS on all hosts (highest priority)
#   ./test1.sh "nvidia-smi dmon -s pucm" -f hosts.txt -n 6

set -uo pipefail

### Defaults ###
HOSTFILE="os_ip.txt"
USER="root"
PASS="abcdef"
SESSION_BASE="monitor"
PANE_PER_WINDOW=9
MODE="top"

# ----- read optional custom command (highest priority) -----
CUSTOM_CMD=""
# 只有在「有參數且第一個不是選項」時，才把它當成自訂指令
if [[ $# -gt 0 && "$1" != -* ]]; then
  CUSTOM_CMD="$1"   # 建議把多詞命令用引號包起來，例如 "ps -aux"
  shift
fi

usage() {
  cat <<EOF
Usage: $0 [custom_cmd] [-f hostfile] [-u user] [-p password] [-s session_name] [-n panes_per_window] [-m mode]
  custom_cmd: 遠端要直接執行的指令（優先於 -m），多詞請用引號包起來，如 "ps -aux"
  -f host file (default: os_ip.txt)
  -u ssh user (default: root)
  -p ssh password (default: abcdef)
  -s tmux session base name (default: monitor)
  -n panes per window (default: 9)
  -m monitor mode: top | htop | batch (default: top)
EOF
  exit 1
}

while getopts ":f:u:p:s:n:m:h" opt; do
  case $opt in
    f) HOSTFILE="$OPTARG" ;;
    u) USER="$OPTARG" ;;
    p) PASS="$OPTARG" ;;
    s) SESSION_BASE="$OPTARG" ;;
    n) PANE_PER_WINDOW="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    h|*) usage ;;
  esac
done

# Hosts
[[ -f "$HOSTFILE" ]] || { echo "[ERROR] $HOSTFILE not found"; exit 1; }
readarray -t hosts < "$HOSTFILE"
[[ ${#hosts[@]} -gt 0 ]] || { echo "[ERROR] No hosts in $HOSTFILE"; exit 1; }

# QoL
grep -q "set -g mouse on" ~/.tmux.conf 2>/dev/null || echo "set -g mouse on" >> ~/.tmux.conf

# Decide remote command by priority: CUSTOM_CMD > MODE > default top
if [[ -n "$CUSTOM_CMD" ]]; then
  REMOTE_MONITOR="export TERM=xterm-256color; ${CUSTOM_CMD}"
else
  case "$MODE" in
    top)   REMOTE_MONITOR='export TERM=xterm-256color; top' ;;
    htop)  REMOTE_MONITOR='export TERM=xterm-256color; (command -v htop >/dev/null && htop) || top' ;;
    batch) REMOTE_MONITOR='export TERM=dumb; while :; do top -b -n 1 | head -n 20; sleep 1; done' ;;
    *)     echo "[ERROR] Unknown mode: $MODE"; exit 1 ;;
  esac
fi
REMOTE_ESCAPED=$(printf "%q" "$REMOTE_MONITOR")

# tmux session (avoid duplicate)
SESSION_NAME="$SESSION_BASE"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  SESSION_NAME="${SESSION_BASE}_$(date +%H%M%S)"
  echo "[WARN] tmux session exists, switch to: $SESSION_NAME"
fi

WINDOW_INDEX=0
PANE_INDEX=0

echo "[INFO] Creating tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME" -n "win${WINDOW_INDEX}"
tmux set-window-option -t "$SESSION_NAME:win${WINDOW_INDEX}" automatic-rename off 2>/dev/null || true

# Build panes (no -P/-F dependency)
for idx in "${!hosts[@]}"; do
  host="${hosts[$idx]}"

  # create new window when reaching pane limit
  if (( PANE_INDEX % PANE_PER_WINDOW == 0 && PANE_INDEX != 0 )); then
    ((WINDOW_INDEX++))
    start_idx=$((WINDOW_INDEX * PANE_PER_WINDOW))
    end_idx=$((start_idx + PANE_PER_WINDOW - 1))
    [[ $end_idx -ge ${#hosts[@]} ]] && end_idx=$((${#hosts[@]} - 1))
    tmux new-window -t "$SESSION_NAME" -n "${start_idx}-${end_idx}"
    tmux set-window-option -t "$SESSION_NAME:${WINDOW_INDEX}" automatic-rename off 2>/dev/null || true
  fi

  WIN_TARGET="${SESSION_NAME}:${WINDOW_INDEX}"
  tmux select-window -t "$WIN_TARGET"

  if (( PANE_INDEX % PANE_PER_WINDOW == 0 )); then
    TARGET_PANE="${WIN_TARGET}.0"
  else
    tmux split-window -t "$WIN_TARGET" -v
    TARGET_PANE="$WIN_TARGET"   # active pane of window
  fi

  tmux select-pane -t "$TARGET_PANE" -T "$host" 2>/dev/null || true

  # Keep $ret fully on remote side to avoid unbound variable locally
  CMD=$'echo "==== '"$host"$' ===="; \n'\
$'sshpass -p '"$PASS"$' ssh -tt -o StrictHostKeyChecking=no -o LogLevel=ERROR -o ConnectTimeout=4 -o ServerAliveInterval=15 '"$USER"'@'"$host"$' bash -lc '"$REMOTE_ESCAPED"$'; \n'\
$'ret=$?; echo "==== Done on '"$host"$' (rc:$ret) ===="; \n'\
$'exec bash'

  tmux send-keys -t "$TARGET_PANE" "$CMD" C-m
  tmux select-layout -t "$WIN_TARGET" tiled

  ((PANE_INDEX++))
done

tmux set-option -t "$SESSION_NAME" remain-on-exit on 2>/dev/null || true
tmux attach -t "$SESSION_NAME"
