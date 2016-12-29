local sounds = require "sounds"

WINNING_FONT           = BIG_FONT 
WINNING_TEXT_Y         = PIXEL_HEIGHT*0.1
WINNING_TEXT_XCENTER   = PIXEL_WIDTH/2
WINNING_TEXT_MAX_XDIFF = 10

local winning = {}

WinScreen = love.graphics.newImage("win.png")

function winning.init()
  sounds.play("song0", true)
  WinningText = Winner .. " HAS WON"
  WinningTextWidth = WINNING_FONT:getWidth(WinningText)
end

function winning.update(dt)
  WinningTextX = WINNING_TEXT_XCENTER - WinningTextWidth/2 + math.sin(love.timer.getTime()*2)*WINNING_TEXT_MAX_XDIFF
  return nil
end

function winning.draw()
  love.graphics.setFont(WINNING_FONT)
  love.graphics.clear()
  love.graphics.setColor(stringColor(Winner))
  love.graphics.draw(WinScreen)
  love.graphics.print(WinningText, WinningTextX, WINNING_TEXT_Y)
end

return winning