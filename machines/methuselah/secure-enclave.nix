# Secure Enclave commit signing identities.
#
# Host-specific because it is hardware: the keys live in this Mac's Secure
# Enclave, cannot be exported, cannot be backed up, and do not migrate to
# another machine. A logic-board service ends them.
#
# Reached through OpenSSH's SecurityKeyProvider interface via macOS's own
# /usr/lib/ssh-keychain.dylib, so there is no third-party agent, no socket and
# no SSH_AUTH_SOCK plumbing -- and gpg.ssh.program stays unset, which keeps git
# calling the real ssh-keygen (op-ssh-sign silently breaks
# gpg.ssh.revocationFile, reporting every commit as a bad signature).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  homeDirectory = config.home.homeDirectory;
  provider = "/usr/lib/ssh-keychain.dylib";

  # Which identity signs this user's commits. Flip to "onepassword" and rebuild
  # to roll back: both keys stay registered on GitHub and GitLab and both stay
  # in allowed_signers, so history signed by either keeps verifying either way.
  activeSigner = "secure-enclave";

  signers = {
    secure-enclave = {
      signingKey = "${homeDirectory}/.ssh/joel-signing";
      sshProgram = null;
    };
    # Byte-identical to what worked before the migration, deprecated bare-key
    # form included, so rolling back restores a known-good state.
    onepassword = {
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu";
      sshProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
  };

  signer = signers.${activeSigner};

  # label -> protection. "bio" prompts for Touch ID on every signature; "none"
  # never prompts and, unlike Secretive's keys, keeps signing while the screen
  # is locked (measured: 28/28 signatures across a 143s lock, zero failures).
  # That is the right trade only for a key whose whole job is unattended
  # signing under its own identity.
  identities = [
    {
      label = "joel-signing";
      protection = "bio";
      cn = "Joel Gerber";
      email = "joel@grrbrr.ca";
    }
    {
      label = "agent-signing";
      protection = "none";
      cn = "Agent (methuselah)";
      email = "agent@grrbrr.ca";
    }
  ];

  # One identity a line, its fields separated by tabs, as se-keys.sh reads them.
  identityLines = lib.concatMapStringsSep "\n" (
    i:
    lib.concatStringsSep "\t" [
      i.label
      i.protection
      i.cn
      i.email
    ]
  ) identities;

  se-keys = pkgs.writeShellApplication {
    name = "se-keys";
    runtimeEnv = {
      inherit provider;
      identities = identityLines;
    };
    text = builtins.readFile ./se-keys.sh;
  };
in
{
  home = {
    packages = [ se-keys ];

    # Report drift rather than generating keys mid-switch: key creation is a
    # deliberate act, not a side effect of a rebuild.
    activation.secureEnclaveKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for label in ${lib.concatMapStringsSep " " (i: i.label) identities}; do
        if [ ! -f "$HOME/.ssh/$label" ]; then
          warnEcho "secure-enclave: $HOME/.ssh/$label missing -- run 'se-keys'"
        fi
      done
    '';
  };

  # Which identity signs is decided by zsh's own file semantics, with no
  # marker variables and no conditionals to keep in sync:
  #
  #   .zshenv  -- sourced by EVERY zsh, including the non-interactive ones
  #               Claude Code and pi spawn. Agent identity is the default.
  #   .zshrc   -- sourced ONLY by interactive zsh, i.e. a human at a terminal.
  #               Reclaims the biometric key.
  #
  # Defaulting to the agent identity is the safe direction: a non-interactive
  # shell is by definition not a human approving a commit, so it must never
  # reach the key whose whole meaning is "a human touched the sensor". The
  # trade is that a script you run non-interactively signs as the agent --
  # correct, if slightly surprising, since it is machine-made either way.
  programs.zsh = {
    envExtra = ''
      # Required to sign with enclave-held sk keys; not required to verify.
      # Deliberately here rather than in home.sessionVariables: those are
      # sourced behind a __HM_SESS_VARS_SOURCED guard that a shell inherits
      # from its parent, so a session started before a rebuild silently blocks
      # every child from ever seeing new variables. .zshenv is unconditional.
      export SSH_SK_PROVIDER=${provider}

      # Agent commit identity. GIT_CONFIG_* overrides user.signingkey for this
      # process only, leaving the declared config alone.
      export GIT_CONFIG_COUNT=1
      export GIT_CONFIG_KEY_0=user.signingkey
      export GIT_CONFIG_VALUE_0=${homeDirectory}/.ssh/agent-signing
      export GIT_COMMITTER_NAME="Joel Gerber (agent)"
    '';

    initContent = ''
      # Interactive shell: a human is typing, so use the biometric key and
      # drop the agent committer name.
      export GIT_CONFIG_VALUE_0=${homeDirectory}/.ssh/joel-signing
      unset GIT_COMMITTER_NAME
    '';
  };

  programs.git = {
    signing.key = signer.signingKey;
    settings.gpg.ssh = lib.optionalAttrs (signer.sshProgram != null) {
      program = signer.sshProgram;
    };
  };
}
