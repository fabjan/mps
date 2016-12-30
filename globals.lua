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
RUNNING_EPSILON = 0.1
GROUND_DRAG     = 0.8

ATTACK_DURATION = 0.1
LIVES           = 5

COLOR_PALETTE = {     -- standard CGA colors
  {0x00, 0x00, 0x00}, --black
  {0x00, 0x00, 0xAA},
  {0x55, 0x55, 0xFF},
  {0x00, 0xAA, 0x00},
  {0x55, 0xFF, 0x55},
  {0x00, 0xAA, 0xAA},
  {0x55, 0xFF, 0xFF},
  {0xAA, 0x00, 0x00},
  {0xFF, 0x55, 0x55},
  {0xAA, 0x00, 0xAA},
  {0xFF, 0x55, 0xFF},
  {0xAA, 0x55, 0x00}, -- tweaked brown
  {0xFF, 0xFF, 0x55},
  {0xAA, 0xAA, 0xAA},
  {0xFF, 0xFF, 0xFF}
}

function displayCoord(y)
  return PIXEL_HEIGHT - y
end

function stringHash(s)
  local base = string.byte("A")
  local hash  = 0
  local radix = 1
  for i = 1, s:len(), 1 do
    hash = hash + (base - s:byte(i)) * radix
    radix = radix * 10
  end
  return hash
end

function stringColor(s)
  return COLOR_PALETTE[stringHash(s) % (#COLOR_PALETTE) + 1 + 1] -- avoid black, as it's the background color
end