# What every personal NixOS machine adds to core.nix's roles: the personal
# layer in every account. 1Password, niri and the rest come with the roles.
{ homeModules }:
{
  home-manager.sharedModules = [ homeModules.personal ];
}
