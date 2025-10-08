-- •	gd on [[Note]] or [text](Note.md#heading) jumps to the target.
-- •	gr on a heading shows backlinks across your vault.
-- •	<leader>mr on a heading/file path lets you rename and updates references.
-- •	Diagnostics highlight broken links and duplicate/ambiguous headings.  ￼

return {
	-- Ensure the server is installed
	{
		"mason-org/mason.nvim",
		opts = function(_, opts)
			opts = opts or {}
			opts.ensure_installed = opts.ensure_installed or {}
			if not vim.tbl_contains(opts.ensure_installed, "marksman") then
				table.insert(opts.ensure_installed, "marksman")
			end
		end,
	},

	-- LSP config
	{
		"neovim/nvim-lspconfig",
		ft = { "markdown", "markdown.mdx" },
		opts = {
			servers = {
				marksman = {
					-- Make the LSP root your vault root
					root_dir = function(fname)
						local util = require("lspconfig.util")
						return util.root_pattern(".marksman.toml", ".git")(fname) or vim.fs.dirname(fname)
					end,
					-- You can restrict to your vault if you like:
					-- single_file_support = false,
				},
			},
		},
		config = function(_, opts)
			local lspconfig = require("lspconfig")
			local servers = opts.servers or {}
			if servers.marksman then
				lspconfig.marksman.setup(servers.marksman)
			end

			-- Markdown-only LSP keymaps (buffer-local when LSP attaches)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "marksman" then
						local map = function(lhs, rhs, desc)
							vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "MD LSP: " .. desc })
						end
						map("gd", vim.lsp.buf.definition, "Goto link/heading")
						map("gr", vim.lsp.buf.references, "Find backlinks")
						map("K", vim.lsp.buf.hover, "Hover on link/heading")
						-- LazyVim often binds <leader>cr to rename; add a local alias:
						map("<leader>mr", vim.lsp.buf.rename, "Rename heading/file + update refs")
						-- Optional: code actions if you use them
						map("<leader>ma", vim.lsp.buf.code_action, "Code actions")
					end
				end,
			})
		end,
	},
}
