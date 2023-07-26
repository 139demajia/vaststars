local UNIT <const> = 10
local BORDER <const> = 5
local MAP_WIDTH <const> = 256
local MAP_HEIGHT <const> = 256
local WIDTH <const> = MAP_WIDTH + BORDER * 2
local HEIGHT <const> = MAP_HEIGHT + BORDER * 2
local OFFSET <const> = WIDTH // 2
assert(OFFSET == HEIGHT // 2)

local MIN_X <const> = -BORDER + 1
local MAX_X <const> = MAP_WIDTH + BORDER
local MIN_Y <const> = -BORDER + 1
local MAX_Y <const> = MAP_HEIGHT + BORDER

density = 0.3

mountain_coords = {
    {MIN_X, MIN_Y, WIDTH, BORDER},
    {MIN_X, MIN_Y + BORDER, BORDER, HEIGHT - BORDER * 2},
    {MAX_X - BORDER + 1, MIN_Y + BORDER, BORDER, HEIGHT - BORDER * 2},
    {MIN_X, MAX_Y - BORDER + 1, WIDTH, BORDER},
    {153,101, 1, 1},
    {97,113, 1, 1},
    {92,110, 1, 1},
    {84,109, 1, 1},
    ------------------------------------
    {145,139, 2, 2},
    {146,139, 2, 2},
    {145,140, 2, 2},
    {146,140, 2, 2},
    {146,138, 2, 2},
    {145,141, 2, 2},
    {145,137, 2, 2},
    {144,140, 2, 2},
    {144,139, 2, 2},
    ------------------------------------
    {146,143, 2, 2},
    {147,143, 2, 2},
    {148,144, 2, 2},
    {149,144, 2, 2},
    {150,145, 2, 2},
    {149,145, 2, 2},
    {150,146, 2, 2},
    {149,146, 2, 2},
    ------------------------------------
    {73,159, 2, 2},
    {72,159, 2, 2},
    {74,160, 2, 2},
    {74,161, 2, 2},
    {73,160, 2, 2},
    {73,161, 2, 2},
    {75,159, 2, 2},
    {75,160, 2, 2},
    {74,159, 2, 2},
    {74,158, 2, 2},
    ------------------------------------
    {91,109, 2, 2},
    {90,109, 2, 2},
    {90,110, 2, 2},
    {91,110, 1, 1},
    {91,111, 2, 2},
    {90,111, 2, 2},
    ------------------------------------
    {96,112, 2, 2},
    {95,112, 2, 2},
    {95,113, 1, 1},
    ------------------------------------
    {114,70, 3, 3},
    {113,70, 3, 3},
    {115,69, 3, 3},
    ------------------------------------
    {187,177, 5, 5},
    {190,180, 3, 3},
    {196,184, 2, 2},
    ------------------------------------
    {173,62, 1, 1},
    {172,61, 1, 1},
    {172,62, 2, 2},
    {173,61, 2, 2},
    ------------------------------------
    {144,71, 1, 1},
    {143,71, 2, 2},
    {144,72, 1, 1},
    {143,72, 3, 3},
    ------------------------------------
    {186,44, 1, 1},
    {186,43, 2, 2},
    {184,42, 3, 3},
    {183,41, 2, 2},
    ------------------------------------
    {112,41, 1, 1},
    {113,43, 2, 2},
    {114,42, 3, 3},
    {115,41, 2, 2},
    ------------------------------------
    {89,234, 1, 1},
    {90,233, 2, 2},
    {91,235, 3, 3},
    {92,232, 2, 2},
    ------------------------------------
    {208,234, 1, 1},
    {209,233, 2, 2},
    {210,235, 3, 3},
    {211,232, 2, 2},
    ------------------------------------
    {170,220, 1, 1},
    {171,219, 2, 2},
    {172,221, 3, 3},
    {173,218, 2, 2},
    {174,220, 1, 1},
    ------------------------------------
    {143,50, 1, 1},
    {144,49, 2, 2},
    {145,51, 3, 3},
    {146,48, 2, 2},
    {147,50, 1, 1},
    ------------------------------------
    {177,95, 1, 1},
    {178,94, 2, 2},
    {179,96, 3, 3},
    {180,93, 2, 2},
    {181,95, 1, 1},
}

-- the first two numbers represent the x and y coordinates of the upper-left corner of the rectangle
-- the last two numbers represent the width and height of the rectangle
excluded_rects = {
    {29, 89, 187, 116},
    {92, 45, 118, 72},
    {85, 25, 111, 45},
    {29, 63, 52, 81},
    {14, 14, 33, 29},
    {150, 211, 172, 218},
    {44, 219, 68, 235},
}
