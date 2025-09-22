{
  pkgs,
  username,
  ...
}:
{
  nix = {
    package = pkgs.nix;
    optimise.automatic = true;
    settings.experimental-features = "nix-command flakes";
  };

  # Fix GID mismatch between existing Nix and nix-darwin
  ids.gids.nixbld = 350;

  # Additional Homebrew packages (extends core.nix configuration)
  homebrew = {
    # GUI Applications (Casks)
    casks = [
      "1password-cli"
      "balenaetcher"
      "claude"
      "docker-desktop"
      "logitech-g-hub"
      "musescore"
      "obs"
      "openvpn-connect"
      "postman"
      "racket"
      "sonic-pi"
      "swiftformat-for-xcode"
      "zoom"
    ];
  };

  system = {
    # Used for backwards compatibility, please read the changelog before changing
    stateVersion = 4;
    # Primary user for system defaults
    primaryUser = username;
  };
}
