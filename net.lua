local socket = require "socket"

local lume   = require "lib.lume"

local console = require "console"

local AcceptTimeout = 0.002
local SocketTimeout = 0.001
local SelectTimeout = 0.002

local Servers        = {}
local Clients        = {}
local ClientMessages = {}
local Callbacks      = {}

local net = {}

function message(msgType, content)
  if not content then content = "" end
  return msgType.." "..content
end

function net.listen(callbacks, port, address)
  if not port then port = math.random(1024, 65535) end
  if not address then address = "0.0.0.0" end
  local server, errMsg = socket.bind(address, port)
  if server then
    console.log("listening for controllers on "..address..":"..port)
    server:settimeout(AcceptTimeout)
    Callbacks[server] = callbacks
    lume.push(Servers, server)
    return {
      address = address,
      port = port
    }
  elseif errMsg then
    console.log("bind error: "..errMsg)
  end
  return nil
end

function net.update()
  for i, server in ipairs(Servers) do
    local client, errMsg = server:accept()
    if client then
      client:settimeout(SocketTimeout)
      client:send(message("HELLO").."\r\n")
      ClientMessages[client] = {}
      Callbacks[client] = Callbacks[server]
      lume.push(Clients, client)
      Callbacks[client].onAccept(client)
    elseif errMsg and not errMsg == "timeout" then
      console.log("accept error on "..server:getsockname()..": "..errMsg)
    end
  end
  spoolClients()
end

function spoolClients(waves)
  if not waves then waves = 1 end
  local timeout = SelectTimeout / waves
  repeat
    local reading, writing, errMsg = socket.select(Clients, Clients, timeout)
    if errMsg and not errMsg == "timeout" then
      console.log("clients select error: "..errMsg)
    else
      for i, client in ipairs(reading) do
        local msg, err = client:receive("*l")
        if err then
          console.log("receive error: "..err.." from "..client:getpeername())
        else
          Callbacks[client].onReceive(client, msg)
        end
      end
    end
    waves = waves - 1
  until waves <= 0
end

return net
