{
  pkgs,
  username,
  homeDirectory,
  ...
}:
{
  home = {
    stateVersion = "24.05";

    username = username;
    homeDirectory = homeDirectory;

    packages = with pkgs; [
      # Development Tools
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
      watch
      coreutils
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
    ];
  };

  programs = {
    git = {
      userEmail = "joel@grrbrr.ca";
      lfs.enable = true;
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu";
        signByDefault = true;
      };
      extraConfig = {
        commit.template = "~/.config/git/commit-template";
        gpg = {
          format = "ssh";
          ssh = {
            program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
            allowedSignersFile = "~/.config/git/gpg-ssh-allowed-signers";
          };
        };
      };
    };

    bat = {
      config = {
        theme = "TwoDark";
        style = "changes";
      };
    };

    go = {
      enable = true;
    };
  };
}