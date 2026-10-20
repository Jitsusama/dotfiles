# Neovim outside work: Python for the plugins that need it, and the Rust
# language server's settings. core.nix sets up the rest of Neovim.
{
  programs.neovim = {
    withPython3 = true;
    initLua = builtins.readFile ./rust-lsp.lua;
  };
}
