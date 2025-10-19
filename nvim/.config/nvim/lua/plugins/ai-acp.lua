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
        -- Keep UI simple and fast
        adapters = {
          opts = {
            show_model_choices = false, -- don't prompt for models when switching
          },

          -- === ACP adapters (agent CLIs that use your user subscription) ===
          acp = {
            -- Claude Code via ACP with Claude Pro OAuth token (no API billing)
            claude_code = function()
              return adapters.extend("claude_code", {
                -- Paste the token you get from: `claude setup-token`
                -- You can also pull it from 1Password/GPG using `cmd:...`
                env = {
                  CLAUDE_CODE_OAUTH_TOKEN = os.getenv("CLAUDE_CODE_OAUTH_TOKEN") or "paste-oauth-token-here",
                },
              })
            end,

            -- Gemini CLI via ACP (no billing key required if you auth via CLI);
            -- you *can* set GEMINI_API_KEY if you have one from Google AI Studio.
            gemini_cli = function()
              return adapters.extend("gemini_cli", {
                -- If your system needs a custom executable path, uncomment commands:
                -- commands = { default = { "gemini", "--experimental-acp" } },
                defaults = {
                  auth_method = "oauth-personal", -- or "gemini-api-key" / "vertex-ai"
                  timeout = 20000,
                  mcpServers = {}, -- add MCP servers if you like
                },
                env = {
                  GEMINI_API_KEY = os.getenv("GEMINI_API_KEY") or "",
                },
              })
            end,
          },

          -- (Optional) HTTP adapters if later you decide to use API keys:
          -- http = {
          --   anthropic = function() ... end,
          --   gemini = function() ... end,
          --   openai = function() ... end,
          -- },
        },

        -- Use agents for both chat and inline edits
        strategies = {
          chat = {
            adapter = {
              name = "gemini",
              model = "gemini-2.5-flash",
            },
            roles = {
              user = "Benigno",
            },
          },
          keymaps = {
            send = {
              modes = {
                i = { "<C-CR>", "<C-s>" },
              },
            },
            completion = {
              modes = {
                i = { "<C-x>" },
              },
            },
          },
          slash_commands = {
            ["buffer"] = {
              keymaps = {
                modes = {
                  i = "C-b",
                },
              },
            },
            ["fetch"] = {
              keymaps = {
                modes = {
                  i = "C-f",
                },
              },
            },
          },
          -- chat = { adapter = "claude_code" }, -- default chat = Claude Code
          inline = { adapter = "gemini", model = "gemini-2.5-flash" }, -- default inline edits = Gemini
          -- Quick switch: :CodeCompanionActions → Change Adapter → Gemini CLI
        },

        -- Nice defaults
        opts = {
          log_level = "WARN", -- set to "DEBUG" if you need to troubleshoot
        },
      }
    end,
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI Chat (CodeCompanion)" },
      { "<leader>ai", "<cmd>CodeCompanionInline<cr>", desc = "AI Inline Edit (visual select first)" },
      { "<leader>as", "<cmd>CodeCompanionSuperDiff<cr>", desc = "AI Super Diff (review agent edits)" },
      { "<leader>am", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions / Switch Agent" },
      { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>", desc = "Add code to a chat buffer", mode = { "v" } },
    },
  },
}
