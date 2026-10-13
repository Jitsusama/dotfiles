# methuselah, Joel's personal MacBook.
{ pkgs, ... }:
{
  networking.hostName = "methuselah";
  nixpkgs.hostPlatform = "aarch64-darwin";

  # nix-darwin runs Nix here, and its build group was made before nix-darwin
  # was, with a different GID.
  nix = {
    package = pkgs.nix;
    optimise.automatic = true;
    settings.experimental-features = "nix-command flakes";
  };
  ids.gids.nixbld = 350;

  system.primaryUser = "jitsusama";
  users.users.jitsusama.home = "/Users/jitsusama";
  home-manager.users.jitsusama.imports = [ ./home.nix ];
  # Read the changelog before changing it.
  system.stateVersion = 4;
}
