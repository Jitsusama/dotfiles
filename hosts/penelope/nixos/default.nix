{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Fix TSC clocksource instability
  boot.kernelParams = [ "tsc=unstable" ];

  networking.hostName = "penelope";
  networking.networkmanager.enable = true;

  services.libinput.enable = true;
  services.openssh.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      command = "${pkgs.tuigreet}/bin/tuigreet --cmd 'niri --session'";
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    neovim
    sudo
  ];

  # Open ports in the firewall.
  networking.firewall.enable = false;

  programs.hyprland.enable = true;
  programs.niri.enable = true;
  programs.zsh.enable = true;

  # Fix desktop portal for Wayland compositors
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland # for Hyprland
      xdg-desktop-portal-gtk # for GTK file dialogs etc.
    ];
    config = {
      hyprland.default = [
        "hyprland"
        "gtk"
      ];
      niri.default = lib.mkForce [
        "gtk"
      ];
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  system.stateVersion = "25.05"; # Did you read the comment?
}
