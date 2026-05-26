# tmux-pane-input

A [tmux](https://github.com/tmux/tmux) plugin that keeps you in `synchronize-panes` flow while handling the steps where each pane needs a **different value**.

**The problem:** `synchronize-panes` is excellent for running near-identical commands across multiple panes or servers — until one step requires a unique input per pane (a hostname, password, environment name, etc.). At that point you're stuck: toggle sync off, manually switch to each pane, type the value, switch back, toggle sync on, and continue. Repeat for every such step.

**The solution:** `tmux-pane-input` eliminates that toggle-switch-type-repeat cycle entirely. Trigger it with a single keypress — it walks you through each pane via a popup prompt, captures a unique value for each, then automatically restores `synchronize-panes` so your shared workflow resumes without interruption.

---

## Demo

<div align="center">
  <img src="demo.gif" alt="tmux-pane-input demo" width="700" />
</div>

---

## Synced-Panes Workflow

This plugin is designed to slot into a `synchronize-panes` session without breaking your flow:

```
┌─────────────────────────────────────────────────────────────────┐
│  synchronize-panes ON                                           │
│  → type shared command parts (e.g. ssh user@, cd /app, etc.)   │
└───────────────────────────┬─────────────────────────────────────┘
                            │ reach a step that needs unique input
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  prefix + V  (trigger tmux-pane-input)                         │
│  → popup per pane: type the unique value for each              │
│     pane 0: server-a.prod                                       │
│     pane 1: server-b.prod                                       │
│     pane 2: server-c.prod                                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │ all panes visited
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  synchronize-panes automatically restored to ON                 │
│  → continue typing shared commands as normal                    │
└─────────────────────────────────────────────────────────────────┘
```

You never touch the sync toggle manually. The plugin handles the off/on cycle so you stay in the synced-panes flow throughout — only pausing at each unique-input step.

---

## How It Works

1. Press `prefix + V` (configurable — see [Configuration](#configuration)).
2. Pane numbers are displayed on screen for reference.
3. If `synchronize-panes` is currently **on**, it is automatically turned **off**.
4. A popup prompt appears for **each pane** in the current window in index order.
5. Type a value and press `Enter` — the text is sent to that pane (typed but not submitted; no `Enter` is sent to the pane's program, letting you review before confirming).
6. After all panes have been visited, `synchronize-panes` is turned back **on**.

---

## Requirements

| Requirement | Minimum version |
|-------------|-----------------|
| tmux        | 3.0 (introduces `display-popup`) |
| Bash        | 4.0             |

---

## Installation

### Via TPM (recommended)

Add the following line to `~/.tmux.conf`:

```tmux
set -g @plugin 'your-username/tmux-pane-input'
```

Then reload your config and install:

```
prefix + I
```

### Manual

Clone the repository:

```sh
git clone https://github.com/your-username/tmux-pane-input \
  ~/.tmux/plugins/tmux-pane-input
```

Add the following line to `~/.tmux.conf`:

```tmux
run '~/.tmux/plugins/tmux-pane-input/pane-input.tmux'
```

Reload tmux config:

```sh
tmux source-file ~/.tmux.conf
```

---

## Configuration

All options are set in `~/.tmux.conf` **before** the `run` line.

| Option | Default | Description |
|--------|---------|-------------|
| `@pane_input_key` | `V` | Key used with the tmux prefix to trigger the plugin |

**Example — change the trigger key to `C`:**

```tmux
set -g @pane_input_key 'C'
run '~/.tmux/plugins/tmux-pane-input/pane-input.tmux'
```

---

## Usage

```
prefix + V
```

A popup will appear for each pane in the current window:

```
Enter value for pane 0: _
```

Type a value and press `Enter`. The plugin moves on to the next pane automatically. Once all panes have been visited, the session returns to normal with `synchronize-panes` re-enabled.

> **Note:** The entered text is typed into the pane's active program but **not submitted** (no `Enter` keypress is forwarded). This lets you review or modify the text before pressing `Enter` yourself.

---

## Project Structure

```
tmux-pane-input/
├── pane-input.tmux           # Plugin entry point — registers the keybinding
└── scripts/
  ├── pane-input.sh         # Orchestrator: displays panes, disables sync, starts loop
    ├── entry-setup.sh        # Collects pane list and initialises loop state
    ├── prompt-next.sh        # Shows popup for the current pane, advances the loop
    └── send-keys.sh          # Sends the captured input to the target pane
```

### Script responsibilities

#### `pane-input.tmux`
The plugin entry point. Reads `@pane_input_key` (falling back to `V`) and binds `prefix + <key>` to the main script.

#### `scripts/pane-input.sh`
Orchestrator. Calls `tmux display-panes` for visual reference, turns off `synchronize-panes` if needed, then delegates to `entry_setup.sh`.

#### `scripts/entry-setup.sh`
Enumerates all panes in the current window via `tmux list-panes`. Stores the pane index list and a counter in the global tmux options `@pane_input_panes` and `@pane_input_index`, then hands off to `prompt_next.sh`.

#### `scripts/prompt-next.sh`
Reads the current index. If all panes have been visited it re-enables `synchronize-panes` and exits. Otherwise it opens a `display-popup` to capture user input, stores the result in `@pane_input_target`, then calls `send_keys.sh`.

#### `scripts/send-keys.sh`
Receives the target pane ID as `$1`. Reads `@pane_input_target` and forwards the value with `tmux send-keys`. Increments `@pane_input_index` and calls `prompt_next.sh` to continue the loop.

---

## Tmux Option Namespace

All internal state is stored under the `@pane_input_` prefix:

| Option | Description |
|--------|-------------|
| `@pane_input_panes` | Space-separated list of pane indices for the current run |
| `@pane_input_index` | Current position in the pane list |
| `@pane_input_target` | The value entered in the most recent popup |

These are global tmux options (`-g`) scoped to a single run and overwritten on each invocation.

---

## Suggested Improvements

| # | Improvement | Detail |
|---|-------------|--------|
| 1 | **Auto-submit input** | Append `Enter` to the `send-keys` call (`tmux send-keys -t "$PANE_ID" "$VALUE" Enter`) if you want each value submitted immediately without manual confirmation. |
| 2 | **Window-scoped state** | Replace `set-option -g` with `set-window-option` to avoid state collisions when the plugin runs in multiple windows simultaneously. |
| 3 | **Abort on empty input** | Detect an empty popup submission and skip (or abort entirely) instead of sending an empty string to the pane. |
| 4 | **Preserve sync state** | Save the original `synchronize-panes` value at the start and restore exactly that value at the end, rather than unconditionally turning it on. |
| 5 | **Configurable pane scope** | Add an option to target only a user-supplied subset of panes rather than all panes in the window. |

---

## License

MIT
