local LIFX = require "lifx.types"

local parser = {}

local function parse_header(data)
  local size, flags, source, req_flags, sequence, type
  local target = {}

  -- target field has defined length of 8 bytes in header, but only the first 6 bytes are used (MAC addr size), ignore last 2 bytes with padding
  size,
    flags,
    source,
    target[1],
    target[2],
    target[3],
    target[4],
    target[5],
    target[6],
    req_flags,
    sequence,
    type = string.unpack("<I2I2I4I1I1I1I1I1I1xxxxxxxxI1I1xxxxxxxxI2xx", data)

  local proto = (flags >> LIFX.HEADER_FLAGS_PROTOCOL_BITS_SHIFT) & ((1 << LIFX.HEADER_FLAGS_PROTOCOL_BITS) - 1)
  local addressable =
    (flags >> LIFX.HEADER_FLAGS_ADDRESSABLE_BITS_SHIFT) & ((1 << LIFX.HEADER_FLAGS_ADDRESSABLE_BITS) - 1)
  local tagged = (flags >> LIFX.HEADER_FLAGS_TAGGED_BITS_SHIFT) & ((1 << LIFX.HEADER_FLAGS_TAGGED_BITS) - 1)
  local origin = (flags >> LIFX.HEADER_FLAGS_ORIGIN_BITS_SHIFT) & ((1 << LIFX.HEADER_FLAGS_ORIGIN_BITS) - 1)

  local ack_required = (req_flags >> LIFX.HEADER_ACK_REQUIRED_BITS_SHIFT) & ((1 << LIFX.HEADER_ACK_REQUIRED_BITS) - 1)
  local res_required =
    (req_flags >> LIFX.HEADER_RES_REQUIRED_BITS_SHIFT) & ((1 << LIFX.HEADER_RES_REQUIRED_BITS_SHIFT) - 1)

  return {
    frame = {
      size = size,
      protocol = proto,
      addressable = addressable,
      tagged = tagged,
      origin = origin,
      source = source
    },
    frame_address = {
      target = target,
      res_required = res_required,
      ack_required = ack_required,
      sequence = sequence
    },
    protocol_header = {type = type}
  }
end

local function parse_state_payload(data)
  local hue, sat, bri, kel, power, label = string.unpack("<I2I2I2I2xxI2c32xxxxxxxx", data, LIFX.HEADER_SIZE + 1)

  -- Convert power value to true/false for convinence
  if power == LIFX.POWER_ON then
    power = true
  else
    power = false
  end

  return {
    color = {hue = hue, saturation = sat, brightness = bri, kelvin = kel},
    power = power,
    label = label
  }
end

local function parse_state_version_payload(data)
  local vendor, product, version = string.unpack("<I4I4I4", data, LIFX.HEADER_SIZE + 1)

  return {vendor = vendor, product = product, version = version}
end

local function parse_state_label_payload(data)
  local label = string.unpack("<c32", data, LIFX.HEADER_SIZE + 1)

  return {label = label}
end

local function parse_state_power_payload(data)
  local power = string.unpack("<I2", data, LIFX.HEADER_SIZE + 1)

  -- Convert power value to true/false for convinence
  if power == LIFX.POWER_ON then
    power = true
  else
    power = false
  end

  return {power = power}
end

function parser.parse_message(msg)
  local header = parse_header(msg)

  if header.protocol_header.type == LIFX.MSG_TYPE_STATE then
    local state = parse_state_payload(msg)

    return header.frame_address.target, header.protocol_header.type, state
  elseif header.protocol_header.type == LIFX.MSG_TYPE_STATEPOWER then
    local power = parse_state_power_payload(msg)

    if power == nil then
      return nil, "error parsing payload for msg type: " .. header.protocol_header.type
    end

    return header.frame_address.target, header.protocol_header.type, power
  elseif header.protocol_header.type == LIFX.MSG_TYPE_STATEVERSION then
    local version_info = parse_state_version_payload(msg)

    if version_info == nil then
      return nil, "error parsing payload for msg type: " .. header.protocol_header.type
    end

    return header.frame_address.target, header.protocol_header.type, version_info
  elseif header.protocol_header.type == LIFX.MSG_TYPE_STATELABEL then
    local label = parse_state_label_payload(msg)
    if label == nil then
      return nil, "error parsing payload for msg type: " .. header.protocol_header.type
    end

    return header.frame_address.target, header.protocol_header.type, label
  else
    return nil, "received unhandled message type: " .. header.protocol_header.type
  end
end

return parser
