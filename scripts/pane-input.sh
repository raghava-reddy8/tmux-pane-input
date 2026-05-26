#!/usr/bin/env bash
set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux display-panes

# Turn off synchronize-panes if it is currently on
SYNC_STATE="$(tmux show-option -wqv 'synchronize-panes')"
if [ "$SYNC_STATE" = "on" ]; then
  tmux setw synchronize-panes off
fi

tmux run-shell "$CURRENT_DIR/entry-setup.sh"
