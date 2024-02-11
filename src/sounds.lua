local sfxr = require "vendor/sfxr"

local console = require "console"

local sounds = {}

local SongFiles = {
  song0 = "song_0.mp3",
  song1 = "song_1.mp3"
}

local Sounds = {}

function sounds.load()
  for trackName, fileName in pairs(SongFiles) do
    Sounds[trackName] = love.audio.newSource(fileName, "stream")
  end
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
  sound:play()
end

function sounds.stop(soundName)
  local sound = Sounds[soundName]
  if not sound then
    console.log("sound", soundName, "not found")
    return
  end
  sound:stop()
end

function sounds.playRandom(soundType, volume)
  volume = colume or 1
  local sfx = sfxr.newSound()
  sfx["random"..soundType](sfx)
  local soundData = sfx:generateSoundData()
  local src = love.audio.newSource(soundData)
  src:setVolume(volume)
  src:play()
end

return sounds
