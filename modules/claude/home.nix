# Claude Code's skills outside work: agentic-harness.pi's portable ones.
# core.nix installs Claude Code itself.
{ agentic-harness-pi }:
{ pkgs, ... }:
{
  # agentic-harness.pi's skills follow the Agent Skills standard, the same
  # format Claude Code loads. Most assume a pi extension is there to back a
  # tool they tell the model to call, so only the portable ones ship here;
  # skills.nix lists them, with the small patches that take pi's tools out
  # of a few.
  home.file.".claude/skills/agentic-harness-pi".source = pkgs.callPackage ./skills.nix {
    inherit agentic-harness-pi;
  };
}
