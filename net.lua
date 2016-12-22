local socket = require "socket"

local lume   = require "lume"

local console = require "console"

local AcceptTimeout = 0.002
local SocketTimeout = 0.001
local SelectTimeout = 0.002

local Servers        = {}
local Clients        = {}
local ClientMessages = {}
local ServerMessages = {}
local Callbacks      = {}
local Disconnected   = {}

local net = {}

function net.listen(callbacks, port, address)
  if not port then port = math.random(1024, 65535) end
  if not address then address = "0.0.0.0" end
  local server, errMsg = socket.bind(address, port)
  if server then
    server:settimeout(AcceptTimeout)
    Callbacks[server] = callbacks
    lume.push(Servers, server)
    return {
      ip = socket.dns.toip(socket.dns.gethostname()),
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
      ClientMessages[client] = {}
      ServerMessages[client] = {}
      Callbacks[client] = Callbacks[server]
      lume.push(Clients, client)
      Callbacks[client].onAccept(client)
    elseif errMsg and not errMsg == "timeout" then
      console.log("accept error on "..server:getsockname()..": "..errMsg)
    end
  end
  spoolClients()
  disconnectClients()
  pushMessages()
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
          console.log("receive error: "..err.." from "..tostring(client:getpeername()))
          if err == "closed" then
            Disconnected[client] = true
          end
        else
          Callbacks[client].onReceive(client, msg)
        end
      end
    end
    waves = waves - 1
  until waves <= 0
end

function disconnectClients()
  for client, t in pairs(Disconnected) do
    lume.remove(Clients, client)
    client:shutdown()
    ServerMessages[client] = nil
  end
  Disconnected = {}
end

function net.sendMessage(client, message)
  lume.push(ServerMessages[client], message)
end

function pushMessages(waves)
  if not waves then waves = 1 end
  local timeout = SelectTimeout / waves
  repeat
    local reading, writing, errMsg = socket.select(Clients, Clients, timeout)
    if errMsg and not errMsg == "timeout" then
      console.log("clients select error: "..errMsg)
    else
      for i, client in ipairs(writing) do
        for j, message in ipairs(ServerMessages[client]) do
          local bytes, err = client:send(message)
          if err then
            console.log("send error: "..err.." from "..tostring(client:getpeername()))
            if err == "closed" then
              Disconnected[client] = true
            end
          end
        end
      end
    end
    waves = waves - 1
  until waves <= 0
end

return net
