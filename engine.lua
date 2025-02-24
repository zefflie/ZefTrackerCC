--[[
    Engine - Движок ZefTracker
]]

local engine = {}

--  [ Import ]

local notes = require "notes"
local modules = require "modules"
local generators = require "generators"
local effects = require "effects"

--  [ Constants ]
local SAMPLERATE = 44000
local ROWS_PER_BEAR = 4
local TICKS_PER_ROW = 6

--  [ Fields ]

engine.speaker = nil

engine.module = nil
engine.playing = false
engine.position = {
    order = 1,
    row = 1,
}

engine.channels = {}
engine.buffer_length = 0

--  [ Functions ]

function engine:init()
    self.speaker = peripheral.find("speaker")
end

function engine:loadmodule(path)
    self.module = modules:load(path)
    self.buffer_length = (SAMPLERATE * 60 * self.module.settings.speed) / (self.module.settings.tempo * ROWS_PER_BEAR * TICKS_PER_ROW)

    for channel_index = 1, self.module.settings.channels do
        self.channels[channel_index] = { buffer = nil, hz = 0, instrument = "01", volume = 127, phase = 0, past = { hz = 0, instrument = "01", volume = 127, phase = 0 } }
    end
end

function engine:step()
    for channel_index = 1, self.module.settings.channels do
        local channel = self.channels[channel_index]

        --  Save past
        channel.past = { hz = channel.hz, instrument = channel.instrument, volume = channel.volume, phase = channel.phase }

        --  Read row
        local pattern_index = tonumber(self.module.order[self.position.order][channel_index])
        local note_name, instrument_name, volume_name = table.unpack(self.module.patterns[pattern_index][self.position.row])

        if note_name ~= "..." then
            channel.hz = notes[note_name]
        end
        if channel.hz == nil then
            channel.hz = 0
        end

        if instrument_name ~= ".." then
            channel.instrument = instrument_name
        end

        if volume_name ~= ".." then
            channel.volume = tonumber(volume_name) * 127 / 100
        end

        --  Generate wave
        if channel.hz then
            self:play_instrument(channel)

            if note_name ~= "..." then
                effects:apply_clickfix_attack(channel)
            end
        else
            if note_name == "---" then
                self:apply_clickfix_release(self, channel)
            else
                channel.buffer = nil
            end
        end
    end
    
    --  Mix channels
    local buffer = self:mix_channels()

    --  Play
    if self.speaker ~= nil then
        self.position = self:nextrow(self.position)
        while not self.speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function engine:nextrow(pos)
    local position = { row = pos.row, order = pos.order }
    position.row = position.row + 1

    if position.row > self.module.settings.rows then
        position.row = 1
        position.order = position.order + 1

        if position.order > #self.module.order then
            position.order = 1
        end
    end

    return position
end

function engine:play_instrument(channel)
    if channel.instrument == "02" then
        generators:square(channel, self.buffer_length)
    elseif channel.instrument == "03" then
        generators:pulse(channel, self.buffer_length)
    elseif channel.instrument == "04" then
        generators:saw(channel, self.buffer_length)
    elseif channel.instrument == "05" then
        generators:noise(channel, self.buffer_length)
    else
        generators:sine(channel, self.buffer_length)
    end

    effects:dc_center(channel)
end

function engine:mix_channels()
    buffer = {}

    for i = 1, self.buffer_length do
        local sample = 0

        for j = 1, self.module.settings.channels do
            if self.channels[j].buffer then
                sample = sample + (self.channels[j].buffer[i] or 0) / self.module.settings.channels 
            end
        end

        buffer[i] = math.max(-127, math.min(127, math.floor(sample)))
    end

    return buffer
end

--  Export

return engine
