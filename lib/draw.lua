--[[
  Draw library
]]

--  Module

local draw = {}

--  Functions

function draw.set_cursor(x, y)
  local past_x, past_y = term.getCursorPos()
  term.setCursorPos(x or past_x, y or past_y)
end

function draw.set_color(fg, bg)
  if fg then
    term.setTextColor(fg)
  end

  if bg then
    term.setBackgroundColor(bg)
  end
end

function draw.write(text, x, y)
  draw.set_cursor(x, y)
  term.write(text)
end

--[[
  colors.white      1    	0x1	    0		#F0F0F0	240, 240, 240	
  colors.orange	    2    	0x2    	1		#F2B233	242, 178, 51	
  colors.magenta	  4    	0x4	    2		#E57FD8	229, 127, 216	
  colors.lightBlue	8	    0x8	    3		#99B2F2	153, 178, 242	
  colors.yellow	    16  	0x10	  4		#DEDE6C	222, 222, 108	
  colors.lime	      32  	0x20	  5		#7FCC19	127, 204, 25	
  colors.pink	      64  	0x40	  6		#F2B2CC	242, 178, 204	
  colors.gray	      128  	0x80	  7		#4C4C4C	76,  76,  76	
  colors.lightGray	256	  0x100  	8		#999999	153, 153, 153	
  colors.cyan	      512	  0x200	  9		#4C99B2	76,  153, 178	
  colors.purple   	1024	0x400	  a		#B266E5	178, 102, 229	
  colors.blue     	2048	0x800  	b		#3366CC	51,  102, 204	
  colors.brown    	4096	0x1000	c		#7F664C	127, 102, 76	
  colors.green    	8192	0x2000	d		#57A64E	87,  166, 78	
  colors.red	      16384	0x4000	e		#CC4C4C	204, 76,  76	
  colors.black	    32768	0x8000	f		#111111	17,  17,  17
]]

function draw.writef(text, x, y, align)
  text = tostring(text)

  --  Aligning

  local len = #text:gsub("\027..", "")

  if align == "center" then
    x = x - len / 2

  elseif align == "right" then
    x = x - len
  end

  --  Processing

  draw.set_cursor(x, y)
  local flag_esc = false
  local colors = {
    colors.toBlit(term.getTextColor()),
    colors.toBlit(term.getBackgroundColor()),
  }
  local newcolors = {}

  for i = 1, #text do
    local char = text:sub(i, i)

    if char == "\027" then
      flag_esc = true

    elseif flag_esc and #newcolors == 0 then
      if char == "x" then
        char = colors[1]
      end

      table.insert(newcolors, char)

    elseif flag_esc and #newcolors == 1 then
      if char == "x" then
        char = colors[2]
      end

      table.insert(newcolors, char)

      colors = newcolors
      newcolors = {}

      flag_esc = false

    else
      term.blit(char, colors[1], colors[2])
    end
  end
end

function draw.clear(fg, bg)
  draw.set_color(fg, bg)
  term.clear()
end

function draw.clear_line(y, fg, bg)
  draw.set_cursor(nil, y)
  draw.set_color(fg, bg)
  term.clearLine()
end

function draw.clear_range(y1, y2, fg, bg)
  draw.set_color(fg, bg)
  for i = y1, y2 do
    draw.set_cursor(nil, i)
    term.clearLine()
  end
end

function draw.get_width()
  local w, _ = term.getSize()
  return w
end

function draw.get_height()
  local _, h = term.getSize()
  return h
end

--  Export

return draw