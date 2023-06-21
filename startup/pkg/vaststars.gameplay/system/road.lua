local system = require "register.system"
local prototype = require "prototype"
local query = prototype.queryById

local ROAD_TILE_WIDTH_SCALE <const> = 2
local ROAD_TILE_HEIGHT_SCALE <const> = 2

local m = system "road"

local mt = {}
mt.__index = function (t, k)
    t[k] = setmetatable({}, mt)
    return t[k]
end

local function is_roadid(pt)
    for _, t in ipairs(pt.type) do
        if t == "road" then
            return true
        end
    end
    return false
end

local roadbits = setmetatable({}, mt)
local roadbits_rev = setmetatable({}, mt)

local Direction <const> = {
    ["N"] = 0,
    ["E"] = 1,
    ["S"] = 2,
    ["W"] = 3,
}

local N <const> = 0
local E <const> = 1
local S <const> = 2
local W <const> = 3

-- see also clibs\gameplay\src\roadnet\network.cpp - enum class MapRoad
local MapRoad <const> = {
    Left         = 1 << 0,
    Top          = 1 << 1,
    Right        = 1 << 2,
    Bottom       = 1 << 3,
    Endpoint     = 1 << 4,
    NoHorizontal = 1 << 5,
    NoVertical   = 1 << 6,
}

-- see also clibs\gameplay\src\roadnet\type.h - enum class direction
local RoadDirection = {
    l = 0,
    t = 1,
    r = 2,
    b = 3,
}

local DirectionToMapRoad <const> = {
    [N] = RoadDirection.t,
    [E] = RoadDirection.r,
    [S] = RoadDirection.b,
    [W] = RoadDirection.l,
}

local function pack(x, y)
    return (y << 8)|x
end

local function unpack(coord)
    return coord & 0xFF, coord >> 8
end

local function rotate(position, direction, area)
    local w, h = area >> 8, area & 0xFF
    local x, y = position[1], position[2]
    w = w - 1
    h = h - 1
    if direction == N then
        return x, y
    elseif direction == E then
        return h - y, x
    elseif direction == S then
        return w - x, h - y
    elseif direction == W then
        return y, w - x
    end
end

local function calc_roadbits(pt, direction)
    local bits = 0
    for _, c in ipairs(pt.crossing.connections) do
        local dir = (Direction[c.position[3]] + direction) % 4
        bits = bits | (1 << (DirectionToMapRoad[dir]))
    end
    return bits
end

local function open(bits, dir)
    return bits | (1 << (DirectionToMapRoad[dir]))
end

local function close(bits, dir)
    assert(bits & (1 << (DirectionToMapRoad[dir])) ~= 0)
    return bits & ~(1 << (DirectionToMapRoad[dir]))
end

local function check(bits, dir)
    return (bits & (1 << (DirectionToMapRoad[dir]))) ~= 0
end

local function build_road(world, building, map, eid_cache)
    local ecs = world.ecs
    local pt = query(building.prototype)

    local affected_roads_mask = 0
    if building.direction == N or building.direction == S then
        affected_roads_mask = MapRoad.NoVertical
    else
        affected_roads_mask = MapRoad.NoHorizontal
    end

    for _, e in ipairs(pt.affected_roads) do
        local dx, dy = rotate(e.position, building.direction, pt.area)
        dx, dy = building.x + dx, building.y + dy
        local mapkey = pack(dx//ROAD_TILE_WIDTH_SCALE, dy//ROAD_TILE_HEIGHT_SCALE)
        local key = pack(dx//ROAD_TILE_WIDTH_SCALE*ROAD_TILE_WIDTH_SCALE, dy//ROAD_TILE_HEIGHT_SCALE*ROAD_TILE_HEIGHT_SCALE) -- TODO: optimize
        if not map[mapkey] then
            goto continue
        end

        local dir = (Direction[e.dir] + building.direction) % 4
        map[mapkey] = open(map[mapkey], dir)
        map[mapkey] = map[mapkey] | affected_roads_mask

        local eid = assert(eid_cache[key])
        local e = assert(world.entity[eid])
        local pt = prototype.queryById(e.building.prototype)
        local f = roadbits_rev[pt.building_category][map[mapkey] & 0xf]
        e.building.prototype = f.prototype
        e.building.direction = f.direction
        e.building_changed = true
        ::continue::
    end

    for _, e in ipairs(pt.endpoint_road) do
        local dx, dy = rotate(e.position, building.direction, pt.area)
        dx, dy = building.x + dx, building.y + dy
        local mapkey = pack(dx//ROAD_TILE_WIDTH_SCALE, dy//ROAD_TILE_HEIGHT_SCALE)
        local key = pack(dx, dy)
        local pt = prototype.queryByName(e.prototype) -- TODO remove e.prototype

        assert(not map[mapkey])
        local dir = (Direction[e.dir]+ building.direction) % 4
        map[mapkey] = roadbits[pt.id][dir]
        for _, m in ipairs(e.mask) do
            map[mapkey] = map[mapkey] | MapRoad[m]
        end

        assert(rawget(roadbits_rev, pt.building_category) ~= nil)
        assert(rawget(roadbits_rev[pt.building_category], map[mapkey] & 0xf) ~= nil)
        local f = roadbits_rev[pt.building_category][map[mapkey] & 0xf]
        eid_cache[key] = ecs:new {
            building = {
                x = dx,
                y = dy,
                prototype = f.prototype,
                direction = f.direction,
            },
            road = true,
            endpoint_road = true,
            building_changed = true,
        }
    end
end

function m.prototype_restore(world)
    roadbits = setmetatable({}, mt)
    roadbits_rev = setmetatable({}, mt)

    for _, pt in pairs(prototype.all()) do
        if is_roadid(pt) then
            for _, dir in pairs(pt.building_direction) do
                local bits = calc_roadbits(pt, Direction[dir])
                assert(rawget(roadbits[pt.id], dir) == nil)
                roadbits[pt.id][Direction[dir]] = bits

                assert(rawget(roadbits_rev[pt.building_category], bits) == nil)
                roadbits_rev[pt.building_category][bits] = { prototype = pt.id, direction = Direction[dir] }
            end
        end
    end
end

local function move(d)
    if d == N then
        return 0, -1
    elseif d == E then
        return 1, 0
    elseif d == S then
        return 0, 1
    elseif d == W then
        return -1, 0
    end
end

local function reverse(d)
    if d == N then
        return S
    elseif d == E then
        return W
    elseif d == S then
        return N
    elseif d == W then
        return E
    end
end

local function repair(world, map, eid_cache)
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
                else
                    if not check(neighbor_mask, reverse(dir)) then
                        m = close(m, dir)
                    end
                end
            end
        end

        if mask ~= m then
            map[coord] = m

            local x, y = unpack(coord)
            local key = pack(x*ROAD_TILE_WIDTH_SCALE, y*ROAD_TILE_HEIGHT_SCALE)
            local e = assert(world.entity[eid_cache[key]])
            local pt = assert(prototype.queryById(e.building.prototype))
            local f = roadbits_rev[pt.building_category][map[coord] & 0xf]

            e.building.prototype = f.prototype
            e.building.direction = f.direction
            e.building_changed = true
        end
    end
    return map
end

local DIRTY_ROADNET <const> = 1 << 4

function m.build(world)
    local ecs = world.ecs

    if world._dirty & DIRTY_ROADNET == 0 then
        return
    end

    local map = {}
    local eid_cache = {}

    for v in ecs:select "endpoint_road:in eid:in" do
        ecs:remove(v.eid)
    end

    for v in ecs:select "road:in building:in eid:in REMOVED:absent" do
        local key =  pack(v.building.x, v.building.y)
        local mapkey = pack(v.building.x//ROAD_TILE_WIDTH_SCALE, v.building.y//ROAD_TILE_HEIGHT_SCALE)
        map[mapkey] = roadbits[v.building.prototype][v.building.direction]
        eid_cache[key] = v.eid
    end

    for v in ecs:select "endpoint building:in eid:in" do
        build_road(world, v.building, map, eid_cache)
    end

    map = repair(world, map, eid_cache)
    world:roadnet_reset(map)
end