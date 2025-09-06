{ system }:
{
  inherit system;

  config = {
    allowUnfree = true; # Non-OSS Packages
    allowBroken = false; # Allow Broken Packages
    allowInsecure = false; # Allow Insecure Packages
  };

  overlays = [
    # Add custom overlays here.
  ];
}
