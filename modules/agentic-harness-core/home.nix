# agentic-harness-core, the CLI holding agentic-harness's logic apart from
# pi, which the Claude Code plugin calls (../claude).
{ agentic-harness-core }:
{ pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ./package.nix { inherit agentic-harness-core; }) ];
}
