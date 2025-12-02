tmux list-sessions | awk '{print $1}' | sed 's/://g' | xargs -I {} tmux kill-session -t {}
