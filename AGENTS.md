# AGENTS.md - Neovim Configuration Guide

This file contains guidelines for agents working on this Neovim configuration codebase.

## Overview

This is a highly personalized Neovim configuration using a custom plugin manager built on `vim.pack`. Plugins are defined in `lua/pack/specs/start/` (loaded on startup) and `lua/pack/specs/opt/` (lazy-loaded).

## Build/Lint/Test Commands

### Formatting
```bash
# Check formatting
make format-check

# Auto-format code
make format
```

### Linting
```bash
# Run luacheck
make lint
```

### Single Test Running
This project uses plenary.nvim for testing. Tests are typically run via:
```bash
# Run all tests
:PlenaryBustedDirectory ./tests/ {minimal_init = ./tests/minimal_init.lua}

# Run single test file
:PlenaryBustedFile ./tests/some_test.lua
```

Or via Makefile targets if defined. Check `tests/` directory for test structure.

### Plugin Installation
```bash
# First-time setup (prompts for plugin installation)
NVIM_APPNAME=nvim nvim +1

# To reinstall all plugins, remove lock file first:
rm ~/.config/nvim/nvim-pack-lock.json
NVIM_APPNAME=nvim nvim
```

## Code Style Guidelines

### General Principles
- Keep code clean, modular, and self-documenting
- Use descriptive variable/function names
- Avoid unnecessary complexity

### Lua Version
- Target Lua 5.1 (Neovim's embedded Lua version)
- Use compatibility patterns where needed

### Imports
```lua
-- Use local require for module imports
local utils = require('utils')
local hl = require('utils.hl')
local key = require('utils.key')

-- Lazy-load heavy modules inside functions when possible
local function some_function()
  local lazy_module = require('heavy.module')
end
```

### Formatting
- Use **StyLua** for formatting (enforced via Makefile)
- 2-space indentation
- Trailing commas in tables
```lua
-- Good
local opts = {
  key = 'value',
  another = 'thing',
}

-- Avoid
local opts = { key = 'value', another = 'thing' }
```

### Types
- Use LuaLS type annotations with `---@` comments
- Common annotations:
```lua
---@param opts table<string, string>
---@return boolean
local function setup(opts)
end

---@type pack.spec
return {
  name = 'plugin-name',
  src = 'https://github.com/user/repo',
}
```

### Naming Conventions
- **Variables/functions**: `snake_case` (e.g., `local function setup_opts()`)
- **Modules**: `snake_case` (e.g., `require('utils.key')`)
- **File names**: `snake_case.lua`
- **Auto commands/augroups**: lowercase with descriptive names
- **Keymaps**: Use `<leader>` prefix for user keymaps

### Error Handling
- Use `pcall` for unsafe operations:
```lua
local ok, module = pcall(require, 'module')
if not ok then
  vim.notify('Module failed to load: ' .. module, vim.log.levels.ERROR)
  return
end
```
- Use `vim.notify` for user-facing errors
- Return early on errors to avoid nested conditionals
- Validate function inputs at entry points

### Neovim-Specific Patterns

#### Plugin Spec Format
```lua
---@type pack.spec
return {
  name = 'plugin-name',        -- Optional: helps with debugging
  src = 'https://github.com/user/repo',
  data = {
    event = { event = 'BufReadPre' },  -- Lazy-load on event
    cmd = { 'SomeCommand' },           -- Lazy-load on command
    keys = {                           -- Lazy-load on keypress
      { '<leader>x', '<cmd>SomeCommand<cr>', desc = 'Do something' },
    },
    ft = { 'python', 'lua' },         -- Lazy-load on filetype
    deps = { 'dependency-plugin' },   -- Load before this plugin
    postload = function()              -- Setup after loading
      require('plugin').setup({})
    end,
  },
}
```

#### Keymaps
Use utility functions from `utils.key`:
```lua
local nmap = require('utils.key').nmap
local xmap = require('utils.key').xmap
local imap = require('utils.key').imap

nmap({
  { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
})
```

#### Autocommands
```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function(args)
    vim.b[args.buf].some_setting = true
  end,
  desc = 'Description of what this does',
})
```

#### Highlights
```lua
local hl = require('utils.hl')
hl.set(0, 'GroupName', { fg = '#ffffff', bg = '#000000' })
hl.link('AnotherGroup', 'ExistingGroup')
```

### Common Pitfalls

1. **Don't use `vim.cmd`** - Use `vim.api.nvim_*` functions instead
2. **Don't use global variables** - Use module locals or `vim.g`/`vim.b`/`vim.w`/`vim.t`
3. **Don't block startup** - Lazy-load heavy plugins
4. **Don't forget to validate** - Check if plugins exist before configuring

## Directory Structure

```
nvim/
├── lua/
│   ├── core/          -- Core configuration (options, keymaps, pack)
│   ├── pack/specs/
│   │   ├── start/     -- Startup plugins
│   │   └── opt/       -- Optional/lazy-loaded plugins
│   ├── plugin/        -- Plugin configurations
│   └── utils/         -- Utility modules
├── after/             -- ftplugin overrides
├── colors/           -- Color schemes
├── syntax/           -- Syntax files
├── queries/          -- Tree-sitter queries
└── Makefile          -- Format/lint commands
```

## Testing

When adding new functionality:
1. Test manually with `NVIM_APPNAME=nvim nvim`
2. Check for errors with `:messages` or `:lua vim.notify()`
3. Verify no regressions in existing functionality

## Dependencies

- **stylua**: Code formatter
- **luacheck**: Linter
- **plenary.nvim**: Required for testing
- **fd**, **rg**, **fzf**: Required for fuzzy finding features

---

Generated for agent-assisted development. See README.md for more details.
