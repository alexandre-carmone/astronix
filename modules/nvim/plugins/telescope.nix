{ pkgs, lib, ... }:
{
  plugins = with pkgs.vimPlugins; [
    plenary-nvim
    telescope-nvim
    telescope-fzf-native-nvim
  ];

  extraPackages = [ pkgs.fzf ];

  extraLuaConfig = ''
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        prompt_prefix = " ",
        selection_caret = " ",
      },
    })
    pcall(telescope.load_extension, "fzf")

    local map = vim.keymap.set
    map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
    map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
    map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
    map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
    map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
    map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" })
    map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document symbols" })
    map("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Grep" })
    map("n", "<leader><space>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
    map("n", "<leader>,", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
    map("n", "<leader>sD", function()
      require("telescope.builtin").live_grep({ cwd = vim.fn.input("Dir: ", "", "dir") })
    end, { desc = "Grep in directory" })
    map("n", "<leader>sF", function()
      require("telescope.builtin").find_files({ cwd = vim.fn.input("Dir: ", "", "dir") })
    end, { desc = "Find files in directory" })
  '';
}
