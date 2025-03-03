--[[
  Effects lib
]]

local effects = {}

--  Functions

function effects.clicking_attack(channel)
  for i = 1, 100 do
      channel.buffer[i] = math.floor(channel.buffer[i] * (i / 100))
  end
end

function effects.clicking_release(channel)
  for i = 1, #channel.buffer do
    if i <= 100 then
      channel.buffer[i] = math.floor(channel.buffer[i] * ((100 - i) / 100))

    else
      channel.buffer[i] = 0

    end
  end
end

function effects.dc_offset(channel)
  local sum = 0

  for i = 1, #channel.buffer do
      sum = sum + channel.buffer[i]
  end

  local average = sum / #channel.buffer

  for i = 1, #channel.buffer do
      channel.buffer[i] = channel.buffer[i] - average
  end
end

--  Export

return effects
