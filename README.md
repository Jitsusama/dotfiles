# Dotfiles

Joel's personal machines, built on [core.nix][core]: methuselah, a MacBook,
and penelope, an AMD laptop running NixOS. core.nix holds everything that
belongs on any of his machines; this repository holds only what's personal.

## What's Here

| Path                | What it holds                                                    |
| ------------------- | ---------------------------------------------------------------- |
| `flake.nix`         | both machines, each core's roles, the personal layer and its own |
| `layers/personal/`  | what every personal machine adds: the email, tools, pi, git      |
| `machines/<name>/`  | what belongs to that machine alone                               |
| `modules/`          | the packages the layer builds: pi, its skills, agentic-harness   |
| `docs/`             | how methuselah's commits are signed from its Secure Enclave      |

Each machine is the stock builder with core's roles, as core's [machines
guide][machines] lays out. home-manager is part of the system, so one switch
applies the machine and the account together.

## Applying It

On methuselah:

```sh
darwin-rebuild build --flake .#methuselah
sudo darwin-rebuild switch --flake .#methuselah
```

On penelope:

```sh
nixos-rebuild build --flake .#penelope
nixos-rebuild switch --sudo --flake .#penelope
```

Taking core's latest is one input: `nix flake update core`.

## The First Switch on Core's Roles

Both machines used to apply home-manager on its own, with `home-manager
switch`. After the first system switch, that standalone profile is left
over and can go: `nix profile list` shows it as `home-manager-path`, and
`nix profile remove home-manager-path` takes it away.

penelope's SSH keys and commit signing now come from its TPM, as on every
Linux workstation core builds, in place of 1Password's agent. Until the
steps from "Make the SSH Keys" on in core's [installing guide][installing]
have made them there, penelope can't reach GitHub over SSH or sign, and the
signing keys' public halves join the signers in `layers/personal/home.nix`.

[core]: https://github.com/Jitsusama/core.nix
[machines]: https://github.com/Jitsusama/core.nix/blob/main/docs/machines.md
[installing]: https://github.com/Jitsusama/core.nix/blob/main/docs/installing.md#9-make-the-ssh-keys
