# Disable HTTP proxying in vscode
# (no clue why he assumes proxying when none is configured)
set -Ux NO_PROXY "*"
if status is-interactive
    if test (which code)
        set -Ux EDITOR (which code)
    else
        set -Ux EDITOR (which vim)
    end
end
