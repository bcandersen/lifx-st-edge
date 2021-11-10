local lifx = require "lifx"

local FIELDS = require "fields"
local event_handlers = require "event_handlers"
local log = require "log"
local capabilities = require "st.capabilities"

local command_handlers = {}

function command_handlers.handle_switch_on(driver, device)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local resp, err = lifx_device:set_power(true, .5)
    if resp then
      event_handlers.handle_switch_event(driver, device, true, true)
    else
      log.warn("Error handling switch ON cmd: ", err)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

function command_handlers.handle_switch_off(driver, device)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local resp, err = lifx_device:set_power(false, .5)
    if resp then
      event_handlers.handle_switch_event(driver, device, false, true)
    else
      log.warn("Error handling switch ON cmd: ", err)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

function command_handlers.handle_set_level(driver, device, command)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local bri = math.floor((command.args.level * lifx.get_max_brightness()) / 100)

    local resp, err = lifx_device:set_color(nil, nil, bri, nil, .5)
    if resp then
      event_handlers.handle_level_event(driver, device, bri, true)
    else
      log.warn("Error handling set level cmd: ", err)
    end

    -- If the device is off and brightness > 0, turn on the device. Performed after setting bri in attempt
    -- to hide large brightness transition at power on.
    if
      bri > 0 and device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "off"
     then
      command_handlers.handle_switch_on(driver, device)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

function command_handlers.handle_set_hue(driver, device, command)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local hue = math.floor((command.args.color.hue * lifx.get_max_hue()) / 100.0 + 0.5)

    local resp, err = lifx_device:set_color(hue, nil, nil, nil, .5)
    if resp then
      event_handlers.handle_hue_event(driver, device, hue, true)
    else
      log.warn("Error handling set hue cmd: ", err)
    end

    -- If the device is off, turn on the device. Performed after setting hue in attempt
    -- to hide hue transition at power on.
    if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "off" then
      command_handlers.handle_switch_on(driver, device)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

function command_handlers.handle_set_saturation(driver, device, command)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local sat = math.floor((command.args.color.saturation * lifx.get_max_sat()) / 100.0 + 0.5)

    local resp, err = lifx_device:set_color(nil, sat, nil, nil, .5)
    if resp then
      event_handlers.handle_saturation_event(driver, device, sat, true)
    else
      log.warn("Error handling set saturation cmd: ", err)
    end

    -- If the device is off, turn on the device. Performed after setting saturation in attempt
    -- to hide saturation transition at power on.
    if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "off" then
      command_handlers.handle_switch_on(driver, device)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

function command_handlers.handle_set_color(driver, device, command)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local hue = math.floor((command.args.color.hue * lifx.get_max_hue()) / 100.0 + 0.5)
    local sat = math.floor((command.args.color.saturation * lifx.get_max_sat()) / 100.0 + 0.5)

    local resp, err = lifx_device:set_color(hue, sat, nil, nil, .5)
    if resp then
      event_handlers.handle_hue_event(driver, device, hue, true)
      event_handlers.handle_saturation_event(driver, device, sat, true)
    else
      log.warn("Error handling set color cmd: ", err)
    end

    -- If the device is off, turn on the device. Performed after setting color in attempt
    -- to hide color transition at power on.
    if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "off" then
      command_handlers.handle_switch_on(driver, device)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

function command_handlers.handle_set_color_temp(driver, device, command)
  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device then
    local kel = math.min(command.args.temperature, lifx.get_max_kelvin())

    -- Note: For color temp to be evident for a LIFX bulb, saturation must be set to 0
    local resp, err = lifx_device:set_color(nil, 0, nil, kel, .5)
    if resp then
      event_handlers.handle_colortemp_event(driver, device, kel, false)
    else
      log.warn("Error handling set color temp cmd: ", err)
    end

    -- If the device is off, turn on the device. Performed after setting color temp in attempt
    -- to hide color temp transition at power on.
    if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "off" then
      command_handlers.handle_switch_on(driver, device)
    end
  else
    log.warn("[" .. device.id .. "] No lifx_device found for device")
    device:set_field(FIELDS.ONLINE, false)
  end
end

return command_handlers
