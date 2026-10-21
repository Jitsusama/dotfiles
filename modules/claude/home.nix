# Claude Code's skills outside work: agentic-harness.pi's portable ones, and
# agentic-harness.claude as a plugin. core.nix installs Claude Code itself.
{ agentic-harness-pi, agentic-harness-claude }:
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

  # A Claude Code plugin in a skills folder of its own loads with no
  # marketplace or install step: agentic-harness.claude's own
  # .claude-plugin/plugin.json is enough. It calls the agentic-harness-core
  # CLI, which ../agentic-harness-core puts on the path, for the logic
  # agentic-harness.pi drives through pi's extensions.
  home.file.".claude/skills/agentic-harness-claude".source = agentic-harness-claude;
}
