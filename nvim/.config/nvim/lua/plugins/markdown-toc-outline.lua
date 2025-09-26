return {
  -- Inline Table of Contents (GFM) – inserts/updates TOC in the buffer
  {
    "mzlogin/vim-markdown-toc",
    ft = "markdown",
    cmd = { "GenTocGFM", "UpdateToc" },
    init = function()
      vim.g.vmt_auto_update_on_save = 0
      vim.g.vmt_dont_insert_fence = 1
      vim.g.vmt_toc_header = "## Table of contents"
      vim.g.vmt_list_indent_text = "  "
    end,
    keys = {
      { "<leader>zT", "<cmd>GenTocGFM<CR>", desc = "Markdown: Generate/Update TOC" },
      { "<leader>zU", "<cmd>UpdateToc<CR>", desc = "Markdown: Update TOC" },
    },
  },

  -- Live outline sidebar (Treesitter-backed)
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNavToggle", "AerialNext", "AerialPrev" },
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      backends = { "treesitter", "markdown" },
      layout = { min_width = 28, default_direction = "right" },
      show_guides = true,
      filter_kind = false, -- show all heading levels
      nerd_font = "auto",
    },
    keys = {
      { "<leader>zo", "<cmd>AerialToggle<CR>", desc = "Outline: Toggle" },
      { "<leader>zO", "<cmd>AerialOpen right<CR>", desc = "Outline: Open (right)" },
      { "<leader>zn", "<cmd>AerialNavToggle<CR>", desc = "Outline: Nav popup" },
      { "]o", "<cmd>AerialNext<CR>", desc = "Outline: Next symbol" },
      { "[o", "<cmd>AerialPrev<CR>", desc = "Outline: Prev symbol" },
    },
  },
}
