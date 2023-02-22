lurker = require "lurker"

LastLurk = 0
LurkingEnabled = false

reloader = {}

function reloader.update(dt)
  if not LurkingEnabled then return end
  
	LastLurk = LastLurk + dt
	if (LastLurk > LURK_LAG) then
		lurker.update()
	end
end

function reloader.enable()
  LurkingEnabled = true
end

function reloader.disable()
  LurkingEnabled = false
end

function reloader.toggle()
  LurkingEnabled = not LurkingEnabled
end

return reloader
