return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = function(_, opts)
      opts = opts or {}
      local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
      opts.parser_install_dir = parser_dir

      local ts_install = require("nvim-treesitter.install")
      ts_install.prefer_git = false
      ts_install.compilers = { "clang", "cl", "gcc" }

      if not string.find(vim.o.runtimepath, parser_dir, 1, true) then
        vim.opt.runtimepath:append(parser_dir)
      end

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "lua",
        "vim",
        "vimdoc",
        "query",
        "markdown",
        "markdown_inline",
        "regex",
        "bash",
      })
      opts.auto_install = false
      opts.sync_install = true
      opts.highlight = { enable = true, additional_vim_regex_highlighting = false }
      opts.indent = { enable = true }
      return opts
    end,
  },
}
