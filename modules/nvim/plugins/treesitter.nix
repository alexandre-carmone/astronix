{ pkgs, lib, ... }:
{
  # withAllGrammars ships parsers as part of the derivation — no :TSUpdate needed on NixOS.
  plugins = [
    (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
      p.python
      p.lua
      p.rust
      p.json
      p.yaml
      p.toml
      p.markdown
      p.markdown_inline
      p.vimdoc
      p.bash
    ]))
  ];

  extraPackages = [ pkgs.tree-sitter ];

  extraLuaConfig = ''
    require("nvim-treesitter.configs").setup({
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
  '';
}
