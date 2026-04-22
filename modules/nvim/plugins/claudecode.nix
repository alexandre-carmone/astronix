{ pkgs, lib, ... }:

let
  # claudecode.nvim is not (yet) in nixpkgs — build it from source.
  # Bump `rev` / `hash` when upgrading.
  claudecode-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "claudecode.nvim";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "coder";
      repo = "claudecode.nvim";
      rev = "main";
      # Replace with actual hash from `nix-prefetch-github coder claudecode.nvim`:
      hash = lib.fakeHash;
    };
  };
in
{
  plugins = [ claudecode-nvim ];

  extraPackages = [ pkgs.claude-code ];

  extraLuaConfig = ''
    require("claudecode").setup({})

    local map = vim.keymap.set
    map({ "n", "v" }, "<leader>a", "", { desc = "+ai" })
    map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
    map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
    map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
    map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
    map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
    map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })

    -- File-explorer scoped "add file" mapping
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "NvimTree", "neo-tree", "oil" },
      callback = function(event)
        vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>",
          { buffer = event.buf, desc = "Add file" })
      end,
    })

    map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
    map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })
    map("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Navigate left from terminal" })
  '';
}
