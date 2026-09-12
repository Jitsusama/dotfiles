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
      lima
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

    # Append-only identity register, shared by every machine because it says
    # who may sign, not who does. Retire an identity by adding
    # valid-before="YYYYMMDD" to its line -- never by deleting the line: git
    # checks these bounds against the commit's own timestamp, not the wall
    # clock, so retiring this way keeps everything signed earlier verifiable.
    file.".config/git/gpg-ssh-allowed-signers".text = ''
      # 1Password-held ed25519. Still live: it is the rollback target.
      joel@grrbrr.ca namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu
      # methuselah Secure Enclave, identity joel-signing (-t bio).
      joel@grrbrr.ca namespaces="git" sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBP/+4vmV9jofa+NC1HONKq//dKeeLk5BGswU6Jod45hIkac0NHyXwaYSO/Js7h34ceJfQB2ReQrE+BGcQPcGH60AAAAEc3NoOg==
      # methuselah Secure Enclave, identity agent-signing (-t none). Listed
      # under joel@grrbrr.ca because a forge only renders Verified when the
      # committer email is a verified address on the account, and that is the
      # only such address. Attribution therefore lives in the committer *name*
      # and in the signing key fingerprint, not in the email. The key remains
      # separately revocable: valid-before, a GitLab revoke and a GitHub delete
      # all act per key, not per principal.
      joel@grrbrr.ca namespaces="git" sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBNBQUgGis2mignI9aGhDFOi7MMHjIgFCN7abqcsquQDsnjnYGAn7YyHtQPkg/0GDDyx994qyzJ7tSqea0x/hBxEAAAAEc3NoOg==
    '';
  };

  programs = {
    git = {
      # signing.key and gpg.ssh.program are host-specific: methuselah signs from
      # its Secure Enclave, penelope through 1Password. Set in hosts/*.
      signing.signByDefault = true;
      settings = {
        user.email = "joel@grrbrr.ca";
        commit.template = "~/.config/git/commit-template";

        # Reclaimed from a hand-written ~/.gitconfig that had been shadowing
        # this file since January. The editor and diff/merge tools pointed at
        # VS Code, which fought the rest of the environment (EDITOR is already
        # nvim); nvimdiff is a git built-in, so no cmd lines are needed.
        core = {
          excludesFile = "~/.config/git/core-excludes";
          editor = "nvim";
        };
        diff.tool = "nvimdiff";
        merge.tool = "nvimdiff";
        gpg = {
          format = "ssh";
          ssh.allowedSignersFile = "~/.config/git/gpg-ssh-allowed-signers";
        };
      };
    };
    neovim = {
      withPython3 = true;
      initLua = builtins.readFile ./neovim/rust-lsp.lua;
    };
  };
}
