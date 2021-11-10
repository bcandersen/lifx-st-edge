local capabilities = require "st.capabilities"
local lifx = require "lifx"

local event_handlers = {}

function event_handlers.handle_switch_event(driver, device, power, force)
  local cached_switch = device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "on"

  if force or cached_switch ~= power then
    if power then
      device:emit_event(capabilities.switch.switch.on())
    else
      device:emit_event(capabilities.switch.switch.off())
    end
  end
end

function event_handlers.handle_level_event(driver, device, level, force)
  if not device:supports_capability_by_id("switchLevel") then
    return
  end
  local level_calc = math.floor((level / lifx.get_max_brightness()) * 100 + 0.5)

  if force or device:get_latest_state("main", capabilities.switchLevel.ID, capabilities.switchLevel.level.NAME) ~= level_calc then
    device:emit_event(capabilities.switchLevel.level(level_calc))
  end
end

function event_handlers.handle_colortemp_event(driver, device, kel, force)
  if not device:supports_capability_by_id("colorTemperature") then
    return
  end

  local cached_kel = device:get_latest_state("main", capabilities.colorTemperature.ID, capabilities.colorTemperature.colorTemperature.NAME)

  -- ignore 0 ct values as they are not valid in ST
  if (force or cached_kel ~= kel) and kel ~= 0 then
    device:emit_event(capabilities.colorTemperature.colorTemperature(kel))
  end
end

function event_handlers.handle_hue_event(driver, device, hue, force)
  if not device:supports_capability_by_id("colorControl") then
    return
  end

  hue = math.max(1, math.floor((hue / lifx.get_max_hue()) * 100.0 + 0.5))

  if force or device:get_latest_state("main", capabilities.colorControl.ID, capabilities.colorControl.hue.NAME) ~= hue then
    device:emit_event(capabilities.colorControl.hue(hue))
  end
end

function event_handlers.handle_saturation_event(driver, device, sat, force)
  if not device:supports_capability_by_id("colorControl") then
    return
  end

  sat = math.max(1, math.floor((sat / lifx.get_max_sat()) * 100.0 + 0.5))
  if force or device:get_latest_state("main", capabilities.colorControl.ID, capabilities.colorControl.saturation.NAME) ~= sat then
    device:emit_event(capabilities.colorControl.saturation(sat))
  end
end

return event_handlers
