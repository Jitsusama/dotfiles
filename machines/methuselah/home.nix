# Joel's account on methuselah: OmniWM tiling its windows, and his agents'
# commits named as theirs. Its commits are signed with keys in its Secure
# Enclave, which core.nix's workstation role brings, picking his key at a
# terminal and the agents' over pipes.
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

  programs.omniwm.enable = true;
  home.stateVersion = "24.05";
}
