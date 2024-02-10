local lume = require "vendor/lume"

RobotChangeDelay = 0.2  -- seconds

local robot = {}

function robot.init()
  RobotChangeTimer = 0
  RobotInputMap = {}
end

function robot.update(dt)
  RobotChangeTimer = RobotChangeTimer + dt
  if RobotChangeTimer > RobotChangeDelay then
    RobotChangeTimer = 0
    robotDoSomething()
  end
  return RobotInputMap
end

function robotDoSomething()
  local buttons = {
    --"jump",
    "rock",
    "paper",
    "scissors"
    --"left",
    --"right"
  }
  local actions = {"pressed", "released"}
  RobotInputMap[lume.randomchoice(buttons)] = lume.randomchoice(actions)
end

return robot
