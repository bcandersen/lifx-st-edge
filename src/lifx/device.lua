--------------------------------------------------------------------------------------------
-- LIFX Device Module
--------------------------------------------------------------------------------------------
local LIFX = require "lifx.types"
local products_json = require "lifx.products"
local builder = require "lifx.builder"
local protocol = require "lifx.protocol"
local parser = require "lifx.parser"
local json = require "dkjson"

--- @module device
local device_module = {}

-- Device definition
--- @class Device
--- TODO
local Device = {}
Device.__index = Device

Device._init = function(cls, id, label, model, ipv4, port, color, color_temp_range)
  local device = {
    id = id,
    label = label,
    model = model,
    ipv4 = ipv4,
    port = port,
    color = color,
    color_temp_range = color_temp_range
  }

  setmetatable(device, cls)
  return device
end

function Device:get_model()
  return self.model
end

function Device:supports_color()
  return self.color
end

function Device:get_color_temp_range()
  return self.color_temp_range
end

function Device:get_state(timeout)
  local msg = builder.build_get_message(self.id)
  local resp_msg, ip_or_err, port = protocol.send_cmd(msg, self.ipv4, self.port, timeout)
  if resp_msg == nil then
    return nil, "failed to receive getState response: " .. ip_or_err
  else
    local target, msg_type_or_err, parsed_resp = parser.parse_message(resp_msg)
    if target == nil then
      return nil, "failed to parse getState response: " .. msg_type_or_err
    end

    if msg_type_or_err == LIFX.MSG_TYPE_STATE then
      return {
        label = parsed_resp.label,
        power = parsed_resp.power,
        hue = parsed_resp.color.hue,
        sat = parsed_resp.color.saturation,
        bri = parsed_resp.color.brightness,
        kel = parsed_resp.color.kelvin
      }
    else
      return nil, "received unexpected message type: " .. msg_type_or_err
    end
  end
end

function Device:set_color(hue, sat, bri, kel, timeout)
  local msg = builder.build_set_waveform_optional_message(self.id, hue, sat, bri, kel)
  local resp_msg, ip_or_err, port = protocol.send_cmd(msg, self.ipv4, self.port, timeout)
  if resp_msg == nil then
    return nil, "failed to receive setWaveformOptional response: " .. ip_or_err
  else
    local target, msg_type_or_err, parsed_resp = parser.parse_message(resp_msg)
    if target == nil then
      return nil, "failed to parse setWaveformOptional response: " .. msg_type_or_err
    end

    if msg_type_or_err == LIFX.MSG_TYPE_STATE then
      return {
        label = parsed_resp.label,
        power = parsed_resp.power,
        hue = parsed_resp.color.hue,
        sat = parsed_resp.color.saturation,
        bri = parsed_resp.color.brightness,
        kel = parsed_resp.color.kelvin
      }
    else
      return nil, "received unexpected message type: " .. msg_type_or_err
    end
  end
end

function Device:set_power(power, timeout)
  local msg = builder.build_set_power_message(self.id, power)
  local resp_msg, ip_or_err, port = protocol.send_cmd(msg, self.ipv4, self.port, timeout)
  if resp_msg == nil then
    return nil, "failed to receive setWaveformOptional response: " .. ip_or_err
  else
    local target, msg_type_or_err, parsed_resp = parser.parse_message(resp_msg)
    if target == nil then
      return nil, "failed to parse setWaveformOptional response: " .. msg_type_or_err
    end

    if msg_type_or_err == LIFX.MSG_TYPE_STATEPOWER then
      return parsed_resp
    else
      return nil, "received unexpected message type: " .. msg_type_or_err
    end
  end
end

setmetatable(
  Device,
  {
    __call = Device._init
  }
)

device_module.Device = Device

return device_module
