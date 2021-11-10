local socket = require "cosock".socket

function send_cmd(cmd, ip, port, timeout)
  local sock = socket.udp()

  sock:settimeout(timeout)
  local success, err = sock:setsockname("0.0.0.0", 0) -- eventually this should be "*"
  if success == nil then
    sock:close()
    return nil, err
  end

  success, err = sock:sendto(cmd, ip, port)
  if success == nil then
    sock:close()
    return nil, err
  end

  local data, ip_or_err, port = sock:receivefrom()
  if data then
    sock:close()
    return data, ip, port
  else
    sock:close()
    return nil, ip_or_err
  end
end

function send_broadcast_cmd(cmd, port, timeout, callback)
  local sock = socket.udp()

  sock:settimeout(timeout)
  local success, err = sock:setsockname("0.0.0.0", 0) -- eventually this should be "*"
  if success == nil then
    sock:close()
    return nil, err
  end

  success, err = sock:setoption("broadcast", true)
  if success == nil then
    sock:close()
    return nil, err
  end

  --TODO TIMEOUT DECREASE
  local res, err = sock:sendto(cmd, "255.255.255.255", port)
  if res == nil then
    log.warn("Failed to send broadcast command: " .. err)
  else
    while true do
      local data, ip_or_err, port = sock:receivefrom()
      if data == nil then
        callback(nil, ip_or_err)
        break
      else
        callback(data, ip_or_err, port)
      end
    end
  end

  sock:close()
end

return {
  send_cmd = send_cmd,
  send_broadcast_cmd = send_broadcast_cmd
}
