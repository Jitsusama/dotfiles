# penelope, Joel's personal Surface Laptop 4, as the guide installs it: its
# NVMe disk encrypted as core lays it out, Secure Boot with its own keys, and the
# account. The hardware, niri, greetd and networking come from core.nix, and
# README.md says why the install it runs today can't switch to this.
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
  home-manager.users.jitsusama.imports = [ ./home.nix ];

  # methuselah's own host key, which mycelium's link to it checks.
  programs.ssh.knownHosts.methuselah = {
    hostNames = [ "methuselah.local" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSbRSaae8/rtKXp4BAHE1JwCI7qwFU1plO3INqjssss";
  };
  # The resolver answers a .local name with a link-local IPv6 address and
  # no interface, which ssh can't connect to, so it asks for IPv4 alone.
  programs.ssh.extraConfig = ''
    Host methuselah.local
      AddressFamily inet
  '';
  nix.settings.trusted-users = [ "jitsusama" ];

  # The machine's own account: the greeter wears its look and asks for it
  # first, and since unlocking the disk already proved it's Joel, niri
  # starts without asking again. Without it the greeter is tuigreet alone.
  jitsusama.login.account = "jitsusama";

  # The release it was first installed with by the guide; read the release
  # notes before changing it.
  system.stateVersion = "26.05";
}
