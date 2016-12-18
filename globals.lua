SCALE = 4

PIXEL_WIDTH = 320
PIXEL_HEIGHT = 200

WINDOW_WIDTH  = PIXEL_WIDTH * SCALE
WINDOW_HEIGHT = PIXEL_HEIGHT * SCALE

FONT_SIZE = 14
LINE_HEIGHT = FONT_SIZE + 2
FONT_NAME = "MonospaceTypewriter.ttf"

CONSOLE_LINES = 5
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

PLAYER_COLORS = {     -- standard CGA colors, without black
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
