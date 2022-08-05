set _desired_go_version 1.19

if which go$_desired_go_version >/dev/null 2>&1
    set -x GOROOT (go$_desired_go_version env GOROOT)
    fish_add_path -m $GOROOT/bin
end
