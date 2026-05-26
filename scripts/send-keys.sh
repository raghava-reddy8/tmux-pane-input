#!/usr/bin/env bash
set -euo pipefail

PANE_ID="$1"
VALUE="$(tmux show-option -gqv @pane_input_target)"
INDEX="$(tmux show-option -gqv @pane_input_index)"

# Send the value to the target pane (text is typed but not submitted)
tmux send-keys -t "$PANE_ID" "$VALUE"

# Advance to the next pane
tmux set-option -g @pane_input_index "$((INDEX + 1))"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmux run-shell "$CURRENT_DIR/prompt-next.sh"
