# What every personal machine adds to core.nix's roles in Joel's account, on
# macOS and Linux alike: the personal identity, the tools he uses outside
# work, pi and Claude Code's skills, git's personal settings, and every key
# that may sign. core.nix's roles sign every commit, with the TPM on Linux
# and the Secure Enclave on a Mac. Each machine's own account settings are
# in machines/.
{ core, homeModules }:
{ config, pkgs, ... }:
{
  imports = [
    # Where the identity this layer sets is declared.
    core.homeModules.identity
    # Where the signers this layer lists are declared; the roles bring the
    # hardware that signs.
    core.homeModules.signing
    homeModules.claude
    homeModules.pi
    ../../modules/neovim/home.nix
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
  #
  # Every key is listed under joel@grrbrr.ca, the agents' too, because a
  # forge only renders Verified when the committer email is a verified
  # address on the account, and that is the only such address. Attribution
  # lives in the committer name and the key's fingerprint instead, and each
  # key stays revocable on its own: valid-before, a GitLab revoke and a
  # GitHub delete all act per key, not per principal.
  jitsusama.signing.allowedSigners =
    map (key: ''${config.jitsusama.identity.email} namespaces="git" ${key}'')
      [
        # 1Password-held ed25519, which signed before the Secure Enclave did.
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu"
        # methuselah's Secure Enclave: joel-signing (Touch ID), then agent-signing.
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBP/+4vmV9jofa+NC1HONKq//dKeeLk5BGswU6Jod45hIkac0NHyXwaYSO/Js7h34ceJfQB2ReQrE+BGcQPcGH60AAAAEc3NoOg=="
        "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBNBQUgGis2mignI9aGhDFOi7MMHjIgFCN7abqcsquQDsnjnYGAn7YyHtQPkg/0GDDyx994qyzJ7tSqea0x/hBxEAAAAEc3NoOg=="
        # penelope's TPM, made by core's guide on 2026-10-25: joel-signing
        # (its PIN), then agent-signing.
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBESjVkN/tSPAJweRv3fOrntjOA5oqCzUi6n9V7jqXSKPTPtfsqQgUjFpQPpedzShpgqRkbJKLwLTaY6g/X6vEIY="
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAKy/GVdnQYujyvYnzwc+AwH+HcZdT9U2jnF9xotfm/5cR01wwsViK6QTwoQbKHcgCcUyixzfYLM7/ClDDX5PTM="
      ];

  programs.git = {
    settings = {
      # nvimdiff is built into git, so no cmd lines are needed. git's editor
      # is nvim through EDITOR, and its ignores are home-manager's
      # ~/.config/git/ignore, core's patterns among them, which any
      # core.excludesFile set here would stop git reading.
      diff.tool = "nvimdiff";
      merge.tool = "nvimdiff";
    };
  };
}
