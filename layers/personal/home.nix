# What every personal machine adds to core.nix's roles in Joel's account, on
# macOS and Linux alike: the personal identity, the tools he uses outside
# work, pi and Claude Code's skills, and git's personal settings. Each
# machine's own account settings, its signing included, are in machines/.
{ core, homeModules }:
{ pkgs, ... }:
{
  imports = [
    # Where the identity this layer sets is declared.
    core.homeModules.identity
    homeModules.agentic-harness-core
    homeModules.claude
    ../../modules/neovim/home.nix
    ../../modules/pi/home.nix
  ];

  jitsusama.identity.email = "joel@grrbrr.ca";

  home.packages = [
    # Development tools
    pkgs.delve
    pkgs.exercism
    pkgs.glab
    pkgs.gradle
    pkgs.lima
    pkgs.mise
    pkgs.nodejs
    pkgs.pipx
    pkgs.poetry
    pkgs.python3
    pkgs.usage

    # Language servers and formatters
    pkgs.bash-language-server
    pkgs.black
    pkgs.dockerfile-language-server
    pkgs.golangci-lint
    pkgs.golangci-lint-langserver
    pkgs.gopls
    pkgs.helm-ls
    pkgs.marksman
    pkgs.python3Packages.python-lsp-server
    pkgs.shfmt
    pkgs.taplo
    pkgs.terraform-ls
    pkgs.typescript-language-server
    pkgs.yaml-language-server
    pkgs.yamllint

    # System utilities
    pkgs.coreutils
    pkgs.exiftool
    pkgs.ffmpeg
    pkgs.minicom
    pkgs.nethack
    pkgs.watch

    # Network and security
    pkgs.awscli
    pkgs.gitleaks
    pkgs.lychee

    # Security and DevOps
    pkgs.ansible
    pkgs.ansible-lint
    pkgs.hadolint
    pkgs.kics
    pkgs.trivy

    # Containers and infrastructure
    pkgs.kubernetes-helm
    pkgs.kustomize
  ];

  # Who may sign, shared by every machine because it says who may sign, not
  # who does. It only grows: an identity is retired by adding
  # valid-before="YYYYMMDD" to its line, never by deleting the line, since
  # git checks those bounds against the commit's own time rather than the
  # clock's, so everything signed earlier stays verifiable.
  home.file.".config/git/gpg-ssh-allowed-signers".text = ''
    # 1Password-held ed25519. Still live: it is the rollback target.
    joel@grrbrr.ca namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu
    # methuselah Secure Enclave, identity joel-signing (-t bio).
    joel@grrbrr.ca namespaces="git" sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBP/+4vmV9jofa+NC1HONKq//dKeeLk5BGswU6Jod45hIkac0NHyXwaYSO/Js7h34ceJfQB2ReQrE+BGcQPcGH60AAAAEc3NoOg==
    # methuselah Secure Enclave, identity agent-signing (-t none). Listed
    # under joel@grrbrr.ca because a forge only renders Verified when the
    # committer email is a verified address on the account, and that is the
    # only such address. Attribution therefore lives in the committer name
    # and in the signing key fingerprint, not in the email. The key remains
    # separately revocable: valid-before, a GitLab revoke and a GitHub delete
    # all act per key, not per principal.
    joel@grrbrr.ca namespaces="git" sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBNBQUgGis2mignI9aGhDFOi7MMHjIgFCN7abqcsquQDsnjnYGAn7YyHtQPkg/0GDDyx994qyzJ7tSqea0x/hBxEAAAAEc3NoOg==
  '';

  programs.git = {
    # Which key signs is each machine's: methuselah's Secure Enclave
    # (machines/methuselah), and penelope's TPM, through core's signing.
    signing.signByDefault = true;
    settings = {
      commit.template = "~/.config/git/commit-template";

      # Reclaimed from a hand-written ~/.gitconfig that had been shadowing
      # this file since January. Its editor and diff and merge tools were VS
      # Code, which fought the rest of the environment, where EDITOR is
      # already nvim; nvimdiff is built into git, so no cmd lines are needed.
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
}
