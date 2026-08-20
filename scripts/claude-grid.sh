#!/usr/bin/env bash
set -euo pipefail

# Opens a new Windows Terminal window attached to a tmux session with four
# quadrant panes, one per project, each running claude. The session is named
# after the parent directory (projects); each pane border shows its project.

PARENT="$HOME/projects"
DIRS=(workinabox truthdb nrdr-org dronerds)
SESSION="$(basename "$PARENT")"

if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
  tmux new-session -d -s "$SESSION" -x 220 -y 50 -c "$PARENT/${DIRS[0]}"
  WIN="$(tmux display-message -p -t "$SESSION" '#{window_id}')"

  for dir in "${DIRS[@]:1}"; do
    tmux split-window -t "$WIN" -c "$PARENT/$dir"
    tmux select-layout -t "$WIN" tiled
  done

  # Panes end up in row-major order: top-left, top-right, bottom-left, bottom-right.
  mapfile -t PANES < <(tmux list-panes -t "$WIN" -F '#{pane_id}')
  tmux set-option -w -t "$WIN" pane-border-status top
  # --name gives each claude session its project name (same as /rename), shown
  # in the session picker and the terminal title. --remote-control enables
  # Remote Control (same as /remote-control), with the project name as the
  # remote session name.
  for i in "${!DIRS[@]}"; do
    tmux send-keys -t "${PANES[$i]}" "claude --name '${DIRS[$i]}' --remote-control '${DIRS[$i]}'" C-m
  done
  tmux select-pane -t "${PANES[0]}"
fi

# Server-wide quality-of-life options, applied on every run so an existing
# session picks them up too. set-clipboard "on" (vs the default "external")
# also lets apps inside panes write the system clipboard via OSC 52.
tmux set-option -g mouse on
tmux set-option -s focus-events on
tmux set-option -s set-clipboard on

# -p applies the distro's Windows Terminal profile (color scheme, font); without
# it, a raw commandline gets the stock defaults and a black background.
wt.exe -w new -p "$WSL_DISTRO_NAME" wsl.exe -d "$WSL_DISTRO_NAME" --cd "$HOME" -e tmux attach-session -t "$SESSION"
