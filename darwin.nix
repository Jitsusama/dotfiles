{ config, pkgs, system, username, ... }:

{
  environment.systemPackages = with pkgs; [
    # Fonts
    (nerdfonts.override { fonts = [ "FiraCode" "VictorMono" ]; })
  ];

  # Nix package manager settings
  nix = {
    package = pkgs.nix;
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-rebuild
  system.configurationRevision = null;

  # Used for backwards compatibility, please read the changelog before changing
  system.stateVersion = 4;

  # Fix GID mismatch between existing Nix and nix-darwin
  ids.gids.nixbld = 350;

  # Primary user for system defaults
  system.primaryUser = username;

  # Use the new optimise option instead of auto-optimise-store
  nix.optimise.automatic = true;

  # macOS system settings
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      minimize-to-application = true;
    };
    
    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "clmv";
    };
    
    loginwindow = {
      GuestEnabled = false;
    };
    
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
  };
}
