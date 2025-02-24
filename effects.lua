
local effects = {}

function effects:apply_clickfix_attack(channel)
    for i = 1, 100 do
        channel.buffer[i] = math.floor(channel.buffer[i] * (i / 100))
    end
end

function effects:apply_clickfix_release(engine, channel)
    local past_channel = channel.past
    past_channel.buffer = {}
    engine:play_instrument(past_channel)

    for i = 1, 100 do
        channel.buffer[i] = math.floor(past_channel.buffer[i] * (i / 100))
    end
end

function effects:dc_center(channel)
    local sum = 0
    for i = 1, #channel.buffer do
        sum = sum + channel.buffer[i]
    end
    local average = sum / #channel.buffer

    for i = 1, #channel.buffer do
        channel.buffer[i] = channel.buffer[i] - average
    end
end

return effects
