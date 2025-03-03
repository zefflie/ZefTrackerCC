--[[
  Waves lib
]]

local waves = {}

--  Variables

local SAMPLERATE = 48000
local TAU = math.pi * 2

local noise_counter = 0
local noise_phase = 0

--  Functions

function waves.pulse(phase)
  return math.sin(phase) > 0.5 and 1 or -1
end

function waves.noise(phase, hz)
  if noise_counter > SAMPLERATE / hz then
    noise_counter = 0
    noise_phase = math.random() * 2 - 1
  end

  noise_counter = noise_counter + 1
  return noise_phase
end

function waves.square(phase)
  return math.sin(phase) > 0 and 1 or -1
end

function waves.saw(phase)
  return phase / TAU
end

waves.sine = math.sin

--  Export

return waves
