# How `nix fmt` formats and lints this repository, and what the formatting
# check holds it to: core.nix's own tools and settings for Nix and Lua, and
# shellcheck for shell. Lines stop at 100 characters.
{
  projectRootFile = "flake.nix";

  programs = {
    deadnix.enable = true;
    nixfmt.enable = true;
    shellcheck.enable = true;
    statix.enable = true;
    stylua = {
      enable = true;
      settings = {
        column_width = 100;
        indent_type = "Spaces";
        indent_width = 2;
        quote_style = "AutoPreferSingle";
      };
    };
  };
}
