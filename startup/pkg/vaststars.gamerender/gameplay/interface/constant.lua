local math3d = require "math3d"
local mathpkg = import_package"ant.math"
local mc = mathpkg.constant

local DIRECTION <const> = {
    N = 0,
    E = 1,
    S = 2,
    W = 3,
    [0] = 0, -- TODO: remove this
    [1] = 1,
    [2] = 2,
    [3] = 3,
}

local M = {}
M.MAP_WIDTH = 256
M.MAP_HEIGHT = 256
M.MAP_OFFSET = M.MAP_WIDTH // 2
M.SURFACE_HEIGHT = 0
M.TILE_SIZE = 10
M.ROAD_SIZE = 2
M.ROAD_WIDTH = M.TILE_SIZE * M.ROAD_SIZE
M.ROAD_HEIGHT = M.TILE_SIZE * M.ROAD_SIZE
M.ALL_DIR = {'N', 'S', 'W', 'E'}
M.ALL_DIR_NUM = {0, 1, 2, 3}
M.DEFAULT_DIR = 'N'
M.DIRECTION = DIRECTION
M.DIR_MOVE_DELTA = {
    ['N'] = {x = 0,  y = -1},
    ['E'] = {x = 1,  y = 0},
    ['S'] = {x = 0,  y = 1},
    ['W'] = {x = -1, y = 0},
    [DIRECTION.N] = {x = 0,  y = -1},
    [DIRECTION.E] = {x = 1,  y = 0},
    [DIRECTION.S] = {x = 0,  y = 1},
    [DIRECTION.W] = {x = -1, y = 0},
}
M.ROTATORS = {
    N = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(0)})   )),
    E = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(90)})  )),
    S = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(180)}) )),
    W = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(270)}) )),

    [DIRECTION.N] = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(0)})   )), -- TODO: remove
    [DIRECTION.E] = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(90)})  )),
    [DIRECTION.S] = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(180)}) )),
    [DIRECTION.W] = math3d.constant( math3d.totable(math3d.quaternion({axis=mc.YAXIS, r=math.rad(270)}) )),
}
M.FPS = 30
M.UPS = 30
M.DELTA_TIME = 1000 / M.UPS

M.DuskTick   = 100 * M.UPS;
M.NightTick  =  50 * M.UPS + M.DuskTick;
M.DawnTick   = 100 * M.UPS + M.NightTick;
M.DayTick    = 250 * M.UPS + M.DawnTick;

M.CHANGED_FLAG_ASSEMBLING = 1 << 0
M.CHANGED_FLAG_BUILDING   = 1 << 1
M.CHANGED_FLAG_CHIMNEY    = 1 << 2
M.CHANGED_FLAG_ROADNET    = 1 << 3
M.CHANGED_FLAG_FLUIDFLOW  = 1 << 4
M.CHANGED_FLAG_ALL = M.CHANGED_FLAG_ASSEMBLING | M.CHANGED_FLAG_BUILDING | M.CHANGED_FLAG_CHIMNEY | M.CHANGED_FLAG_ROADNET | M.CHANGED_FLAG_FLUIDFLOW

M.IN_FLUIDBOXES = {
    {fluid = "in1_fluid", id = "in1_id"},
    {fluid = "in2_fluid", id = "in2_id"},
    {fluid = "in3_fluid", id = "in3_id"},
    {fluid = "in4_fluid", id = "in4_id"},
}
M.OUT_FLUIDBOXES = {
    {fluid = "out1_fluid", id = "out1_id"},
    {fluid = "out2_fluid", id = "out2_id"},
    {fluid = "out3_fluid", id = "out3_id"},
}

return M