# methuselah, Joel's personal MacBook, and a builder for optimus's Nix: its
# own aarch64-darwin, and Linux through core's builder VM.
{ config, pkgs, ... }:
let
  # optimus's root key for sending builds out (its
  # /etc/nix/offload_ed25519.pub).
  optimusOffload = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRkdxraohorYagcirm3lEonh6at0F7DvFoLuEqBQajh nix-offload";
  # Where the Linux VM's SSH answers, on this Mac's loopback.
  vmSsh = "127.0.0.1:${toString config.jitsusama.linux-builder.port}";
  signers = import ../../personal/signers.nix;
in
{
  networking.hostName = "methuselah";
  nixpkgs.hostPlatform = "aarch64-darwin";

  # nix-darwin runs Nix here, and its build group was made before nix-darwin
  # was, with a different GID.
  nix = {
    package = pkgs.nix;
    optimise.automatic = true;
    settings.experimental-features = "nix-command flakes";
    # The builder may give the daemon derivations to build, which only a
    # trusted user can. nix-darwin keeps root beside it.
    settings.trusted-users = [ "builder" ];
    # The Linux builder's line, after nix-darwin's empty `builders`, so it
    # counts.
    extraOptions = ''
      !include linux-builder.conf
    '';
  };
  ids.gids.nixbld = 350;

  # Linux builds go to the VM at utility QoS, so they yield to Joel's own
  # programs. Here nix-darwin runs Nix, so it's nix-darwin's daemon that
  # starts again to read the VM's line.
  jitsusama.linux-builder.nixDaemon = "org.nixos.nix-daemon";
  # This daemon won't pass a build from optimus on to the VM, so optimus
  # signs in to the VM itself, jumping through the builder account below.
  jitsusama.linux-builder.authorizedKeys = [ optimusOffload ];

  # The account optimus's Nix signs in as to build here. Its key may only
  # speak Nix's daemon protocol, never open a shell, and forward only to
  # the Linux VM's SSH.
  users.knownUsers = [ "builder" ];
  users.users.builder = {
    uid = 450;
    gid = 20;
    home = "/var/empty";
    shell = "/bin/sh";
    isHidden = true;
    openssh.authorizedKeys.keys = [
      ''restrict,port-forwarding,permitopen="${vmSsh}",command="/run/current-system/sw/bin/nix-daemon --stdio" ${optimusOffload}''
    ];
  };
  # Remote Login here admits only com.apple.access_ssh's members, a group
  # nix-darwin doesn't manage, so the builder is put in it at each switch.
  system.activationScripts.postActivation.text = ''
    /usr/sbin/dseditgroup -o checkmember -m builder com.apple.access_ssh > /dev/null ||
      /usr/sbin/dseditgroup -o edit -a builder -t user com.apple.access_ssh
  '';

  system.primaryUser = "jitsusama";
  users.users.jitsusama = {
    home = "/Users/jitsusama";
    # penelope's agents' key, from a TPM that asks nothing, so its personal
    # node links here without a prompt.
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAKy/GVdnQYujyvYnzwc+AwH+HcZdT9U2jnF9xotfm/5cR01wwsViK6QTwoQbKHcgCcUyixzfYLM7/ClDDX5PTM= jitsusama@penelope agents"
    ];
  };
  # optimus's personal link key, from its TPM, pinned to its end of a link or
  # an attach as optimus, so it never runs a shell here.
  jitsusama.mycelium = {
    account = "jitsusama";
    linkedFrom.personal.optimus = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOmKJWW7RcdxOhuqYvu/xU7R0ktu509y7dJVtuKNKP+vUgsHucMkl6uhEUa4LSw/om7fdytbPgkDnpnM2GJnWtM= jitsusama@optimus personal link";
  };
  home-manager.users.jitsusama.imports = [ ./home.nix ];

  # methuselah updates itself to this repository's main when Joel's account
  # asks, so no switch here waits on him at the Mac. main counts only when
  # GitHub signed it, merging a change (its key, personal/github-merges.asc, from
  # github.com/web-flow.gpg), or Joel did with a key of his own; an agent's
  # key alone never moves the Mac.
  jitsusama.update-to-main = {
    repository = "https://github.com/Jitsusama/dotfiles";
    output = "darwinConfigurations.methuselah.system";
    signers = {
      openpgp = [ ../../personal/github-merges.asc ];
      ssh = map (
        key: ''${config.home-manager.users.jitsusama.jitsusama.identity.email} namespaces="git" ${key}''
      ) signers.joel;
    };
    askers = [ "jitsusama" ];
  };
  # Read the changelog before changing it.
  system.stateVersion = 4;
}
