# methuselah

Joel's personal MacBook, on core.nix's Mac roles.

## 📁 Where Things Live

```text
darwin.nix          # the Mac: its name, Nix's settings and build group, the account
home.nix            # Joel's account: the agents' committer name
```

## 🚀 Applying It

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
