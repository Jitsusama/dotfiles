# Joel's Personal Machines

The configuration for Joel's personal machines: methuselah, a MacBook, and
penelope, a Surface Laptop 4 running NixOS. [core.nix][core] holds everything
that belongs on any of his machines; this repository holds only what's
personal.

## 🏗️ How It Fits

A machine here is a stock `darwinSystem` or `nixosSystem` call in `flake.nix`
that imports the roles it plays from core.nix, the personal layer, and its
own directory, as core's [machines guide][machines] lays out. home-manager
runs inside the system, so one switch applies the machine and Joel's account
together.

- **Only what's personal belongs here.** Anything useful on another machine
  goes into core.nix instead, hardware included.
- **core.nix pins nixpkgs and nix-darwin.** This repository follows them, so
  every machine runs the combination core's checks passed with.

## 📁 Layout

```text
flake.nix                 # the index: the machines, the layer and its modules
checks.nix                # what `nix flake check` runs
treefmt.nix               # how the formatter formats and lints
layers/personal/          # the personal layer: what every personal machine adds
├── darwin.nix            #   for macOS: the apps Homebrew installs
├── nixos.nix             #   for NixOS
└── home.nix              #   for the account: identity, tools and git
modules/<tool>/           # one tool: agentic-harness-core, claude, neovim, pi
machines/methuselah/      # the MacBook; its README says more
machines/penelope/        # the Surface Laptop 4; its README says more
docs/                     # how methuselah's commits are signed
```

## 🚀 Applying It

On methuselah:

```sh
darwin-rebuild build --flake .#methuselah
sudo darwin-rebuild switch --flake .#methuselah
```

penelope is installed by the guide from a USB stick rather than switched;
[its README](machines/penelope/README.md) says why.

Taking core's latest is one input: `nix flake update core`.

## 🔬 Checking It

`nix flake check --keep-going` evaluates each module on its own on a bare
NixOS machine and a bare Mac, the personal layer on each, both machines, and
the promises they make: penelope installs onto core's encrypted disk and
boots under its own Secure Boot keys, then finishes itself with core's guide,
and both machines commit as Joel and sign every commit. Evaluating builds
nothing, so most checks take seconds; `neovim-loads` starts Neovim once.

[core]: https://github.com/Jitsusama/core.nix
[machines]: https://github.com/Jitsusama/core.nix/blob/main/docs/machines.md
