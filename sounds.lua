local console = require "console"

local sounds = {}

local testFile = "song_0.mp3"

local Sounds = {}

function sounds.load()
  Sounds.test = love.audio.newSource(testFile, "stream")
end

function sounds.update(dt)
  -- scheduling for sounds ?
end

function sounds.play(soundName, loop)
  local sound = Sounds[soundName]
  if not sound then
    console.log("sound", soundName, "not found")
    return
  end
  if loop then
    sound:setLooping(true)
  end
  console.log("playing sound", soundName, "looping:", loop)
  sound:play()
end

return sounds