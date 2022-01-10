<#
.SYNOPSIS
    Bootstraps chezmoi on Windows.
.PARAMETER EmalAddress
    1Password Email address.
.PARAMETER GithubUsername
    Username on Github.
#>

param(
    [Parameter(Position = 0)][string]$EmailAddress,
    [Parameter(Position = 1)][string]$GithubUsername
)

$ONEP_VERSION = "v1.12.3"
$ONEP_HOST = "my.1password.ca"

function main {
    param ([string]$EmailAddress, [string]$GithubUsername)

    # TODO - setup choco?
    setupOnePassword -EmailAddress $EmailAddress
    # TODO - setup vault
    setupChezmoi -GithubUsername $GithubUsername
}

function setupOnePassword {
    param ([string]$EmailAddress)

    $URI = "https://cache.agilebits.com/dist/1P/op/pkg/$ONEP_VERSION/op_windows_amd64_$ONEP_VERSION.zip"
    Invoke-WebRequest -Uri $URI -OutFile $HOME\AppData\Local\Programs\Common\op.exe
    Invoke-Expression $(op signin $ONEP_HOST $EmailAddress)
}

function setupChezmoi {
    param ([string]$GithubUsername)

    '$params = "-BinDir ~/AppData/Local/Programs/Common"', (Invoke-WebRequest https://git.io/chezmoi.ps1).Content | powershell -c -
    chezmoi.exe init --apply $GithubUsername
}

main -EmailAddress $EmailAddress -GithubUsername $GithubUsername
