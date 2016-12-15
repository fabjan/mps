require "globals"

local lume = require "lume"

local ConsoleBuffer = {}
local ShowConsole = false

console = {}

function console.toggle()
  ShowConsole = not ShowConsole
end

function console.showing()
  return ShowConsole
end

function console.log(...)
	local lines = {...}
	local line  = ""
	for i,v in ipairs(lines) do
		line = line .. tostring(v) .. "\t"
	end
	lume.push(ConsoleBuffer, line)
	if (#ConsoleBuffer > CONSOLE_LINES) then
		ConsoleBuffer = lume.slice(ConsoleBuffer, 2, CONSOLE_LINES + 2)
	end
end

function console.draw()
	if (not ShowConsole) then return end
	local lines = #ConsoleBuffer
	local width = love.graphics.getWidth() - CONSOLE_MARGIN*2

	love.graphics.setColor(20, 20, 20, 200)
	love.graphics.rectangle("fill",	CONSOLE_MARGIN, 0, width, lines*LINE_HEIGHT)
  love.graphics.setColor(255, 255, 255, 200)
	for i, line in ipairs(ConsoleBuffer) do
		love.graphics.print(line, CONSOLE_MARGIN*2, (i - 1)*LINE_HEIGHT)
	end
end

return console