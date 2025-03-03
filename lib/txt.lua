--[[
  Advanced string library
]]

--  Module

txt = {}

--  Functions

function txt.leftfill(str, n, char)
  str = tostring(str)
  char = char or " "

  while #str < n do
    str = char .. str
  end

  return str
end

function txt.trim(str, pattern)
  str = tostring(str)
  pattern = pattern or "%s*"
  return str:match(pattern.."(.*)"..pattern)
end

function txt.tostring(value)
  local t = type(value)

  if t == nil then
    return "nil"

  elseif t == "boolean" then
    return value and "true" or "false"

  elseif t == "string" then
    return '"'..value..'"'

  elseif t == "table" then
    --  Use custom tostring method
    if type(value.tostring) == "function" then
      return value:tostring()
    end

    local str = "{"
    local has_fields = false
    
    for k, v in pairs(value) do
      has_fields = true
      str = str .. txt.tostring(k) .. " = " .. txt.tostring(v) .. ", "
    end

    if has_fields then
      str = str:sub(1, -3)
    end

    return str .. "}"

  else
    return tostring(value)
  end
end

--  Export

return txt