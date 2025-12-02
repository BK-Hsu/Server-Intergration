#!/usr/bin/env bash
# BK-quick.sh - 快速選單啟動器（會依實際檔案存在與否顯示選項）
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---------- 小工具 ----------
have()          { command -v "$1" >/dev/null 2>&1; }
exists()        { [[ -f "$1" && -x "$1" ]]; }
exists_any()    { [[ -e "$1" ]]; }  # 只檢查存在，不一定可執行
pause()         { read -rp "按 Enter 繼續..." _; }
line()          { printf '%*s\n' "${COLUMNS:-100}" '' | tr ' ' -; }
title()         { line; echo "$1"; line; }
ts()            { date +%Y%m%d_%H%M; }

run_if_exists() {
  local f="$1"; shift || true
  if [[ -x "$f" ]]; then
    "$f" "$@"
  else
    echo "[X] 找不到或不可執行：$f"
    return 127
  fi
}

# ---------- 二階互動 ----------
submenu_parallel_cmd() {
  local runner="$1" label="$2"
  title "$label"
  if ! exists "$runner"; then
    echo "[X] 目前資料夾沒有 $runner"
    pause; return 1
  fi
  read -rp "請輸入要在主機上執行的指令（例如：ipmitool chassis power status）: " user_cmd
  if [[ -z "${user_cmd:-}" ]]; then echo "[!] 未輸入指令"; pause; return 1; fi
  echo
  echo ">>> $runner \"$user_cmd\""
  "$runner" "$user_cmd"
  echo "=== 完成 ==="
  pause
}

submenu_nvqual_batch() {
  title "批次執行 nvqual"
  if ! have sshpass; then
    echo "[X] 需要 sshpass，請先安裝（yum/apt 安裝）"; pause; return 1
  fi
  read -rp "輸入目標 IP（空白分隔，如：192.168.2.31 192.168.2.32 ...）: " -a IPs
  if [[ "${#IPs[@]}" -eq 0 ]]; then echo "[!] 未輸入 IP"; pause; return 1; fi

  read -rp "SSH 密碼（預設 abcdef）: " PASS
  PASS="${PASS:-abcdef}"

  echo "選擇要跑的 tests："
  echo "  1) 1 1.1 1.2 37 37.1"
  echo "  2) 1 1.1 1.2"
  echo "  3) 1"
  read -rp "輸入 1/2/3（預設 1）: " TSEL
  case "${TSEL:-1}" in
    1) TESTS="1 1.1 1.2 37 37.1" ;;
    2) TESTS="1 1.1 1.2" ;;
    3) TESTS="1" ;;
    *) TESTS="1 1.1 1.2 37 37.1" ;;
  esac

  NVQ_DIR="/root/NVQUAL_GB_NVL_1.9"
  echo
  echo "將在每台主機上執行：cd $NVQ_DIR && ./nvqual --bypass_menu --tests $TESTS"
  echo
  for ip in "${IPs[@]}"; do
    echo "==== $ip ===="
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "root@$ip" \
      "cd '$NVQ_DIR' && ./nvqual --bypass_menu --tests $TESTS" || echo "[!] $ip 執行失敗"
    echo "==== Done on $ip ===="
  done
  echo "=== 全部完成 ==="
  pause
}

submenu_watch_power() {
  local log="for-power.log"
  title "持續監看電力（power-consumption.sh）"
  if ! exists "./power-consumption.sh"; then
    echo "[X] 找不到 power-consumption.sh"; pause; return 1
  fi
  read -rp "輸入 watch 週期秒數（預設 5）: " SEC
  SEC="${SEC:-5}"
  echo "開始：每 ${SEC}s 執行一次並附加輸出到 $log（Ctrl-C 結束）"
  sleep 0.5
  watch -n "$SEC" "./power-consumption.sh | tee -a '$log'"
}

submenu_tmux_kill_all() {
  title "關閉所有 tmux sessions"
  if ! have tmux; then echo "[X] 沒有 tmux 指令"; pause; return 1; fi
  if tmux list-sessions >/dev/null 2>&1; then
    tmux list-sessions | awk '{print $1}' | sed 's/://g' | xargs -r -I {} tmux kill-session -t {}
    echo "[✓] 已嘗試關閉所有 tmux session"
  else
    echo "[i] 目前沒有 tmux session"
  fi
  pause
}

submenu_power_shelf() {
  title "power-shelf 快捷選單"
  if ! exists "./power-shelf.sh"; then
    echo "[X] 找不到 power-shelf.sh"; pause; return 1
  fi
  echo "請選擇 PSU 動作："
  echo " 1) On"
  echo " 2) ForceOn"
  echo " 3) ForceOff"
  echo " q) 返回主選單"
  read -rp "輸入選項: " act
  case "$act" in
    1) ./power-shelf.sh On ;;
    2) ./power-shelf.sh ForceOn ;;
    3) ./power-shelf.sh ForceOff ;;
    q|Q) return 0 ;;
    *) echo "[!] 無效選項" ;;
  esac
  pause
}

clear_known_hosts() {
  title "清除 SSH known_hosts 憑證"
  for file in os_ip.txt bmc_ip.txt nvos_ip.txt; do
    [[ -f $file ]] || continue
    echo "[*] 掃描 $file"
    readarray -t hosts < "$file"
    for host in "${hosts[@]}"; do
      ip="$(echo "$host" | awk '{print $1}')"
      [[ -n "$ip" ]] || continue
      echo "  - 清除 $ip"
      ssh-keygen -f "/root/.ssh/known_hosts" -R "$ip" >/dev/null 2>&1 || true
    done
  done
  echo "[✓] 已清除憑證"
  pause
}

# ---------- 主選單 ----------
main_menu() {
  while true; do
    clear
    title "BK-quick 快速選單（$SCRIPT_DIR）"

    idx=0
    show() { idx=$((idx+1)); printf "%2d) %s\n" "$idx" "$1"; OPTS[$idx]="$2"; }

    declare -A OPTS=()

    # 1) L11_state_check.sh
    if exists "./L11_state_check.sh"; then
      show "執行 L11_state_check.sh（輸出 L11-info_時間.log）" \
           "run_if_exists ./L11_state_check.sh | tee \"L11-info_$(ts).log\"; pause"
    fi

    # 2) power-consumption.sh（單次）
    exists "./power-consumption.sh" \
      && show "執行 power-consumption.sh" "run_if_exists ./power-consumption.sh; pause"

    # 3) power-consumption.sh（watch & tee）
    exists "./power-consumption.sh" \
      && show "持續監看 power-consumption（watch + tee）" "submenu_watch_power"

    # 4) os-cmd-parallel.sh
    exists "./os-cmd-parallel.sh" \
      && show "OS 並行命令（互動輸入指令）" "submenu_parallel_cmd ./os-cmd-parallel.sh 'OS 並行命令'"

    # 5) bmc-cmd-parallel.sh
    exists "./bmc-cmd-parallel.sh" \
      && show "BMC 並行命令（互動輸入指令）" "submenu_parallel_cmd ./bmc-cmd-parallel.sh 'BMC 並行命令'"

    # 6) bmc-cmd.sh（單次）
    exists "./bmc-cmd.sh" \
      && show "BMC 單次命令（互動輸入指令）" "submenu_parallel_cmd ./bmc-cmd.sh 'BMC 單次命令'"

    # 7) power-shelf 快捷
    exists "./power-shelf.sh" \
      && show "power-shelf 快捷（On / ForceOn / ForceOff）" "submenu_power_shelf"

    # 8) check_L10_firmware.sh
    if exists "./check_L10_firmware.sh"; then
      show "check_L10_firmware.sh（輸出 L10-fw_時間.log）" \
           "run_if_exists ./check_L10_firmware.sh | tee \"L10-fw_$(ts).log\"; pause"
    fi

    # 9) tmux-fw-update.sh
    exists "./tmux-fw-update.sh" \
      && show "tmux-fw-update.sh" "run_if_exists ./tmux-fw-update.sh"

    # 10) tmux-nvsw-update.sh
    exists "./tmux-nvsw-update.sh" \
      && show "tmux-nvsw-update.sh" "run_if_exists ./tmux-nvsw-update.sh"

    # 11) 關閉所有 tmux sessions
    show "關閉所有 tmux sessions" "submenu_tmux_kill_all"

    # 12) 批次執行 nvqual
    show "批次執行 nvqual（互動輸入 IP 與 tests）" "submenu_nvqual_batch"

    # 13) 清除 SSH 憑證
    show "清除 SSH 憑證（known_hosts）" "clear_known_hosts"

    # 15) 建立 SSH 互信（18 節點）
    exists "./setup_cluster_ssh_trust.sh" \
      && show "建立 SSH 互信（18 節點）" "run_if_exists ./setup_cluster_ssh_trust.sh; pause"

    # 14) 離開 (q)
    show "離開 (q)" "exit 0"

    echo
    read -rp "請選擇編號或輸入 q 離開: " choice
    echo
    if [[ "${choice,,}" == "q" ]]; then
      exit 0
    elif [[ -n "${choice:-}" && "${OPTS[$choice]+_}" ]]; then
      eval "${OPTS[$choice]}"
    else
      echo "[!] 無效選項：$choice"; sleep 1
    fi
  done
}

main_menu
