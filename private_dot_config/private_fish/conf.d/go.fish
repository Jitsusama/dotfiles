set _desired_go_version 1.17.3

fish_add_path (go env GOPATH)/bin

if which go$_desired_go_version >/dev/null 2>&1
    set -x GOROOT (go$_desired_go_version env GOROOT)
    fish_add_path $GOROOT/bin
end
