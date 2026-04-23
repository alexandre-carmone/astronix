{ pkgs, lib, ... }:

let
  # Each plugin module returns { plugins = [...]; extraPackages = [...]; extraLuaConfig = "..."; }
  mkModule = path: import path { inherit pkgs lib; };

  modules = [
    #(mkModule ./options.nix)
    #(mkModule ./keymaps.nix)
    #(mkModule ./autocmds.nix)

    #(mkModule ./plugins/colorscheme.nix)
    #(mkModule ./plugins/treesitter.nix)
    #(mkModule ./plugins/lsp.nix)
    #(mkModule ./plugins/cmp.nix)
    #(mkModule ./plugins/telescope.nix)
    #(mkModule ./plugins/bufferline.nix)
    #(mkModule ./plugins/lualine.nix)
    #(mkModule ./plugins/explorer.nix)
    #(mkModule ./plugins/which-key.nix)
    #(mkModule ./plugins/lazygit.nix)
    #(mkModule ./plugins/venv-selector.nix)
    #(mkModule ./plugins/claudecode.nix)
  ];

  collect = field: default:
    lib.foldl' (acc: m: acc ++ (m.${field} or default)) [] modules;

  preamble = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- Prioritize nvim-treesitter queries over bundled runtime queries
    vim.opt.runtimepath:remove(vim.env.VIMRUNTIME)
    vim.opt.runtimepath:append(vim.env.VIMRUNTIME)
  '';

  luaConfig = lib.concatStringsSep "\n\n" (
    [ preamble ] ++ (map (m: m.extraLuaConfig or "") modules)
  );
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraConfig = luaConfig;

    plugins = collect "plugins" [];
    extraPackages = collect "extraPackages" [];
  };
}
