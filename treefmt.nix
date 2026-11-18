# How `nix fmt` formats and lints this repository, and what the formatting
# check holds it to: core.nix's linters, with its settings, so code here
# meets the same bar as core's (core.treefmtModules.treefmt, given beside
# this in flake.nix), and what only this repository has. Every file is read
# by a linter or listed here as data, and the check fails on one that's
# neither, so a new kind of file can't slip past them all.
{ lib, pkgs, ... }:
let
  # polkit's rules, the JavaScript polkit runs.
  polkitRules = [ "machines/*/*.js" ];
in
{
  settings.on-unmatched = "fatal";

  # Data no linter reads, beside treefmt-nix's own list of locks, patches,
  # licences and git's files: pi's npm lock, written by npm, and the key
  # GitHub signs its merges with, as GitHub publishes it.
  settings.excludes = [
    "modules/pi/package-lock.json"
    "personal/github-merges.asc"
  ];

  # luacheck's settings are Lua, read as core reads its own.
  settings.formatter.luacheck.includes = [ ".luacheckrc" ];
  settings.formatter.stylua.includes = [ ".luacheckrc" ];

  # polkit's rules, read by biome as the JavaScript polkit runs, with every
  # rule on but those biome.jsonc turns off, and biome.jsonc itself. Core's
  # linter reads every other .js file as the JavaScript QML imports, which
  # polkit's isn't, so it leaves these to this one.
  settings.formatter.qt-javascript-lint.excludes = polkitRules;
  settings.formatter.polkit-javascript-lint = {
    command = lib.getExe pkgs.biome;
    options = [
      "lint"
      "--error-on-warnings"
      "--max-diagnostics=none"
      "--config-path=biome.jsonc"
    ];
    includes = polkitRules ++ [ "biome.jsonc" ];
  };
}
