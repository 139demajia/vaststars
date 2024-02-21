local ecs = ...
local world = ecs.world
local w = world.w

local N <const> = 0
local E <const> = 1
local S <const> = 2
local W <const> = 3

local gameplay_core = require "gameplay.core"
local road_sys = ecs.system "road_system"
local iroad = {}

local iroadnet_converter = require "roadnet_converter"
local iroadnet = ecs.require "engine.roadnet"
local iprototype = require "gameplay.interface.prototype"

local gameplay = import_package "vaststars.gameplay"
local igameplay_building = gameplay.interface "building"

local function pack(x, y)
    return (y << 8)|x
end

local function unpack(coord)
    return coord & 0xFF, coord >> 8
end

local function open(m, dir)
    assert(m & (1 << dir) == 0)
    return m | (1 << dir)
end

local function close(m, dir)
    assert(m & (1 << dir) ~= 0)
    return m & ~(1 << dir)
end

local function check(m, dir)
    return (m & (1 << dir)) ~= 0
end

local function move(d)
    if d == N then
        return 0, -2
    elseif d == E then
        return 2, 0
    elseif d == S then
        return 0, 2
    elseif d == W then
        return -2, 0
    end
end

local function _update_road_shape(world, map, road_cache)
    local m
    for coord, mask in pairs(map) do
        m = mask
        local x, y = unpack(coord)
        for dir = 0, 3 do
            if check(m, dir) then
                local dx, dy = move(dir)
                dx, dy = x + dx, y + dy

                local neighbor_mask = map[pack(dx, dy)]
                if not neighbor_mask then
                    m = close(m, dir)
                end
            else
                local dx, dy = move(dir)
                dx, dy = x + dx, y + dy

                local neighbor_mask = map[pack(dx, dy)]
                if neighbor_mask then
                    m = open(m, dir)
                end
            end
        end

        if mask ~= m then
            map[coord] = m

            local e = assert(world:fetch_entity(road_cache[coord]))
            local prototype_name, dir = iroadnet_converter.mask_to_prototype_name_dir(m)

            igameplay_building.destroy(gameplay_core.get_world(), gameplay_core.get_entity(road_cache[coord]))
            local eid = igameplay_building.create(gameplay_core.get_world(), prototype_name)({
                x = e.building.x,
                y = e.building.y,
                dir = dir,
                road = true,
            })
            road_cache[coord] = eid
        end
    end
    return map
end

function road_sys:gameworld_prebuild()
    local road = {}
    local map = {}
    local world = gameplay_core.get_world()
    for e in world.ecs:select "road building:in eid:in REMOVED:absent" do
        local key = pack(e.building.x, e.building.y)
        map[key] = iroadnet_converter.prototype_name_dir_to_mask(iprototype.queryById(e.building.prototype).name, iprototype.dir_tostring(e.building.direction))
        road[key] = e.eid
    end
    _update_road_shape(world, map, road)
end

function road_sys:gameworld_build()
    local world = gameplay_core.get_world()

    iroadnet:clear("road")
    for e in world.ecs:select "road building:in REMOVED:absent" do
        local mask = iroadnet_converter.prototype_name_dir_to_mask(iprototype.queryById(e.building.prototype).name, iprototype.dir_tostring(e.building.direction))
        local shape, dir = iroadnet_converter.mask_to_shape_dir(mask)
        iroadnet:set("road", e.building.x, e.building.y, 0xffffffff, shape, dir)
    end
    iroadnet:flush()
end

function iroad.open(...)
    return open(...)
end

function iroad.check(...)
    return check(...)
end

return iroad
