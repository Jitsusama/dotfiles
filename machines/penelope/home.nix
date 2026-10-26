# Joel's account on penelope: Chrome, and the home-manager release it was
# set up with. Commits are signed with keys sealed in its TPM, as core's
# signing module says, which the guide made at its first start; the
# personal modules list them among the allowed signers.
{ pkgs, ... }:
{
  home.packages = [ pkgs.google-chrome ];
  home.stateVersion = "24.05";
}
