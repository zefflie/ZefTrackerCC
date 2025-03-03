--[[
  Zeftracker engine
]]

--  Module

local engine = {}



--  Import

engine.notes = require "engine.notes"
engine.waves = require "engine.waves"
engine.effects = require "engine.effects"

local txt = require "lib.txt"



--  Functions (General)

local SAMPLERATE = 48000
local TAU = math.pi * 2

local speaker = peripheral.find("speaker")
local waves = {
  [0] = engine.waves.pulse,
  --[1] = engine.waves.triangle,
  [2] = engine.waves.noise,
  [3] = engine.waves.square,
  [4] = engine.waves.saw,
  [5] = engine.waves.sine,
}

local commands = {
  none = 0,
  accord = 1,
}

engine.state = {}

function engine.new_state()
  engine.state = {
    play = false,
  
    song_index = 1,
    frame_index = 1,
    row_index = 1,

    bufferlength = 0,
    channels = {},
  }
end

engine.new_state()

function engine.mainloop()
  local hz = 0
  while true do
    if engine.state.play then
      engine._step()
    end

    sleep(0)
  end
end

function engine._step()
  local song = engine.ztm.songs[engine.state.song_index]

  for ci, channel in ipairs(engine.state.channels) do
    local pattern_index = tonumber(song.order[engine.state.frame_index][ci], 16)
    local row = song.patterns[pattern_index][engine.state.row_index]
    local clicking_attack = false
    local clicking_release = false

    --  Resolve note
    if row.note == "..." then
      -- pass

    elseif row.note == "---" then
      clicking_release = true

    else
      clicking_attack = true
      channel.note = engine.notes.index[row.note]
    end

    --  Resolve instrument
    if row.instrument ~= ".." then 
      channel.instrument = waves[tonumber(row.instrument, 16)]

      if channel.instrument == nil then
        channel.instrument = waves[0]
      end
    end

    --  Resolve volume
    if row.volume ~= "." then
      channel.volume = tonumber(row.volume, 16) * 8
    end

    --  Resolve command
    if row.command[1] ~= ".." then
      channel.command = { tonumber(row.command[1], 16), tonumber(row.command[2], 16) }
    end

    --  Generate channel buffer
    channel.buffer = {}
    channel.hz0 = engine.notes.hz[channel.note]

    local delta0 = TAU * channel.hz0 / SAMPLERATE

    for si = 1, engine.state.bufferlength do
      table.insert(channel.buffer, math.floor(channel.instrument(channel.phase0, channel.hz0) * channel.volume))
      channel.phase0 = (channel.phase0 + delta0) % TAU
    end

    --  Special Effects
    engine.effects.dc_offset(channel)

    if clicking_attack then
      engine.effects.clicking_attack(channel)
    end

    if clicking_release then
      engine.effects.clicking_release(channel)
      channel.note = 0
    end
  end

  --  Mix into main buffer
  local mainbuffer = {}

  for ri = 1, engine.state.bufferlength do
    mainbuffer[ri] = 0

    for ci, channel in ipairs(engine.state.channels) do
      mainbuffer[ri] = mainbuffer[ri] + channel.buffer[ri]
    end

    mainbuffer[ri] = math.floor(mainbuffer[ri] / song.settings.channels)
  end

  --  Playing main buffer
  while not speaker.playAudio(mainbuffer) do
    os.pullEvent("speaker_audio_empty")
  end

  engine._increment()
end

function engine._increment()
  engine.state.row_index = engine.state.row_index + 1

  if engine.state.row_index > engine.ztm.songs[engine.state.song_index].settings.rows then
    engine.state.row_index = 1
    engine.state.frame_index = engine.state.frame_index + 1
  end

  if engine.state.frame_index > #engine.ztm.songs[engine.state.song_index].order then
    engine.state.frame_index = 1
  end
end

function engine.select_song(index)
  if 0 < index and index <= #engine.ztm.songs then
    engine.state.song_index = index
    engine.new_state()

    local song = engine.ztm.songs[index]
    engine.state.bufferlength = (SAMPLERATE * 60) / (song.settings.tempo * 4)

    for i = 1, song.settings.channels do
      engine.state.channels[i] = {
        note = 0,
        instrument = waves[0],
        volume = 120,
        command = {"00", "00"},

        buffer = nil,
        hz0 = 0,
        phase0 = 0,
      }
    end
  end
end

--  Functions (ztmodule)

local file = nil
local file_line = ""
local file_at_line = 0

local ztm = {}
engine.ztm = ztm

engine.ZTM_VERSION = 1

function engine.ztm_new()
  engine.new_state()
  ztm.module = {
    name = "(name)",
    author = "(author)",
    copyright = "(copyright)",
  }
  ztm.songs = {}
end

engine.ztm_new()

function engine.ztm_open(filename)
  engine.ztm_new()
  file = fs.open(filename, "r")
  file_at_line = 0
  engine._ztm_formatcheck()
  engine._ztm_decode()
  file:close()
  engine.select_song(1)
end

function engine.ztm_save(filename)
  -- TODO
end

function engine._ztm_decode()
  local in_module = false
  local in_song = false
  local subsection_name = ""
  local song_index = 0
  local pattern_index = 0
  print()

  --  File reading
  while true do
    local token = engine._ztm_readtoken()
    --print(token.at_line.." | "..token.line)

    if token.type == "eof" then
      print("End of file")
      break

    elseif token.type == "section" then
      if token.key == "module" then
        print("Switch to [module] section")
        in_module = true
        in_song = false

      elseif token.key == "song" then
        print("Switch to [song "..token.value.."] section")
        in_module = false
        in_song = true
        song_index = tonumber(token.value)
        engine.ztm.songs[song_index] = {
          settings = {
            speed = 6,
            tempo = 128,
            rows = 0,
            channels = 0,
          },
          order = {},
          patterns = {},
        }

      elseif token.key == "settings" or token.key == "order" then
        print("Switch to ["..token.key.."] sub-section")
        subsection_name = token.key

      elseif token.key == "pattern" then
        print("Switch to [pattern "..token.value.."] sub-section")
        subsection_name = "pattern"
        pattern_index = tonumber(token.value)
        engine.ztm.songs[song_index].patterns[pattern_index] = {}

      else
        error("File error: Invalid section > "..token.at_line.." | "..token.line)
      end

    elseif token.type == "assign" then
      if in_module then
        print("Assign to module "..token.key..' value "'..token.value..'"')
        engine.ztm.module[token.key] = token.value

      elseif in_song and subsection_name == "settings" then
        print("Assign to song settings "..token.key..' value "'..token.value..'"')
        engine.ztm.songs[song_index].settings[token.key] = tonumber(token.value)

      else
        error("File error: Unexpected assign > "..token.at_line.." | "..token.line)
      end

    elseif token.type == "order_row" then
      if in_song and subsection_name == "order" then
        print("Push to song order row "..txt.tostring(token.value))
        table.insert(engine.ztm.songs[song_index].order, token.value)

      else
        error("File error: Unexpected order row > "..token.at_line.." | "..token.line)
      end

    elseif token.type == "note_row" then
      if in_song and subsection_name == "pattern" then
        print("Push to pattern row {"..token.note..", "..token.instrument..", "..token.volume.."}")
        table.insert(ztm.songs[song_index].patterns[pattern_index], {
          note = token.note,
          instrument = token.instrument,
          volume = token.volume,
          command = token.command,
        })

      else
        error("File error: Unexpected note row > "..token.at_line.." | "..token.line)
      end

    else
      error("File error: Invalid line "..token.at_line.." | "..token.line)
    end
  end

  --  Validate data
  for si, song in ipairs(engine.ztm.songs) do
    local rows = song.settings.rows
    local channels = song.settings.channels

    for oi, order in ipairs(song.order) do
      if #order ~= channels then
        error("File error: Song "..si..", order row "..oi.." has incorrect length "..#order..", "..channels.." required")
      end
    end

    for pi, pattern in ipairs(song.patterns) do
      if #pattern ~= rows then
        error("File error: Song "..si..", pattern "..pi.." has incorrect length "..#pattern..", "..rows.." required")
      end
    end
  end

  --  Add zero-patterns
  for si, song in ipairs(engine.ztm.songs) do
    local zeropattern = {}

    for ni = 1, song.settings.rows do
      table.insert(zeropattern, {note = "...", instrument = "..", volume = ".", command = {"..", ".."}})
    end

    song.patterns[0] = zeropattern
  end
end

function engine._ztm_encode()
  -- TODO
end

function engine._ztm_readline()
  local line = ""

  while line == "" do
    line = file.readLine()
    file_at_line = file_at_line + 1

    if line == nil then break end

    local pos = line:find("//")
    if pos then
      line = line:sub(1, pos - 1)
    end

    line = txt.trim(line)
  end

  file_line = line
  return line
end

-- Constructor
function Token(_type, value, key)
  local token = {
    type = _type,
    value = value,
    key = key,
    line = file_line,
    at_line = file_at_line,
  }

  function token:tostring()
    local str = "<"..token.type .."> {"
    local has_fields = false

    for k, v in pairs(token) do
      if k ~= "type" and type(v) ~= "function" then
        has_fields = true
        str = str .. txt.tostring(k) .. " = " .. txt.tostring(v) .. ", "
      end
    end

    if has_fields then
      str = str:sub(1, -3)
    end
    
    return str.."}"
  end

  return token
end

function engine._ztm_readtoken()
  local line = engine._ztm_readline()
  local token = Token("invalid", line) -- ВЫ ЧЕ ИНВАЛИДЫ, СОВСЕМ СДУРЕЛИ?? х) /кухня момент/
 
  --   Вот нету в регулярках луа "|", так реализую костылями х)
  local function multimatch(...)
    local patterns = {...}
    local str = table.remove(patterns, 1)

    for i, pattern in ipairs(patterns) do
      local mo = {str:match(pattern)}
      if mo[1] then return mo end
    end

    return {}
  end

  -- EOF
  if line == nil then
    return Token("eof")
  end

  -- Section
  local mo = { line:match("%[(%a+)%s?(%x*)%]") }
  if mo[1] then
    return Token("section", mo[2], string.lower(mo[1]))
  end

  -- Assign
  mo = { line:match("(%w+)%s?=%s?(.*)") }
  if mo[1] then
    return Token("assign", txt.trim(mo[2]), txt.trim(mo[1]))
  end
  
  -- Order Row
  mo = line:match("^>%s")

  if mo then
    token = Token("order_row", {})

    for index in line:gmatch("(%x%x)") do
      table.insert(token.value, index)
    end

    return token
  end

  -- Note Row
  mo = line:match("^-%s")

  if mo then
    local mo_row = {line:match("-%s(...)%s(..)%s(.)%s(....)")}

    if mo_row[1] then
      token = Token("note_row")

      --  Note
      local mo_note = multimatch(mo_row[1], "%.%.%.", "%-%-%-", "[A-G][#%-][1-9]")
      if mo_note[1] then
        token.note = mo_note[1]
      end

      --  Instrument
      local mo_inst = multimatch(mo_row[2], "%.%.", "%x%x")
      if mo_inst[1] then
        token.instrument = mo_inst[1]
      end

      --  Volume
      local mo_volume = multimatch(mo_row[3], "%.", "%x")
      if mo_volume[1] then
        token.volume = mo_volume[1]
      end

      --  Command
      local mo_command = multimatch(mo_row[4], "(%.%.)(%.%.)", "(%x%x)(%x%x)")
      if mo_command[1] then
        token.command = { mo_command[1], mo_command[2]}
      end

      --  End
      if not (token.note and token.instrument and token.volume and token.command) then
        return Token("invalid")
      end

      return token
    end
  end

  return token
end 

function engine._ztm_formatcheck()
  local firstline = engine._ztm_readline()

  local mo = firstline:match("ZefTrackerModule v(%d+)")
  if mo then 
    assert(tonumber(mo) == engine.ZTM_VERSION, "File error: Unsupported module version. Got v"..mo..", v"..engine.ZTM_VERSION.." expected")
  else
    error("File error: Not a ZTM format")
  end
end

--  Export

return engine
