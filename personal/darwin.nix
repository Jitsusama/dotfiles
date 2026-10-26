# What every personal Mac adds to core.nix's roles: the apps Homebrew
# installs beside core's, with the personal modules in every account.
{ homeModules }:
{
  home-manager.sharedModules = [ homeModules.personal ];

  homebrew.casks = [
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
}
