local net = require "net"

Documents = {}

local httpd = {}

local EOL = "\r\n"

function response(content, status)
  status = status or 200
  local preamble = "HTTP/1.1 "..status
  local headers = "Content-Length: "..string.len(content)
  return preamble..EOL..headers..EOL..EOL..content
end

function handleConnect(client)
end

function handleRequest(client, message)
  if string.find(message, "^GET") then
    console.log("GET from "..client:getpeername()..": "..message)
    local path = string.gsub(message, "^GET /([^ ]*).*", "%1")
    local doc = Documents[path]
    if doc then
      net.sendMessage(client, response(doc))
    else
      console.log("no doc found at path: "..tostring(path))
    end
  end
end

function httpd.load()
  for i, filename in ipairs(love.filesystem.getDirectoryItems(".")) do
    if string.find(filename, "html$") or string.find(filename, ".css$") then
      console.log("adding document "..filename)
      Documents[filename] = love.filesystem.read(filename)
    end
  end
  local sock = net.listen({
    onAccept     = handleConnect,
    onReceive    = handleRequest,
    onDisconnect = nil
  })
  console.log("listening for http requests on "..sock.ip..":"..sock.port)
end

function httpd.update(dt)
  net.update(dt)
end

return httpd
