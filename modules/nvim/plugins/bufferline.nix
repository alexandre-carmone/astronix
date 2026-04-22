{ pkgs, lib, ... }:
{
  plugins = with pkgs.vimPlugins; [
    bufferline-nvim
    nvim-web-devicons
  ];

  extraLuaConfig = ''
    require("bufferline").setup({
      options = {
        mode = "buffers",
        separator_style = "slant",
        always_show_bufferline = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        color_icons = true,
        custom_filter = function(buf_number)
          local name = vim.fn.bufname(buf_number)
          if name:match("^term://.*claude") or name:match("Claude") then
            return false
          end
          return true
        end,
      },
    })

    local map = vim.keymap.set
    map("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
    map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  '';
}
