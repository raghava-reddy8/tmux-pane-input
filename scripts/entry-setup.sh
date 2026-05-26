#!/usr/bin/env bash
set -euo pipefail

PANES=($(tmux list-panes -F "#{pane_index}"))

if [ "${#PANES[@]}" -eq 1 ]; then
  tmux display-message "Only one pane — sync ctrl input requires multiple panes"
  exit 0
fi

# Store pane list and reset index in global tmux options
tmux set-option -g @pane_input_panes "${PANES[*]}"
tmux set-option -g @pane_input_index 0

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmux run-shell "$CURRENT_DIR/prompt-next.sh"
