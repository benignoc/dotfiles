-- Plain Markdown notes (portable macOS/Windows/WSL) + optional pickers
-- Keys (<leader> = Space):
--   <leader>z n : New note
--   <leader>z d : Today note
--   <leader>z l : Insert [[link]]
--   <leader>z s : Live search (Snacks if present)
--   <leader>z t : Search by tag  (PCRE2 via ripgrep)
--   <leader>z b : Backlinks      (Marksman LSP, fallback to rg)
--   <leader>z B : Backlinks      (force ripgrep)
--   TODOS
--   <leader>tt → all tasks
--   <leader>to → open tasks
--   <leader>tp → filter by @person
--   <leader>tg → filter by #tag
--   <leader>tx → toggle [ ] ↔ [x] on current line
--   <leader>tn → new todo item
--   gf          : Follow [[wikilink]] (create if missing)
return {
  {
    "nvim-lua/plenary.nvim",
    event = "VeryLazy",
    init = function()
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({ { "<leader>z", group = "Notes" } })
      end
      -- UI preference: "snacks" | "fzf" | "quickfix"
      vim.g.notes_results = vim.g.notes_results or "snacks"
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
      -- default: Marksman backlinks
      {
        "<leader>zb",
        function()
          require("notes").backlinks_marksman()
        end,
        desc = "Notes: Backlinks (LSP)",
        mode = "n",
      },
      -- force ripgrep backlinks
      {
        "<leader>zB",
        function()
          require("notes").backlinks()
        end,
        desc = "Notes: Backlinks (ripgrep)",
        mode = "n",
      },
    },
    config = function()
      local Path = require("plenary.path")
      -- Load the main Snacks module (has .picker.* APIs)
      local has_snacks, Snacks = pcall(require, "snacks")

      local M = {}
      package.loaded["notes"] = M

      vim.pesc = vim.pesc or function(str)
        return (str:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
      end

      -- vault paths
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

      ------------------------------------------------------------------
      -- Results UI chooser: Snacks (qflist) → fzf-lua → Quickfix
      ------------------------------------------------------------------
      local function show_results_ui(title)
        if vim.g.notes_results == "snacks" and has_snacks and Snacks.picker and Snacks.picker.qflist then
          local ok, err = pcall(function()
            Snacks.picker.qflist({ title = title })
          end)
          if ok then
            return
          end
          vim.notify("Snacks qflist failed; falling back: " .. tostring(err), vim.log.levels.WARN)
        end
        local ok_fzf, fzf = pcall(require, "fzf-lua")
        if vim.g.notes_results ~= "quickfix" and ok_fzf then
          fzf.quickfix()
          return
        end
        vim.cmd("copen")
      end

      ------------------------------------------------------------------
      -- run ripgrep, fill Quickfix safely, then show results UI
      ------------------------------------------------------------------
      local function run_rg_to_qf(opts)
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
          pat,
        }

        local res = vim.system(cmd, { cwd = cwd, text = true }):wait()
        local stdout = (res and res.stdout) or ""
        local lines = {}
        for s in stdout:gmatch("[^\r\n]+") do
          lines[#lines + 1] = s
        end

        -- helper: make file path absolute (respect ~ and Windows drive letters)
        local function to_abs(p, cwd2)
          if not p or p == "" then
            return p
          end
          if p:sub(1, 1) == "~" then
            p = vim.fn.expand(p)
          end
          if vim.fn.has("win32") == 1 then
            if p:match("^%a:[/\\]") or p:match("^\\\\") then
              return p
            end
          else
            if p:sub(1, 1) == "/" then
              return p
            end
          end
          return vim.fn.fnamemodify(cwd2 .. "/" .. p, ":p")
        end

        local qf = {}
        for _, line in ipairs(lines) do
          local file, lno, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
          if file and lno and col then
            file = to_abs(file, cwd)
            qf[#qf + 1] = { filename = file, lnum = tonumber(lno), col = tonumber(col), text = text }
          end
        end

        vim.fn.setqflist({}, "r")
        if #qf > 0 then
          vim.fn.setqflist(qf, "r")
        end
        vim.fn.setqflist({}, "a", { title = title })

        if #qf == 0 then
          vim.notify(("No matches (%s)\nroot: %s"):format(title, cwd), vim.log.levels.INFO)
        else
          vim.notify(("Found %d matches (%s)\nroot: %s"):format(#qf, title, cwd), vim.log.levels.INFO)
        end
        show_results_ui(title)
      end
      -- expose for other modules (e.g. todos)
      M.run_rg_to_qf = run_rg_to_qf

      ------------------------------------------------------------------
      -- actions
      ------------------------------------------------------------------
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

      -- Minimal "New note" command (vault root)
      vim.api.nvim_create_user_command("NotesNew", function()
        vim.ui.input({ prompt = "Title: " }, function(t)
          if not t or t == "" then
            return
          end
          local function slug(s)
            return (s:gsub("[%s/]+", "-"):gsub("[^%w%-_]", ""):lower())
          end
          local file = M.root .. "/" .. slug(t) .. ".md"

          if vim.fn.filereadable(file) == 0 then
            local Path = require("plenary.path")
            local body
            if require("plenary.path").new(M.default_tpl):exists() then
              body = Path:new(M.default_tpl):read():gsub("{{TITLE}}", t):gsub("{{title}}", t)
            else
              body = ("---\ntitle: %s\n---\n\n# %s\n"):format(t, t)
            end
            Path:new(file):write(body, "w")
          end

          vim.cmd.edit(vim.fn.fnameescape(file))
        end)
      end, {})

      -- Use a non-conflicting key (leave Aerial's <leader>zn alone)
      vim.keymap.set("n", "<leader>zN", "<cmd>NotesNew<CR>", { desc = "Notes: New note" })

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
          local title = text:match("\n?title:%s*([^\n]+)") or text:match("^#%s+([^\n]+)") or rel:gsub("%.md$", "")
          vim.api.nvim_put({ string.format("[[%s]]", title) }, "c", true, true)
        end)
      end

      -- live full-text search
      function M.search_text()
        if has_snacks and vim.g.notes_results == "snacks" and Snacks.picker and Snacks.picker.grep then
          Snacks.picker.grep({ cwd = M.root, title = "Search notes" })
        else
          vim.ui.input({ prompt = "Search pattern: " }, function(q)
            if not q or q == "" then
              return
            end
            run_rg_to_qf({ cwd = M.root, title = "Search: " .. q, pattern = q })
          end)
        end
      end

      -- TAG SEARCH: body + frontmatter (with or without '#'), case-insensitive
      function M.search_tag()
        vim.ui.input({ prompt = "Tag (with or without #): " }, function(input)
          if not input or input == "" then
            return
          end
          local tag = input:gsub("^%s*#?", "")
          local t = vim.pesc(tag)
          local class = "[A-Za-z0-9_/-]"
          local pat = table.concat({
            "(?mi)" .. "(?<!" .. class .. ")#" .. t .. "(?!#?" .. class .. ")", -- body #tag
            "(?mi)^tags:%s*%[[^]]*\\b#?" .. t .. "\\b", -- frontmatter inline list
            "(?mi)^%s*-%s*#?" .. t .. "\\b", -- frontmatter list items
          }, "|")
          run_rg_to_qf({ cwd = M.root, title = "#" .. tag .. " (tags + frontmatter)", pattern = pat })
        end)
      end

      -- BACKLINKS (ripgrep): wikilinks + markdown links (multi-path, case-insensitive)
      function M.backlinks()
        local buf = vim.api.nvim_buf_get_name(0)
        if buf == "" then
          return vim.notify("Open a note first", vim.log.levels.WARN)
        end

        local name = Path:new(buf):make_relative(M.root):gsub("%.md$", "")
        local text = (vim.fn.filereadable(buf) == 1) and table.concat(vim.fn.readfile(buf), "\n") or ""
        local title = text:match("\n?title:%s*([^\n]+)") or text:match("^#%s+([^\n]+)") or name

        local s_title = slug(title)
        local s_name = slug(name)

        local targets = table.concat({
          vim.pesc(name),
          vim.pesc(title),
          vim.pesc(s_title),
          vim.pesc(s_name),
        }, "|")

        local wikilink = [=[(?mi)\[\[(?:[^|\]]*/)*?(?:]=] .. targets .. [=[)(?:\.md)?(?:#[^\]\|]*)?(?:\|[^\]]*)?\]\]]=]
        local mdlink = [=[(?mi)\]\((?:[^)\s]*/)*?(?:]=] .. targets .. [=[)(?:\.md)?(?:#[^)]+)?\)]=]
        local pat = wikilink .. "|" .. mdlink

        run_rg_to_qf({ cwd = M.root, title = "Backlinks to [[" .. title .. "]]", pattern = pat })
      end

      ------------------------------------------------------------------
      -- BACKLINKS via Marksman LSP (default on <leader>zb)
      ------------------------------------------------------------------
      local function loc_to_qf(loc)
        local uri = loc.uri or loc.targetUri
        local range = loc.range or loc.targetSelectionRange or loc.targetRange
        local fname = uri and vim.uri_to_fname(uri) or ""
        local lnum = (range and range.start and (range.start.line + 1)) or 1
        local col = (range and range.start and (range.start.character + 1)) or 1
        local text = ""
        if fname ~= "" then
          pcall(function()
            local lines = vim.fn.readfile(fname)
            text = (lines[lnum] or ""):gsub("%s+$", "")
          end)
        end
        return { filename = fname, lnum = lnum, col = col, text = text }
      end

      function M.backlinks_marksman()
        local bufnr = vim.api.nvim_get_current_buf()
        local file = vim.api.nvim_buf_get_name(bufnr)
        if file == "" then
          vim.notify("Open a note first", vim.log.levels.WARN)
          return
        end

        -- Is Marksman attached to this buffer?
        local has_mm = false
        for _, c in ipairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
          if c.name == "marksman" then
            has_mm = true
            break
          end
        end
        if not has_mm then
          -- fallback to ripgrep
          return M.backlinks()
        end

        -- Request references synchronously (works uniformly on 0.11)
        local params = vim.lsp.util.make_position_params()
        params.context = { includeDeclaration = false }

        -- timeout in ms (tweak if you like)
        local resp = vim.lsp.buf_request_sync(bufnr, "textDocument/references", params, 2000)
        if type(resp) ~= "table" then
          vim.notify("LSP returned no data; falling back to ripgrep", vim.log.levels.WARN)
          return M.backlinks()
        end

        -- Convert responses to quickfix items
        local function loc_to_qf(loc)
          local uri = loc.uri or loc.targetUri
          local range = loc.range or loc.targetSelectionRange or loc.targetRange
          local fname = uri and vim.uri_to_fname(uri) or ""
          local lnum = (range and range.start and (range.start.line + 1)) or 1
          local col = (range and range.start and (range.start.character + 1)) or 1
          local text = ""
          if fname ~= "" then
            pcall(function()
              local lines = vim.fn.readfile(fname)
              text = (lines[lnum] or ""):gsub("%s+$", "")
            end)
          end
          return { filename = fname, lnum = lnum, col = col, text = text }
        end

        local qf = {}
        for _, server_res in pairs(resp) do
          if type(server_res) == "table" and type(server_res.result) == "table" then
            for _, loc in ipairs(server_res.result) do
              qf[#qf + 1] = loc_to_qf(loc)
            end
          end
        end

        if #qf == 0 then
          vim.notify("No backlinks found via Marksman", vim.log.levels.INFO)
          return
        end

        vim.fn.setqflist({}, "r")
        vim.fn.setqflist(qf, "r")
        vim.fn.setqflist({}, "a", { title = "Backlinks (marksman)" })

        -- Show with your preferred UI
        if vim.g.notes_results == "snacks" then
          local ok_s, S = pcall(require, "snacks")
          if ok_s and S.picker and S.picker.qflist then
            pcall(function()
              S.picker.qflist({ title = "Backlinks (marksman)" })
            end)
            return
          end
        end
        local ok_fzf, fzf = pcall(require, "fzf-lua")
        if ok_fzf then
          fzf.quickfix()
        else
          vim.cmd("copen")
        end
      end
      -- ===== Obsidian-style TODOs (checkboxes + #tags + @people) =====
      -- Commands + keymaps reuse the same run_rg_to_qf + M.root

      -- ensure vim.pesc exists (already defined above, but safe)
      vim.pesc = vim.pesc or function(str)
        return (str:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1"))
      end

      -- Commands
      vim.api.nvim_create_user_command("NotesTodosAll", function()
        run_rg_to_qf({ cwd = M.root, title = "TODOs (all)", pattern = [[(?m)^\s*[-*]\s*\[[ xX]\]\s+.*$]] })
      end, {})
      vim.api.nvim_create_user_command("NotesTodosOpen", function()
        run_rg_to_qf({ cwd = M.root, title = "TODOs (open)", pattern = [[(?m)^\s*[-*]\s*\[\s\]\s+.*$]] })
      end, {})
      vim.api.nvim_create_user_command("NotesTodosPerson", function()
        vim.ui.input({ prompt = "Person (without @): " }, function(person)
          if not person or person == "" then
            return
          end
          run_rg_to_qf({
            cwd = M.root,
            title = "TODOs for @" .. person,
            pattern = [[(?m)^\s*[-*]\s*\[\s\]\s+.*@]] .. vim.pesc(person) .. [[\b]],
          })
        end)
      end, {})
      vim.api.nvim_create_user_command("NotesTodosTag", function()
        vim.ui.input({ prompt = "Tag (without #): " }, function(tag)
          if not tag or tag == "" then
            return
          end
          run_rg_to_qf({
            cwd = M.root,
            title = "TODOs tagged #" .. tag,
            pattern = [[(?m)^\s*[-*]\s*\[\s\]\s+.*#]] .. vim.pesc(tag) .. [[\b]],
          })
        end)
      end, {})
      vim.api.nvim_create_user_command("NotesToggleCheckbox", function()
        local line = vim.api.nvim_get_current_line()
        if not line then
          vim.notify("No line content found", vim.log.levels.ERROR)
          return
        end

        local new_line = nil
        if line:match("%[%s%]") then
          new_line = line:gsub("%[%s%]", "[x]", 1)
        elseif line:match("%[[xX]%]") then
          new_line = line:gsub("%[[xX]%]", "[ ]", 1)
        else
          vim.notify("No checkbox on this line", vim.log.levels.INFO)
          return
        end

        if new_line and new_line ~= line then
          vim.api.nvim_set_current_line(new_line)
        end
      end, {})

      -- Create new todo item
      vim.api.nvim_create_user_command("NotesNewTodo", function()
        vim.ui.input({ prompt = "Todo: " }, function(todo_text)
          if not todo_text or todo_text == "" then
            return
          end

          local line_num = vim.api.nvim_win_get_cursor(0)[1]
          local current_line = vim.api.nvim_get_current_line()

          -- If current line is empty or just whitespace, replace it
          if current_line:match("^%s*$") then
            vim.api.nvim_set_current_line("- [ ] " .. todo_text)
          else
            -- Insert new todo line after current line
            vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { "- [ ] " .. todo_text })
          end
        end)
      end, {})

      -- Keymaps (Tasks group)
      local ok_wk, wk = pcall(require, "which-key")
      if ok_wk then
        wk.add({ { "<leader>t", group = "Tasks" } })
      end
      vim.keymap.set("n", "<leader>tt", "<cmd>NotesTodosAll<CR>", { desc = "TODOs: All" })
      vim.keymap.set("n", "<leader>to", "<cmd>NotesTodosOpen<CR>", { desc = "TODOs: Open only" })
      vim.keymap.set("n", "<leader>tp", "<cmd>NotesTodosPerson<CR>", { desc = "TODOs: By @person" })
      vim.keymap.set("n", "<leader>tg", "<cmd>NotesTodosTag<CR>", { desc = "TODOs: By #tag" })
      vim.keymap.set("n", "<leader>tx", "<cmd>NotesToggleCheckbox<CR>", { desc = "TODOs: Toggle checkbox" })
      vim.keymap.set("n", "<leader>tn", "<cmd>NotesNewTodo<CR>", { desc = "TODOs: New todo" })

      -- tiny debug helper
      vim.api.nvim_create_user_command("NotesDebug", function()
        local uv = vim.uv or vim.loop
        local exists = (uv and uv.fs_stat and uv.fs_stat(M.root)) and "yes" or "no"
        local out = {
          "NOTES DEBUG",
          "root = " .. (M.root or "<nil>"),
          "exists(root) = " .. exists,
          "Filling Quickfix with '.' search…",
        }
        vim.notify(table.concat(out, "\n"), vim.log.levels.INFO)
        run_rg_to_qf({ cwd = M.root, title = "DEBUG: any .md", pattern = [=[.]=] })
      end, {})
    end,
  },
}
