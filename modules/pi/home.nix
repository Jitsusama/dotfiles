# pi, the coding agent, outside work, with agentic-harness.pi as its one
# package. core.nix gives pi its theme and keys, and merges the settings
# below into the file pi keeps, beside its own; the package is built here,
# from the tarball pi publishes.
{ pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ./package.nix { }) ];

  jitsusama.pi.settings = {
    defaultProvider = "anthropic";
    defaultModel = "claude-sonnet-5";
    packages = [ "git:github.com/Jitsusama/agentic-harness.pi" ];
  };
}
