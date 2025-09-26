return {
  -- Lightweight, deterministic Markdown folds via regex foldexpr
  {
    "nvim-lua/plenary.nvim", -- harmless dep so Lazy has a spec; remove if you prefer
    event = "BufReadPre",
    init = function()
      -- Global sensible defaults
      vim.opt.foldcolumn = "1"
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
      vim.opt.foldenable = true

      -- Our foldexpr (headings + setext; fenced code is excluded)
      _G.MarkdownFoldExpr = function(lnum)
        local getline = vim.fn.getline

        -- Are we inside a fenced block at this line?
        local in_fence = false
        local fence_char, fence_len = nil, 0
        for i = 1, lnum do
          local l = getline(i)
          local fence = l:match("^%s*([`~]{3,})")
          if fence then
            local ch = fence:sub(1, 1)
            if not in_fence then
              in_fence = true
              fence_char = ch
              fence_len = #fence
            else
              if ch == fence_char and #fence >= fence_len then
                in_fence = false
                fence_char, fence_len = nil, 0
              end
            end
          end
        end
        if in_fence then
          return 0
        end

        local line = getline(lnum)

        -- ATX headings: #, ##, ### ... -> level = count of '#'
        local hashes = line:match("^%s*(#+)%s+")
        if hashes then
          return #hashes
        end

        -- Setext headings: underline with === => H1, --- => H2
        if line:match("^%s*===+%s*$") then
          return 1
        end
        if line:match("^%s*---+%s*$") then
          return 2
        end

        -- Not a heading start: no fold level change
        return 0
      end

      -- Turn it on for Markdown buffers
      local grp = vim.api.nvim_create_augroup("MarkdownRegexFolds", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufReadPost", "BufWinEnter" }, {
        group = grp,
        pattern = "markdown",
        callback = function()
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr = "v:lua.MarkdownFoldExpr(v:lnum)"
          vim.opt_local.foldenable = true
          vim.opt_local.foldlevel = 99
          vim.opt_local.foldlevelstart = 99
          vim.opt_local.foldminlines = 1
          vim.opt_local.foldcolumn = "1"
        end,
        desc = "Enable regex-based Markdown folding",
      })

      -- Convenience keys (native)
      vim.keymap.set("n", "<leader>zR", "zR", { desc = "Folds: Open all" })
      vim.keymap.set("n", "<leader>zM", "zM", { desc = "Folds: Close all" })
      vim.keymap.set("n", "<leader>zz", "za", { desc = "Folds: Toggle" })
    end,
  },
}
