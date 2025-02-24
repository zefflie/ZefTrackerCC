--  Module

local page = {}

--  Import

local draw = require "lib.draw"

--  Variables

page.name = "rows"

--  Functions

function page.draw()
  draw.writef("Rows", 3, 3)
end

function page.input(event, data)
  
end

function page.opened()

end

--  Export

return page
