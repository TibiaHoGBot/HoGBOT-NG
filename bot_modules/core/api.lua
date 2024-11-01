local state_manager = require("bot_modules/core/state_manager")
local helpers = require("bot_modules/core/helpers")

local api = {
  updateState = state_manager.updateState,
  loadFile = helpers.loadFile,
  saveFile = helpers.saveFile
}

return api
