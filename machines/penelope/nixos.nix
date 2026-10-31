# penelope, Joel's personal Surface Laptop 4, as the guide installs it: its
# NVMe disk encrypted as core lays it out, Secure Boot with its own keys, and the
# account. The hardware, niri, greetd and networking come from core.nix.
{ config, lib, ... }:
let
  signers = import ../../personal/signers.nix;
  systemctl = lib.getExe' config.systemd.package "systemctl";
in
{
  networking.hostName = "penelope";

  jitsusama.disk = {
    device = "/dev/disk/by-id/nvme-eui.ace42e0005506bd1";
    # As much as its 8 GB of memory, so it can hibernate.
    swapSize = "8G";
    # The guide lays the disk out with a first key it holds in memory, and
    # takes it off once the YubiKeys and the recovery key are enrolled.
    installKey = "/run/guide/install-key";
  };

  # penelope is the machine the guide is proven on, wiped and installed again
  # and again from optimus, which reaches it over SSH: Joel with his own key
  # and his agents with theirs, both sealed in optimus's TPM.
  services.openssh.enable = true;
  users.users.jitsusama = {
    isNormalUser = true;
    description = "Joel Gerber";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPJqAsoQlLkci9Hi2MKEGpdyFPtNZLH1wYQa5ofTY2AH05qxHBjMh89kLS4ev+9T6DVTRQjQ7TR9BLY/DkZCheE= jitsusama@optimus"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAXa4vhfKKZFJT7h88Yo70XedUORGkaxhdUkhzMw99qoWC5AKadmuY1K++B6/Bob9dcWOUJnoqkeLpLoAzua81Y= jitsusama@optimus agents"
    ];
  };
  # optimus's personal-realm node links here with a key of its own in
  # optimus's TPM, which core pins to that realm's link or joining a session
  # held here, as optimus: no shell, and nothing forwarded.
  jitsusama.mycelium = {
    account = "jitsusama";
    linkedFrom.personal.optimus = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOmKJWW7RcdxOhuqYvu/xU7R0ktu509y7dJVtuKNKP+vUgsHucMkl6uhEUa4LSw/om7fdytbPgkDnpnM2GJnWtM= jitsusama@optimus personal link";
  };
  home-manager.users.jitsusama.imports = [ ./home.nix ];

  # methuselah's own host key, which mycelium's link to it checks.
  programs.ssh.knownHosts.methuselah = {
    hostNames = [ "methuselah.local" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSbRSaae8/rtKXp4BAHE1JwCI7qwFU1plO3INqjssss";
  };
  # The dock on Joel's desk, its cable trusted as his Wi-Fi is, so penelope
  # finds methuselah and optimus by their .local names over the link that
  # holds its route, and is found there.
  jitsusama.network.trustedCables = [ "d0:c1:b5:22:58:b9" ];

  # The resolver answers a .local name with a link-local IPv6 address and
  # no interface, which ssh can't connect to, so it asks for IPv4 alone.
  programs.ssh.extraConfig = ''
    Host methuselah.local
      AddressFamily inet
  '';
  nix.settings.trusted-users = [
    "jitsusama"
    "builder"
  ];
  # Two builds at once, each with three compilers, so a C++ build stays near
  # six compilers and 1.5 GB in penelope's 7.2. At Nix's default, every
  # thread at once, openvino-genai ran nine compilers beside rustc, took
  # 10.8 GB of swap, and left Joel's session waiting on memory for 22% of
  # a 10 s stretch (10-31).
  nix.settings.cores = 3;
  nix.settings.max-jobs = 2;

  # penelope works for the personal realm with its lid shut. On a charger,
  # the desk's monitor among them, a shut lid never puts it to sleep. On
  # battery a shut lid sleeps it as on any laptop, unless something holds a
  # block against that: the rule lets mycelium's node, a service of Joel's
  # with no session, hold one while it runs work.
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  security.polkit.extraConfig = builtins.readFile ./node-holds-the-lid.rules;

  # penelope builds for optimus: optimus's nix-daemon logs in as builder with
  # its own key and speaks Nix's protocol, and core's nix-daemon module keeps
  # those builds below Joel's programs. The key can run nothing else, so a
  # trusted store user is all it gets.
  users.users.builder = {
    isSystemUser = true;
    group = "builder";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      ''restrict,command="${config.nix.package}/bin/nix-daemon --stdio" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRkdxraohorYagcirm3lEonh6at0F7DvFoLuEqBQajh optimus nix-daemon''
    ];
  };
  users.groups.builder = { };

  # The machine's own account: the greeter wears its look and asks for it
  # first, and since unlocking the disk already proved it's Joel, niri
  # starts without asking again. Without it the greeter is tuigreet alone.
  jitsusama.login.account = "jitsusama";

  # penelope updates itself to this repository's main when Joel's account
  # asks, mycelium's node among what runs as it, so no switch waits on him
  # here. As on methuselah, main counts only when GitHub signed it merging a
  # change, or Joel did with a key of his own; an agent's key alone never
  # moves it. A changed kernel waits for the next boot, and below 20% on
  # battery it doesn't start.
  jitsusama.update-to-main = {
    repository = "https://github.com/Jitsusama/dotfiles";
    output = "nixosConfigurations.penelope.config.system.build.toplevel";
    signers = {
      openpgp = [ ../../personal/github-merges.asc ];
      ssh = map (
        key: ''${config.home-manager.users.jitsusama.jitsusama.identity.email} namespaces="git" ${key}''
      ) signers.joel;
    };
    askers = [ "jitsusama" ];
    # After a live switch it's whole when the greeter Joel signs in at, its
    # Wi-Fi and the SSH optimus reaches it by all run; otherwise it goes back.
    # One unit each, since is-active passes when any one of several is.
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

  # The release it was first installed with by the guide; read the release
  # notes before changing it.
  system.stateVersion = "26.05";
}
