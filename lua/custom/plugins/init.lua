-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec


-- execute build command from first line of file
local get_log_buffer = function()
  -- https://github.com/nvim-neo-tree/neo-tree.nvim/blob/e968cda658089b56ee1eaa1772a2a0e50113b902/lua/neo-tree/utils.lua#L157-L165
  local name = '__log_buffer'
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if string.sub(buf_name, -#name) == name then
      -- todo: force buffer to be listed in :buffers (the user might have closed it with :bd)
      return buf
    end
  end
  local log_buffer = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(log_buffer, name)
  return log_buffer
end
local run_build_command = function()
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
  vim.cmd.w() -- building should save changes first
  local build_command = string.match(first_line, 'BUILD_COMMAND +(.*)$')
  if not build_command then return end

  local log_buffer = get_log_buffer()
  local with_log_buffer = function(fun) vim.api.nvim_buf_call(log_buffer, fun) end
  local append_to_buffer = function(data_list)
    with_log_buffer(function()
      vim.cmd('norm! G$') -- move cursor to end of buffer
      vim.api.nvim_put(data_list, 'c', false, true)
    end)
  end

  -- clear the log buffer
  with_log_buffer(function() vim.cmd('norm!gg"_dG') end)
  append_to_buffer({'running: ' .. build_command, ''})
  -- run build in background, write log
  vim.fn.jobstart(build_command, {
    on_stdout = function(_, data)
      append_to_buffer(data)
    end,
    on_stderr = function(_, data)
      append_to_buffer(data)
    end
    })
end
vim.keymap.set('n', '<leader>b', run_build_command, { desc = '[B]uild current buffer' })

return {}
