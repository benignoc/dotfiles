-- Use Snacks picker if LazyVim is present; harmless otherwise
vim.g.lazyvim_picker = "snacks" -- change to "fzf" or "telescope" if you prefer

-- Windows: better shell for install steps (safe on non-Windows)
if vim.fn.has("win32") == 1 and vim.fn.executable("pwsh") == 1 then
  vim.opt.shell = "pwsh"
  vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

-- Make default explorer be shown in tree mode
-- vim.cmd("let g:netwr_liststyle 3")
