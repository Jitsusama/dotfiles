-- A project's own .nvim.lua, from the nearest folder above the file opened,
-- once Neovim has asked whether to trust it.
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local found = vim.fs.find('.nvim.lua', { upward = true, path = vim.fn.expand('%:p:h') })[1]
    if found and vim.secure.read(found) then
      dofile(found)
    end
  end,
})

-- rust-analyzer, from the project's own toolchain, checking with clippy and
-- reading every feature. Neovim's own configuration needs no plugin, so it's
-- set now. core.nix loads completion only once it's wanted, so its
-- capabilities join as the first Rust file opens: this autocmd is made
-- before vim.lsp.enable's own, so it runs before the server starts, and
-- requiring the module is what loads the plugin.
vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        runBuildScripts = true,
      },
      checkOnSave = true,
      check = {
        allFeatures = true,
        command = 'clippy',
        extraArgs = { '--no-deps' },
      },
      procMacro = {
        enable = true,
        ignored = {
          ['async-trait'] = { 'async_trait' },
          ['napi-derive'] = { 'napi' },
          ['async-recursion'] = { 'async_recursion' },
        },
      },
    },
  },
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  once = true,
  callback = function()
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    vim.lsp.config('rust_analyzer', { capabilities = capabilities })
  end,
})
vim.lsp.enable('rust_analyzer')
