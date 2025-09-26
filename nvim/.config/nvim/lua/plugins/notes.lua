-- Plain Markdown notes (portable macOS/Windows/WSL) + optional pickers
-- Keys (<leader> = Space):
--   <leader>z n : New note
--   <leader>z d : Today note
--   <leader>z l : Insert [[link]]
--   <leader>z s : Live search (Snacks if present)
--   <leader>z t : Search by tag  (PCRE2 via ripgrep)
--   <leader>z b : Backlinks      (PCRE2 via ripgrep)
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
        local function to_abs(p, cwd)
          if p == nil or p == "" then
            return p
          end
          -- expand ~
          if p:sub(1, 1) == "~" then
            p = vim.fn.expand(p)
          end
          -- already absolute? (win or unix)
          if vim.fn.has("win32") == 1 then
            if p:match("^%a:[/\\]") or p:match("^\\\\") then
              return p
            end
          else
            if p:sub(1, 1) == "/" then
              return p
            end
          end
          -- make absolute relative to the rg cwd
          return vim.fn.fnamemodify(cwd .. "/" .. p, ":p")
        end

        local qf = {}
        for _, line in ipairs(lines) do
          local file, lno, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
          if file and lno and col then
            file = to_abs(file, cwd) -- <<< normalize to absolute
            qf[#qf + 1] = {
              filename = file,
              lnum = tonumber(lno),
              col = tonumber(col),
              text = text,
            }
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
          local tag = input:gsub("^%s*#?", "") -- normalize
          local t = vim.pesc(tag)
          local class = "[A-Za-z0-9_/-]"
          local pat = table.concat({
            -- body #tag with custom "word" class so '-' and '/' stay inside
            "(?mi)"
              .. "(?<!"
              .. class
              .. ")#"
              .. t
              .. "(?!"
              .. class
              .. ")",
            -- frontmatter inline list
            "(?mi)^tags:%s*%[[^]]*\\b#?"
              .. t
              .. "\\b",
            -- frontmatter list items
            "(?mi)^%s*-%s*#?"
              .. t
              .. "\\b",
          }, "|")
          run_rg_to_qf({ cwd = M.root, title = "#" .. tag .. " (tags + frontmatter)", pattern = pat })
        end)
      end

      -- BACKLINKS: wikilinks + markdown links (multi-path, case-insensitive)
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
