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
  # Who may move main: GitHub merging a change (its key,
  # personal/github-merges.asc, from github.com/web-flow.gpg), or Joel with a
  # key of his own; an agent's key alone never moves the Mac.
  mergers = {
    openpgp = [ ../../personal/github-merges.asc ];
    ssh = map (
      key: ''${config.home-manager.users.jitsusama.jitsusama.identity.email} namespaces="git" ${key}''
    ) signers.joel;
  };
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
  # Joel restarts a wedged VM from optimus over SSH, where sudo would want
  # this Mac's password; this lets him run just those two restarts without.
  jitsusama.linux-builder.restartableBy = [ config.system.primaryUser ];
  # The VM is optimus's only native aarch64 builder, and a kernel or a whole
  # NixOS system fills core's 60 GiB. 150 leaves this Mac's own disk about
  # 34 GB. The image is only made when missing, so a larger size takes hold
  # once /var/lib/linux-builder-vz/nixos.qcow2 is removed and the VM
  # restarted.
  jitsusama.linux-builder.disk = 150 * 1024;

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
  users.users.jitsusama.home = "/Users/jitsusama";
  # The link keys of penelope and optimus, each from a TPM that asks
  # nothing, pinned to its end of a link or an attach as that machine, so
  # neither runs a shell here: any agent there may sign with its key.
  jitsusama.mycelium = {
    account = "jitsusama";
    linkedFrom.personal.penelope = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAKy/GVdnQYujyvYnzwc+AwH+HcZdT9U2jnF9xotfm/5cR01wwsViK6QTwoQbKHcgCcUyixzfYLM7/ClDDX5PTM= jitsusama@penelope agents";
    linkedFrom.personal.optimus = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOmKJWW7RcdxOhuqYvu/xU7R0ktu509y7dJVtuKNKP+vUgsHucMkl6uhEUa4LSw/om7fdytbPgkDnpnM2GJnWtM= jitsusama@optimus personal link";
  };
  home-manager.users.jitsusama.imports = [ ./home.nix ];

  # penelope's own host key, which mycelium's link to her checks.
  programs.ssh.knownHosts.penelope = {
    hostNames = [ "penelope.local" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxQCGNt7AzUZc8Niz0KOE61rWUmwdxb9nGO7xk7U8BL";
  };

  # methuselah updates itself to this repository's main and core.nix's, as
  # penelope does: Joel's account follows both and asks whenever either moves,
  # so no update waits on him or on a lock bump. It waits out a call and
  # while he's at the Mac, and says so in a notice when it can't update.
  jitsusama.update-to-main = {
    repository = "https://github.com/Jitsusama/dotfiles";
    output = "darwinConfigurations.methuselah.system";
    signers = mergers;
    follows.core = {
      repository = "https://github.com/Jitsusama/core.nix";
      signers = mergers;
    };
    askers = [ "jitsusama" ];
    follower = "jitsusama";
    # A switch goes back unless, within two minutes, what optimus leans on
    # here is running again: the Linux VM, its only native aarch64 builder,
    # and mycelium's agent, which holds the links, in Joel's account. That
    # agent only runs while he's signed in, so with no session of his it
    # counts as back. Each reads launchd's state line alone, never a job's
    # environment, which can hold tokens.
    health =
      let
        running =
          target: "/bin/launchctl print ${target} | /usr/bin/grep -q '^[[:space:]]*state = running$'";
        account = config.system.primaryUser;
        mycelium = config.home-manager.users.${account}.launchd.agents.mycelium.config.Label;
      in
      [
        [
          "/bin/sh"
          "-c"
          (running "system/${config.launchd.daemons.linux-builder-vz.serviceConfig.Label}")
        ]
        [
          "/bin/sh"
          "-c"
          ''
            uid=$(/usr/bin/id -u ${account}) || exit 1
            /bin/launchctl print "gui/$uid" > /dev/null 2>&1 || exit 0
            ${running "\"gui/$uid/${mycelium}\""}
          ''
        ]
      ];
  };
  # macOS's firewall, which ships off: a MacBook joins any network it's
  # taken to, and the AirPlay receiver and other sharing answer there on
  # every interface. Software Apple or a known developer signed may still
  # take connections, so Remote Login, and the SSH optimus's builds and
  # mycelium's links come in through, are untouched, as is the Linux VM,
  # which answers only on loopback. Stealth leaves a port nothing answers on
  # silent, ping included. macOS asks the person at the screen before an
  # unsigned program, which anything Nix builds is, takes connections from
  # the network; on 7 November only Apple's own listened past loopback
  # here, so nothing asks. That's why it's this Mac's setting, not core's: a
  # Mac takes it once its own listeners are checked. This one is moving to
  # NixOS, whose firewall core already sets.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    allowSigned = true;
    allowSignedApp = true;
  };

  # Read the changelog before changing it.
  system.stateVersion = 4;
}
