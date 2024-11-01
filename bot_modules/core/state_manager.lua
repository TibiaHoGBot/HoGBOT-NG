local helpers = require("bot_modules/core/helpers")

local stateManager = {}

local VALID_ACTIONS = {
  update = true,
  remove = true,
  create = true,
  reorder = true,
  enable = true,
  load = true,
}

local VALID_ITEM_TYPES = {
  healthRule = true,
  persistenceRule = true,
  waypointGroup = true,
  waypoint = true,
  targetingRule = true,
  targetingSetting = true,
  state = true,
}

local function parseInput(jsonLib, value)
  local success, parsed = pcall(jsonLib.decode, value)

  if not success then
    error("Failed to decode JSON input")
  end

  if not parsed.action or not VALID_ACTIONS[parsed.action] then
    error("Action is absent or invalid")
  end

  if not parsed.itemType or not VALID_ITEM_TYPES[parsed.itemType] then
    error("Item type is required")
  end

  return parsed
end

local function getItems(state, parsed, itemType)
  if itemType == "healthRule" then
    return state.healer.rules
  elseif itemType == "persistenceRule" then
    return state.persistences.rules
  elseif itemType == "waypointGroup" then
    return state.cavebot.waypoints
  elseif itemType == "waypoint" then
    local parentId = parsed.parentId or parsed.value.parentId
    return state.cavebot.waypoints[parentId]
  elseif itemType == "targetingRule" then
    return state.targeting.rules
  elseif itemType == "targetingSetting" then
    local parentId = parsed.parentId or parsed.value.parentId
    local parentIdx = helpers.findItemIdxById(state.targeting.rules, parentId)
    return state.targeting.rules[parentIdx]["settings"]
  end

  return nil
end

local actionHandlers = {
  load    = function(state, parsed, _)
    for field, val in pairs(parsed["value"]) do state[field] = val end
    print(helpers.dump(state))
  end,

  create  = function(state, parsed, itemType)
    local newVal = parsed.value

    local items = getItems(state, parsed, itemType)

    if not items then
      error("Failed to find the collection")
    end

    if itemType == "healthRule" then
      table.insert(items, #items + 1, newVal)
    elseif itemType == "persistenceRule" then
      table.insert(items, #items + 1, newVal)
    elseif itemType == "waypointGroup" then
      for k, v in pairs(newVal) do
        items[k] = v
        break
      end
    elseif itemType == "waypoint" then
      table.insert(items, #items + 1, newVal)
    elseif itemType == "targetingRule" then
      table.insert(items, #items + 1, newVal)
    elseif itemType == "targetingSetting" then
      table.insert(items, #items + 1, newVal)
    end
  end,

  reorder = function(state, parsed, itemType)
    local items = getItems(state, parsed, itemType)

    if not items then
      error("Failed to find the collection")
    end

    local item = table.remove(items, parsed.startIdx + 1)
    table.insert(items, parsed.dropIdx + 1, item)
  end,

  update  = function(state, parsed, itemType)
    local items = getItems(state, parsed, itemType)

    if not items then
      error("Failed to find the collection")
    end

    local itemIdx = helpers.findItemIdxById(items, parsed.id)

    if itemIdx then
      for field, val in pairs(parsed.value) do
        items[itemIdx][field] = val
      end
    else
      error("Failed to find the item")
    end
  end,

  remove  = function(state, parsed, itemType)
    local items = getItems(state, parsed, itemType)

    if not items then
      error("Failed to find the collection")
    end

    local itemIdx = helpers.findItemIdxById(items, parsed.id)

    if itemIdx then
      table.remove(items, itemIdx)
    elseif items[parsed.id] then
      items[parsed.id] = nil
    else
      error("Failed to find the item")
    end
  end,

  enable  = function(state, parsed, itemType)
    local items = getItems(state, parsed, itemType)

    if not items then
      error("Failed to find the collection")
    end

    local itemIdx = helpers.findItemIdxById(items, parsed["id"]) or items[parsed.id]

    if not itemIdx then
      error("Failed to find the item")
    end

    items[itemIdx].enabled = parsed.value
  end
}

function stateManager.updateState(value, callback, context, _)
  local jsonLib = context.jsonLib
  local state = context.state

  local s, parsed = pcall(parseInput, jsonLib, value)

  if not s then
    callback(false, tostring(parsed))
    return
  end

  local action = parsed.action
  local itemType = parsed.itemType

  print("updateState - " .. action .. " - " .. itemType .. "\n" .. value)

  local s, r = pcall(actionHandlers[action], state, parsed, itemType)

  print(helpers.dump(state))
  print("\n\n")

  if s then
    callback(true, "success")
  else
    callback(false, tostring(r))
  end
end

return stateManager
