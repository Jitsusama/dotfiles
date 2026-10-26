# pi, the coding agent, outside work. core.nix gives pi its theme and keys,
# agentic-harness.pi as its first package, installed whole by pi-packages,
# and merges the settings below into the file pi keeps, beside its own; pi
# itself is built here, from the tarball pi publishes. It runs on Joel's own
# Claude plan, through Claude Code's login on the machine, as the one pi
# there is.
{ core }:
{ pkgs, ... }:
{
  # Where the settings below are declared.
  imports = [ core.homeModules.pi ];

  home.packages = [ (pkgs.callPackage ./package.nix { }) ];

  # The plan picks pi's provider and model, and never draws on extra usage.
  jitsusama.pi.plan = "claude";
}
