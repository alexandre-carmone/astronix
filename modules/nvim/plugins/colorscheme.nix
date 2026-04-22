{ pkgs, lib, ... }:
{
  plugins = [ pkgs.vimPlugins.catppuccin-nvim ];

  extraLuaConfig = ''
    require("catppuccin").setup({
      integrations = {
        cmp = true,
        gitsigns = false,
        mason = true,
        neo_tree = true,
        treesitter = true,
        which_key = true,
        telescope = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    })
    vim.cmd.colorscheme("catppuccin")
  '';
}
