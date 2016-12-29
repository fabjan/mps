local sounds = require "sounds"

MENU_TEXT    = "PRESS THE ANY KEY"
MENU_FONT    = BIG_FONT
MENU_TEXT_X  = PIXEL_WIDTH/2 - MENU_FONT:getWidth(MENU_TEXT)/2
MENU_TEXT_Y  = PIXEL_HEIGHT*0.8
MENU_TEXT_DY = 5

local menu = {}

SplashScreen = love.graphics.newImage("splash.png")

function menu.init()
  sounds.play("song0", true)
  MenuTextY = MENU_TEXT_Y
end

function menu.update(dt)
  local nextScene = nil
  MenuTextY = MENU_TEXT_Y + math.sin(love.timer.getTime()*2)*MENU_TEXT_DY
  if love.keyboard.isDown("space") then
    nextScene = "playing"
  end
  return nextScene
end

function menu.draw()
  love.graphics.setFont(MENU_FONT)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(SplashScreen)
  love.graphics.print(MENU_TEXT, MENU_TEXT_X, MenuTextY)
end

function menu.leave()
  sounds.stop("song0")
end

return menu