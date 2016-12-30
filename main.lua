require "globals"

-- some libs
local lume = require "lume"
local reloader = require "hot_reloading"

-- local libs
local keyboard = require "keyboard"
local sprites = require "sprites"
local sounds = require "sounds"

ShowFPS = false
ShowBoundingBoxes = false
ShowDebugInfo = false

-- Scenes
Scenes = {
  menu = require "scene_menu",
  playing = require "scene_playing",
  winning = require "scene_winning"
}
CurScene = "menu"

function love.load()
  math.randomseed(os.time())
  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
  love.graphics.setFont(CONSOLE_FONT)
    
  -- setup modules
  reloader.enable()
  sprites.load()
  sounds.load()
  keyboard.load()
  
  LowrezCanvas = love.graphics.newCanvas()
  LowrezCanvas:setFilter("nearest", "nearest")
  
  selectScene("menu")
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
  keyboard.keypressed(key)
end

function love.keyreleased(key)
  keyboard.keyreleased(key)
end

function selectScene(newName)
  local lastScene = Scenes[CurScene]
  if lastScene and lastScene.leave then lastScene.leave() end
  local newScene = Scenes[newName]
  CurScene = newName
  
  if not (newScene.init == nil) then
    newScene.init()
  end
  
  love.update = updateScene
  love.draw   = drawScene
end

function updateScene(dt)
  reloader.update(dt)
  if Scenes[CurScene] and Scenes[CurScene].update then
    local nextScene = Scenes[CurScene].update(dt)
    if nextScene then
      selectScene(nextScene)
    end
  end
end

function drawScene()
  love.graphics.setCanvas(LowrezCanvas)
  if Scenes[CurScene] and Scenes[CurScene].draw then
    Scenes[CurScene].draw()
  end
  love.graphics.setCanvas()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(LowrezCanvas, 0, 0, 0, SCALE, SCALE)
end
