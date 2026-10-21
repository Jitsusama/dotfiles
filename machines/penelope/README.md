# penelope

Joel's personal Surface Laptop 4. It's also where the guide that installs
core.nix machines from a USB stick is proven, so it's wiped and installed
again often, and nothing on it is dear.

## 💻 The Hardware

| Part     | What it is                                                          |
| -------- | ------------------------------------------------------------------- |
| Model    | Surface Laptop 4, 13.5" with AMD: `microsoft-surface-laptop-4-1958` |
| CPU      | AMD Ryzen 5 Microsoft Surface Edition, six Zen 2 cores             |
| Memory   | 8 GB                                                               |
| Drive    | SK hynix HFM128GDGTNG-87A0A, 128 GB, `nvme-eui.ace42e0005506bd1`   |
| TPM      | a discrete Nuvoton TPM 2.0                                         |
| Keyboard | Colemak Mod-DH on the built-in keyboard, the disk's prompt too     |

## 📁 Where Things Live

```text
nixos.nix   # penelope as the guide installs it: its disk, its kernel's clock,
            # SSH from optimus, and the account
home.nix    # Joel's account: Chrome
```

## 🚀 Installing It

The guide installs it from a USB stick: core's encrypted disk on its NVMe
drive, Secure Boot with its own keys, and the disk opened by either YubiKey or
the recovery key. Sealing it to the TPM with a PIN comes with the guide's
steps for the installed machine, which are still to be built.

1. With the stick plugged into an x86-64 Linux machine, run `nix run .#guide`
   there, as yourself. It names the stick, asks for a recovery passphrase for
   the stick's vault twice (keep it in 1Password), asks for an administrator's
   password once to open the stick, and writes penelope's whole install onto
   it. Either YubiKey and its PIN, or the passphrase, opens it on penelope.
2. Its firmware enforces Secure Boot with penelope's own keys, so the stick
   needs them, or the firmware cleared:
   - With penelope's rescue bundle, run `nix run .#guide -- --rescue-bundle`
     and the bundle's file instead. It asks for either YubiKey's PIN and a
     touch, or the bundle's recovery passphrase, and holds the keys only in
     memory. The stick is signed with penelope's own db key, so the firmware
     boots it, and carries the keys sealed in its vault, so the guide puts
     them back and the firmware is never visited. Penelope makes the bundle
     itself, as root, with `guide seal-keys`; it's ciphertext only, so keep
     it in 1Password and on the other machines.
   - Otherwise the guide makes new keys, which the firmware only takes in
     setup mode. Hold volume-up, press and release power, and keep holding
     until Surface UEFI opens; under Security, set Secure Boot to None.
     Other Surfaces enter setup mode then, but this model hasn't been seen
     to; if it doesn't, the guide says so before it changes anything.
3. To boot the stick, hold volume-down, press and release power, and keep
   holding volume-down until the Surface logo has gone. The guide asks for
   the recovery passphrase, has `penelope` typed back before it wipes the
   drive, enrols the Nano and then the 5Ci, each with its PIN, shows the
   recovery key to keep in 1Password and has it typed back, installs, and
   asks for the account's password twice.
4. It shuts down. Take the stick out and turn penelope on: the disk asks for
   a security token PIN, so type a YubiKey's PIN and touch the key. The
   first boot enrols the keys the guide made and restarts once with Secure
   Boot on.

Its install from before has a plain ext4 disk that `nixos.nix` doesn't
describe, so it can't switch to this. It stays as it is until the guide
wipes it.

## 🔑 Signing

Commits are signed with keys sealed in its TPM, as core's signing module
says; until they're made there, git can't sign, and their public halves join
the signers in `layers/personal/home.nix`.
