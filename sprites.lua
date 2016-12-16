local anim8 = require "anim8"
local lume = require "lume"
local console = require "console"

local SpriteSheets = {}

local Animations = {
	gubbe = {}
}

local Prototypes = {}

local Sprites = {}

local sprites = {}

function sprites.create(name, prototype)
  local newSprite = {}
  for k,v in pairs(Prototypes[prototype]) do
    newSprite[k] = v
  end
  Sprites[name] = newSprite
end

local Animations = {
  gubbe = {
    idle    = { cols = '1-2', rows = 1, delay = 0.8},
    jumping = { cols =    1 , rows = 1, delay = 1  },
    hurt    = { cols =    1 , rows = 1, delay = 1  },
    attack  = { cols =    1 , rows = 1, delay = 0.2}
  }
}

function sprites.load()
  local spriteSize = 32

  for animName, animStates in pairs(Animations) do
    for stateName, frameInfo in pairs(animStates) do
      local stateKey = animName.."_"..stateName
      local img = love.graphics.newImage(stateKey..".png")
	    local grid = anim8.newGrid(spriteSize,spriteSize, img:getWidth(),img:getHeight(), 0,0)
      SpriteSheets[animName.."_"..stateName] = img
	    Animations[animName][stateName] = anim8.newAnimation(grid(frameInfo.cols, frameInfo.rows), frameInfo.delay)
    end
  end
  
	Prototypes.player = {
    x              = PIXEL_WIDTH/2,
    y              = PIXEL_HEIGHT-spriteSize,
    dx             = 0,
    dy             = 0,
    ddx            = 0,
    ddy            = 0,
    width          = spriteSize*0.6, height = spriteSize,
    xMargin        = spriteSize*0.4/2,
    color          = {255, 255, 255},
    animations     = "gubbe",
    animationState = "idle",
    flipX          = false
  }
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

function sprites.getRect(spriteName)
  local sprite = Sprites[spriteName]
  if not sprite then return nil end
  
  return {
    x = sprite.x,
    y = sprite.y,
    w = sprite.width,
    h = sprite.height
  }
end

function sprites.getFeet(spriteName)
  local sprite = Sprites[spriteName]
  if not sprite then return nil end
  
  return {
    x = sprite.x,
    y = sprite.y,
    w = sprite.width,
    h = 1
  }
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
    if sprite.color then
      love.graphics.setColor(sprite.color)
    else
      love.graphics.setColor(255, 255, 255)
    end
    local animation = Animations[sprite.animations][sprite.animationState]
    local displayY = displayCoord(lume.round(sprite.y))-sprite.height
    local flipXScale = 1
    local flipXOffset = 0
    if sprite.flipX then flipXScale = -1 end
    if sprite.flipX then flipXOffset = sprite.width + 2*sprite.xMargin end
    animation:draw(SpriteSheets[sprite.animations.."_"..sprite.animationState], lume.round(sprite.x - sprite.xMargin + flipXOffset), displayY, 0, flipXScale, 1)
  end
end

return sprites