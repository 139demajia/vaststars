local ecs = ...
local world = ecs.world
local w = world.w

local iroad = ecs.require "engine.road"
local iroadnet_converter = require "roadnet_converter"
local CONSTANT <const> = require "gameplay.interface.constant"

local iterrain  = ecs.require "ant.landform|terrain_system"
local RENDER_LAYER <const> = ecs.require "engine.render_layer".RENDER_LAYER

local roadnet = {}

-- logic axis
-- ┌──►x
-- │
-- │
-- ▼
-- y

-- render axis
-- z
-- ▲
-- │
-- │
-- └──►x

local function __pack(x, y)
    assert(x & 0xFF == x and y & 0xFF == y)
    return x | (y<<8)
end

local function __unpack(coord)
    return coord & 0xFF, coord >> 8
end
---------------------------------------------------------

local LAYER_NAMES <const> = {"road", "indicator"}
function roadnet:create()
    iterrain.gen_terrain_field(CONSTANT.MAP_WIDTH, CONSTANT.MAP_HEIGHT, CONSTANT.MAP_OFFSET, CONSTANT.TILE_SIZE, RENDER_LAYER.TERRAIN)
end

-- map = {coord = {x, y, shape_type, shape, dir}, ...}
function roadnet:init(map)
    local res = {}
    for coord, v in pairs(map) do
        local x, y = __unpack(coord)
        res[#res + 1] = {x, y, v[3], v[4], v[5]}
    end
    iroad:init("road", res)
end

function roadnet:clear(layer_name)
    self._layer_cache = self._layer_cache or {}
    for coord in pairs(self._layer_cache[layer_name] or {}) do
        local x, y = __unpack(coord)
        iroad:del(layer_name, x, y)
    end
    self._layer_cache[layer_name] = {}
end

function roadnet:update()
    iroad:flush()
end

function roadnet:set(layer_name, shape_state, x, y, mask)
    local shape, dir = iroadnet_converter.mask_to_shape_dir(mask)
    iroad:set(layer_name, shape_state, x, y, shape, dir)

    self._layer_cache[layer_name] = self._layer_cache[layer_name] or {}
    self._layer_cache[layer_name][__pack(x, y)] = true
end

function roadnet:del(layer_name, x, y)
    iroad:del(layer_name, x, y)
    self._layer_cache[layer_name][__pack(x, y)] = nil
end

return roadnet