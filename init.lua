--[[
  ZefTracker - Music tracker with real 
  multi-channel sound generation.
  Inspired by FamiTracker.

  Repo: https://github.com/savehope/zeftracker

  MIT (c) 2025 Savehope.
]]

--  Module

zeftracker = {}

--  Variables

zeftracker.version = "0.6 b8"
zeftracker.engine = require "engine"
zeftracker.ui = require "ui"

--  Main

--  Parallel startup to split the event queue.
parallel.waitForAny(
  zeftracker.ui.mainloop, 
  zeftracker.engine.mainloop
)
