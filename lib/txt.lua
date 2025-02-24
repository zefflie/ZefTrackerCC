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

--  Export

return txt