{ pkgs, lib, ... }:
{
  extraLuaConfig = ''
    local opt = vim.opt

    -- Line numbers
    opt.number = true
    opt.relativenumber = true

    -- Tabs & indentation
    opt.tabstop = 4
    opt.shiftwidth = 4
    opt.expandtab = true
    opt.smartindent = true

    -- Search
    opt.ignorecase = true
    opt.smartcase = true
    opt.hlsearch = true
    opt.incsearch = true

    -- Appearance
    opt.termguicolors = true
    opt.signcolumn = "yes"
    opt.cursorline = true
    opt.scrolloff = 8
    opt.sidescrolloff = 8

    -- Splits
    opt.splitbelow = true
    opt.splitright = true

    -- System
    opt.clipboard = "unnamedplus"
    opt.undofile = true
    opt.swapfile = false
    opt.updatetime = 250
    opt.timeoutlen = 300

    -- Wrapping
    opt.wrap = false

    -- Completion
    opt.completeopt = "menu,menuone,noinsert"

    -- Grep
    opt.grepprg = "rg --vimgrep"
    opt.grepformat = "%f:%l:%c:%m"
  '';

  extraPackages = [ pkgs.ripgrep ];
}
