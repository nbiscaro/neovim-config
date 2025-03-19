-- Extremely simple implementation with minimal options
local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
  return
end

-- Make sure termguicolors is enabled (required for bufferline)
vim.opt.termguicolors = true

-- Add this to properly handle buffer deletion
local status_ok_bd, _ = pcall(require, "bufdelete")

bufferline.setup({
  options = {
    close_command = status_ok_bd and "Bdelete! %d" or "bdelete! %d",
    right_mouse_command = "bdelete! %d",
    left_mouse_command = "buffer %d",
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        text_align = "left",
      }
    },
    separator_style = "thin",
  }
})
