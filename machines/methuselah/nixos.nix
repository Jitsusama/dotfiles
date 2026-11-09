# methuselah once it runs NixOS, Joel's personal MacBook Air M2, still a
# builder for optimus, as the guide installs it: its disk laid out in the
# space Asahi's installer leaves free, the account, its links, and what it
# updates itself from. The hardware, its kernel and boot chain, niri, greetd and
# networking come from core.nix. macOS stays beside it. It's built and checked
# here before NixOS is installed; until then, darwin.nix is all the Mac runs.
{ config, lib, ... }:
let
  signers = import ../../personal/signers.nix;
  systemctl = lib.getExe' config.systemd.package "systemctl";
  # Who may move a main methuselah builds: GitHub, merging a change, or Joel
  # with a key of his own; an agent's key alone never does.
  mergers = {
    openpgp = [ ../../personal/github-merges.asc ];
    ssh = map (
      key: ''${config.home-manager.users.jitsusama.jitsusama.identity.email} namespaces="git" ${key}''
    ) signers.joel;
  };
in
{
  networking.hostName = "methuselah";

  # macOS keeps its own partitions, and Asahi's installer makes the boot
  # partition m1n1 names. The guide makes one encrypted partition in the
  # free space beside them, laid out as core lays out a whole disk, and
  # names that boot partition for it; either YubiKey or the recovery words
  # open it, since the Mac has no TPM. The Mac has one internal disk, and a
  # stick is a USB one, so nvme0n1 is always it.
  jitsusama.disk = {
    device = "/dev/nvme0n1";
    shared = true;
    # As much as its 24 GB of memory.
    swapSize = "24G";
    # The guide lays the disk out with a first key it holds in memory, and
    # takes it off once the YubiKeys and the recovery key are enrolled.
    installKey = "/run/guide/install-key";
  };

  users.users.jitsusama = {
    isNormalUser = true;
    description = "Joel Gerber";
    extraGroups = [ "wheel" ];
  };
  home-manager.users.jitsusama.imports = [ ./home.nix ];

  # The link keys of penelope and optimus, each from a TPM that asks
  # nothing, pinned to its end of a link or an attach as that machine, so
  # neither runs a shell here, as on the Mac today. methuselah's own link
  # key has no TPM or Secure Enclave to live in on Linux, so core keeps it
  # as a file on the encrypted disk, as it does on any machine with no TPM.
  jitsusama.mycelium = {
    account = "jitsusama";
    linkedFrom.personal.penelope = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAKy/GVdnQYujyvYnzwc+AwH+HcZdT9U2jnF9xotfm/5cR01wwsViK6QTwoQbKHcgCcUyixzfYLM7/ClDDX5PTM= jitsusama@penelope agents";
    linkedFrom.personal.optimus = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOmKJWW7RcdxOhuqYvu/xU7R0ktu509y7dJVtuKNKP+vUgsHucMkl6uhEUa4LSw/om7fdytbPgkDnpnM2GJnWtM= jitsusama@optimus personal link";
  };

  # penelope's own host key, which mycelium's link to her checks.
  programs.ssh.knownHosts.penelope = {
    hostNames = [ "penelope.local" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxQCGNt7AzUZc8Niz0KOE61rWUmwdxb9nGO7xk7U8BL";
  };

  # methuselah builds aarch64-linux for optimus natively, as its VM does on
  # the Mac today: optimus's nix-daemon logs in as builder with its own key
  # and speaks Nix's protocol, and core's nix-daemon module keeps those
  # builds below Joel's programs. The key can run nothing else, so a trusted
  # store user is all it gets. x86_64 builds stay with optimus's other
  # builders, since nothing here runs them at Rosetta's speed.
  services.openssh.enable = true;
  users.users.builder = {
    isSystemUser = true;
    group = "builder";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      ''restrict,command="${config.nix.package}/bin/nix-daemon --stdio" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRkdxraohorYagcirm3lEonh6at0F7DvFoLuEqBQajh optimus nix-daemon''
    ];
  };
  users.groups.builder = { };
  nix.settings.trusted-users = [
    "jitsusama"
    "builder"
  ];

  # The machine's own account: the greeter wears its look and asks for it
  # first, and since unlocking the disk already proved it's Joel, niri
  # starts without asking again.
  jitsusama.login.account = "jitsusama";

  # methuselah updates itself to this repository's main, with core.nix at
  # its own main, as penelope does: Joel's account follows both and asks
  # whenever either moves, and mycelium's node may ask too. main counts only
  # when GitHub signed it merging a change, or Joel did with a key of his
  # own. A changed kernel waits for the next boot.
  jitsusama.update-to-main = {
    repository = "https://github.com/Jitsusama/dotfiles";
    output = "nixosConfigurations.methuselah.config.system.build.toplevel";
    signers = mergers;
    follows.core = {
      repository = "https://github.com/Jitsusama/core.nix";
      signers = mergers;
    };
    askers = [ "jitsusama" ];
    follower = "jitsusama";
    # After a live switch it's whole when the greeter, its Wi-Fi and the SSH
    # optimus builds through all run; otherwise it goes back. One unit each,
    # since is-active passes when any one of several is.
    health =
      map
        (unit: [
          systemctl
          "is-active"
          "--quiet"
          unit
        ])
        [
          "greetd.service"
          "wifid.service"
          "sshd.service"
        ];
  };

  # The release it will first be installed with; read the release notes
  # before changing it.
  system.stateVersion = "26.11";
}
