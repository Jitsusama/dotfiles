This repository contains dotfiles for your's truly.

I am utilizing [chezmoi](https://www.chezmoi.io/) because of its awesome UX
and support for macOS, Linux, WSL and Windows from the same Git repo. This is
definitely still a work in progress.

To bootstrap this on a \*NIX workstation, run the following command from your
shell prompt, replacing _1PASSWORD_EMAIL_ and _GITHUB_USERNAME_ with the
appropriate values:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jitsusama/dotfiles/main/bootstrap.sh)" <1PASSWORD_EMAIL> <GITHUB_USERNAME>
```

To bootstrap this on a Windows workstation, run the following command from a
PowerShell prompt, relacing _1PASSWORD_EMAIL_ and _GITHUB_USERNAME_ with the
appropriate values:

```powershell
'$params = "-EmalAddress 1PASSWORD_EMAIL -GithubUsername GITHUB_USERNAME"', (Invoke-WebRequest https://raw.githubusercontent.com/Jitsusama/dotfiles/main/bootstrap.ps1).Content | powershell -c -
```
