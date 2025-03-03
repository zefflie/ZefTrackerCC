--  Module

local page = {}

--  Import

local draw = require "lib.draw"
local txt = require "lib.txt"

--  Variables

local engine = zeftracker.engine

page.name = "edit"

--  Functions

function draw_moduleinfo(x, y)
  draw.set_color(colors.white, colors.black)
  draw.write("Module info", x, y)

  if engine.ztm.module then
    draw.set_color(colors.lightGray)
    draw.write("Name      "..engine.ztm.module.name, x, y + 1)
    draw.write("Author    "..engine.ztm.module.author, x, y + 2)
    draw.write("Copyright "..engine.ztm.module.copyright, x, y + 3)
  end
end

function draw_songinfo(x, y)
  draw.set_color(colors.white, colors.black)
  draw.write("Song info", x, y)

  draw.set_color(colors.lightGray)
  if #engine.ztm.songs > 0 then
    local song = engine.ztm.songs[engine.state.song_index]
    draw.write("Speed    "..song.settings.speed, x, y + 1)
    draw.write("Tempo    "..song.settings.tempo, x, y + 2)
    draw.write("Rows     "..song.settings.rows, x, y + 3)
    draw.write("Channels "..song.settings.channels, x, y + 4)

  else
    draw.write("(no song)", x, y + 1)
  end
end

function draw_frameorder(x, y)
  draw.set_color(colors.white, colors.black)
  draw.write("Frame order", x, y)

  if #engine.ztm.songs > 0 then
    local song = engine.ztm.songs[engine.state.song_index]

    for i, row in ipairs(song.order) do
      if i + 1 >= engine.state.frame_index then
        draw.set_color(i == engine.state.frame_index and colors.magenta or colors.gray)
        draw.write(txt.leftfill(i, 2, "0").." | "..table.concat(row, " "), x, y + i)
      end

      if i > 5 then break end
    end

  else
    draw.set_color(colors.lightGray)
    draw.write("(no song)", x, y + 1)
  end
end

function draw_state(x, y)
  draw.set_color(colors.white, colors.black)
  draw.write("Engine state", x, y)
  draw.set_color(colors.lightGray)
  draw.write("Mode     "..(engine.state.play and "Play" or "Edit"), x, y + 1)
  draw.write("At song  "..engine.state.song_index, x, y + 2)
  draw.write("At frame "..engine.state.frame_index, x, y + 3)
  draw.write("At row   "..engine.state.row_index, x, y + 4)
end

function page.draw()
  draw_moduleinfo(2, 3)
  draw_songinfo(30, 3)
  draw_frameorder(2, 9)
  draw_state(30, 9)

  if #engine.ztm.songs > 0 then
    local song = engine.ztm.songs[engine.state.song_index]
    draw.set_color(colors.magenta, colors.black)

    for ri = 1, 4 do
      draw.set_color(ri == 1 and colors.white or colors.lightGray, colors.black)
      draw.set_cursor(2, 14 + ri)

      local row_i = engine.state.row_index + ri
      local frame_i = engine.state.frame_index

      if row_i > song.settings.rows then
        row_i = row_i - song.settings.rows
        frame_i = frame_i + 1
      end

      if frame_i > #song.order then
        frame_i = 1
      end

      for ci = 1, #engine.state.channels do
        local pattern_index = tonumber(song.order[frame_i][ci], 16)
        local row = song.patterns[pattern_index][row_i]
        draw.write(row.note.." "..row.instrument.." "..row.volume.." | ")
      end
    end
  end
end

function page.input(event, data)
  if event == "key" then
    if data[1] == keys.space then
      if #engine.ztm.songs > 0 then
        engine.state.play = not engine.state.play
      end

    elseif data[1] == keys.up then
      engine.state.frame_index = engine.state.frame_index - 1

    elseif data[1] == keys.down then
      engine.state.frame_index = engine.state.frame_index + 1
    
    end
  end
end

function page.opened()

end

--  Export

return page
