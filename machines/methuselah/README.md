# methuselah

Joel's personal MacBook, on core.nix's Mac roles.

## 📁 Where Things Live

```text
darwin.nix          # the Mac: its name, Nix's settings and build group, the account
home.nix            # Joel's account: the signing keys and OmniWM
secure-enclave.nix  # the Secure Enclave keys that sign its commits
```

## 🚀 Applying It

```sh
darwin-rebuild build --flake .#methuselah
sudo darwin-rebuild switch --flake .#methuselah
```

## 🔑 Signing

Its commits are signed by keys in its Secure Enclave, which can't be
exported or backed up and end with the logic board. [The
specification](../../docs/commit-signing-spec.md) says how and [the
rationale](../../docs/commit-signing-rationale.md) says why.
