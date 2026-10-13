# penelope, Joel's personal AMD laptop. Its disks are as the installer found
# them (hardware.nix); niri, greetd, NetworkManager and the rest come with
# core's roles.
{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  networking.hostName = "penelope";
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Its TSC is an unstable clock source, so the kernel is told not to trust it.
  boot.kernelParams = [ "tsc=unstable" ];

  # Reached over SSH, with its firewall off, as it was set up.
  services.openssh.enable = true;
  networking.firewall.enable = false;

  users.users.jitsusama = {
    isNormalUser = true;
    description = "Joel Gerber";
    extraGroups = [ "wheel" ];
  };
  home-manager.users.jitsusama.imports = [ ./home.nix ];
  nix.settings.trusted-users = [ "jitsusama" ];

  # The NixOS it was installed with; read the release notes before changing.
  system.stateVersion = "25.05";
}
