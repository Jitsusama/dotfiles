# Disable HTTP proxying in vscode
# (no clue why he assumes proxying when none is configured)
set -Ux NO_PROXY "*"
if status is-interactive
    set -Ux EDITOR (which code)
end
