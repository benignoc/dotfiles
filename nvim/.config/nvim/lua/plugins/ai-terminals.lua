-- File: lua/plugins/ai-terminals.lua
return {
  {
    "akinsho/toggleterm.nvim",
    event = "VeryLazy",
    opts = {
      direction = "float",
      float_opts = { border = "rounded", winblend = 0 },
      size = 20,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      local Terminal = require("toggleterm.terminal").Terminal

      local claude = Terminal:new({
        cmd = "claude",
        hidden = true,
        direction = "float",
        dir = "git_dir", -- open at repo root if available
        close_on_exit = false,
      })

      local cursor = Terminal:new({
        cmd = "cursor",
        hidden = true,
        direction = "float",
        dir = "git_dir",
        close_on_exit = false,
      })

      function _CLAUDE_TOGGLE()
        claude:toggle()
      end
      function _CURSOR_TOGGLE()
        cursor:toggle()
      end

      vim.keymap.set("n", "<leader>aC", _CLAUDE_TOGGLE, { desc = "Claude Code CLI (float)" })
      vim.keymap.set("n", "<leader>aU", _CURSOR_TOGGLE, { desc = "Cursor CLI (float)" })
    end,
  },
}
