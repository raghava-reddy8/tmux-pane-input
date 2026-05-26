#!/usr/bin/env bash
set -euo pipefail

PANES_STR="$(tmux show-option -gqv @pane_input_panes)"
INDEX="$(tmux show-option -gqv @pane_input_index)"

read -r -a PANES <<<"$PANES_STR"

# All panes have been visited — restore synchronize-panes and exit
if [[ "$INDEX" -ge "${#PANES[@]}" ]]; then
  tmux set-window-option synchronize-panes on
  exit 0
fi

PANE_ID="${PANES[$INDEX]}"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux display-popup -E "bash -c '
  read -p \"Enter value for pane ${PANE_ID}: \" value
  tmux set-option -g @pane_input_target \"\$value\"
'"
tmux run-shell "$CURRENT_DIR/send-keys.sh $PANE_ID"
