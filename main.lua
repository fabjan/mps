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
  
  for player, gamepad in controllers.enumerate() do
    local inputState = controllers.inputState(player)
    if inputState.jump == "pressed" then
      local sfx = sfxr.newSound()
      sfx:randomJump()
      local soundData = sfx:generateSoundData()
      love.audio.newSource(soundData):play()
      
      sprites.mutate("player", {dy = -8})
      lume.push(Falling, "player")
    end
    if inputState.left == "pressed" then
      sprites.mutate("player", {dx = -0.6})
    end
    if inputState.right == "pressed" then
      sprites.mutate("player", {dx = 0.6})
    end
    if inputState.left == "held" then
      sprites.mutate("player", {ddx = -0.2})
    end
    if inputState.right == "held" then
      sprites.mutate("player", {ddx = 0.2})
    end
    if inputState.left == "released" then
      sprites.mutate("player", {ddx = 0, dx = 0})
    end
    if inputState.right == "released" then
      sprites.mutate("player", {ddx = 0, dx = 0})
    end
    if inputState.duck == "pressed" then
      sprites.mutate("player", {dx = 0})
    end
  end
  
  for i, spriteName in ipairs(Falling) do
    local spriteY = sprites.get(spriteName, "y")
    -- console.log(spriteName.."is falling, y is "..tostring(spriteY))
    --if spriteY == nil then
    --  console.log("weird, y for "..spriteName.." was nil")
    --  spriteY = 0
    --end
    if spriteY > 100 then
      sprites.mutate(spriteName, {dy = 0, ddy = 0, y = 100})
      lume.remove(Falling, spriteName)
    else
      sprites.mutate(spriteName, {ddy = 0.6})
    end
  end
  
  sprites.update(dt)
  sounds.update(dt)
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
