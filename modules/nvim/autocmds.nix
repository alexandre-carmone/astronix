{ pkgs, lib, ... }:
{
  extraLuaConfig = ''
    local augroup = vim.api.nvim_create_augroup
    local autocmd = vim.api.nvim_create_autocmd

    -- Highlight on yank
    autocmd("TextYankPost", {
      group = augroup("highlight_yank", { clear = true }),
      callback = function()
        vim.highlight.on_yank()
      end,
    })

    -- Resize splits when terminal is resized
    autocmd("VimResized", {
      group = augroup("resize_splits", { clear = true }),
      callback = function()
        vim.cmd("tabdo wincmd =")
      end,
    })

    -- Set working directory to the argument passed on startup
    autocmd("VimEnter", {
      group = augroup("set_cwd", { clear = true }),
      callback = function()
        local arg = vim.fn.argv(0)
        if arg == "" then return end
        local dir
        if vim.fn.isdirectory(arg) == 1 then
          dir = arg
        else
          dir = vim.fn.fnamemodify(arg, ":p:h")
        end
        vim.cmd.cd(dir)
      end,
    })

    -- Go to last location when opening a buffer
    autocmd("BufReadPost", {
      group = augroup("last_loc", { clear = true }),
      callback = function(event)
        local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
        local lcount = vim.api.nvim_buf_line_count(event.buf)
        if mark[1] > 0 and mark[1] <= lcount then
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
    })
  '';
}
