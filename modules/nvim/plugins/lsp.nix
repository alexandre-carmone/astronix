{ pkgs, lib, ... }:
{
  # On NixOS, install LSP servers declaratively via extraPackages instead of Mason.
  # Mason-managed downloads don't play well with the read-only Nix store.
  plugins = with pkgs.vimPlugins; [
    nvim-lspconfig
    cmp-nvim-lsp
  ];

  extraPackages = with pkgs; [
    basedpyright
    ruff
    lua-language-server
    rust-analyzer
  ];

  extraLuaConfig = ''
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    -- LSP keymaps on attach
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
      callback = function(event)
        local buf = event.buf
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = buf, desc = "LSP: " .. desc })
        end

        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("gr", vim.lsp.buf.references, "References")
        map("gI", vim.lsp.buf.implementation, "Go to implementation")
        map("gy", vim.lsp.buf.type_definition, "Go to type definition")
        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("K", vim.lsp.buf.hover, "Hover")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>cr", vim.lsp.buf.rename, "Rename")
        map("<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format")
      end,
    })

    -- Server configs using vim.lsp.config (Neovim 0.11+)
    vim.lsp.config("basedpyright", { capabilities = capabilities })

    vim.lsp.config("ruff", { capabilities = capabilities })

    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    })

    vim.lsp.config("rust_analyzer", {
      capabilities = capabilities,
      settings = {
        ["rust-analyzer"] = {
          checkOnSave = { command = "clippy" },
        },
      },
    })

    vim.lsp.enable({ "basedpyright", "ruff", "lua_ls", "rust_analyzer" })
  '';
}
