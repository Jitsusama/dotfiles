# pi, the coding agent, outside work, with agentic-harness.pi as its one
# package. core.nix gives pi its theme and keys; the package is built here,
# from the tarball pi publishes.
{ pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ./package.nix { }) ];

  home.file.".pi/agent/settings.json".text = builtins.toJSON {
    defaultProvider = "anthropic";
    defaultModel = "claude-sonnet-5";
    packages = [ "git:github.com/Jitsusama/agentic-harness.pi" ];
  };
}
