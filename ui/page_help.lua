--  Module

local page = {}

--  Import

local draw = require "lib.draw"

--  Variables

page.name = "help"
page.content = {}
page.position = 1

--  Functions

function page.draw()
  local height = draw.get_height()
  draw.set_color(colors.white, colors.black)

  for i = page.position, #page.content do
    draw.write(page.content[i], 1, i - page.position + 2)

    --  Display limit
    if i - page.position > height - 1 then
      break
    end
  end
end

function page.input(event, data)
  if event == "key" then
    local key = data[1]

    --  Scroll up
    if key == keys.up then
      page.scroll(-1)

    -- Scroll down
    elseif key == keys.down then
      page.scroll(1)

    end

  elseif event == "mouse_scroll" then
    page.scroll(data[1])
    
  end
end

function page.opened()
  page.content = {}

  local file = fs.open(fs.combine(shell.dir(), "help.txt"), "r")
  while true do
    line = file.readLine()

    if not line then 
      break
    end

    table.insert(page.content, line)
  end

  file.close()
end

function page.scroll(x)
  page.position = page.position + x

  if page.position < 1 then
    page.position = 1

  elseif page.position > #page.content then
    page.position = #page.content

  end
end

--  Export

return page
