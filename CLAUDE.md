# Working on Joel's Personal Machines

This repository is the personal layer on top of [core.nix][core]. Read the
[README](README.md) for what it holds and how it's applied.

## The One Rule

Configuration that's useful on any of Joel's machines belongs in core.nix.
Only what's personal belongs here: the personal email, the tools he uses
outside work, pi and its skills, and each machine's own settings. When
something is part universal and part personal, split it: core.nix carries
the universal part, often with a `jitsusama.*` option, and this repository
sets it.

## How a Machine Is Built

`flake.nix` builds each machine with the stock `darwinSystem` or
`nixosSystem` from core.nix's roles, the personal layer in
`layers/personal/`, and `machines/<machine>/`. A layer file that needs a
flake input takes it as an outer function, and `flake.nix` gives it with
`moduleFrom`, as core.nix does; nothing goes through `specialArgs`. This
repository follows core.nix's [conventions][conventions]. To change what
core.nix sets, use the ways in its [machines guide][machines].

## Commands

```sh
nix flake check                                     # evaluate both machines
darwin-rebuild build --flake .#methuselah           # on the Mac
nixos-rebuild build --flake .#penelope              # on penelope or any Linux
nix flake update core                               # take core.nix's latest
nix fmt                                             # format
```

A flake sees only files git knows about, so `git add` a new file before
building.

## Changing core.nix Too

Land the core.nix change first, then `nix flake update core` here. Before it
merges, try both together with `--override-input core path:$HOME/src/core.nix`.

## Commit Signing

methuselah signs from its Secure Enclave: @docs/commit-signing-spec.md for
how, and @docs/commit-signing-rationale.md for why, before changing it.

[core]: https://github.com/Jitsusama/core.nix
[conventions]: https://github.com/Jitsusama/core.nix/blob/main/docs/conventions.md
[machines]: https://github.com/Jitsusama/core.nix/blob/main/docs/machines.md
