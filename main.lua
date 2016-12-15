package.path = package.path .. ';lib/?.lua'

require "globals"

-- some libs

local lume = require "lume"
local sfxr = require "sfxr"

-- my things

local console = require "console"
local reloader = require "hot_reloading"
local controllers = require "controllers"
local sprites = require "sprites"
local sounds = require "sounds"

-- here we go

local NextLine = 0

Sounds = {}

RobotChangeTimer = 0
RobotChangeDelay = 1  -- seconds
RobotInputMap = {}

-- Sprite collections
Players = {}
Falling = {}

function love.load()
	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
	love.graphics.setFont(love.graphics.newFont(FONT_NAME, FONT_SIZE))
  
  -- setup modules
  reloader.enable()
  sprites.load()
  sounds.load()
  
  -- setup internals
  SpriteCanvas = love.graphics.newCanvas()
  SpriteCanvas:setFilter("nearest", "nearest")
end

function love.update(dt)
  reloader.update(dt)
  controllers.update(dt)
  
  RobotChangeTimer = RobotChangeTimer + dt
  if RobotChangeTimer > RobotChangeDelay then
    RobotChangeTimer = 0
    robotDoSomething()
  end
  
  for player, gamepad in controllers.enumerate() do
    local inputState = controllers.inputState(player)
    actOnInput("player", inputState)
  end
  
  actOnInput("robot", RobotInputMap)
  updateRobotInput()
  
  for i, spriteName in ipairs(Falling) do
    local spriteY = sprites.get(spriteName, "y")
    -- console.log(spriteName.."is falling, y is "..tostring(spriteY))
    --if spriteY == nil then
    --  console.log("weird, y for "..spriteName.." was nil")
    --  spriteY = 0
    --end
    if spriteY < 0 then
      sprites.mutate(spriteName, {dy = 0, ddy = 0, y = 0})
      lume.remove(Falling, spriteName)
    else
      sprites.mutate(spriteName, {ddy = -0.6})
    end
  end
  
  sprites.update(dt)
  
  for i, spriteName in ipairs(Players) do
    -- Holy Leaky Abstraction Batman, how will this EVER pass review!?
    local spriteInfo = sprites.get(spriteName, {"x", "width"})
    local xOnScreen = lume.clamp(spriteInfo.x, 0, PIXEL_WIDTH-spriteInfo.width)
    if not (spriteInfo.x == xOnScreen) then
      sprites.mutate(spriteName, {x = xOnScreen, dx = 0, ddx = 0})
    end
  end

  sounds.update(dt)
end

function actOnInput(spriteName, inputState)
  if inputState.jump == "pressed" and not lume.find(Falling, spriteName) then
    local sfx = sfxr.newSound()
    sfx:randomJump()
    local soundData = sfx:generateSoundData()
    love.audio.newSource(soundData):play()
    
    sprites.mutate(spriteName, {dy = 8})
    lume.push(Falling, spriteName)
  end
  if inputState.left == "pressed" then
    sprites.mutate(spriteName, {dx = -0.6})
  end
  if inputState.right == "pressed" then
    sprites.mutate(spriteName, {dx = 0.6})
  end
  if inputState.left == "held" then
    sprites.mutate(spriteName, {ddx = -0.2})
  end
  if inputState.right == "held" then
    sprites.mutate(spriteName, {ddx = 0.2})
  end
  if inputState.left == "released" then
    sprites.mutate(spriteName, {ddx = 0, dx = 0})
  end
  if inputState.right == "released" then
    sprites.mutate(spriteName, {ddx = 0, dx = 0})
  end
  if inputState.duck == "pressed" then
    sprites.mutate(spriteName, {dx = 0})
  end
end

function love.keypressed(key)
	if key == "tab" then
		console.toggle()
	end
  if key == "space" then
		sounds.play("test")
	end
  local soundMap = {
    z = "Laser",
    x = "Jump",
    c = "Hit",       -- often crap if random
    v = "Blip",
    b = "Powerup",
    n = "Explosion",
    m = "Pickup"
  }
  for k,fun in pairs(soundMap) do
    if key == k then
      local sfx = sfxr.newSound()
      sfx["random"..fun](sfx)
      local soundData = sfx:generateSoundData()
      love.audio.newSource(soundData):play()
    end
  end
end

function robotDoSomething()
  local actions = {
    function () console.log("robot walks") end,
    function () console.log("robot talks") end,
    function ()
      RobotInputMap["jump"] = "pressed"
    end
  }
  lume.randomchoice(actions)()
end

function updateRobotInput()
  RobotInputMap["jump"] = nil
end

function love.draw()
  love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), CONSOLE_MARGIN, WINDOW_HEIGHT-LINE_HEIGHT)
	-- debug print controller map state
	local xOffset
	love.graphics.setColor(0,200,0)
	for player, gamepad in controllers.enumerate() do
		NextLine = LINE_HEIGHT * CONSOLE_LINES
		xOffset = CONSOLE_MARGIN + (player - 1) * 150
		printLine("player " .. tostring(player), xOffset)
		xOffset = xOffset + CONSOLE_MARGIN*2
		if (gamepad:isConnected()) then
			for k, v in pairs(controllers.inputState(player)) do
				printLine(k .. ": " .. tostring(v), xOffset)
			end
		else
			printLine("controller not connected", xOffset)
		end
	end
  
  NextLine = LINE_HEIGHT * CONSOLE_LINES
  for k, v in pairs(sprites.enumerate("player")) do
    printLine("player."..k.."="..v, 300)
  end
  
  love.graphics.setCanvas(SpriteCanvas)
  love.graphics.clear()
  sprites.draw()
  love.graphics.setCanvas()
  love.graphics.draw(SpriteCanvas, 0, 0, 0, SCALE, SCALE)
	console.draw()
end

function printLine(s, x, startAt)
	if (startAt ~= nil) then
		NextLine = startAt
	end
	if (NextLine == nil) then
		NextLine = 0
	else
		NextLine = NextLine + LINE_HEIGHT
	end

	love.graphics.print(s, x, NextLine)
end
