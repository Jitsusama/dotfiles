{ config, pkgs, username, homeDirectory, ... }:

{
  # Home Manager configuration
  home = {
    username = username;
    homeDirectory = homeDirectory;

    # Home Manager Release That Config Is Compatible With
    stateVersion = "24.05";

    # User Packages
    packages = with pkgs; [
      # Development Tools
      # git
      # vim
      # curl
      # wget
      
      # System Utilities
      # htop
      # tree
      # jq
    ];

    # Dotfiles Management
    file = {
      # Example: manage a config file
      # ".vimrc".source = ./dotfiles/.vimrc;
    };

    # Environment Variables
    sessionVariables = {
      # EDITOR = "vim";
    };
  };

  # Program Configurations
  programs = {
    home-manager.enable = true;
    
    # git = {
    #   enable = true;
    #   userName = "Your Name";
    #   userEmail = "you@example.com";
    # };
  };
}
