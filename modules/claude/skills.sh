# shellcheck shell=bash disable=SC2154 # out, source, patches and both lists come from skills.nix.
# Copies the skills skills.nix allows out of agentic-harness.pi's source, and
# patches each it lists as patched with its patch from skills-patches/. A
# patch applies only where every line of its context still matches (-F0,
# no fuzz), so one upstream has moved past fails the build rather than
# landing beside what it was made for.
mkdir -p "$out"
for name in $unpatched; do
  cp -r "$source/skills/$name" "$out/$name"
done
for name in $patched; do
  cp -r "$source/skills/$name" "$out/$name"
  chmod -R u+w "$out/$name"
  patch -F0 -p1 -d "$out/$name" < "$patches/$name.patch"
done
