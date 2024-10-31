function(path)
  if (path:find("^libs/")) then
    return require("dist/core")(path)
  elseif (path:find("^library/")) then
    return require("dist/lib")(path)
  else
    return require(path)
  end
end