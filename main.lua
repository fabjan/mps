require "globals"

-- some libs

local lume = require "lume"

-- my things

local console = require "console"
local reloader = require "hot_reloading"
local controllers = require "controllers"
local netgamepads = require "netgamepads"
local sprites = require "sprites"
local sounds = require "sounds"

-- here we go

local NextLine = 0
ShowFPS = false
ShowBoundingBoxes = false
ShowDebugInfo = false

MonkeyLives = false  -- Number 5 is alive!
RobotChangeTimer = 0
RobotChangeDelay = 0.2  -- seconds
RobotInputMap = {}

NameChoices = require "usr_share_dict_words"
ColorChoices = lume.shuffle(PLAYER_COLORS)

-- Some rules
Beats = {
  rock     = { scissors = true },
  paper    = { rock     = true },
  scissors = { paper    = true }
}

-- Scenes
Scenes = {
  menu = {},
  playing = {},
  winning = {}
}
CurScene = nil

-- Static things
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

function love.load()
  math.randomseed(os.time())
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
  love.graphics.setFont(CONSOLE_FONT)
  
  SplashScreen = love.graphics.newImage("splash.png")
  WinScreen = love.graphics.newImage("win.png")
  MenuTextY = PIXEL_HEIGHT*0.8
  
  -- setup modules
  reloader.enable()
  sprites.load()
  sounds.load()
  netgamepads.load()
  
  -- setup internals
  if MonkeyLives then
    sprites.create("robot", "player")
    sprites.create("robothand", "attack")
    Hands["robot"] = "robothand"
    Lives["robot"] = 5
    Score["robot"] = 0
    Tag["robot"]   = "BOT"
    Color["robot"] = { 0xFF, 0xFF, 0xFF }
    sprites.mutate("robot", {x = lume.random(0, PIXEL_WIDTH), tag = "BOT"})
    lume.push(Falling, "robot")
    lume.push(Fallers, "robot")
    lume.push(Players, "robot")
  end
  
  LowrezCanvas = love.graphics.newCanvas()
  LowrezCanvas:setFilter("nearest", "nearest")
  
  selectScene("menu")
end

function selectScene(newName)
  local lastScene = Scenes[CurScene]
  if lastScene and lastScene.leave then lastScene.leave() end
  local newScene = Scenes[newName]
  CurScene = newName
  
  if not (newScene.init == nil) then
    newScene.init()
  end
  
  love.update = newScene.update
  love.draw   = newScene.draw
end

function Scenes.menu.init()
  sounds.play("song0", true)
end

function Scenes.menu.leave()
  sounds.stop("song0")
end


function Scenes.playing.init()
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

  ColorChoices = lume.shuffle(PLAYER_COLORS)
  
  sounds.play("song1", true)
end

function Scenes.playing.leave()
  sounds.stop("song1")
end

function Scenes.menu.update(dt)
  MenuTextY = PIXEL_HEIGHT*0.8+math.sin(love.timer.getTime()*2)*5
  if love.keyboard.isDown("space") then
    selectScene("playing")
  end
end

function Scenes.menu.draw()
  local menuText = "PRESS THE ANY KEY"
  local menuFont = BIG_FONT
  local menuTextX = PIXEL_WIDTH/2-menuFont:getWidth(menuText)/2
  love.graphics.setFont(menuFont)
  love.graphics.setCanvas(LowrezCanvas)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(SplashScreen)
  love.graphics.print(menuText, menuTextX, MenuTextY)
  love.graphics.setCanvas()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(LowrezCanvas, 0, 0, 0, SCALE, SCALE)
end

function Scenes.winning.init()
  sounds.play("song0", true)
end

function Scenes.winning.update(dt)
  WinningTextY = PIXEL_HEIGHT*0.2+math.sin(love.timer.getTime()*2)*5
end

function Scenes.winning.draw()
  local winningFont = BIG_FONT
  local winningTextX = PIXEL_WIDTH/2 - BIG_FONT:getWidth(Winner)
  love.graphics.setFont(winningFont)
  love.graphics.setCanvas(LowrezCanvas)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(WinScreen)
  love.graphics.print(Winner, winningTextX, WinningTextY)
  love.graphics.setCanvas()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(LowrezCanvas, 0, 0, 0, SCALE, SCALE)
end

function Scenes.playing.update(dt)
  reloader.update(dt)
  netgamepads.update(dt)
  controllers.update(dt)
  
  for playerNo, gamepad in controllers.enumerate() do
    local inputState = controllers.inputState(playerNo)
    local playerName = "player"..playerNo
    local handName = "hand"..playerNo
    if not lume.find(Players, playerName) and not lume.find(Dead, playerName) then
      sprites.create(playerName, "player")
      sprites.create(handName, "attack")
      local playerColor = ColorChoices[playerNo % 14 + 1]
      local playerTag = randomName()
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

  --sounds.update(dt)
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
  if table.getn(Players) == 1 and table.getn(Dead) > 0 then
    Winner = Tag[Players[1]]
    selectScene("winning")
  end
end

function jazzHands()
  for i, playerName in ipairs(Players) do
    local handName = Hands[playerName]
    local playerInfo = sprites.get(playerName, {"x", "y", "flipX", "width", "height", "xMargin"})
    local newFlipX = playerInfo.flipX
    local xOffset = playerInfo.width   * 1.1
    local yOffset = playerInfo.height  * 0.46
    if newFlipX then xOffset = -xOffset end
    local newX = playerInfo.x + playerInfo.xMargin/4 + xOffset  -- /4 ought to be enough for anyone
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
        local attackB = ((Attacks[defender] or {})[agressor] or {}).attackType
        if attackA == attackB then
          resolveDraw(agressor, defender)
        elseif Beats[attackA][attackB] then
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
  sounds.playRandom("Hit")
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
  -- Holy Leaky Abstraction Batman, how will this EVER pass review!?
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
  sounds.playRandom("Hit")
  sprites.mutate(spriteName, {dy = 0, ddy = 0, animationState = "idle"})
  lume.remove(Falling, spriteName)
end

function actOnInput(spriteName, inputState)
  local isFalling = lume.find(Falling, spriteName)
  local spriteInfo = sprites.get(spriteName, {"dx", "ddx", "dy"})

  -- jumping
  if inputState.jump == "pressed" and not isFalling then
    sounds.playRandom("Jump")
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
  end
  if (not attacking) and (inputState.rock == "released" or inputState.paper == "released" or inputState.scissors == "released") then
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
  local newName = string.upper(lume.randomchoice(NameChoices))
  if not lume.find(Names, newName) then
    return newName
  else
    if tries == nil then tries = 3 end
    if tries <= 0 then return "BOB" end
    return randomName(tries - 1)
  end
end

function love.keypressed(key)
  if key == "tab" then
    console.toggle()
  elseif key == "d" then
    ShowDebugInfo = not ShowDebugInfo
  elseif key == "f" then
    ShowFPS = not ShowFPS
  elseif key == "b" then
    ShowBoundingBoxes = not ShowBoundingBoxes
  elseif key == "escape" then
    selectScene("menu")
  end
end

function robotDoSomething()
  local buttons = {
    --"jump",
    --"rock",
    "paper"
    --"scissors",
    --"left",
    --"right"
  }
  local actions = {"pressed", "released"}
  RobotInputMap[lume.randomchoice(buttons)] = lume.randomchoice(actions)
end

function updateRobotInput()
  RobotInputMap["jump"] = nil
end

function Scenes.playing.draw()
  if ShowDebugInfo or ShowBoundingBoxes then
    love.graphics.setFont(CONSOLE_FONT)
    love.graphics.setColor(255, 255, 255)
    local xOffset
    local consoleBottom = LINE_HEIGHT * CONSOLE_LINES
    
    if ShowDebugInfo and MonkeyLives then
      love.graphics.setColor(255, 255, 255)
      NextLine = LINE_HEIGHT * CONSOLE_LINES
      xOffset = 550
      printLine("robot", xOffset)
      for k, v in pairs(sprites.enumerate("robot")) do
        printLine(k .. ": " .. tostring(v), xOffset + CONSOLE_MARGIN*2)
      end
    end
    for player, gamepad in controllers.enumerate() do
      local spriteName = "player"..player
      if ShowDebugInfo then
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
      end
      if ShowBoundingBoxes then
        local r = sprites.getRect(spriteName)
        love.graphics.setColor(0, 255, 0)
        love.graphics.rectangle("line", r.x*SCALE, displayCoord(r.y)*SCALE, r.w*SCALE, -r.h*SCALE)
        local f = sprites.getFeet(spriteName)
        love.graphics.setColor(255, 0, 255)
        love.graphics.rectangle("line", f.x*SCALE, displayCoord(f.y)*SCALE, f.w*SCALE, -f.h*SCALE)
        local h = sprites.getRect(Hands[spriteName], true)
        if h then
          love.graphics.setColor(0, 255, 255)
          love.graphics.rectangle("line", h.x*SCALE, displayCoord(h.y)*SCALE, h.w*SCALE, -h.h*SCALE)
        end
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

  -- What are the scores George Dawes?
  local scores = {}
  for name, score in pairs(Score) do
    lume.push(scores, {name, score})
  end
  local yOff = LINE_HEIGHT
  love.graphics.setColor(0x55, 0x55, 0x55)
  love.graphics.rectangle("fill", 0, 0, UIMargin, PIXEL_HEIGHT)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("HIGH SCORE", CONSOLE_MARGIN, yOff)
  for i, nameAndScore in ipairs(lume.sort(scores, function(a, b) return a[2] > b[2] end)) do
    local playerName = nameAndScore[1]
    local score = nameAndScore[2]
    local tag = Tag[playerName]
    if lume.find(Dead, playerName) then tag = "†"..tag else tag = " "..tag end
    love.graphics.setColor(Color[playerName])
    yOff = yOff + LINE_HEIGHT
    love.graphics.print(tag..": "..tostring(score), CONSOLE_MARGIN, yOff)
  end
  love.graphics.setCanvas()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(LowrezCanvas, 0, 0, 0, SCALE, SCALE)

  -- debug things
  console.draw()
  if ShowFPS then
    love.graphics.setFont(CONSOLE_FONT)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), WINDOW_WIDTH - 100, LINE_HEIGHT)
  end
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
