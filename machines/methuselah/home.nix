# Joel's account on methuselah: his agents' commits named as theirs,
# pi-claude told where Claude Code's login is, and windows left to macOS,
# with no tiling manager. Its commits are signed with
# keys in its Secure Enclave, which core.nix's workstation role brings,
# picking his key at a terminal and the agents' over pipes.
{ config, ... }:
{
  # Every zsh reads .zshenv, and only one a person types in reads .zshrc, so
  # what a harness commits carries the agents' name and what Joel commits,
  # his own.
  programs.zsh = {
    envExtra = ''
      export GIT_COMMITTER_NAME="${config.jitsusama.identity.name} (agent)"
    '';
    initContent = ''
      unset GIT_COMMITTER_NAME
    '';
  };

  # pi-claude drives Claude Code with its own login, which here is the only
  # one and lives where Claude Code keeps it by default.
  home.sessionVariables.PI_CLAUDE_CONFIG_DIR = "$HOME/.claude";

  home.stateVersion = "24.05";
}
