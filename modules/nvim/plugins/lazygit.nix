{ pkgs, lib, ... }:
{
  plugins = with pkgs.vimPlugins; [
    lazygit-nvim
    plenary-nvim
  ];

  extraPackages = [ pkgs.lazygit ];

  extraLuaConfig = ''
    local map = vim.keymap.set
    map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
    map("n", "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", { desc = "LazyGit current file" })
  '';
}
