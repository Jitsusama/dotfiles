#!/bin/bash

$ONEP_VERSION = "v1.12.3"
$ONEP_HOST = "my.1password.ca"

function setup_homebrew {
    $URI = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    /bin/bash -c "$(curl -fsSL $URI)"
}

## setup_onepassword <EMAIL>
function setup_onepassword {
    $URI = "https://cache.agilebits.com/dist/1P/op/pkg/${ONEP_VERSION}/op_linux_amd64_${ONEP_VERSION}.zip"
    curl --output 1p.zip $URI && unzip 1p.zip op -d .local/bin && rm 1p.zip
    eval $(op signin $ONEP_HOST $1 --shorthand my)
}

## setup_chezmoi <GITHUB_USERNAME>
function setup_chezmoi {
    brew install chezmoi
    chezmoi init --apply $1
}

## print_usage <PROCESS_NAME>
function print_usage {
    echo "$1 <1PASSWORD_EMAIL> <GITHUB_USERNAME>"
    echo "This program bootstraps this dotfile's repo into your *NIX workstation."
}

## main <1PASSWORD_EMAIL> <GITHUB_USERNAME>
function main {
    setup_homebrew
    setup_onepassword $1
    # TODO - setup vault
    setup_chezmoi $2
}

if [ -z $1 -o -z $2 ]; then
    print_usage $0
else
    main $1 $2
fi
