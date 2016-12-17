local bit = bit32 or require "lib.bit"

local net = require "net"

NetGamepads = {}

NetButtons = {"dpleft", "dpright", "dpup", "dpdown", "a", "b", "x", "y"}

function connectNetGamepad(client)
  local joystickName = "virtual net controller ("..client:getpeername()..")"
  local inputs = {}
  local fakeJoystick = {
    states        = {},
    isGamepadDown = function(self, button) return self.states[button] end,
    isGamepad     = function() return true end,
    isConnected   = function() return true end,
    getName       = function() return joystickName end
  }
  NetGamepads[client] = fakeJoystick
  love.joystickadded(fakeJoystick)
end

function updateNetGamepad(client, message)
  local gamepad = NetGamepads[client]
  if not gamepad then
    console.log("no gamepad for "..client:getpeername())
  end
  for button, buttonState in pairs(decodeButtons(message)) do
    gamepad.states[button] = buttonState
  end
end

function decodeButtons(message)
  local encoded = tonumber(message)
  if not encoded then return {} end
  local decoded = {}
  for i, name in ipairs(NetButtons) do
    local buttonMask = math.pow(2, i - 1)
    if bit.band(encoded, buttonMask) == buttonMask then
      decoded[name] = true
    else
      decoded[name] = false
    end
  end
  return decoded
end

local netgamepads = {}

function netgamepads.load()
  net.listen({
    onAccept  = connectNetGamepad,
    onReceive = updateNetGamepad
  })
end

function netgamepads.update(dt)
  net.update(dt)
end

return netgamepads 
