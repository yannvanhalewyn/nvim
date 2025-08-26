---@type vim.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  -- on_init = function(client)
  --   client.server_capabilities.semanticTokensProvider = nil
  -- end,
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    'selene.toml',
    'selene.yml',
    '.git',
  },
  settings = {
    Lua = {
      telemetry = { enable = false },
      runtime = {
        version = "Lua 5.4",
      },
      completion = {
        enable = true,
      },
      diagnostics = {
        enable = true,
        globals = { "vim" },
      },
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
    },
  },
}
