local lume = require "vendor/lume"

local console     = require "console"
local controllers = require "controllers"
local sprites     = require "sprites"
local sounds      = require "sounds"
local robot       = require "robot"

NAME_CHOICES = require "usr_share_dict_words"

UIMargin = 88
MapWidth = PIXEL_WIDTH-UIMargin
local ph = PIXEL_HEIGHT/20
local pw = MapWidth/5
Platforms = {
  {
    x=UIMargin + pw*2, y=ph*16,
    w=pw, h = ph
  },
  {
    x=PIXEL_WIDTH-pw, y=ph*11,
    w=pw, h=ph
  },
  {
    x=UIMargin, y=ph*11,
    w=pw, h=ph
  },
  {
    x=UIMargin + pw, y=ph*6,
    w=MapWidth - pw*2, h=ph
  },
  {
    x=UIMargin, y=ph,
    w=MapWidth, h=ph
  }
}

local playing = {}

function playing.init()
  -- Some rules
  Beats = {
    rock     = { scissors = true },
    paper    = { rock     = true },
    scissors = { paper    = true }
  }

  -- Sprite collections
  Players  = {}
  Hands    = {}
  Falling  = {}
  Hanging  = {}
  Fallers  = {}
  Rock     = {}
  Paper    = {}
  Scissors = {}
  Dead     = {}

  -- Other tracking
  Attacks = {}
  Score   = {}
  Lives   = {}
  Names   = {}
  Tag     = {}
  Color   = {}
  Winner  = "NOBODY"

  -- shared mutable state for debug text printlines
  NextLine = 0

  -- setup monkey business
  -- make this true to test with a dummy
  -- if you have no extra controllers
  MonkeyLives = false  -- Number 5 is alive!

  if MonkeyLives then
    robot.init()
    spawnPlayer(-1, "robot", "robotHand")
  end

  sounds.play("song1", true)
end

function playing.leave()
  sounds.stop("song1")
end

function playing.update(dt)
  controllers.update(dt)

  for playerNo, gamepad in controllers.enumerate() do
    local inputState = controllers.inputState(playerNo)
    local playerName = "player"..playerNo
    local handName = "hand"..playerNo
    if not lume.find(Players, playerName) and not lume.find(Dead, playerName) then
      spawnPlayer(playerNo, playerName, handName)
    else
      actOnInput(playerName, inputState)
    end
  end

  if MonkeyLives then  -- debugging buddy
    local robotInput = robot.update(dt)
    actOnInput("robot", robotInput)
  end

  for i, spriteName in ipairs(Falling) do
    local hang = 1
    if lume.find(Hanging, spriteName) then hang = JUMP_HANG end
    sprites.mutate(spriteName, {ddy = LIKE_GRAVITY/hang})
  end

  sprites.update(dt)
  resolvePlatforming()
  clampToScreen()
  jazzHands()
  resolvePlayerCollisions()
  resolveFights(dt)
  killAllDeadPlayers()

  if table.getn(Players) == 1 and table.getn(Dead) > 0 then
    Winner = Tag[Players[1]]
    return "winning"
  end
end

function spawnPlayer(playerNo, playerName, handName, playerTag)
  sprites.create(playerName, "player")
  sprites.create(handName, "attack")
  playerTag = playerTag or randomName()

  local playerColor = stringColor(playerTag)
  local playerX = lume.random(0, PIXEL_WIDTH)
  sprites.mutate(playerName, {x = playerX, color = playerColor, tag = playerTag})
  sprites.mutate(handName, {color = playerColor})
  lume.push(Players, playerName)
  lume.push(Falling, playerName)
  lume.push(Fallers, playerName)
  Hands[playerName] = handName
  Score[playerName] = 0
  Lives[playerName] = LIVES
  Tag[playerName]   = playerTag
  Color[playerName] = playerColor
  console.log(playerName.." spawned!")
end

function killAllDeadPlayers()
  local died = {}
  for i, playerName in ipairs(Players) do
    local lives = Lives[playerName]
    if lives <= 0 then
      lume.push(died, playerName)
    end
  end
  for i, playerName in ipairs(died) do
    console.log(playerName.." died!")
    lume.push(Dead, playerName)
    lume.remove(Players, playerName)
    lume.remove(Falling, playerName)
    lume.remove(Fallers, playerName)
    if playerName == "robot" then MonkeyLives = false end
    Attacks[playerName] = nil
    sprites.mutate(Hands[playerName], {visible = false})
    sprites.mutate(playerName, {visible = false, dy=0, ddy=0, dx=0, ddx=0})
    sounds.playRandom("Explosion")
  end
end

function jazzHands()
  for i, playerName in ipairs(Players) do
    local handName = Hands[playerName]
    local playerInfo = sprites.get(playerName, {"x", "y", "flipX", "width", "height", "xMargin"})
    local handWidth = sprites.get(handName, "width")
    local newFlipX = playerInfo.flipX
    local xOffset = playerInfo.width + 4
    local yOffset = playerInfo.height  * 0.46
    if newFlipX then xOffset = -handWidth - 4 end
    local newX = playerInfo.x + xOffset
    local newY = playerInfo.y + yOffset
    sprites.mutate(handName, {x = newX, y = newY, flipX = newFlipX})
  end
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
      -- check for ground one pixel below the feet
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
    local handA = Hands[playerA]
    for j, playerB in ipairs(Players) do
      local handB = Hands[playerB]
      if not (playerA == playerB) then
        local rPA = sprites.getRect(playerA)
        local rPB = sprites.getRect(playerB)
        local rHA = sprites.getRect(handA, true)
        local rHB = sprites.getRect(handB, true)
        if isCollision(rHA, rPB) then attack(playerA, handA, playerB) end
        if isCollision(rHB, rPA) then attack(playerB, handB, playerA) end
      end
    end
  end
end

function attack(aggressor, hand, defender)
  if nil == Attacks[aggressor] then Attacks[aggressor] = {} end
  local alreadyAttacking = not (Attacks[aggressor][defender] == nil)
  if not alreadyAttacking then
    local attackType = sprites.get(hand, "animationState")
    Attacks[aggressor][defender] = { duration = ATTACK_DURATION, attackType = attackType }
  end
end

function resolveFights(dt)
  local toRemove = {}
  for agressor, fights in pairs(Attacks) do
    for defender, attack in pairs(fights) do
      attack.duration = attack.duration - dt
      if attack.duration <= 0 then
        if not toRemove[agressor] then toRemove[agressor] = {} end
        toRemove[agressor][defender] = true
        local attackA = attack.attackType
        local attackD = ((Attacks[defender] or {})[agressor] or {}).attackType
        if attackA == attackD then
          resolveDraw(agressor, defender)
        elseif attackD == nil or Beats[attackA][attackD] then
          resolveBeat(agressor, defender)
        end
      end
    end
  end
  for agressor, defenders in pairs(toRemove) do
    for defender, v in pairs(defenders) do
      Attacks[agressor][defender] = nil
    end
  end
end

function resolveDraw(agressor, defender)
  console.log(agressor.." and "..defender.." tied!")
  local impact = JUMP_POWER/3
  bumpBack(agressor, impact)
  bumpBack(defender, impact)
  sounds.playRandom("Hit", 0.5)
end

function resolveBeat(agressor, defender)
  console.log(agressor.." beat "..defender.."!")
  Score[agressor] = Score[agressor] + 1
  Lives[defender] = Lives[defender] - 1
  local impact = JUMP_POWER/2
  bumpBack(defender, impact)
  sounds.playRandom("Blip")
end

function bumpBack(spriteName, impact)
  if not lume.find(Falling, spriteName) then lume.push(Falling, spriteName) end
  local flipFactor = -1
  if sprites.get(spriteName, "flipX") then flipFactor = 1 end
  sprites.mutate(spriteName, {dy = impact*2, dx = flipFactor*impact, animationState="hurt"})
end

function isCollision(rect1, rect2)
  if rect1 == nil or rect2 == nil then return false end
  -- from https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
  return (
    rect1.x           < rect2.x + rect2.w and
    rect1.x + rect1.w > rect2.x           and
    rect1.y           < rect2.y + rect2.h and
    rect1.h + rect1.y > rect2.y
  )
end

function clampToScreen()
  for i, spriteName in ipairs(Players) do
    local spriteInfo = sprites.get(spriteName, {"x", "width"})
    local xOnScreen = lume.clamp(spriteInfo.x, UIMargin, PIXEL_WIDTH-spriteInfo.width)
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
  sounds.playRandom("Hit", 0.2)
  sprites.mutate(spriteName, {dy = 0, ddy = 0, animationState = "idle"})
  lume.remove(Falling, spriteName)
end

function actOnInput(spriteName, inputState)
  if lume.find(Dead, spriteName) then return end
  local isFalling = lume.find(Falling, spriteName)
  local spriteInfo = sprites.get(spriteName, {"dx", "ddx", "dy"})

  -- jumping
  if inputState.jump == "pressed" and not isFalling then
    sounds.playRandom("Jump", 0.2)
    sprites.mutate(spriteName, {dy = JUMP_POWER, animationState = "jumping"})
    lume.push(Falling, spriteName)
  end
  if inputState.jump == "held" and isFalling and spriteInfo.dy > 0 and not lume.find(Hanging, spriteName) then
    lume.push(Hanging, spriteName)
  end
  if inputState.jump == "released" and isFalling then
    lume.remove(Hanging, spriteName)
  end

  -- moving
  if inputState.left == "pressed" then
    sprites.mutate(spriteName, {dx = -RUNNING_START, flipX = true})
  end
  if inputState.right == "pressed" then
    sprites.mutate(spriteName, {dx = RUNNING_START, flipX = false})
  end
  if inputState.left == "held" then
    sprites.mutate(spriteName, {ddx = -RUNNING_ACCEL})
  end
  if inputState.right == "held" then
    sprites.mutate(spriteName, {ddx = RUNNING_ACCEL})
  end
  if inputState.left == "off" and inputState.right == "off" then
    if math.abs(spriteInfo.dx) < RUNNING_EPSILON then
      sprites.mutate(spriteName, {ddx = 0, dx = 0})
    else
      local dragFactor = GROUND_DRAG
      if isFalling then dragFactor = AIR_DRAG end
      sprites.mutate(spriteName, {ddx = spriteInfo.ddx*dragFactor,  dx = spriteInfo.dx*dragFactor})
    end
  end

  local newSpriteInfo = sprites.get(spriteName, {"dx", "ddx", "dy"})
  if newSpriteInfo.dx < -RUNNING_MAX then
    sprites.mutate(spriteName, {ddx = 0,  dx = -RUNNING_MAX})
  elseif newSpriteInfo.dx > RUNNING_MAX then
    sprites.mutate(spriteName, {ddx = 0,  dx = RUNNING_MAX})
  end

  -- attacking
  local attackName
  if inputState.rock == "pressed" then
    attackName = rock(spriteName)
  end
  if inputState.paper == "pressed" then
    attackName = paper(spriteName)
  end
  if inputState.scissors == "pressed" then
    attackName = scissors(spriteName)
  end
  if attackName then
    sprites.mutate(spriteName, {animationState = "attack"})
    sprites.mutate(Hands[spriteName], {visible = true, animationState = attackName})
  elseif (inputState.rock == "released" or inputState.paper == "released" or inputState.scissors == "released") then
    sprites.mutate(spriteName, {animationState = "idle"})
    sprites.mutate(Hands[spriteName], {visible = false})
  end
end

function rock(spriteName)
  lume.remove(Paper, spriteName)
  lume.remove(Scissors, spriteName)
  lume.push(Rock, spriteName)
  return "rock"
end

function paper(spriteName)
  lume.remove(Rock, spriteName)
  lume.remove(Scissors, spriteName)
  lume.push(Paper, spriteName)
  return "paper"
end

function scissors(spriteName)
  lume.remove(Rock, spriteName)
  lume.remove(Paper, spriteName)
  lume.push(Scissors, spriteName)
  return "scissors"
end

function randomName(tries)
  local newName = string.upper(lume.randomchoice(NAME_CHOICES))
  if not lume.find(Names, newName) then
    return newName
  else
    if tries == nil then tries = 3 end
    if tries <= 0 then return "BOB" end
    return randomName(tries - 1)
  end
end

function playing.draw()
  -- debug "underlay"
  if ShowDebugInfo or ShowBoundingBoxes then
    drawDebugCrap()
  end

  love.graphics.clear()

  -- game graphics
  for i, p in ipairs(Platforms) do
    love.graphics.setColor(0.67, 0.67, 0.67)
    love.graphics.rectangle("fill", p.x, displayCoord(p.y), p.w, 2)
  end
  sprites.draw()

  -- UI
  drawSidebar()

  -- debug overlay
  if ShowFPS then
    local fpsText = "FPS: "..tostring(love.timer.getFPS())
    local xOff = PIXEL_WIDTH - CONSOLE_MARGIN - SMALL_FONT:getWidth(fpsText)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(fpsText, xOff, LINE_HEIGHT)
  end
end

function drawSidebar()
  -- What are the scores George Dawes?
  local scores = {}
  for name, score in pairs(Score) do
    lume.push(scores, {name, score})
  end
  local yOff = LINE_HEIGHT
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("line", SCALE_X/2, SCALE_Y/2, UIMargin-SCALE_X, PIXEL_HEIGHT-SCALE_Y*3)
  love.graphics.print("HIGH SCORE", CONSOLE_MARGIN, yOff)
  for i, nameAndScore in ipairs(lume.sort(scores, function(a, b) return a[2] > b[2] end)) do
    local playerName = nameAndScore[1]
    local score = nameAndScore[2]
    local tag = Tag[playerName]
    if lume.find(Dead, playerName) then tag = "X"..tag else tag = " "..tag end
    love.graphics.setColor(Color[playerName])
    yOff = yOff + LINE_HEIGHT
    love.graphics.print(tag..": "..tostring(score), CONSOLE_MARGIN, yOff)
  end
end

function drawMonkeyDebug()
  love.graphics.setColor(1, 1, 1)
  xOffset = WINDOW_WIDTH - 400
  resetPrintLine(LINE_HEIGHT * CONSOLE_LINES + 300)
  printLine("robot", xOffset)
  for k, v in pairs(sprites.enumerate("robot")) do
    printLine(k .. ": " .. tostring(v), xOffset)
  end
end

function drawPlayerDebug(player, gamepad, xOffset)
  love.graphics.setColor(1, 1, 1)
  resetPrintLine(consoleBottom)
  printLine("player " .. tostring(player), xOffset)
  if (gamepad:isConnected()) then
    for k, v in pairs(controllers.inputState(player)) do
      printLine(k .. ": " .. tostring(v), xOffset)
    end
  else
    printLine("controller not connected", xOffset)
  end
  for k, v in pairs(sprites.enumerate("player"..player)) do
    printLine(k .. ":", xOffset)
    if k == "color" then
      r, g, b = unpack(v)
      printLine(string.format("  %.2f %.2f %.2f", r, g, b), xOffset)
    else
      printLine("  " .. tostring(v), xOffset)
    end
  end
end

function drawBoundingBox(spriteName)
  local r = sprites.getRect(spriteName)
  love.graphics.setColor(0, 1, 0)
  love.graphics.rectangle("line", r.x*SCALE_X, displayCoord(r.y)*SCALE_Y, r.w*SCALE_X, -r.h*SCALE_Y)
  local f = sprites.getFeet(spriteName)
  love.graphics.setColor(1, 0, 1)
  love.graphics.rectangle("line", f.x*SCALE_X, displayCoord(f.y)*SCALE_Y, f.w*SCALE_X, -f.h*SCALE_Y)
  local h = sprites.getRect(Hands[spriteName], true)
  if h then
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle("line", h.x*SCALE_X, displayCoord(h.y)*SCALE_Y, h.w*SCALE_X, -h.h*SCALE_Y)
  end
end

function drawDebugCrap()
  local oldCanvas = love.graphics.getCanvas()
  love.graphics.setCanvas()
  love.graphics.setFont(CONSOLE_FONT)
  love.graphics.clear()
  love.graphics.setColor(1, 1, 1)
  local xOffset
  local consoleBottom = LINE_HEIGHT * CONSOLE_LINES

  if ShowDebugInfo and MonkeyLives then
    drawMonkeyDebug()
  end

  for player, gamepad in controllers.enumerate() do
    local spriteName = "player"..player
    if ShowDebugInfo then
      xOffset = CONSOLE_MARGIN + (player - 1) * 200 + UIMargin * SCALE_X
      drawPlayerDebug(player, gamepad, xOffset)
    end
    if ShowBoundingBoxes then
      drawBoundingBox(spriteName)
    end
  end
  love.graphics.setCanvas(oldCanvas)
end

function resetPrintLine(startAt)
  NextLine = startAt or 0
end

function printLine(s, x)
  NextLine = NextLine + LINE_HEIGHT * 1.5
  love.graphics.print(s, x, NextLine)
end

return playing
