local lume = require "lume"
local console = require "console"

local Gamepads = {}

local InputMap = {
	dpleft = "left",
	dpright = "right",
  dpdown = "duck",
	a = "jump",
}

local ControllerState = {}

local ControllerStateTransitions = {
	off = {
		["true"] = "pressed",
    ["false"] = "off"
	},
	pressed = {
		["true"] = "held",
		["false"] = "released"
	},
	held = {
    ["true"] = "held",
		["false"] = "released"
	},
	released = {
		["true"] = "pressed",
		["false"] = "off"
	}
}

local function indexOf(joystick)
	for index, gamepad in ipairs(Gamepads) do
		if (gamepad == joystick) then
			return index
		end
	end
end

local function updateGamepad(gamepad)
	local controllerNo = indexOf(gamepad)
	local controllerState
	local buttonState, lastState, nextState

	if (not ControllerState[controllerNo]) then
		ControllerState[controllerNo] = {}
	end
	controllerState = ControllerState[controllerNo]
	for button, action in pairs(InputMap) do
		buttonState = tostring(gamepad:isGamepadDown(button))
		lastState = controllerState[action]
		if (not lastState) then lastState = "off" end
		nextState = ControllerStateTransitions[lastState][buttonState]
		if (nextState) then
			controllerState[action] = nextState
		end
	end
end

-- module interface

local controllers = {}

function controllers.update(dt)
	for player,gamepad in ipairs(Gamepads) do
		if (gamepad) then
			updateGamepad(gamepad)
		end
	end
end

function controllers.enumerate()
  return ipairs(Gamepads)
end

function controllers.inputState(controllerNo)
  return ControllerState[controllerNo]
end

-- LÖVE callbacks

function love.gamepadpressed(joystick, button)
	local controllerNo = indexOf(joystick)
	if (controllerNo) then
		console.log("controller #" .. controllerNo, "pressed", button)
	end
end

function love.gamepadreleased(joystick, button)
	console.log("gamepad released", joystick:getName(), button)
end

function love.joystickadded(joystick)
	console.log("joystick added", joystick:getName())
	if (lume.find(Gamepads, joystick)) then
		return
	end
	if (joystick:isGamepad()) then
		console.log("added gamepad")
		lume.push(Gamepads, joystick)
	end
end

function love.joystickremoved(joystick)
	console.log("joystick removed", joystick:getName())
end

return controllers