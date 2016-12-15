local anim8 = require "anim8"
local lume = require "lume"
local console = require "console"

local SpriteSheets = {}

local Animations = {
	gubbe = {}
}

local Sprites = {}

local sprites = {}

function sprites.load()
	local gubbe = love.graphics.newImage('gubbe.png')
  local spriteSize = 32
  
  SpriteSheets.gubbe = gubbe
  
	local grid = anim8.newGrid(spriteSize,spriteSize, gubbe:getWidth(),gubbe:getHeight(), 0,0, 1)
	Animations.gubbe.idle = anim8.newAnimation(grid('1-2',1), 0.1)
	Sprites.player = {
    x = 0, y = 0,
    dx = 0, dy = 0,
    ddx = 0, ddy = 0,
    width = spriteSize*0.6, height = spriteSize,
    xMargin = spriteSize*0.4/2,
    animations = "gubbe",
    animationState = "idle"
  }
  Sprites.robot = {}
  for k,v in pairs(Sprites.player) do
    Sprites.robot[k] = v
  end
  Sprites.robot.x = PIXEL_WIDTH/2
end

function sprites.get(spriteName, keys)
  local sprite = Sprites[spriteName]
  
  if lume.isarray(keys) then
    if not sprite then
      console.log("sprite "..spriteName.. " cannot be gotten")
      return {}
    end
    
    local result = {}
    for i, key in ipairs(keys) do
      result[key] = sprite[key]
    end
    return result
  else -- not array, assume one key was asked for
    if not sprite then
      console.log("sprite "..spriteName.. " cannot be gotten")
      return nil
    end
  
    return sprite[keys]
  end
end

function sprites.enumerate(spriteName)
  local sprite = Sprites[spriteName]
  local result = {}

  if not sprite then
    console.log("sprite "..spriteName.. " cannot be gotten")
    return result
  end
    
  for key, value in pairs(sprite) do
    result[key] = value
  end
  return result
end

function sprites.mutate(spriteName, newKeysAndValues)
  for key, value in pairs(newKeysAndValues) do
    Sprites[spriteName][key] = value
  end
end

function sprites.update(dt)
  for name, sprite in pairs(Sprites) do
    local animation = Animations[sprite.animations][sprite.animationState]
    animation:update(dt)
    sprite.dy = sprite.dy + sprite.ddy
    sprite.dx = sprite.dx + sprite.ddx
    sprite.y = sprite.y + sprite.dy
    sprite.x = sprite.x + sprite.dx
  end
end

function sprites.draw()
  for name, sprite in pairs(Sprites) do
    local animation = Animations[sprite.animations][sprite.animationState]
    animation:draw(SpriteSheets.gubbe, lume.round(sprite.x - sprite.xMargin), PIXEL_HEIGHT-lume.round(sprite.y)-sprite.height)
  end
end

return sprites