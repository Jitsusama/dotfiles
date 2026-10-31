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
home.nix            # Joel's account: the agents' committer name
```

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
says how the design came about and [the
rationale](../../docs/commit-signing-rationale.md) says why.
