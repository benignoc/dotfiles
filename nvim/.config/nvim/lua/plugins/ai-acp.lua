-- File: lua/plugins/ai-acp.lua
return {
  {
    "olimorris/codecompanion.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
      local adapters = require("codecompanion.adapters")

      return {
        -- === Adapters =======================================================
        adapters = {
          -- Show model picker each time (and avoid silent failures)
          opts = {
            show_model_choices = true, -- you'll be prompted for the model
          },

          -- ACP adapters (no API billing if you auth via their CLIs)
          acp = {
            -- Claude Code via ACP (uses your Claude Pro OAuth token)
            claude_code = function()
              return adapters.extend("claude_code", {
                env = {
                  CLAUDE_CODE_OAUTH_TOKEN = os.getenv("CLAUDE_CODE_OAUTH_TOKEN") or "paste-oauth-token-here",
                },
              })
            end,

            -- Gemini CLI via ACP
            gemini_cli = function()
              return adapters.extend("gemini_cli", {
                defaults = {
                  auth_method = "oauth-personal",
                  timeout = 20000,
                  mcpServers = {},
                },
                env = { GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") or "" },
              })
            end,
          },

          -- IMPORTANT: do NOT override the built-in Ollama adapter here.
          -- Use the built-in "ollama" adapter and let the model picker ask you.
        },

        -- === Strategies (how CC behaves in chat/inline) =====================
        strategies = {
          --   - "ollama" (your local Ollama server; pick model like qwen2.5-coder:7b or llama3.2:3b)
          -- CHAT: use Gemini CLI via ACP as the default adapter/model
          chat = {
            -- adapter left unset on purpose so you can choose when opening chat
            adapter = "gemini",
            model = "gemini-2.5-flash", -- Replace with the actual model you want to use
            roles = { user = "Benigno" },
          },

          -- INLINE: also leave unset so you can choose per use (or set a default if you prefer)
          inline = {
            adapter = "gemini",
            model = "gemini-2.5-flash", -- Replace with the actual model you want to use
            -- adapter = "ollama",
            -- model   = "qwen2.5-coder:7b",
          },

          -- Keymaps (your originals, kept)
          keymaps = {
            send = { modes = { i = { "<C-CR>", "<C-s>" } } },
            completion = { modes = { i = { "<C-x>" } } },
          },
          slash_commands = {
            ["buffer"] = { keymaps = { modes = { i = "C-b" } } },
            ["fetch"] = { keymaps = { modes = { i = "C-f" } } },
          },
        },

        -- Plugin opts
        opts = {
          log_level = "DEBUG", -- helpful while testing adapter/model switching
        },
      }
    end,

    -- Keys (unchanged)
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI Chat (CodeCompanion)" },
      { "<leader>ai", "<cmd>CodeCompanionInline<cr>", desc = "AI Inline Edit (visual select first)" },
      { "<leader>as", "<cmd>CodeCompanionSuperDiff<cr>", desc = "AI Super Diff (review agent edits)" },
      { "<leader>am", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions / Switch Agent" },
      { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>", desc = "Add code to a chat buffer", mode = { "v" } },
    },
  },
}
