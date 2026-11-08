# Skill Patches

One patch per agentic-harness.pi skill that Claude Code gets with a
change, named for the skill it patches. Each strips what assumes a pi
tool Claude Code doesn't have, so the skill doesn't tell the model to
call something that isn't there. `../skills.nix` lists which skills
are patched and which ship as they are, and `../skills.sh` applies the
patches as it builds.

A patch is made against the skill as upstream has it, and applied with
no fuzz. When upstream changes any line it reads, even a line of its
context, it no longer applies and the build fails, which is the sign to
make it again: apply the old one by hand to the new skill and diff the
result. A skill that needs no change isn't patched, and
nothing but patches goes here.
