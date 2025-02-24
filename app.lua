--[[
    App - Приложение ZefTracker
]]

local app = {}

--  [ Import ]

local engine = require "engine"
local draw = require "draw"
local asf = require "asf"

local varg = ...

--  [ Functions ]

function app:main()
    if not varg then
        print("Please pass file argument.")
        return
    end

    varg = shell.dir() .. "/" .. varg
    print(varg)

    if not fs.exists(varg) then
        print("This file not exist")
        return
    end

    engine:init()
    engine:loadmodule(varg)
    self:ui_init()
    self:main_loop()
end

function app:main_loop()
    while true do
        self.ui_step()
        engine:step()
    end
end

function app:ui_init()
    draw:clear()

    draw:set_color(colors.lightGray, colors.gray)
    draw:text(1, 1, asf:clone("=", draw.width))
    draw:set_color(colors.white)
    draw:text_centered(draw.width / 2, 1, " ZefTracker v0.6 ")

    draw:set_color(colors.white, colors.black)
    draw:text(3, 3, "Speed " .. tostring(engine.module.settings.speed))
    draw:text(3, 4, "Tempo " .. tostring(engine.module.settings.tempo))
    draw:text(3, 5, "Rows  " .. tostring(engine.module.settings.rows))
    draw:text(14, 3, engine.module.info.author .. " - " .. engine.module.info.name)
    draw:text(14, 4, "Copyright: " .. engine.module.info.copyright)
    draw:text(14, 5, engine.module.info.comment)

    draw:set_color(colors.white, colors.gray)
    draw:set_cursor(3, 8)
    draw:clear_line()
    draw:write("Row | ")
    for channel_index = 1, engine.module.settings.channels do
        draw:write("Ch. " .. tostring(channel_index) .. "  | ")
    end
end

function app:ui_step()
    draw:set_color(colors.magenta, colors.black)
    draw:set_cursor(1, 6)
    draw:clear_line()
    draw:text(3, 6, "Pos " .. engine.position.order .. ":" .. engine.position.row)
    draw:text(14, 6, "Patterns " .. asf:from_array(engine.module.order[engine.position.order]))

    local str_names = {
        ["01"] = "Sine  ",
        ["02"] = "Square",
        ["03"] = "Pulse ",
        ["04"] = "Saw   ",
        ["05"] = "Noise ",
    }
    draw:set_color(colors.gray, colors.black)
    draw:set_cursor(7, 7)
    draw:write("| ")
    for channel_index = 1, engine.module.settings.channels do
        draw:write((str_names[engine.channels[channel_index].instrument] or "Sine  ") .. " | ")
    end

    local pos = engine.position
    for i = 1, 11 do
        if i == 1 then
            draw:set_color(colors.magenta, colors.black)
        elseif pos.row < engine.position.row then
            draw:set_color(colors.lightGray, colors.black)
        else
            draw:set_color(colors.white, colors.black)
        end

        draw:set_cursor(3, 8 + i)
        draw:write(asf:fill_right(tostring(pos.row), 3) .. " | ")
        for channel_index = 1, engine.module.settings.channels do
            local pattern_index = tonumber(engine.module.order[pos.order][channel_index])
            local note_name, instrument_name, volume_name = table.unpack(engine.module.patterns[pattern_index][pos.row])
            draw:write(note_name .. " " .. instrument_name .. " | ")
        end
        pos = engine:nextrow(pos)
    end
end

--  [ Main ]

app:main()

--[[
function too_string(value)
    if type(value) == "table" then
        local str = "{"

        for k, v in pairs(value) do
            str = str .. "[" .. too_string(k) .. "] = " .. too_string(v) .. ","
        end

        return str .. "}"
    elseif type(value) == "string" then
        return '"' .. value .. '"'
    else
        return tostring(value)
    end
end
]]
