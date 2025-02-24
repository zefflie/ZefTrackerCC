
local SAMPLERATE = 44000
local AMPLITUDE = 127
local PI = math.pi
local TAU = PI * 2

generators = {}

function generators:sine(channel, length)
    channel.buffer = {}
    local delta = TAU * channel.hz / SAMPLERATE
    for i = 1, length do
        channel.buffer[i] = math.floor(math.sin(channel.phase) * channel.volume)
        channel.phase = (channel.phase + delta) % TAU
    end
end

function generators:square(channel, length)
    channel.buffer = {}
    local delta = TAU * channel.hz / SAMPLERATE
    for i = 1, length do
        channel.buffer[i] = math.sin(channel.phase) > 0 and channel.volume or -channel.volume
        channel.phase = (channel.phase + delta) % TAU
    end
end

function generators:pulse(channel, length)
    channel.buffer = {}
    local delta = TAU * channel.hz / SAMPLERATE
    for i = 1, length do
        channel.buffer[i] = math.sin(channel.phase) > 0.5 and channel.volume or -channel.volume
        channel.phase = (channel.phase + delta) % TAU
    end
end

function generators:saw(channel, length)
    channel.buffer = {}
    local delta = TAU * channel.hz / SAMPLERATE
    for i = 1, length do
        channel.buffer[i] = math.floor(channel.phase / TAU * channel.volume)
        channel.phase = (channel.phase + delta) % TAU
    end
end

function generators:noise(channel, length)
    channel.buffer = {}
    local step = SAMPLERATE / channel.hz  -- Частота обновления шума
    local counter = 0

    for i = 1, length do
        if counter >= step then
            channel.phase = math.random() * 2 - 1  -- Новое случайное значение
            counter = 0
        end
        channel.buffer[i] = math.floor(channel.phase * channel.volume)
        counter = counter + 1
    end
end

return generators
