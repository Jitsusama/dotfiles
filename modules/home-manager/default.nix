{
  pkgs,
  username,
  homeDirectory,
  agentic-harness-pi,
  agentic-harness-core,
  agentic-harness-claude,
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
      (callPackage ./pi/package.nix { })
      (callPackage ./agentic-harness-core/package.nix { inherit agentic-harness-core; })
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
      terraform-ls
      typescript-language-server
      yaml-language-server
      yamllint

      # System Utilities
      coreutils
      exiftool
      ffmpeg
      minicom
      nethack
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

    file.".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = "anthropic";
      defaultModel = "claude-sonnet-5";
      packages = [
        "git:github.com/Jitsusama/agentic-harness.pi"
      ];
    };

    # agentic-harness.pi's skills follow the Agent Skills standard, the same
    # format Claude Code loads. Most skills assume a pi extension is present
    # to back a tool they instruct the model to call, so only the portable
    # subset ships here (see pi/claude-skills.nix for the allowlist and the
    # small patches that strip pi-specific tooling from a few of them).
    file.".claude/skills/agentic-harness-pi".source =
      pkgs.callPackage ./pi/claude-skills.nix { inherit agentic-harness-pi; };

    # A Claude Code plugin in a skills-directory subfolder auto-loads with
    # no marketplace or install step: agentic-harness.claude's own
    # .claude-plugin/plugin.json is enough. It calls the
    # agentic-harness-core CLI above (on PATH) for the same domain logic
    # agentic-harness.pi drives through pi's extension API.
    file.".claude/skills/agentic-harness-claude".source = agentic-harness-claude;
  };

  programs = {
    git = {
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu";
        signByDefault = true;
      };
      settings = {
        user.email = "joel@grrbrr.ca";
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
    neovim = {
      withPython3 = true;
      initLua = builtins.readFile ./neovim/rust-lsp.lua;
    };
  };
}
