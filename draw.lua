--[[
    Advanced TUI output
]]

local w, h = term.getSize()

local draw = {
    width = w,
    height = h,
}

function draw:clear(fg, bg)
    self.set_color(fg, bg)
    term.clear()
end

function draw:clear_line(fg, bg)
    self.set_color(fg, bg)
    term.clearLine()
end

function draw:set_color(fg, bg)
    if fg then term.setTextColor(fg) end
    if bg then term.setBackgroundColor(bg) end
end

function draw:set_cursor(x, y)
    local past_x, past_y = term.getCursorPos()
    if x == nil then x = past_x end
    if y == nil then y = past_y end
    term.setCursorPos(x, y)
end

function draw:write(text)
    term.write(text)
end

function draw:text(x, y, text)
    term.setCursorPos(x, y)
    term.write(text)
end

function draw:text_centered(x, y, text)
    x = x - #text / 2
    if x < 1 then x = 1 end
    term.setCursorPos(x, y)
    term.write(text)
end

return draw
