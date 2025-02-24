--  Module

local page = {}

--  Import

local draw = require "lib.draw"
local txt = require "lib.txt"

--  Variables

local engine = zeftracker.engine
local ztmodule = engine.ztmodule

page.name = "edit"

--  Functions

function page.draw()
  draw.set_color(colors.white, colors.black)
  draw.write("Order", 2, 2)
  draw.write("Module info", 19, 2)
  draw.write("Song settings", 2, 10)
  draw.write("Player", 19, 10)
  draw.set_color(colors.lightGray, colors.black)
  draw.write("Name      "..ztmodule.module.name, 19, 3)
  draw.write("Author    "..ztmodule.module.author, 19, 4)
  draw.write("Copyright "..ztmodule.module.copyright, 19, 5)
  draw.write("State "..(engine.r_play and "Playing" or "Editing"), 19, 11)
  draw.write("Song  "..ztmodule.index_song, 19, 12)
  draw.write("Order "..ztmodule.index_order, 19, 13)
  draw.write("Row   "..ztmodule.index_row, 19, 14)

  --  Song data
  if #ztmodule.songs == 0 then
    return
  end

  local song = ztmodule.songs[1]

  draw.write("Speed    "..song.settings.speed, 2, 11)
  draw.write("Tempo    "..song.settings.tempo, 2, 12)
  draw.write("Rows     "..song.settings.rows, 2, 13)
  draw.write("Channels "..song.settings.channels, 2, 14)

  --  Order data
  if #song.order == 0 then
    return
  end
  for i, value in ipairs(song.order) do
    draw.set_color(i == ztmodule.index_order and colors.magenta or colors.white, colors.gray)
    draw.write(txt.leftfill(i, 2, "0").." | "..table.concat(value, " "), 2, 2 + i)
  end
end

function page.input(event, data)
  if event == "key" then
    if data[1] == keys.space then
      engine.r_play = not engine.r_play
    end
  end
end

function page.opened()

end

--  Export

return page
