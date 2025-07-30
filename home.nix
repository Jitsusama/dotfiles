{ config, pkgs, username, homeDirectory, ... }:

{
  # Home Manager configuration
  home = {
    username = username;
    homeDirectory = homeDirectory;

    # Home Manager Release That Config Is Compatible With
    stateVersion = "24.05";

    # User Packages (only tools without programs.* support)
    packages = with pkgs; [
      # Development Tools
      git-lfs
      gh
      glab
      nodejs
      python3
      poetry
      pipx
      gradle
      delve
      
      # Language Servers & Formatters  
      terraform
      terraform-ls
      typescript
      typescript-language-server
      yaml-language-server
      marksman
      golangci-lint
      black
      shfmt
      
      # System Utilities
      tree
      watch
      coreutils
      lsd
      ffmpeg
      minicom
      
      # Network & Security
      awscli
      vault
      
      # Security & DevOps Tools
      ansible
      ansible-lint
      hadolint
      kics
      trivy
      
      # Container & Infrastructure
      kubernetes-helm
      kustomize
      
      # Text Processing
      jq
      yq
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
    
    # Version Control
    git = {
      enable = true;
      userName = "Joel Gerber";
      userEmail = "joel@grrbrr.ca";
      
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu";
        signByDefault = true;
      };
      
      extraConfig = {
        core = {
          autocrlf = "input";
          editor = "code --wait";
          excludesFile = "~/.config/git/core-excludes";
        };
        
        init = {
          defaultbranch = "main";
        };
        
        pull = {
          rebase = true;
        };
        
        commit = {
          template = "~/.config/git/commit-template";
        };
        
        gpg = {
          format = "ssh";
          ssh = {
            program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
            allowedSignersFile = "~/.config/git/gpg-ssh-allowed-signers";
          };
        };
      };
    };
    
    # Shell Utilities
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        style = "numbers,changes,header";
      };
    };
    
    # Development Languages
    go = {
      enable = true;
    };
    
    
    # System Monitoring
    btop = {
      enable = true;
    };
  };
}
