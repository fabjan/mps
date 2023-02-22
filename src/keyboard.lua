local console = require "console"

KeyButtons = {
  left  = "dpleft",
  right = "dpright",
  up    = "a",
  x     = "b",
  a     = "x",
  s     = "y"
}

local FakeJoystick = {
  states        = {},
  isGamepadDown = function(self, button) return self.states[button] end,
  isGamepad     = function() return true end,
  isConnected   = function() return true end,
  getName       = function() return "virtual keyboard controller" end
}

function connectKeyGamepad()
  love.joystickadded(FakeJoystick)
end

local keyboard = {}

function keyboard.keypressed(key)
  local button = KeyButtons[key]
  if button then
    FakeJoystick.states[button] = true
  end
end


function keyboard.keyreleased(key)
  local button = KeyButtons[key]
  if button then
    FakeJoystick.states[button] = false
  end
end

function keyboard.load()
  connectKeyGamepad()
  console.log("faking joystick from keyboard events")
end

return keyboard