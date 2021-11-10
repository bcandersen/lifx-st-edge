local LIFX = require "lifx.types"

local builder = {}

local function build_header(mac, msg_size, msg_type)
  local flags = 0
  flags = flags | (LIFX.PROTOCOL_NUMBER << LIFX.HEADER_FLAGS_PROTOCOL_BITS_SHIFT)
  flags = flags | (1 << LIFX.HEADER_FLAGS_ADDRESSABLE_BITS_SHIFT)

  local target = {}

  if mac == nil then -- No provided MAC will default to setting header to broadcast
    flags = flags | (1 << LIFX.HEADER_FLAGS_TAGGED_BITS_SHIFT)

    for i = 1, 8 do
      target[i] = 0
    end
  else
    target[1] = mac[1]
    target[2] = mac[2]
    target[3] = mac[3]
    target[4] = mac[4]
    target[5] = mac[5]
    target[6] = mac[6]
    target[7] = 0 -- byte 7 always 0
    target[8] = 0 -- byte 8 always 0
  end

  local requiredFlags = 0
  -- requiredFlags = requiredFlags | (1 << HEADER_ACK_REQUIRED_BITS_SHIFT) BA: Do not require ACK until we can properly handle it
  requiredFlags = requiredFlags | (1 << LIFX.HEADER_RES_REQUIRED_BITS_SHIFT)

  -- set a source value so target device sends a unicast response, not broadcast
  -- TODO: If we want to generate attribute change events on ACKS, generate a unique source id for every message to correlate request and response. Setting an arbitrary source id of 99 for now.
  return string.pack(
    "<I2I2I4I1I1I1I1I1I1I1I1I6I1xI8I2xx",
    msg_size,
    flags,
    99,
    target[1],
    target[2],
    target[3],
    target[4],
    target[5],
    target[6],
    target[7],
    target[8],
    0,
    requiredFlags,
    0,
    msg_type
  )
end

local function build_set_power_payload(on)
  local level = 0
  if on then
    level = LIFX.POWER_ON
  end

  return string.pack("<I2I4", level, LIFX.DEFAULT_TRANSITION_TIME)
end

local function build_set_waveform_optional_payload(hue, sat, bri, kel)
  return string.pack(
    "<I1I1I2I2I2I2I4fi2I1I1I1I1I1",
    0,
    0,
    hue or 0,
    sat or 0,
    bri or 0,
    kel or 0,
    LIFX.DEFAULT_TRANSITION_TIME,
    1,
    0,
    2,
    hue and 1 or 0,
    sat and 1 or 0,
    bri and 1 or 0,
    kel and 1 or 0
  )
end

function builder.build_get_message(mac)
  return build_header(mac, LIFX.HEADER_SIZE, LIFX.MSG_TYPE_GET)
end

function builder.build_getversion(mac)
  return build_header(mac, LIFX.HEADER_SIZE, LIFX.MSG_TYPE_GETVERSION)
end
function builder.build_getlabel(mac)
  return build_header(mac, LIFX.HEADER_SIZE, LIFX.MSG_TYPE_GETLABEL)
end

function builder.build_set_power_message(mac, power)
  local hdr = build_header(mac, LIFX.HEADER_SIZE + LIFX.SETPOWER_PAYLOAD_SIZE, LIFX.MSG_TYPE_SETPOWER)
  local payload = build_set_power_payload(power)

  return string.pack("c" .. LIFX.HEADER_SIZE .. "c" .. LIFX.SETPOWER_PAYLOAD_SIZE, hdr, payload)
end

function builder.build_set_waveform_optional_message(mac, hue, sat, bri, kel)
  local hdr =
    build_header(mac, LIFX.HEADER_SIZE + LIFX.SETWAVEFORMOPTIONAL_PAYLOAD_SIZE, LIFX.MSG_TYPE_SETWAVEFORMOPTIONAL)
  local payload = build_set_waveform_optional_payload(hue, sat, bri, kel)

  return string.pack("c" .. LIFX.HEADER_SIZE .. "c" .. LIFX.SETWAVEFORMOPTIONAL_PAYLOAD_SIZE, hdr, payload)
end

return builder
