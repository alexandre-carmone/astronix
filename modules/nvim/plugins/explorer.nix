{ pkgs, lib, ... }:
{
  plugins = with pkgs.vimPlugins; [
    neo-tree-nvim
    plenary-nvim
    nvim-web-devicons
    nui-nvim
  ];

  extraLuaConfig = ''
    require("neo-tree").setup({
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = {
        width = 30,
        mappings = {
          ["h"] = "close_node",
          ["l"] = "open",
          ["i"] = "fuzzy_finder",
        },
        fuzzy_finder_mappings = {
          ["<esc>"] = "fuzzy_finder_cancel",
        },
      },
    })

    vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })
  '';
}
