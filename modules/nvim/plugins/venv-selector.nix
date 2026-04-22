{ pkgs, lib, ... }:
{
  plugins = [ pkgs.vimPlugins.venv-selector-nvim ];

  extraLuaConfig = ''
    require("venv-selector").setup({
      options = {
        notify_user_on_venv_activation = true,
        search_venv_managers = true,
        on_venv_activated = function()
          local clients = vim.lsp.get_clients({ name = "basedpyright" })
          if #clients == 0 then
            clients = vim.lsp.get_clients({ name = "pyright" })
          end
          for _, client in ipairs(clients) do
            vim.lsp.stop_client(client.id)
          end
          vim.cmd("LspStart")
        end,
      },
    })

    vim.keymap.set("n", "<leader>cv", "<cmd>VenvSelect<cr>", { desc = "Select VirtualEnv" })
  '';
}
