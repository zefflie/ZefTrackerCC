--  Module

local page = {}

--  Import

local draw = require "lib.draw"
local txt = require "lib.txt"

--  Variables

local FILESIZES = {" B", "KB", "MB"}

page.name = "file"

page.path = "/"..shell.dir()
page.files = { { name = "..", flags = nil } }
page.index = 1

--  Functions

function page.draw()
  local width = draw.get_width()
  draw.set_color(colors.white, colors.black)
  draw.write(page.path, 3, 2)
  draw.clear_line(3, colors.lightGray, colors.gray)
  draw.write("Name", 3)
  draw.writef("Mode Size   Modified        ", width - 1, nil, "right")

  for i, v in ipairs(page.files) do
    draw.set_color(i == page.index and colors.magenta or colors.white, colors.black)
    draw.write(v.name, 3, 3 + i)

    if v.flags then
      --  Size
      local size = "       "

      if not v.flags.isDir then
        size = v.flags.size
        local scale = 1

        while size > 1024 do
          size = math.ceil(size / 1024)
          scale = scale + 1
        end

        size = txt.leftfill(size .. FILESIZES[scale], 7)
      end

      --  Date

      local date = " " .. os.date("%F %H:%M", v.flags.modified / 1000)


      -- Write
      draw.writef( " r" .. (v.flags.isReadOnly and "-" or "w") .. (v.flags.isDir and "d" or "-") .. size .. date, width - 1, nil, "right")
    end
  end
end

function page.input(event, data)
  local file = page.files[page.index]

  if event == "key" then
    local key = data[1]

    --  Select up
    if key == keys.up then
      page.index = page.index - 1

      if page.index <= 0 then
        page.index = 1
      end

    --  Select down
    elseif key == keys.down then
      page.index = page.index + 1

      if page.index > #page.files then
        page.index = #page.files
      end

    --  Open parent directore
    elseif key == keys.backspace then
      page.back()

    --  Open selected file/directory
    elseif key == keys.enter then
      if file.name == ".." then
        
        page.back()

      else
        if file.flags.isDir then
          page.index = 1
          page.path = "/" .. fs.combine(page.path, file.name)
          page.fetch()

        else
          zeftracker.engine.ztmodule.open(fs.combine(page.path, file.name))
          zeftracker.ui.set_tab(2)
        end
      end
    end
  end
end

function page.opened()
  page.fetch()
end

function page.fetch()
  page.files = { { name = "..", flags = nil } }

  for i, v in ipairs(fs.list(page.path)) do
    table.insert(page.files, {
      name = v,
      flags = fs.attributes(fs.combine(page.path, v)),
    })
  end
end

function page.back()
  if page.path == "/" then
    return
  end

  page.index = 1
  page.path = fs.getDir(page.path) .. "/"
  page.fetch()
end

--  Export

return page
