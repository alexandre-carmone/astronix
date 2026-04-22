{ pkgs, lib, ... }:
{
  plugins = [ pkgs.vimPlugins.which-key-nvim ];

  extraLuaConfig = ''
    require("which-key").setup({
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code" },
        { "<leader>a", group = "ai" },
        { "<leader>A", group = "avante" },
      },
    })
  '';
}
