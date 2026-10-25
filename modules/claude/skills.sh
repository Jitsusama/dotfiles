# shellcheck shell=bash disable=SC2154 # out, source, patches and both lists come from skills.nix.
# Copies the skills skills.nix allows out of agentic-harness.pi's source, and
# patches each it lists as patched with its patch from skills-patches/; a
# patch upstream has moved past no longer applies, and fails the build.
mkdir -p "$out"
for name in $unpatched; do
  cp -r "$source/skills/$name" "$out/$name"
done
for name in $patched; do
  cp -r "$source/skills/$name" "$out/$name"
  chmod -R u+w "$out/$name"
  patch -p1 -d "$out/$name" < "$patches/$name.patch"
done
