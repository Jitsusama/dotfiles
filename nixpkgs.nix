{ system }:
{
  # Platform configuration
  hostPlatform = system;

  # Nixpkgs configuration
  config = {
    # Allow unfree packages (like commercial software)
    allowUnfree = true;
    
    # Allow broken packages (use with caution)
    # allowBroken = false;
    
    # Allow insecure packages (use with caution)
    # allowInsecure = false;
  };

  # Overlays for package modifications or additions
  overlays = [
    # Add custom overlays here
    # Example:
    # (final: prev: {
    #   # Custom package modifications
    # })
  ];
}
