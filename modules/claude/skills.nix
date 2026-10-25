# Claude Code loads skills using the same Agent Skills standard pi does,
# so agentic-harness.pi's skills are largely reusable, but several assume
# a pi extension (quest-workflow, tdd-workflow, review-integration, etc.)
# is present to back a tool the skill instructs the model to call. Loading
# those in Claude Code would tell the model to call a tool that doesn't
# exist, so this only ships an allowlist: skills with no pi-specific
# tooling, plus a few with a small patch stripping the parts that assume
# one. The patches are diffed against upstream at build time, so an
# upstream change big enough to invalidate one fails the build instead of
# silently shipping stale advice. skills.sh copies and patches them.
{
  runCommand,
  patch,
  agentic-harness-pi,
}:
let
  unpatched = [
    "code-review-standard"
    "code-style-standard"
    "git-branch-convention"
    "git-commit-convention"
    "git-rebase-convention"
    "github-project-guide"
    "github-sub-issue-guide"
    "markdown-standard"
  ];

  patched = [
    "code-investigation-guide"
    "comment-format"
    "commit-format"
    "github-issue-format"
    "github-pr-format"
    "prose-standard"
  ];
in
runCommand "agentic-harness-pi-claude-skills" {
  nativeBuildInputs = [ patch ];
  source = agentic-harness-pi;
  patches = ./skills-patches;
  inherit unpatched patched;
} (builtins.readFile ./skills.sh)
