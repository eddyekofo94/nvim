-- Every entry in `nvim-pack-lock.json` must be backed by a spec under
-- `lua/pack/specs/`. `vim.pack` reinstalls any lockfile entry on the first
-- `vim.pack` call, so an entry without a spec resurrects a plugin the config
-- no longer declares. Run with `nvim --headless -u NONE -l`.
local srcs = {}

---@param spec any
local function walk(spec)
  if type(spec) == "string" then
    srcs[spec] = true
    return
  end
  if type(spec) ~= "table" then
    return
  end
  if spec.src then
    srcs[spec.src] = true
  end
  -- Fields may sit at the top level or under `data`; `utils.pack` normalizes
  -- them at registration time, which this static check cannot rely on.
  for _, holder in ipairs({ spec, spec.data or {} }) do
    for _, field in ipairs({ "deps", "exts" }) do
      local value = holder[field]
      if type(value) == "string" or (type(value) == "table" and value.src) then
        walk(value)
      elseif type(value) == "table" then
        for _, entry in ipairs(value) do
          walk(entry)
        end
      end
    end
  end
end

for _, dir in ipairs({ "lua/pack/specs/start", "lua/pack/specs/opt" }) do
  for entry in vim.fs.dir(dir) do
    walk(dofile(vim.fs.joinpath(dir, entry)))
  end
end

local names = {}
for src in pairs(srcs) do
  names[vim.fs.basename(src)] = true
end

local lockfile = assert(io.open("nvim-pack-lock.json"))
local lock = vim.json.decode(lockfile:read("a")).plugins
lockfile:close()

local orphans = {}
for name in pairs(lock) do
  if not names[name] then
    table.insert(orphans, name)
  end
end
table.sort(orphans)

if #orphans > 0 then
  io.stderr:write(
    "Lockfile entries without a spec: "
      .. table.concat(orphans, ", ")
      .. "\nRemove them with `:packdel` and commit nvim-pack-lock.json.\n"
  )
  vim.cmd("cquit 1")
end
