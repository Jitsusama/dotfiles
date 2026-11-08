# Working on Joel's Personal Machines

This repository holds Joel's personal machines on top of [core.nix][core].
Read the [README](README.md) for what it holds and how it's applied.

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

# here, in personal/home.nix
jitsusama.identity.email = "joel@grrbrr.ca";
```

## How a Machine Is Built

`flake.nix` builds each machine with the stock `darwinSystem` or
`nixosSystem`, from:

1. core.nix's roles: `workstation` and `graphical`, plus `laptop` and the
   machine's hardware on NixOS, and for a machine the guide installs,
   `disko`, `lanzaboote` and `guide`; and the core modules a machine takes
   on its own, as `flake.nix` lists them, such as `update-to-main` on both
   and `linux-builder` on methuselah
2. the personal modules, `personal/`, which import the tools' modules in
   `modules/`
3. `machines/<machine>/`, settings for that one machine

A file that needs a flake input takes it as an outer function, and
`flake.nix` gives it with `moduleFrom`, as core.nix gives its roles theirs:
`personal/home.nix` takes `core` and this repository's `homeModules`,
`modules/claude` takes the input it reads, `modules/neovim` takes `core`
for the Neovim its Lua builds on, and `modules/pi` takes `core` for the
module declaring its settings. Nothing goes through `specialArgs`.

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
  Secure Boot keys, gets a `holds` check: a list of conditions, each with
  what broke when it doesn't hold, naming the machine, so a failure says
  which.
- Evaluating never runs anything, so what only fails when it runs needs a
  check that builds it, as `neovim-loads` starts the machine's Neovim,
  `claude-skills-build` patches Claude Code's skills and `pi-builds` builds
  pi.
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

penelope is the laptop the guide that installs core.nix machines was proven
on, and it runs what the guide installs: core's encrypted disk and Secure
Boot. It follows this repository's main and core.nix's main by itself
(update-to-main's follower) and builds its own system, so a merge to either
reaches it within minutes. A change that compiles its kernel has the kernel
built on a lent builder and copied to it first, since it's a small laptop
Joel uses. Its [README](machines/penelope/README.md) says more.

## Changing core.nix Too

Land the core.nix change first, then `nix flake update core` here. Before it
merges, try both together with `--override-input core path:$HOME/src/core.nix`.

## Commit Signing

Every machine signs with keys in its hardware, as core.nix builds it:
methuselah's Secure Enclave and penelope's TPM. Only who may sign lives
here, in `personal/signers.nix`. [The
specification](docs/commit-signing-spec.md) says what signs now and [the
rationale](docs/commit-signing-rationale.md) says why; read both before
changing it.

## Bindings

How this repository holds the repository quality standard:

- **Gate:** `nix flake check --keep-going`, every check in `checks.nix`,
  run by hand before a merge since no CI runs here.
- **Linters:** core.nix's, with its settings, through
  `core.treefmtModules.treefmt`: nixfmt, deadnix and statix for Nix,
  shellcheck for shell, stylua and luacheck for Lua (`.luacheckrc` says
  which program runs which file, and is read as Lua itself), and rumdl for
  Markdown. `treefmt.nix` adds biome, with every rule on but those
  `biome.jsonc` turns off with their reasons, for polkit's JavaScript. The
  `formatting` check runs them all, and fails on a file none reads.
- **Data, read by no linter:** pi's `package-lock.json`, which npm writes,
  and `personal/github-merges.asc`, GitHub's key, listed in `treefmt.nix`;
  and treefmt-nix's own list of locks, patches, `LICENSE` and git's files.
- **Exemptions:** shellcheck runs without its optional checks, as core's
  module sets it; turning them on belongs in core. `skills.sh` disables
  SC2154 at its top, saying why.
- **Tests:** every test is a check in `checks.nix`, evaluating or building;
  there are no VM or browser tests, so no sleeps and no skips.
- **Limits:** no check holds files to 800 lines or folders to 40 entries,
  since core exports none; review holds them.

[core]: https://github.com/Jitsusama/core.nix
[conventions]: https://github.com/Jitsusama/core.nix/blob/main/docs/conventions.md
[machines]: https://github.com/Jitsusama/core.nix/blob/main/docs/machines.md
[testing]: https://github.com/Jitsusama/core.nix/blob/main/docs/testing.md
