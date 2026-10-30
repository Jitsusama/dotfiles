# Joel's account on methuselah: his agents' commits named as theirs, and
# windows left to macOS, with no tiling manager. Its commits are signed with
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

  # What work placed here can count on wherever the laptop goes, and the
  # command a personal session starts with: pi, on Joel's Claude plan.
  jitsusama.mycelium.declares.reach = [ "internet" ];
  jitsusama.mycelium.agents.personal = "pi";

  home.stateVersion = "24.05";
}
