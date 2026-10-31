# penelope, Joel's personal Surface Laptop 4, as the guide installs it: its
# NVMe disk encrypted as core lays it out, Secure Boot with its own keys, and the
# account. The hardware, niri, greetd and networking come from core.nix.
{ config, ... }:
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
      # optimus's personal-realm node, with a key of its own in optimus's
      # TPM, may only open mycelium's link in that realm: no shell, and
      # nothing forwarded.
      ''restrict,command="/etc/profiles/per-user/jitsusama/bin/mycelium link --realm personal" ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOmKJWW7RcdxOhuqYvu/xU7R0ktu509y7dJVtuKNKP+vUgsHucMkl6uhEUa4LSw/om7fdytbPgkDnpnM2GJnWtM= jitsusama@optimus personal link''
    ];
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

  # penelope works for the personal realm with its lid shut. On a charger,
  # the desk's monitor among them, a shut lid never puts it to sleep. On
  # battery a shut lid sleeps it as on any laptop, unless something holds a
  # block against that: the rule lets mycelium's node, a service of Joel's
  # with no session, hold one while it runs work.
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  security.polkit.extraConfig = builtins.readFile ./node-holds-the-lid.rules;

  # Asleep on battery, penelope hibernates after an hour, or sooner if the
  # battery falls below 5% first, so a night left unplugged never drains it
  # flat. Its worn battery has about 37 Wh, and the node lets go at 20%, so
  # what's left when it sleeps is little; how fast s2idle spends it here
  # hasn't been measured.
  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  systemd.sleep.settings.Sleep.HibernateDelaySec = "1h";

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

  # The release it was first installed with by the guide; read the release
  # notes before changing it.
  system.stateVersion = "26.05";
}
