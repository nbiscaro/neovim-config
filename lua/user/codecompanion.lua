local status_ok, codecompanion = pcall(require, "codecompanion")
if not status_ok then
  return
end

codecompanion.setup({
  adapters = {
    chat = {
      llm_provider = "ollama", -- Using Ollama for free local models
      llm_model = "mistral", -- Mistral 7B is a good free model with strong performance
      context_window = 8192, -- Reduced context window for local models
      
      -- Ollama configuration (you need to install Ollama first: https://ollama.ai/download)
      ollama = {
        url = "http://localhost:11434", -- Default Ollama API URL
      },
      
      -- Keeping other provider configs for reference but commented out
      -- openai = {
      --   api_key = os.getenv("OPENAI_API_KEY")
      -- },
    },
  },
  auto_insert_mode = false, -- Whether to automatically enter insert mode when opening the chat window
  window = {
    width = 0.4, -- Width of the window (between 0 and 1)
    border = "rounded", -- The border style for the window: "none", "single", "double", "rounded", "solid", "shadow"
  },
  prompts = {
    -- Add your own custom prompts here
    explain_code = {
      prompt = "Explain the following code to me in detail:\n\n$selection",
    },
    improve_code = {
      prompt = "Here's my code:\n\n$selection\n\nRefactor and improve this code. Explain what you did.",
    },
    fix_bugs = {
      prompt = "Here's my code:\n\n$selection\n\nThis code has bugs. Identify and fix them. Explain the issues.",
    },
    add_tests = {
      prompt = "Here's my code:\n\n$selection\n\nWrite comprehensive tests for this code. Cover all important cases.",
    },
    documentation = {
      prompt = "Here's my code:\n\n$selection\n\nWrite proper documentation for this code, including JSDoc/docstrings and inline comments.",
    },
  },
  -- Function to run before sending a buffer to the LLM; returns a table with path, filename and filetype
  before_buffer_send = function()
    return {
      path = vim.api.nvim_buf_get_name(0),
      filename = vim.fn.expand("%:t"),
      filetype = vim.bo.filetype,
    }
  end,
}) 