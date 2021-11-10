--------------------------------------------------------------------------------------------
-- LIFX Discovery
--------------------------------------------------------------------------------------------
local LIFX = require "lifx.types"
local protocol = require "lifx.protocol"
local parser = require "lifx.parser"
local utilities = require "lifx.utilities"
local builder = require "lifx.builder"
local device = require "lifx.device"
local log = require "log"

local function discover(timeout, callback)
  local broadcast_cb = function(resp, ip_or_err, port)
    if resp == nil then
      if ip_or_err ~= "timeout" then
        log.warn("Discovery: received (non-timeout) error" .. ip_or_err)
      end
    else
      local target, msg_type_or_err, parsed_version_msg = parser.parse_message(resp)
      if target == nil then
        log.warn("Failed to parse response message: " .. msg_type_or_err)
        return
      end

      local model, err = utilities.get_model_name_from_product_id(parsed_version_msg.product)
      if model == nil then
        model = "Unknown Model"
        log.warn('Discovery: Failed to find product model name. Defaulting to "' .. model .. '"')
      end

      local color = utilities.get_color_support_from_product_id(parsed_version_msg.product)
      if color == nil then
        color = false
        log.warn("Discovery: Failed to find product color support. Defaulting to false")
      end

      local ct_range = utilities.get_color_temp_range_from_product_id(parsed_version_msg.product)
      if ct_range == nil then
        ct_range = {2700, 2700}
        log.warn("Discovery: Failed to get color temp range. Defaulting to 2700-2700")
      end

      if msg_type_or_err ~= LIFX.MSG_TYPE_STATEVERSION then
        log.warn("Received non-stateVersion message as a discovery response: " .. msg_type_or_err)
        return
      end

      -- Send unicast getLabel message to get device label
      local label_msg = builder.build_getlabel(target)
      local label_resp, ip_or_err, port = protocol.send_cmd(label_msg, ip_or_err, port, timeout) -- TODO use supplied timeout?
      if label_resp == nil then
        log.warn("Discovery: failed to receive stateLabel response: " .. ip_or_err)
        return
      else
        local target, label_msg_type_or_err, parsed_label_msg = parser.parse_message(label_resp)
        if target == nil then
          log.warn("Failed to parse stateLabel response: " .. label_msg_type_or_err)
          return
        end

        if label_msg_type_or_err == LIFX.MSG_TYPE_STATELABEL then
          local lifx_dev =
            device.Device(
            target,
            parsed_label_msg.label,
            model,
            ip_or_err,
            port,
            color,
            {min = ct_range[1], max = ct_range[2]}
          )
          callback(lifx_dev)
        else
          log.warn("Received non-stateLabel message as a discovery response: " .. label_msg_type_or_err)
        end
      end
    end
  end

  log.info("Sending Lifx discovery message")

  local msg = builder.build_getversion()
  protocol.send_broadcast_cmd(msg, LIFX.DEFAULT_PORT, timeout, broadcast_cb)
end

return {
  discover = discover
}
