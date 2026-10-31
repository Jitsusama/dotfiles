# Joel's account on penelope: Chrome, its link to methuselah, what it
# declares to work placed there, and the home-manager release it was set up
# with. Commits are signed with keys sealed in its TPM, as core's
# signing module says, which the guide made at its first start; the
# personal modules list them among the allowed signers.
{ pkgs, ... }:
{
  home.packages = [ pkgs.google-chrome ];

  # penelope dials methuselah, whose Remote Login is on, so the two carry
  # each other's sessions; nixos.nix pins methuselah's host key, and
  # methuselah authorizes penelope's agents' key.
  jitsusama.mycelium.links = [ "methuselah.local" ];
  # What work placed here can count on wherever the laptop goes.
  jitsusama.mycelium.declares.reach = [ "internet" ];
  home.stateVersion = "24.05";
}
