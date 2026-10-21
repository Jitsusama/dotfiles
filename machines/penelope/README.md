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

The guide, which is still being built, installs it from a USB stick: core's
encrypted disk on its NVMe drive, Secure Boot with its own keys, and the disk
opened by the TPM with a PIN, or by either YubiKey or the recovery key. To
boot the stick, hold
volume-down, press and release power, and keep holding volume-down until the
Surface logo has gone.

Its install from before has a plain ext4 disk that `nixos.nix` doesn't
describe, so it can't switch to this. It stays as it is until the guide
wipes it.

## 🔑 Signing

Commits are signed with keys sealed in its TPM, as core's signing module
says; until they're made there, git can't sign, and their public halves join
the signers in `layers/personal/home.nix`.
