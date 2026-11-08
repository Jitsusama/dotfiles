# Neovim outside work: Python for the plugins that need it, and the Lua in
# rust-lsp.lua, which sets up the Rust language server and loads a
# project's own .nvim.lua. core.nix sets up the rest of Neovim, the plugins
# that Lua requires among it.
{ core }:
{
  # Where the plugins rust-lsp.lua requires, cmp_nvim_lsp among them, come
  # from.
  imports = [ core.homeModules.neovim ];

  programs.neovim = {
    withPython3 = true;
    initLua = builtins.readFile ./rust-lsp.lua;
  };
}
