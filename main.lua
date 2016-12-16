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

MonkeyLives = false  -- Number 5 is alive!
RobotChangeTimer = 0
RobotChangeDelay = 1  -- seconds
RobotInputMap = {}

-- Sprite collections
Players = {}
Falling = {}
Fallers = {}

-- Static things
local ph = PIXEL_HEIGHT/20
Platforms = {
  {
    x=0, y=ph,
    w=PIXEL_WIDTH, h=ph
  },
  {
    x=0, y=ph*9,
    w=PIXEL_WIDTH/2, h=ph
  },
  {
    x=PIXEL_WIDTH*0.75, y=ph*4,
    w=PIXEL_WIDTH/5, h=ph
  }
}

function love.load()
	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
	love.graphics.setFont(love.graphics.newFont(FONT_NAME, FONT_SIZE))
  
  -- setup modules
  reloader.enable()
  sprites.load()
  sounds.load()
  
  -- setup internals
  if MonkeyLives then
    sprites.create("robot", "player")
    sprites.mutate("robot", {x = lume.random(0, PIXEL_WIDTH)})
    lume.push(Falling, "robot")
    lume.push(Fallers, "robot")
  end
  
  LowrezCanvas = love.graphics.newCanvas()
  LowrezCanvas:setFilter("nearest", "nearest")
end

function love.update(dt)
  reloader.update(dt)
  controllers.update(dt)
  
  for playerNo, gamepad in controllers.enumerate() do
    local inputState = controllers.inputState(playerNo)
    local playerName = "player"..playerNo
    if not lume.find(Players, playerName) then
      sprites.create(playerName, "player")
      sprites.mutate(playerName, {x = lume.random(0, PIXEL_WIDTH)})
      lume.push(Players, playerName)
      lume.push(Falling, playerName)
      lume.push(Fallers, playerName)
      console.log("player "..playerNo.." spawned!")
    end
    actOnInput(playerName, inputState)
  end
  
  if MonkeyLives then  -- debugging buddy
    RobotChangeTimer = RobotChangeTimer + dt
    if RobotChangeTimer > RobotChangeDelay then
      RobotChangeTimer = 0
      robotDoSomething()
    end
    actOnInput("robot", RobotInputMap)
    updateRobotInput()
  end
  
  for i, spriteName in ipairs(Falling) do
    sprites.mutate(spriteName, {ddy = -0.6})
  end
  
  sprites.update(dt)
  resolvePlatforming()
  resolvePlayerCollisions()
  clampToScreen()

  sounds.update(dt)
end

function resolvePlatforming()
  -- well, this will be fast?
  for i, spriteName in ipairs(Fallers) do
    local isFalling = lume.find(Falling, spriteName)
    local feet = sprites.getFeet(spriteName)
    local dy = sprites.get(spriteName, "dy")
    if feet and isFalling then
      for i, platform in ipairs(Platforms) do
        if isCollision(feet, platform) and dy < 0 then
          land(spriteName)
          sprites.mutate(spriteName, {y = platform.y})
        end
      end
    elseif feet and not isFalling then
      local isOnSolidGround = false
      feet.y = feet.y + 1
      for i, platform in ipairs(Platforms) do
        if isCollision(feet, platform) then
          isOnSolidGround = true
        end
      end
      if not isOnSolidGround then
        lume.push(Falling, spriteName)
      end
    end
  end
end

function resolvePlayerCollisions()
  for i, playerA in ipairs(Players) do
    for j, playerB in ipairs(Players) do
      if not (playerA == playerB) then
        local rectA = sprites.getRect(playerA)
        local rectB = sprites.getRect(playerB)
        if isCollision(rectA, rectB) then
          playRandom("Explosion")
        end
      end
    end
  end
end

function isCollision(rect1, rect2)
  -- from https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
  return (
    rect1.x           < rect2.x + rect2.w and
    rect1.x + rect1.w > rect2.x           and
    rect1.y           < rect2.y + rect2.h and
    rect1.h + rect1.y > rect2.y
  )
end

function clampToScreen()
  -- Holy Leaky Abstraction Batman, how will this EVER pass review!?
  for i, spriteName in ipairs(Players) do
    local spriteInfo = sprites.get(spriteName, {"x", "width"})
    local xOnScreen = lume.clamp(spriteInfo.x, 0, PIXEL_WIDTH-spriteInfo.width)
    if not (spriteInfo.x == xOnScreen) then
      sprites.mutate(spriteName, {x = xOnScreen, dx = 0, ddx = 0})
    end
  end
  for i, spriteName in ipairs(Falling) do
    local spriteY = sprites.get(spriteName, "y")
    if spriteY < 0 then
      land(spriteName)
      sprites.mutate(spriteName, {y = 0})
    end
  end
end

function land(spriteName)
  playRandom("Hit")
  sprites.mutate(spriteName, {dy = 0, ddy = 0})
  lume.remove(Falling, spriteName)
end

function actOnInput(spriteName, inputState)
  local isFalling = lume.find(Falling, spriteName)
  if inputState.jump == "pressed" and not isFalling then
    playRandom("Jump")
    
    sprites.mutate(spriteName, {dy = 10})
    lume.push(Falling, spriteName)
  end
  if inputState.left == "pressed" then
    sprites.mutate(spriteName, {dx = -0.7})
  end
  if inputState.right == "pressed" then
    sprites.mutate(spriteName, {dx = 0.7})
  end
  if inputState.left == "held" then
    sprites.mutate(spriteName, {ddx = -0.3})
  end
  if inputState.right == "held" then
    sprites.mutate(spriteName, {ddx = 0.3})
  end
  if inputState.left == "off" and inputState.right == "off" then
    local old = sprites.get(spriteName, {"dx", "ddx"})
    if math.abs(old.dx) < 0.1 then
      sprites.mutate(spriteName, {ddx = 0, dx = 0})
    else
      local dragFactor = 0.8
      if isFalling then dragFactor = 0.95 end
      sprites.mutate(spriteName, {ddx = old.ddx*dragFactor, dx = old.dx*dragFactor})
    end
  end
  if inputState.duck == "pressed" then
    console.log(spriteName.." ducks!")
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
  for k, soundType in pairs(soundMap) do
    if key == k then
      playRandom(soundType)
    end
  end
end

function playRandom(soundType)
  local sfx = sfxr.newSound()
  sfx["random"..soundType](sfx)
  local soundData = sfx:generateSoundData()
  love.audio.newSource(soundData):play()
end

function robotDoSomething()
  local actions = {
    function () console.log("robot noop") end,
    function ()
      console.log("robot jumps")
      RobotInputMap["jump"] = "pressed"
    end
  }
  lume.randomchoice(actions)()
end

function updateRobotInput()
  RobotInputMap["jump"] = nil
end

function love.draw()
  if console.showing() then
    -- debug print things
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), WINDOW_WIDTH - 100, LINE_HEIGHT)
    local xOffset
    local consoleBottom = LINE_HEIGHT * CONSOLE_LINES
    
    for player, gamepad in controllers.enumerate() do
      love.graphics.setColor(255, 255, 255)
      NextLine = consoleBottom
      xOffset = CONSOLE_MARGIN + (player - 1) * 200
      printLine("player " .. tostring(player), xOffset)
      xOffset = xOffset + CONSOLE_MARGIN*2
      if (gamepad:isConnected()) then
        for k, v in pairs(controllers.inputState(player)) do
          printLine(k .. ": " .. tostring(v), xOffset)
        end
      else
        printLine("controller not connected", xOffset)
      end
      local spriteName = "player"..player
      for k, v in pairs(sprites.enumerate(spriteName)) do
        printLine(k .. ": " .. tostring(v), xOffset)
      end
      local r = sprites.getRect(spriteName)
      love.graphics.setColor(0, 255, 0)
      love.graphics.rectangle("line", r.x*SCALE, displayCoord(r.y)*SCALE, r.w*SCALE, -r.h*SCALE)
      local f = sprites.getFeet(spriteName)
      love.graphics.setColor(255, 0, 255)
      love.graphics.rectangle("line", f.x*SCALE, displayCoord(f.y)*SCALE, f.w*SCALE, -f.h*SCALE)
    end
    
    if MonkeyLives then
      love.graphics.setColor(255, 255, 255)
      NextLine = LINE_HEIGHT * CONSOLE_LINES
      xOffset = 550
      printLine("robot", xOffset)
      for k, v in pairs(sprites.enumerate("robot")) do
        printLine(k .. ": " .. tostring(v), xOffset + CONSOLE_MARGIN*2)
      end
    end
	end
  
  love.graphics.setCanvas(LowrezCanvas)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255)
  for i, p in ipairs(Platforms) do
    love.graphics.rectangle("fill", p.x, displayCoord(p.y), p.w, p.h)
  end
  sprites.draw()
  love.graphics.setCanvas()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(LowrezCanvas, 0, 0, 0, SCALE, SCALE)
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
