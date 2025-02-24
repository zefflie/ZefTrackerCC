--[[
  Zeftracker UI
]]

--  Module

local ui = {}

--  Import

local draw = require "lib.draw"

--  Variables

ui.flag_mainloop = false

ui.pages = {
  require "ui.page_file",
  require "ui.page_edit",
  require "ui.page_rows",
  require "ui.page_help",
}

ui.page_index = 1

--  Functions

function ui.mainloop()
  ui.set_tab(1)
  ui.flag_mainloop = true
  
  while ui.flag_mainloop do
    local page = ui.pages[ui.page_index]

    --  Drawing

    draw.clear(colors.white, colors.black)

    draw.clear_line(1, colors.magenta, colors.gray)
    draw.writef("\02727 ZefTracker v"..zeftracker.version.."\02787 = ", 1)

    for i, v in ipairs(ui.pages) do
      local col = i == ui.page_index and "0" or "8"
      draw.writef("\027"..col.."7 "..v.name.." ")
    end 

    page.draw()
    draw.set_cursor(term.getSize())

    --  Input processing

    local data = { os.pullEvent() }
    local event = table.remove(data, 1)

    if event == "key" then
      local key = data[1]

      --  Exit program
      if key == keys.f4 then
        ui.flag_mainloop = false

      --  First (Home) tab
      elseif key == keys.f5 then
        ui.set_tab(1)

      --  Second (Edit) tab
      elseif key == keys.f6 then
        ui.set_tab(2)

      --  Third (Rows) tab
      elseif key == keys.f7 then
        ui.set_tab(3)

      --  Fourth tab
      elseif key == keys.f8 then
        ui.set_tab(4)

      --  Next tab
      elseif key == keys.tab then
        ui.set_tab(ui.page_index + 1)

      end

    elseif event == "mouse_click" then
      local button, x, y = table.unpack(data)
      local shift = 19

      if y == 1 then
        for i, v in ipairs(ui.pages) do
          local length = #v.name + 2

          if shift < x and x <= shift + length then
            ui.set_tab(i)
          end

          shift = shift + length
        end 
      end
    end

    page.input(event, data)
  end

end

function ui.set_tab(index)
  ui.page_index = index

  if ui.page_index < 1 then
    ui.page_index = #ui.pages
  end

  if ui.page_index > #ui.pages then
    ui.page_index = 1
  end

  ui.pages[ui.page_index].opened()
end

--  Export

return ui
