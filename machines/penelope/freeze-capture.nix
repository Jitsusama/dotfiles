# penelope froze 16 s into the boot after a warm restart on 2026-10-26: the
# disk stopped answering, the kernel ran on logging btrfs read errors, and
# nothing reached the journal after the moment it stopped. This keeps the
# next one's kernel log off the disk, in the firmware's variables through
# efi_pstore, which the kernel writes only when it panics: core's
# disk-loss-panic, which flake.nix imports beside this file, panics it once
# the disk stops answering. systemd-pstore copies the record to
# /var/lib/systemd/pstore at the next boot and clears the variable. This
# file and that import come out once the freeze's cause is fixed.
{ config, ... }:
{
  jitsusama.diskLossPanic.disk = config.jitsusama.disk.device;

  # Every kernel message reaches the text console, so a freeze that never
  # panics still shows nvme's warnings on Ctrl+Alt+F2 for a photo.
  boot.consoleLogLevel = 7;
}
