# penelope, Joel's personal Surface Laptop 4, as the guide installs it: core's
# encrypted disk on its NVMe drive, Secure Boot with its own keys, and the
# account. The hardware, niri, greetd and networking come from core.nix, and
# README.md says why the install it runs today can't switch to this.
{
  networking.hostName = "penelope";

  jitsusama.disk = {
    device = "/dev/disk/by-id/nvme-eui.ace42e0005506bd1";
    # As much as its 8 GB of memory, so it can hibernate.
    swapSize = "8G";
  };

  # Its earlier install ran with this, and why wasn't written down. It puts
  # the clock on HPET, which costs every read of the time, so it stays only
  # until a boot without it has been measured.
  boot.kernelParams = [ "tsc=unstable" ];

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
  nix.settings.trusted-users = [ "jitsusama" ];

  # The release it was first installed with by the guide; read the release
  # notes before changing it.
  system.stateVersion = "26.05";
}
