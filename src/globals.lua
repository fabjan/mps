SCALE_X = 4
SCALE_Y = 4

PIXEL_WIDTH = 320
PIXEL_HEIGHT = 200

WINDOW_WIDTH  = PIXEL_WIDTH * SCALE_X
WINDOW_HEIGHT = PIXEL_HEIGHT * SCALE_Y

FONT_SIZE    = 8
LINE_HEIGHT  = FONT_SIZE + 2
SMALL_FONT   = love.graphics.newFont("PressStart2P.ttf", FONT_SIZE)
BIG_FONT     = love.graphics.newFont("PressStart2P.ttf", FONT_SIZE*2)
CONSOLE_FONT = BIG_FONT

CONSOLE_LINES = 20
CONSOLE_MARGIN = 4

LURK_LAG = 1

-- game parameters
LIKE_GRAVITY = -(PIXEL_HEIGHT*0.002)
JUMP_POWER   = PIXEL_HEIGHT/40
JUMP_HANG    = 2
AIR_DRAG     = 0.95

RUNNING_START   = PIXEL_WIDTH*0.002
RUNNING_ACCEL   = PIXEL_WIDTH*0.0004
RUNNING_MAX     = 4
RUNNING_EPSILON = 0.1
GROUND_DRAG     = 0.8

ATTACK_DURATION = 0.1
LIVES           = 5

-- standard CGA colors
COLOR_PALETTE = {
  {0x00/255, 0x00/255, 0x00/255},
  {0x55/255, 0x55/255, 0x55/255},
  {0x00/255, 0x00/255, 0xAA/255},
  {0x55/255, 0x55/255, 0xFF/255},
  {0x00/255, 0xAA/255, 0x00/255},
  {0x55/255, 0xFF/255, 0x55/255},
  {0x00/255, 0xAA/255, 0xAA/255},
  {0x55/255, 0xFF/255, 0xFF/255},
  {0xAA/255, 0x00/255, 0x00/255},
  {0xFF/255, 0x55/255, 0x55/255},
  {0xAA/255, 0x00/255, 0xAA/255},
  {0xFF/255, 0x55/255, 0xFF/255},
  {0xAA/255, 0x55/255, 0x00/255}, -- tweaked brown
  {0xFF/255, 0xFF/255, 0x55/255},
  {0xAA/255, 0xAA/255, 0xAA/255},
  {0xFF/255, 0xFF/255, 0xFF/255}
}

function displayCoord(y)
  return PIXEL_HEIGHT - y
end

-- djb2 hash from http://www.cse.yorku.ca/~oz/hash.html
function stringHash(s)
  local hash = 5381
  for i = 1, #s do
    hash = (hash * 33) + string.byte(s, i)
  end
  return hash
end

function stringColor(s)
  -- arrays are 1-indexed in Lua
  -- add one to avoid black, being the background color
  -- module length minus one to account for the extra one
  return COLOR_PALETTE[1 + 1 + stringHash(s) % (#COLOR_PALETTE - 1)]
end
