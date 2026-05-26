#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Allow the trigger key to be overridden via @pane_input_key (default: V)
KEY="$(tmux show-option -gqv '@pane_input_key')"
: "${KEY:=V}"

tmux bind-key "$KEY" run-shell "$CURRENT_DIR/scripts/pane-input.sh"
