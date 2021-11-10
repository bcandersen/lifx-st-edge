--------------------------------------------------------------------------------
-- LIFX Library Driver
--------------------------------------------------------------------------------
local LIFX = require "lifx.types"

local builder = require "lifx.builder"
local parser = require "lifx.parser"
local protocol = require "lifx.protocol"
local discovery = require "lifx.discovery"

local m = {}

m.builder = builder
m.parser = parser
m.protocol = protocol
m.discovery = discovery

function m.get_max_hue()
  return LIFX.MAX_HUE
end

function m.get_max_sat()
  return LIFX.MAX_SAT
end

function m.get_max_brightness()
  return LIFX.MAX_BRIGHTNESS
end

function m.get_max_kelvin()
  return LIFX.MAX_KELVIN
end

function m.get_default_port()
  return LIFX.DEFAULT_PORT
end

return m
