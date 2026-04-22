{ pkgs, lib, ... }:
{
  extraLuaConfig = ''
    local map = vim.keymap.set

    -- Better window navigation
    map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
    map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
    map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
    map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

    -- Resize windows with arrows
    map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
    map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
    map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
    map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

    -- Buffer navigation
    map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
    map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

    -- Clear search highlight
    map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

    -- Better indenting (stay in visual mode)
    map("v", "<", "<gv")
    map("v", ">", ">gv")

    -- Move lines
    map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
    map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
    map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
    map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

    -- Quit
    map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

    -- Diagnostic navigation
    map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
    map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
    map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostics" })

    -- Close buffer without closing the window
    map("n", "<leader>bd", function()
      local current_buf = vim.api.nvim_get_current_buf()
      local current_win = vim.api.nvim_get_current_win()

      local other_bufs = vim.tbl_filter(function(b)
        return vim.fn.buflisted(b) == 1 and b ~= current_buf
      end, vim.api.nvim_list_bufs())

      if #other_bufs > 0 then
        vim.api.nvim_win_set_buf(current_win, other_bufs[#other_bufs])
      else
        vim.cmd("enew")
      end

      vim.api.nvim_buf_delete(current_buf, { force = false })
    end, { desc = "Delete buffer" })
  '';
}
