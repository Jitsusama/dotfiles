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
      delve
      exercism
      glab
      gradle
      mise
      nodejs
      pipx
      poetry
      python3
      usage

      # Language Servers & Formatters
      bash-language-server
      black
      dockerfile-language-server
      golangci-lint
      golangci-lint-langserver
      gopls
      helm-ls
      marksman
      python312Packages.python-lsp-server
      shfmt
      taplo
      terraform
      terraform-ls
      typescript
      typescript-language-server
      yaml-language-server
      yamllint

      # System Utilities
      coreutils
      exiftool
      ffmpeg
      minicom
      watch

      # Network & Security
      awscli
      gitleaks
      lychee

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
    go = {
      enable = true;
    };
  };
}
