#!/bin/bash
###
###
###
##
##
#
if [[ ! -f os_ip.txt ]]; then
  echo "[ERROR] os_ip.txt not found"; exit 1
fi
readarray -t hosts < os_ip.txt
#readarray -t hosts < os_ip.txt; for host in "${hosts[@]}"; do echo "Login $host"; ssh-keygen -f "/root/.ssh/known_hosts" -R $host; done
#readarray -t hosts < bmc_ip.txt; for host in "${hosts[@]}"; do echo "Login $host"; ssh-keygen -f "/root/.ssh/known_hosts" -R $host; done

###### tmux setting ######
SESSION_BASE="diag_sess"
MAX_PANES=9
WINDOW_INDEX=0
PANE_INDEX=0
SESSION_NAME="$SESSION_BASE"
LOG_DIR="/root/partnerdiag_logs"
TS=$(date +%Y%m%d_%H%M%S)  # unified timestamp

# tmux mouse setting
if ! grep -q "set -g mouse on" ~/.tmux.conf 2>/dev/null; then
  echo "set -g mouse on" >> ~/.tmux.conf
fi
###### tmux setting ######

# clean and recreate log directory
echo "[INFO] Cleaning and recreating $LOG_DIR"
rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"
COLLECT_LOG="| tee /root/partnerdiag_logs/diag_\${host}_$TS.log 2>&1"

###### function declaration ######
diag="cd /root/629-24975-0000-FLD-42872 && \
./partnerdiag --mfg --run_spec=spec_gb200_nvl_2_4_board_pc_partner_mfg.json \
--run_on_error --no_bmc --skip_tests=Connectivity,Nvlink,BfMgmtPcieProperties,BfPcieProperties "

nvqual="cd /root/NVQUAL_GB_NVL_1.9 && \
./nvqual --bypass_menu --tests 1 "
###### function declaration ######

# create tmux session
echo "[INFO] Creating tmux session $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME" -n diag0

for host in "${hosts[@]}"; do
  if (( PANE_INDEX % MAX_PANES == 0 && PANE_INDEX != 0 )); then
    ((WINDOW_INDEX++))
    tmux new-window -t "$SESSION_NAME" -n win$WINDOW_INDEX
  fi

  WIN_TARGET="$SESSION_NAME:$WINDOW_INDEX"
  LOG_REMOTE_PATH="/root/partnerdiag_logs/diag_${host}_$TS.log"

  CMD="echo ==== $host ====; \
sshpass -p abcdef ssh -o StrictHostKeyChecking=no root@$host \"${nvqual}\"; \
echo ==== Done on $host ====; exec bash"

  if (( PANE_INDEX % MAX_PANES == 0 )); then
    tmux send-keys -t "$WIN_TARGET" "$CMD" C-m
  else
    tmux split-window -t "$WIN_TARGET" -v
    tmux send-keys -t "$WIN_TARGET" "$CMD" C-m
  fi

  tmux select-layout -t "$WIN_TARGET" tiled
  ((PANE_INDEX++))
done

tmux attach -t "$SESSION_NAME"
