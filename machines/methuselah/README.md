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
nixos.nix           # the same Mac once NixOS runs beside macOS: its disk in the
                    # space Asahi's installer leaves, the account, its links,
                    # the builder account and what it updates itself from
home.nix            # Joel's account, on either: the agents' committer name,
                    # mycelium's link to penelope, what it declares to work
                    # placed there, the agent its sessions start, and the
                    # work sessions its own may ask
```

## 🐧 Onto NixOS

methuselah gains NixOS beside macOS, on core.nix's MacBook Air M2
hardware, which brings core's own kernel and boot chain for it. macOS
stays, one choice away at start. `nixos.nix` is built and checked here
(`methuselah-on-nixos`) while the Mac still runs only `darwin.nix`; the
install waits on Joel at the Mac. What it still needs before then:

- **Keys:** with no TPM or Secure Enclave, its signing and link keys need
  a new home, a YubiKey or a key on the encrypted disk.
- **Disk:** Asahi's installer shrinks macOS and makes the boot partition;
  then the guide, from the stick `nix run .#methuselah-guide` writes on
  optimus or the Mac, makes the encrypted partition in the free space,
  leaving macOS's partitions as they are (core's `jitsusama.disk.shared`).
- **Builds:** it builds aarch64-linux for optimus natively; its x86_64 and
  aarch64-darwin builds for optimus come only while it runs macOS.

## 🚀 Applying It

methuselah follows this repository's main and core.nix's by itself with
core.nix's `update-to-main`: Joel's account asks whenever either moves,
waiting out a call and while someone is at the Mac, and shows a notice when
it can't update. Its log is `~/Library/Logs/update-to-main-follows.log`. It
can be asked from Joel's account here or through mycelium too:

```sh
update-to-main ask
```

It builds main only when GitHub signed it merging a change, or Joel did with
one of his own keys, and when it follows on from what the Mac runs. After
switching it goes back to the system it left unless, within two minutes, the
Linux VM and mycelium's agent are running again; the agent counts only while
Joel is signed in. By hand, as before:

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
