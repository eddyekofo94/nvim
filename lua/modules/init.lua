return setmetatable({}, {
  __index = function(self, key)
    self[key] = require("modules." .. key)
    return self[key]
  end,
})
