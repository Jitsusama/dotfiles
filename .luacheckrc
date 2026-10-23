-- luacheck reads every Lua file through `nix fmt`, with all its warnings on.
-- Each file is read as the Lua of the program that runs it, with the names
-- that program gives it, so a name nothing set is caught rather than read as
-- nil.

-- Lines stop where stylua wraps them.
max_line_length = 100

-- Neovim runs LuaJIT, and its config writes into the `vim` table it's given.
files['modules/neovim'] = { std = 'luajit', globals = { 'vim' } }
