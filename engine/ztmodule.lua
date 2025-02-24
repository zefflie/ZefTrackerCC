--  Module

local ztmodule = {}

--  Import

local txt = require "lib.txt"

--  Variables

local ZFM_VERSION = 1

local file = nil
local line_counter = 0

ztmodule.index_song = 1
ztmodule.index_order = 1
ztmodule.index_row = 1

--  Tostring metatables

local meta_array = {}

function meta_array.__concat(a, b)
  local str = "{"

  for i, v in ipairs(a) do
    str = str .. v .. ", "
  end

  return str .. "}" .. b
end

local meta_token = {}

function meta_token.__concat(a, b)
  local str = "["..a.line_pos.."] " ..a.name .. " {"

  for k, v in pairs(a) do
    if k ~= "line_pos" and k ~= "name" then
      str = str .. k .. "=" .. v .. ", "
    end
  end

  return str .. "}" .. b
end

--  Functions

function ztmodule.new()
  ztmodule.index_song = 1
  ztmodule.index_order = 1
  ztmodule.index_row = 1

  ztmodule.module = {
    name = "",
    author = "",
    copyright = "",
  }

  ztmodule.songs = {}
end

function ztmodule.open(filename)
  ztmodule.new()

  file = fs.open(filename, "r")
  line_counter = 0

  --  Version control
  local firstline = ztmodule.readline()
  local mo = firstline:match("ZefTrackerModule v(%d+)")

  if mo then
    if tonumber(mo) ~= ZFM_VERSION then
      error("Open error: Unsupported module version v" .. mo .. ", expected v" .. ZFM_VERSION)
    end
  else
    error("Open error: Not a ZefTrackerModule file")
  end

  local flag_module = false
  local flag_song = 0
  local flag_insong = ""
  local flag_pattern = 0

  while true do
    local token = ztmodule.readtoken()

    if token.name == "eof" then
      break
    end

    if token.name == "invalid" then
      error("Parse error:\n"..(token..""))
    end

    if token.name == "section" then
      if token.key == "module" then
        flag_module = true
        flag_song = 0

      elseif token.key == "song" then
        flag_song = tonumber(token.value)
        flag_insong = ""
        ztmodule.songs[flag_song] = {
          settings = {
            speed = 6,
            tempo = 128,
            rows = 0,
            channels = 0,
          },
          order = {},
          patterns = {},
        }

      elseif token.key == "settings" then
        flag_insong = "settings"

      elseif token.key == "order" then
        flag_insong = "order"

      elseif token.key == "pattern" then
        flag_insong = "pattern"
        flag_pattern = tonumber(token.value)
        ztmodule.songs[flag_song].patterns[flag_pattern] = {}

      else
        error("Key error at "..token.line_pos..":\nUnknown section name '"..token.key.."'")

      end
    end

    if token.name == "assign" then
      if flag_module and flag_song == 0 then
        ztmodule.module[token.key] = token.value

      elseif flag_insong == "settings" then
        ztmodule.songs[flag_song].settings[token.key] = tonumber(token.value)

      else
        error("Semantic error at "..token.line_pos..":\nUnexpected assign '"..token.line.."'")

      end
    end

    if token.name == "order" then
      if flag_insong == "order" then
        table.insert(ztmodule.songs[flag_song].order, token.value)

      else
        error("Semantic error at "..token.line_pos..":\nUnexpected order '"..token.line.."'")

      end
    end

    if token.name == "row" then
      if flag_insong == "pattern" then
        table.insert(ztmodule.songs[flag_song].patterns[flag_pattern], {
          note = token.note,
          instrument = token.instrument,
          volume = token.volume,
        })

      else
        error("Semantic error at "..token.line_pos..":\nUnexpected row '"..token.line.."'")

      end
    end
  end

  file.close()

  for j = 1, #ztmodule.songs do
    local song = ztmodule.songs[j]
    local zeropattern = {}

    for i = 1, song.settings.rows do
      table.insert(zeropattern, {note = "...", instrument = "..", volume = ".."})
    end

    song.patterns[0] = zeropattern
  end
end

function ztmodule.readline()
  local line = ""

  while line == "" do
    line = file.readLine()
    line_counter = line_counter + 1

    --  EOF
    if line == nil then 
      break 
    end

    --  Remove Comments
    local comment_pos = line:find("//")

    if comment_pos then
      line = line:sub(1, comment_pos - 1)
    end

    --  Space trim
    line = txt.trim(line)
  end

  return line
end

function ztmodule.readtoken()
  local line = ztmodule.readline()
  local token = {
    line = line,
    line_pos = line_counter,
    name = "invalid",
  }
  setmetatable(token, meta_token)

  --  EOF token
  if line == nil then
    token.name = "eof"
    return token
  end

  --  Section token
  local mo = { line:match("%[(%a+)%s?(%d*)%]") }

  if mo[1] then
    token.name = "section"
    token.key = string.lower(mo[1])
    token.value = mo[2]
    return token
  end

  --  Assign token
  mo = { line:match("(%w+)%s?=%s?(.*)") }

  if mo[1] then
    token.name = "assign"
    token.key = txt.trim(mo[1])
    token.value = txt.trim(mo[2])
  end

  --  Order token
  mo = line:match("^>%s")

  if mo then
    token.name = "order"
    token.value = {}
    setmetatable(token.value, meta_array)

    for index in line:gmatch("(%d%d)") do
      table.insert(token.value, index)
    end
  end

  --  Row token
  mo = line:match("^-%s")

  if mo then
    token.name = "row"
    local mo_row = table.pack( line:match("-%s(...)%s(..)%s(..)") )

    if mo_row then
      --  Note
      local mo_note = mo_row[1]:match("%.%.%.")

      if mo_note then
        token.note = mo_note
      end

      mo_note = mo_row[1]:match("%-%-%-")

      if mo_note then
        token.note = mo_note
      end

      mo_note = mo_row[1]:match("[A-G][#%-][1-7]")

      if mo_note then
        token.note = mo_note
      end

      --  Instrument
      local mo_inst = mo_row[2]:match("%.%.")

      if mo_inst then
        token.instrument = mo_inst
      end

      mo_inst = mo_row[2]:match("%d%d")

      if mo_inst then
        token.instrument = mo_inst
      end

      --  Volume
      local mo_volume = mo_row[3]:match("%.%.")

      if mo_volume then
        token.volume = mo_volume
      end

      mo_volume = mo_row[3]:match("%d%d")

      if mo_volume then
        token.volume = mo_volume
      end

      --  End
      if not (token.note and token.instrument and token.volume) then
        token.name = "invalid"
      end

      return token
    end

    token.name = "invalid"
  end

  return token
end

--  Export

ztmodule.new()

return ztmodule