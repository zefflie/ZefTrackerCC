--[[
  Zeftracker engine
]]

--  Module

local engine = {}

--  Import

engine.notes = require "engine.notes"
engine.ztmodule = require "engine.ztmodule"

--  Variables

engine.r_play = false

--  Functions

function engine.mainloop()
  while true do
    sleep(0)
  end
end

--  Export

return engine
