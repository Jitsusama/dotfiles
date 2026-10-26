# Working on Joel's Personal Machines

This repository is the personal layer on top of [core.nix][core]. Read the
[README](README.md) for what it holds and how it's applied.

## The One Rule

Configuration that's useful on any of Joel's machines belongs in core.nix.
Only what's personal belongs here: the personal email, the tools he uses
outside work, pi and Claude Code's skills, and each machine's own settings.
A machine's hardware belongs in core.nix too, as one of its hardware
modules.

When something is part universal and part personal, split it. core.nix
carries the universal part, often with a `jitsusama.*` option, and this
repository sets it:

```nix
# core.nix declares jitsusama.identity.email and git reads it

# here, in layers/personal/home.nix
jitsusama.identity.email = "joel@grrbrr.ca";
```

## How a Machine Is Built

`flake.nix` builds each machine with the stock `darwinSystem` or
`nixosSystem`, from:

1. core.nix's roles: `workstation` and `graphical`, plus `laptop` and the
   machine's hardware on NixOS, and for a machine the guide installs,
   `disko`, `lanzaboote` and `guide`
2. the personal layer, `layers/personal/`, which imports this repository's
   modules
3. `machines/<machine>/`, settings for that one machine

A file that needs a flake input takes it as an outer function, and
`flake.nix` gives it with `moduleFrom`, as core.nix gives its roles theirs:
the layer's `home.nix` takes `core` and this repository's `homeModules`,
`modules/claude` takes the input it reads, and `modules/pi` takes `core`
for the module declaring its settings. Nothing goes through `specialArgs`.

This repository follows core.nix's [conventions][conventions] as they're
written, and holds itself to core's [testing][testing] the same way: a
directory per tool, files named for their module system, a header on every
file saying what it's for, no `with pkgs;`, no argument a module doesn't
use, a module importing what it depends on, and no reliance on the order
modules are imported in. To change what core.nix sets, use the ways in its
[machines guide][machines].

## Commands

```bash
nix flake check --keep-going                         # every check
nixos-rebuild build --flake .#penelope               # build without applying
darwin-rebuild build --flake .#methuselah            # on the Mac
nix flake update core                                # take core.nix's latest pins
nix fmt                                              # format and lint
```

A flake sees only files git knows about, so `git add` a new file before
building. In a worktree, pass the checkout as `git+file://$PWD` rather than
`path:`, since a `path:` copy carries the worktree's `.git` file, which the
formatting check can't read.

## Checks

[`checks.nix`](checks.nix) is how a change here is known to work, since no
CI runs it.

- A new module goes in `checks.nix`'s list and is added, on its own, to an
  account on a bare machine of each class. `every-module-is-checked` fails
  until it is.
- A promise the machines make, such as penelope booting under its own
  Secure Boot keys, gets a `holds` check with a message saying what broke.
- Evaluating never runs anything, so what only fails when it runs needs a
  check that builds it, as `neovim-loads` starts penelope's Neovim.
- A doc names only what exists: `docs-name-what-exists`, core's, fails on a
  link or a backticked path that names nothing, so a move or a rename fixes
  its mentions in the same change. A mention of something deliberately
  elsewhere, such as a file in core.nix, is listed in its `exempt` with why.
- Every folder says what it holds: `every-folder-says-what-it-holds`, core's,
  fails on one with no README, no entry file opening with a comment, no line
  of its parent's README opening with its name and, at the top, no line of
  the README's map. A new folder gets its note in the change that makes it.
- A check's name says core.nix's glossary's words: `no-name-says-a-replaced-word`,
  core's, fails on one saying a name the glossary replaces. A name using such
  a word in another sense, or waiting on a rename, goes in its `otherSenses`
  or `waiting` with why.
- Before trusting a new check, break what it covers and watch it fail.

## penelope

penelope is the laptop the guide that installs core.nix machines is proven
on, so it's wiped and installed again often. Its machine file is the system
the guide installs: core's encrypted disk and Secure Boot. Never switch the
install it runs today to it, since that install has a plain disk the new
file doesn't describe; its [README](machines/penelope/README.md) says more.

## Changing core.nix Too

Land the core.nix change first, then `nix flake update core` here. Before it
merges, try both together with `--override-input core path:$HOME/src/core.nix`.

## Commit Signing

methuselah signs from its Secure Enclave: [the
specification](docs/commit-signing-spec.md) says how and [the
rationale](docs/commit-signing-rationale.md) says why. Read both before
changing it.

[core]: https://github.com/Jitsusama/core.nix
[conventions]: https://github.com/Jitsusama/core.nix/blob/main/docs/conventions.md
[machines]: https://github.com/Jitsusama/core.nix/blob/main/docs/machines.md
[testing]: https://github.com/Jitsusama/core.nix/blob/main/docs/testing.md
