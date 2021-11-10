local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local command_handlers = require "command_handlers"
local event_handlers = require "event_handlers"
local socket = require "cosock".socket
local lifx = require "lifx"
local log = require "log"

local FIELDS = require "fields"

local function dni_str_to_byte_array(dni)
  local dni_bytes = {}
  local dni_index = 1
  for j = 1, 6, 1 do
    dni_bytes[j] = tonumber(string.sub(dni, dni_index, dni_index + 1), 16)
    dni_index = dni_index + 2
  end

  return dni_bytes
end

local function dni_byte_array_to_str(dni_bytes)
  return string.format(string.rep("%02X", #dni_bytes), table.unpack(dni_bytes))
end

local function start_poll(device)
  local poll_timer = device:get_field(FIELDS.POLL_TIMER)
  if poll_timer ~= nil then
    log.warn("Poll timer for " .. device.label .. " already started. Skipping...")
    return
  end

  device:set_field(FIELDS.POLL_TIMEOUTS, 0)

  local poll_device = function()
    local online = device:get_field(FIELDS.ONLINE)

    log.debug("Polling device: " .. device.label)

    local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
    if lifx_device then
      local response, err = lifx_device:get_state(.5)
      if response then
        device:set_field(FIELDS.POLL_TIMEOUTS, 0)
        if not online then
          log.info("[" .. device.id .. "] Marking LIFX device online: " .. device.label)
          device:set_field(FIELDS.ONLINE, true)
          device:online()
        end
        event_handlers.handle_switch_event(driver, device, response.power, false)
        event_handlers.handle_level_event(driver, device, response.bri, false)
        event_handlers.handle_colortemp_event(driver, device, response.kel, false)
        event_handlers.handle_hue_event(driver, device, response.hue, false)
        event_handlers.handle_saturation_event(driver, device, response.sat, false)
      else
        log.debug('Error polling device "' .. device.label .. ": " .. err)
        local poll_timeouts = device:get_field(FIELDS.POLL_TIMEOUTS)
        if poll_timeouts >= 5 then
          if online then
            log.info("[" .. device.id .. "] Marking LIFX device offline: " .. device.label)
            device:set_field(FIELDS.ONLINE, false)
            device:offline()
          end
        else
          device:set_field(FIELDS.POLL_TIMEOUTS, poll_timeouts + 1)
        end
      end
    else
      log.debug("[" .. device.id .. "] No lifx_device found for device")
      device:set_field(FIELDS.ONLINE, false)
    end
  end

  poll_timer = device.thread:call_on_schedule(2, poll_device)
  device:set_field(FIELDS.POLL_TIMER, poll_timer)
end

local function discover(driver, discovery_active)
  lifx.discovery.discover(
    5,
    function(lifx_device)
      local dni = dni_byte_array_to_str(lifx_device.id)

      log.debug("discovered device: " .. lifx_device.label .. " (" .. dni .. ")")
      local device = driver.device_dni_map[dni]
      if device then
        -- TODO update vendorName from label
        device:set_field(FIELDS.LIFX_DEVICE, lifx_device)
      elseif discovery_active then
        log.info(
          "Discovered new LIFX device - Name: " ..
            lifx_device.label ..
              "DNI: " ..
                dni .. " IP: " .. lifx_device.ipv4 .. ":" .. lifx_device.port .. " Model: " .. lifx_device.model
        )

        local profile_ref = "lifx.dimmer.v1"
        local ct_range = lifx_device:get_color_temp_range()
        if lifx_device:supports_color() then
          profile_ref = "lifx.rgbw.blub.v1"
        elseif ct_range.min ~= ct_range.max then
          profile_ref = "lifx.ct.blub.v1"
        end

        -- TODO: Control characters makes rust serde barf. Stripping should be probably be done in devices.create_device or on the hubcore rust side
        local label = lifx_device.label:gsub("%c", "")
        local model = lifx_device.model:gsub("%c", "")

        local metadata = {
          type = "LAN",
          device_network_id = dni,
          label = label,
          profile = profile_ref,
          manufacturer = "LIFX",
          model = model,
          vendor_provided_label = label
        }

        driver:try_create_device(metadata)
      end
    end
  )
end

local function discovery(driver, opts, should_continue)
  log.info("Starting LIFX Discovery")
  while should_continue() do
    discover(driver, true)
  end
  log.info("Stopping LIFX Discovery")
end

local function device_init(driver, device)
  log.info(
    "[" .. device.id .. "] Initializing LIFX device: " .. device.label .. " (" .. device.device_network_id .. ")"
  )
  driver.device_dni_map[device.device_network_id] = device

  local lifx_device = device:get_field(FIELDS.LIFX_DEVICE)
  if lifx_device == nil then
    log.warn("No LIFX device object found for " .. device.label .. ". Starting discovery...")
    discover(driver, false)
  end

  start_poll(device)
end

local function device_added(driver, device)
  log.info("[" .. device.id .. "] Adding new LIFX device: " .. device.label)
end

local function device_removed(driver, device)
  --NOTE: Polling timer is on device thread. Timer will be automatically cleaned up.
  log.info("[" .. device.id .. "] Removing LIFX device: " .. device.label)
  driver.device_dni_map[device.device_network_id] = nil
end

---------------------------------------------------------------------------------------------------

log.info("Initializing LIFX Edge Driver")

local lifx_driver =
  Driver(
  "lifx",
  {
    discovery = discovery,
    capability_handlers = {
      [capabilities.switch.ID] = {
        [capabilities.switch.commands.on.NAME] = command_handlers.handle_switch_on,
        [capabilities.switch.commands.off.NAME] = command_handlers.handle_switch_off
      },
      [capabilities.switchLevel.ID] = {
        [capabilities.switchLevel.commands.setLevel.NAME] = command_handlers.handle_set_level
      },
      [capabilities.colorControl.ID] = {
        [capabilities.colorControl.commands.setColor.NAME] = command_handlers.handle_set_color,
        [capabilities.colorControl.commands.setHue.NAME] = command_handlers.handle_set_hue,
        [capabilities.colorControl.commands.setSaturation.NAME] = command_handlers.handle_set_saturation
      },
      [capabilities.colorTemperature.ID] = {
        [capabilities.colorTemperature.commands.setColorTemperature.NAME] = command_handlers.handle_set_color_temp
      }
    },
    lifecycle_handlers = {init = device_init, added = device_added, removed = device_removed},
    device_dni_map = {}
  }
)

function lifx_driver:device_health_check()
  log.debug("Performing periodic device health check")
  for id, device in pairs(self.device_cache) do
    if device:get_field(FIELDS.ONLINE) == false then
      log.info("[" .. device.id .. "] Found offline LIFX device, sending discovery message")
      discover(self, false)
      break
    end
  end
end

-- start 60s periodic health check
lifx_driver.device_health_timer = lifx_driver:call_on_schedule(60, lifx_driver.device_health_check)

lifx_driver:run()
