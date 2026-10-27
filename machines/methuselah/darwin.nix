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
  users.users.jitsusama = {
    home = "/Users/jitsusama";
    # penelope's agents' key from its TPM, which asks nothing, so its
    # mycelium node can link here without a prompt.
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAKy/GVdnQYujyvYnzwc+AwH+HcZdT9U2jnF9xotfm/5cR01wwsViK6QTwoQbKHcgCcUyixzfYLM7/ClDDX5PTM= jitsusama@penelope agents"
    ];
  };
  home-manager.users.jitsusama.imports = [ ./home.nix ];
  # Read the changelog before changing it.
  system.stateVersion = 4;
}
