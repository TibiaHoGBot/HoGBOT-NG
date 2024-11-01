local helpers = {}

function helpers.saveFile(value, _, context, _)
  local dialog = context["dialog"]

  if not dialog then
    print("saveFile: No dialog found.")
    return
  end
  local path = dialog.save_file_dialog_new("Save File", ".json", "script.json")

  if not path then
    print("saveFile:  No file path provided.")
    return
  end

  local file, err = io.open(path, "w")

  if not file then
    print("saveFile:  Error opening file - " .. err)
    return
  end

  file:write(value)
  file:close()
end

function helpers.loadFile(_, callback, context, _)
  local dialog = context["dialog"]

  if not dialog then
    callback(false, "loadFile: No dialog found")
    return
  end

  local path = dialog.open_file_dialog_new("Open File", "json")

  if not path then
    callback(false, "loadFile: No file path provided")
    return
  end

  local file, r = io.open(path, "r")

  if not file then
    callback(false, tostring("loadFile: Error opening file: " .. tostring(r)))
    return
  end

  local val = file:read("*all")

  callback(true, tostring(val))
  file:close()
end

function helpers.findItemIdxById(table, id)
  for idx, item in ipairs(table) do
    if item.id == id then
      return idx
    end
  end
  return nil
end

function helpers.dump(t, indent)
  indent = indent or ""
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(indent .. tostring(k) .. ":")
      helpers.dump(v, indent .. "  ")
    else
      print(indent .. tostring(k) .. ": " .. tostring(v))
    end
  end
end

return helpers
