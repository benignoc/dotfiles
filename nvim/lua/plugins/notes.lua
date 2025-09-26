return {
	{
		"nvim-lua/plenary.nvim",
		event = "VeryLazy",
		init = function()
			local ok, wk = pcall(require, "which-key")
			if ok then
				wk.add({ { "<leader>z", group = "Notes" } })
			end
		end,
		keys = {
			{
				"gf",
				function()
					require("notes").follow_wikilink()
				end,
				desc = "Notes: Follow [[link]]",
				mode = "n",
			},
			{
				"<leader>zn",
				function()
					require("notes").new_note()
				end,
				desc = "Notes: New",
				mode = "n",
			},
			{
				"<leader>zd",
				function()
					require("notes").open_today()
				end,
				desc = "Notes: Today",
				mode = "n",
			},
			{
				"<leader>zl",
				function()
					require("notes").insert_link()
				end,
				desc = "Notes: Insert [[link]]",
				mode = "n",
			},
			{
				"<leader>zs",
				function()
					require("notes").search_text()
				end,
				desc = "Notes: Search (live)",
				mode = "n",
			},
			{
				"<leader>zt",
				function()
					require("notes").search_tag()
				end,
				desc = "Notes: Search #tag",
				mode = "n",
			},
			{
				"<leader>zb",
				function()
					require("notes").backlinks()
				end,
				desc = "Notes: Backlinks",
				mode = "n",
			},
		},
		config = function()
			local Path = require("plenary.path")
			local has_snacks, Snacks = pcall(require, "snacks.picker")
			local M = {}
			package.loaded["notes"] = M

			vim.pesc = vim.pesc or function(str)
				return (str:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
			end

			M.root = vim.env.NOTES_DIR or (vim.env.HOME .. "/notes")
			M.daily_dir = M.root .. "/daily"
			M.templates_dir = M.root .. "/_templates"
			M.attach_dir = M.root .. "/attachments"
			M.default_tpl = M.templates_dir .. "/note.md"
			M.daily_tpl = M.templates_dir .. "/daily.md"

			local function ensure_dir(p)
				vim.fn.mkdir(p, "p")
			end
			ensure_dir(M.root)
			ensure_dir(M.daily_dir)
			ensure_dir(M.templates_dir)
			ensure_dir(M.attach_dir)

			local function read_file(p)
				local pa = Path:new(p)
				return pa:exists() and pa:read() or nil
			end
			local function write_file(p, s)
				Path:new(p):write(s or "", "w")
			end
			local function open(p)
				vim.cmd.edit(vim.fn.fnameescape(p))
			end

			local function slug(s)
				s = s:gsub("[%s/]+", "-"):gsub("[^%w%-_]", ""):lower()
				return s
			end
			local function title_to_filename(t)
				return slug(t) .. ".md"
			end
			local function today()
				return os.date("%Y-%m-%d")
			end
			local function iso()
				return os.date("!%Y-%m-%dT%H:%M:%SZ")
			end
			local function fm(title)
				return ("---\ntitle: %s\naliases: []\ntags: []\ncreated: %s\nupdated: %s\n---\n\n# %s\n"):format(
					title,
					iso(),
					iso(),
					title
				)
			end

			local function apply_template(path, tpl_path, title)
				local tpl = read_file(tpl_path)
				local date = today()
				if not tpl then
					write_file(path, fm(title))
					return
				end
				local rel = Path:new(path):make_relative(M.root)
				local vars = {
					["{{title}}"] = title,
					["{{TITLE}}"] = title,
					["{{date}}"] = date,
					["{{DATE}}"] = date,
					["{{slug}}"] = slug(title),
					["{{SLUG}}"] = slug(title),
					["{{iso}}"] = iso(),
					["{{ISO}}"] = iso(),
					["{{filename}}"] = rel,
					["{{FILENAME}}"] = rel,
				}
				for k, v in pairs(vars) do
					tpl = tpl:gsub(k, v)
				end
				write_file(path, tpl)
			end

			local function grep_rg(opts)
				local cwd = opts.cwd or M.root
				local title = opts.title or "Search"
				local pat = opts.pattern
				local cmd = {
					"rg",
					"--pcre2",
					"--no-config",
					"--with-filename",
					"--line-number",
					"--column",
					"--glob",
					"*.md",
					"--cwd",
					cwd,
					pat,
				}
				if has_snacks then
					return Snacks.grep({ cmd = cmd, cwd = cwd, title = title })
				else
					local out = vim.fn.systemlist(cmd)
					if vim.v.shell_error ~= 0 then
						return vim.notify("rg failed:\n" .. table.concat(out or {}, "\n"), vim.log.levels.ERROR)
					end
					local qf = {}
					for _, line in ipairs(out) do
						local file, lno, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
						if file then
							table.insert(
								qf,
								{ filename = file, lnum = tonumber(lno), col = tonumber(col), text = text }
							)
						end
					end
					if #qf == 0 then
						return vim.notify("No matches for: " .. pat, vim.log.levels.INFO)
					end
					vim.fn.setqflist(qf, "r", { title = title })
					vim.cmd("copen")
				end
			end

			function M.new_note()
				vim.ui.input({ prompt = "Note title: " }, function(input)
					if not input or input == "" then
						return
					end
					local file = M.root .. "/" .. title_to_filename(input)
					if not Path:new(file):exists() then
						apply_template(file, M.default_tpl, input)
					end
					open(file)
				end)
			end

			function M.open_today()
				local file = M.daily_dir .. "/" .. today() .. ".md"
				if not Path:new(file):exists() then
					apply_template(file, M.daily_tpl, today())
				end
				open(file)
			end

			function M.follow_wikilink()
				local line = vim.api.nvim_get_current_line()
				local col = vim.api.nvim_win_get_cursor(0)[2] + 1
				local s, e = line:find("%[%[[^%]]+%]%]")
				while s do
					if col >= s and col <= e then
						local target = line:sub(s + 2, e - 2)
						local fname = title_to_filename((target:match("([^/]+)$") or target))
						local dir = target:match("(.+)/") or ""
						local full_d = (dir ~= "") and (M.root .. "/" .. dir) or M.root
						ensure_dir(full_d)
						local full = full_d .. "/" .. fname
						if not Path:new(full):exists() then
							apply_template(full, M.default_tpl, target)
						end
						open(full)
						return
					end
					s, e = line:find("%[%[[^%]]+%]%]", e + 1)
				end
				vim.notify("No [[link]] under cursor", vim.log.levels.INFO)
			end

			function M.insert_link()
				local choices = {}
				if vim.fn.executable("fd") == 1 then
					local out = vim.fn.systemlist({ "fd", "--type", "f", "--extension", "md", ".", M.root })
					for _, p in ipairs(out or {}) do
						if p and p ~= "" then
							table.insert(choices, p)
						end
					end
				else
					local glob = vim.fn.glob(M.root .. "/**/*.md", true, true)
					for _, p in ipairs(glob or {}) do
						table.insert(choices, p)
					end
				end
				if #choices == 0 then
					return vim.notify("No notes found", vim.log.levels.WARN)
				end
				vim.ui.select(choices, { prompt = "Insert link to note:" }, function(path)
					if not path then
						return
					end
					local text = read_file(path) or ""
					local rel = Path:new(path):make_relative(M.root)
					local title = text:match("\n?title:%s*([^\n]+)")
						or text:match("^#%s+([^\n]+)")
						or rel:gsub("%.md$", "")
					vim.api.nvim_put({ string.format("[[%s]]", title) }, "c", true, true)
				end)
			end

			function M.search_text()
				if has_snacks then
					Snacks.grep({ cwd = M.root, title = "Search notes" })
				else
					vim.ui.input({ prompt = "Search pattern: " }, function(q)
						if not q or q == "" then
							return
						end
						grep_rg({ cwd = M.root, title = "Search: " .. q, pattern = q })
					end)
				end
			end

			function M.search_tag()
				vim.ui.input({ prompt = "Tag (without #): " }, function(tag)
					if not tag or tag == "" then
						return
					end
					local pat = [[\B#]] .. vim.pesc(tag) .. [[\b]]
					grep_rg({ cwd = M.root, title = "#" .. tag, pattern = pat })
				end)
			end

			function M.backlinks()
				local buf = vim.api.nvim_buf_get_name(0)
				if buf == "" then
					return vim.notify("Open a note first", vim.log.levels.WARN)
				end
				local name = Path:new(buf):make_relative(M.root):gsub("%.md$", "")
				local text = (vim.fn.filereadable(buf) == 1) and table.concat(vim.fn.readfile(buf), "\n") or ""
				local title = text:match("\n?title:%s*([^\n]+)") or text:match("^#%s+([^\n]+)") or name
				local pat = [[\[\[(?:]] .. vim.pesc(name) .. [[|]] .. vim.pesc(title) .. [[)\]\]]
				grep_rg({ cwd = M.root, title = "Backlinks to [[" .. title .. "]]", pattern = pat })
			end
		end,
	},
}
