# Joel's account on methuselah, on macOS today and on NixOS after the wipe:
# his agents' commits named as theirs, and its links. On macOS, windows are
# left to macOS, with no tiling manager, and commits are signed with keys
# in its Secure Enclave, which core.nix's workstation role brings, picking
# his key at a terminal and the agents' over pipes.
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

  # methuselah dials penelope as she dials it, so either can drive the other.
  # The node signs in with the agents' key from the Secure Enclave, which
  # penelope authorizes (nixos.nix there) and darwin.nix pins her host key for.
  jitsusama.mycelium.links = [ "penelope.local" ];
  jitsusama.mycelium.agents.personal = "pi";

  # A personal session here may ask work sessions for something, as one on
  # optimus may: the node keeps the message until its link to optimus
  # carries it there, where it crosses into work.
  jitsusama.mycelium.flows = [
    {
      from = "personal";
      to = "work";
    }
  ];

  home.stateVersion = "24.05";
}
