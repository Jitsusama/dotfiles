# methuselah

Joel's personal MacBook, on core.nix's Mac roles. It's also a builder for
optimus's Nix: aarch64-darwin itself, and Linux through core.nix's builder
VM, at utility QoS so builds yield to Joel's own programs.

## 📁 Where Things Live

```text
darwin.nix          # the Mac: its name, Nix's settings and build group, the account
                    # and the keys mycelium's links from penelope and optimus
                    # sign in with, and the builder account optimus's Nix
                    # signs in as, and what it updates itself from
nixos.nix           # the same Mac once it's wiped onto NixOS: its disk in the
                    # space Asahi's installer leaves, the account, its links,
                    # the builder account and what it updates itself from
home.nix            # Joel's account, on either: the agents' committer name,
                    # mycelium's link to penelope, what it declares to work
                    # placed there, the agent its sessions start, and the
                    # work sessions its own may ask
```

## 🐧 Onto NixOS

methuselah moves from macOS to NixOS on core.nix's MacBook Air M2
hardware, which brings Asahi's kernel and boot chain. `nixos.nix` is built
and checked here (`methuselah-on-nixos`) while the Mac still runs
`darwin.nix`; the wipe waits on Joel at the Mac. What it still needs
before then:

- **Keys:** with no TPM or Secure Enclave, its signing and link keys need
  a new home, a YubiKey or a key on the encrypted disk.
- **Disk:** the ESP's UUID and the encrypted partition are written by the
  guide at the install.
- **Builds:** it builds aarch64-linux for optimus natively; its x86_64 and
  aarch64-darwin builds for optimus end with macOS.

## 🚀 Applying It

methuselah updates itself to main with core.nix's `update-to-main`, asked
from Joel's account here or through mycelium, with nobody at the Mac:

```sh
update-to-main ask
```

It builds main only when GitHub signed it merging a change, or Joel did with
one of his own keys, and when it follows on from what the Mac runs. By hand,
as before:

```sh
darwin-rebuild build --flake .#methuselah
sudo darwin-rebuild switch --flake .#methuselah
```

## 🔑 Signing

Its commits are signed by keys in its Secure Enclave, which can't be
exported or backed up and end with the logic board. core.nix's
`secure-enclave-signing` module signs with them, and its `se-keys` makes
them on a new Mac. [The specification](../../docs/commit-signing-spec.md)
says what signs on each machine and [the
rationale](../../docs/commit-signing-rationale.md) says why the design is
what it is.
