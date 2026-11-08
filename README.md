# Joel's Personal Machines

The configuration for Joel's personal machines: methuselah, a MacBook, and
penelope, a Surface Laptop 4 running NixOS. [core.nix][core] holds everything
that belongs on any of his machines; this repository holds only what's
personal.

## 🏗️ How It Fits

A machine here is a stock `darwinSystem` or `nixosSystem` call in `flake.nix`
that imports the roles it plays from core.nix, the personal modules, and its
own directory, as core's [machines guide][machines] lays out. home-manager
runs inside the system, so one switch applies the machine and Joel's account
together.

- **Only what's personal belongs here.** Anything useful on another machine
  goes into core.nix instead, hardware included.
- **core.nix pins nixpkgs and nix-darwin.** This repository follows them, so
  every machine runs the combination core's checks passed with.

## 📁 Layout

```text
flake.nix                 # the index: the machines and the repository's own modules
checks.nix                # what `nix flake check` runs
treefmt.nix               # how the formatter formats and lints
biome.jsonc               # how biome lints polkit's JavaScript
personal/                 # what every personal machine adds
├── darwin.nix            #   for macOS: the apps Homebrew installs
├── nixos.nix             #   for NixOS
├── home.nix              #   for the account: identity, tools and git
├── signers.nix           #   the keys that sign Joel's commits, his own and his agents'
└── github-merges.asc     #   the key GitHub signs its merges with, which main's head carries
modules/                  # one folder per tool: claude, neovim, pi
machines/                 # one folder per machine, its README saying more
├── methuselah/           #   the MacBook
└── penelope/             #   the Surface Laptop 4
docs/                     # how Joel's commits are signed, and why
```

## 🚀 Applying It

On methuselah:

```sh
darwin-rebuild build --flake .#methuselah
sudo darwin-rebuild switch --flake .#methuselah
```

penelope is installed by the guide from a USB stick, and from then on follows
main by itself; [its README](machines/penelope/README.md) says how.

Taking core's latest is one input: `nix flake update core`.

## 🔬 Checking It

`nix flake check --keep-going` evaluates each module on its own on a bare
NixOS machine and a bare Mac, the personal modules on each, both machines, and
the promises they make: penelope installs onto core's encrypted disk and
boots under its own Secure Boot keys, then finishes itself with core's guide,
and both machines commit as Joel and sign every commit. Each condition of a
promise fails with a line of its own naming the machine. Evaluating builds
nothing, so most checks take seconds; what only fails when it runs is built
for the machine of the system checking: `neovim-loads` starts Neovim once,
`claude-skills-build` patches Claude Code's skills, and `pi-builds` builds
pi.

[core]: https://github.com/Jitsusama/core.nix
[machines]: https://github.com/Jitsusama/core.nix/blob/main/docs/machines.md
