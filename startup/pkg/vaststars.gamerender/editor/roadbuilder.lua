local ecs = ...
local world = ecs.world

local create_builder = ecs.require "editor.builder"
local iprototype = require "gameplay.interface.prototype"
local packcoord = iprototype.packcoord
local unpackcoord = iprototype.unpackcoord
local iconstant = require "gameplay.interface.constant"
local ALL_DIR = iconstant.ALL_DIR
local iobject = ecs.require "object"
local iflow_connector = require "gameplay.interface.flow_connector"
local objects = require "objects"
local terrain = ecs.require "terrain"
local math_abs = math.abs
local math_min = math.min
local math_max = math.max
local EDITOR_CACHE_NAMES = {"TEMPORARY", "CONFIRM", "CONSTRUCTED"}
local task = ecs.require "task"
local iroadnet_converter = require "roadnet_converter"
local igrid_entity = ecs.require "engine.grid_entity"
local coord_system = ecs.require "terrain"
local iroadnet = ecs.require "roadnet"
local math3d = require "math3d"
local gameplay_core = require "gameplay.core"
local create_pickup_selected_box = ecs.require "editor.common.pickup_selected_box"
local ROTATORS <const> = require("gameplay.interface.constant").ROTATORS
local GRID_POSITION_OFFSET <const> = math3d.constant("v4", {0, 0.2, 0, 0.0})
local REMOVE <const> = {}
local DEFAULT_DIR <const> = require("gameplay.interface.constant").DEFAULT_DIR
local ibuilding = ecs.import.interface "vaststars.gamerender|ibuilding"
local icamera_controller = ecs.interface "icamera_controller"
local iroad = ecs.import.interface "vaststars.gamerender|iroad"
local ROAD_TILE_SCALE_WIDTH <const> = 2
local ROAD_TILE_SCALE_HEIGHT <const> = 2
local CHANGED_FLAG_ROADNET <const> = require("gameplay.interface.constant").CHANGED_FLAG_ROADNET
local ibackpack = require "gameplay.interface.backpack"

-- To distinguish between "batch construction" and "batch teardown" in the touch_end event.
local STATE_NONE  <const> = 0
local STATE_START <const> = 1
local STATE_TEARDOWN <const> = 2

local function _get_object(self, x, y, cache_names)
    local coord = packcoord(x, y)
    local tmp = self.pending[coord]
    if tmp and tmp ~= REMOVE then
        local prototype_name, dir = iroadnet_converter.mask_to_prototype_name_dir(tmp)
        return {
            id = iobject.new_object_id(),
            x = x,
            y = y,
            prototype_name = prototype_name,
            dir = assert(dir),
        }
    end

    for i = 0, ROAD_TILE_SCALE_WIDTH - 1 do
        for j = 0, ROAD_TILE_SCALE_HEIGHT - 1 do
            local object = objects:coord(x + i, y + j, cache_names)
            local road_object = ibuilding.get(x, y)
            if object then
                assert(not road_object, ("road overlaps with the building(%s,%s) %s"):format(x, y, object.prototype_name))
                return object
            end

            if road_object then
                return {
                    id = iobject.new_object_id(),
                    x = x,
                    y = y,
                    prototype_name = road_object.prototype,
                    dir = assert(road_object.direction),
                }
            end
        end
    end
end

local function __align_roadnet(v)
    return v - (v % 2)
end

local function _get_connections(prototype_name, x, y, dir)
    local typeobject = iprototype.queryByName(prototype_name)
    local r = {}
    if not typeobject.crossing then
        return r
    end

    for _, conn in ipairs(typeobject.crossing.connections) do
        local dx, dy, dir = iprototype.rotate_connection(conn.position, dir, typeobject.area)
        r[#r+1] = {x = __align_roadnet(x + dx), y = __align_roadnet(y + dy), dir = dir}
    end
    return r
end

-- NOTE:
-- automatically connects to its neighbors which has crossing, except for road
local function _connect_to_neighbor(self, x, y, prototype_name, dir)
    local succ, neighbor_x, neighbor_y, dx, dy, connected_dir
    for _, neighbor_dir in ipairs(ALL_DIR) do
        succ, neighbor_x, neighbor_y = terrain:move_coord(x, y, neighbor_dir, 1)
        if not succ then
            goto continue
        end

        local object = _get_object(self, neighbor_x, neighbor_y, EDITOR_CACHE_NAMES)
        if not object then
            goto continue
        end

        if iprototype.is_road(object.prototype_name) then
            goto continue
        end

        for _, fb in ipairs(_get_connections(object.prototype_name, object.x, object.y, object.dir)) do
            if fb.x == x and fb.y == y then
                prototype_name, dir = iflow_connector.set_road_connection(prototype_name, dir, neighbor_dir, true)
                connected_dir = neighbor_dir
                goto continue -- only one connection can be connected to the endpoint
            end
        end
        ::continue::
    end
    return prototype_name, dir, connected_dir
end

-- NOTE:
-- prototype_name is the prototype_name of the road currently being built
local function _get_covers_connections(prototype_name, object)
    local _prototype_name
    if iprototype.is_road(object.prototype_name) then
        -- because road can replace other road
        _prototype_name = prototype_name
    else
        _prototype_name = object.prototype_name
    end
    return _get_connections(_prototype_name, object.x, object.y, object.dir)
end

-- NOTE:
local function _set_endpoint_connection(State, object, connection, dir)
    if iprototype.is_road(object.prototype_name) then
        local typeobject = iprototype.queryByName(object.prototype_name)
        local _prototype_name, _dir
        -- normal road can replace other road
        _prototype_name, _dir = iflow_connector.covers_building_category(object.prototype_name, object.dir, typeobject.building_category)
        _prototype_name, _dir = iflow_connector.set_road_connection(_prototype_name, _dir, dir, true)
        if not _prototype_name or not _dir then
            State.succ = false
            return object.prototype_name, object.dir
        else
            return _prototype_name, _dir
        end
    else
        if not connection then
            State.succ = false
        end
        return object.prototype_name, object.dir
    end
end

-- NOTE:
local function _builder_end(self, datamodel, State, dir, dir_delta)
    local reverse_dir = iprototype.reverse_dir(dir)
    local prototype_name = self.coord_indicator.prototype_name
    local map = {}

    local from_x, from_y
    if State.starting_connection then
        from_x, from_y = State.starting_connection.x, State.starting_connection.y
    else
        from_x, from_y = State.from_x, State.from_y
    end
    local to_x, to_y
    if State.ending_connection then
        to_x, to_y = State.ending_connection.x, State.ending_connection.y
    else
        to_x, to_y = State.to_x, State.to_y
    end
    local x, y = assert(from_x), assert(from_y)
    assert(from_x % ROAD_TILE_SCALE_WIDTH == 0 and from_y % ROAD_TILE_SCALE_HEIGHT == 0)
    assert(to_x % ROAD_TILE_SCALE_WIDTH == 0 and to_y % ROAD_TILE_SCALE_HEIGHT == 0)

    while true do
        local coord = packcoord(x, y)
        local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)

        if x == from_x and y == from_y then
            if object then
                map[coord] = {_set_endpoint_connection(State, object, State.starting_connection, dir)}
            else
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir = _connect_to_neighbor(self, x, y, endpoint_prototype_name, endpoint_dir)
                if not (x == to_x and y == to_y) then
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                end
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        elseif x == to_x and y == to_y then
            if object then
                map[coord] = {_set_endpoint_connection(State, object, State.ending_connection, reverse_dir)}
            else
                local connected_dir
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir, connected_dir = _connect_to_neighbor(self, x, y, endpoint_prototype_name, endpoint_dir)
                if connected_dir ~= reverse_dir then
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                end
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        else
            if object then
                if not iprototype.is_road(object.prototype_name) then
                    State.succ = false
                    map[coord] = {object.prototype_name, object.dir}
                else
                    local endpoint_prototype_name, endpoint_dir = object.prototype_name, object.dir
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                    map[coord] = {endpoint_prototype_name, endpoint_dir}
                end
            else
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        end

        if x == to_x and y == to_y then
            break
        end
        x, y = x + dir_delta.x * ROAD_TILE_SCALE_WIDTH, y + dir_delta.y * ROAD_TILE_SCALE_HEIGHT
    end

    local shape_type = State.succ and "valid" or "invalid"
    self.temporary_map = {}
    for coord, v in pairs(map) do
        local x, y = unpackcoord(coord)
        local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)
        if object and not iprototype.is_road(object.prototype_name) then -- TODO: remove this check
            goto continue
        end
        if x == from_x and y == from_y then
            iroadnet:editor_set("indicator", shape_type, x, y, "U", dir)
        elseif x == to_x and y == to_y then
            iroadnet:editor_set("indicator", shape_type, x, y, "U", reverse_dir)
        else
            iroadnet:editor_set("indicator", shape_type, x, y, "I", dir)
        end

        self.temporary_map[coord] = iroadnet_converter.prototype_name_dir_to_mask(v[1], v[2])
        ::continue::
    end

    iroadnet:update()
    self.to_x, self.to_y = to_x, to_y
    datamodel.show_finish_laying = State.succ
end

-- NOTE:
local function _builder_init(self, datamodel)
    local coord_indicator = self.coord_indicator
    local prototype_name = self.coord_indicator.prototype_name

    local function is_valid_starting(x, y)
        local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)
        if not object then
            return true
        end
        return #_get_covers_connections(prototype_name, object) > 0
    end

    local object = _get_object(self, coord_indicator.x, coord_indicator.y, EDITOR_CACHE_NAMES)
    if object then
        if iprototype.is_road(object.prototype_name) then
            datamodel.show_remove_one = true
            datamodel.show_start_teardown = true
        end
        datamodel.show_place_one = false
        if is_valid_starting(coord_indicator.x, coord_indicator.y) then
            datamodel.show_start_laying = true
        else
            datamodel.show_start_laying = false
        end

        for _, c in pairs(self.pickup_components) do
            c:on_status_change(datamodel.show_start_laying)
        end
    else
        datamodel.show_place_one = true
        datamodel.show_remove_one = false
        datamodel.show_start_teardown = false
        datamodel.show_start_laying = false

        for _, c in pairs(self.pickup_components) do
            c:on_status_change(true)
        end
    end
end

-- sort by distance and direction
-- prototype_name is the prototype_name of the road currently being built
local function _find_starting_connection(prototype_name, object, dx, dy, dir)
    local connections = _get_covers_connections(prototype_name, object)
    assert(#connections > 0) -- promised by _builder_init()

    local function _get_distance(x1, y1, x2, y2)
        return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
    end

    table.sort(connections, function(a, b)
        local dist1 = _get_distance(a.x, a.y, dx, dy)
        local dist2 = _get_distance(b.x, b.y, dx, dy)
        if dist1 < dist2 then
            return true
        elseif dist1 > dist2 then
            return false
        else
            return ((a.dir == dir) and 0 or 1) < ((b.dir == dir) and 0 or 1)
        end
    end)
    return connections[1]
end

-- NOTE:
local function _builder_start(self, datamodel)
    local from_x, from_y = self.from_x, self.from_y
    local to_x, to_y = self.coord_indicator.x, self.coord_indicator.y
    local prototype_name = self.coord_indicator.prototype_name
    local starting = _get_object(self, from_x, from_y, EDITOR_CACHE_NAMES)
    local dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)

    local typeobject = iprototype.queryByName(prototype_name)
    local c = ibackpack.query(gameplay_core.get_world(), typeobject.id) * 2

    local State = {
        succ = true,
        starting_connection = nil,
        ending_connection = nil,
        from_x = from_x,
        from_y = from_y,
        to_x = to_x,
        to_y = to_y,
        dec = 0,
    }


    if starting then
        -- starting object should at least have one connection, promised by _builder_init()
        local connection = _find_starting_connection(prototype_name, starting, to_x, to_y, dir)
        State.starting_connection = connection
        if connection.dir ~= dir then
            State.succ = false
        end

        local succ
        local dx, dy = math_min(math_abs(to_x - connection.x), c), math.min(math_abs(to_y - connection.y), c)
        succ, to_x, to_y = terrain:move_coord(connection.x, connection.y, dir, dx, dy)
        if not succ then
            State.succ = false
        end
        State.dec = math_max(dx, dy) // 2

        local ending = _get_object(self, to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            if starting.x == ending.x and starting.y == ending.y then
                State.succ = false
                State.ending_connection = connection
            else
                for _, another in ipairs(_get_covers_connections(prototype_name, ending)) do
                    if another.dir ~= iprototype.reverse_dir(dir) then
                        goto continue
                    end

                    local dx, dy = math_min(math_abs(another.x - connection.x), c), math_min(math_abs(another.y - connection.y), c)
                    succ, to_x, to_y = terrain:move_coord(connection.x, connection.y, dir, dx, dy)
                    if not succ then
                        goto continue
                    end
                    State.dec = math_max(dx, dy) // 2

                    if to_x == another.x and to_y == another.y then
                        State.ending_connection = another
                        _builder_end(self, datamodel, State, dir, delta)
                        return State.succ
                    end
                    ::continue::
                end
                State.succ = false
            end
        end

        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(connection.x, connection.y, to_x, to_y)
        _builder_end(self, datamodel, State, dir, delta)
        return State.succ
    else
        if not self:check_construct_detector(prototype_name, from_x, from_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end

        State.from_x, State.from_y = from_x, from_y
        local succ
        local dx, dy = math.min(math_abs(to_x - from_x), c), math.min(math_abs(to_y - from_y), c)
        succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir, dx, dy)
        if not succ then
            State.succ = false
        end
        State.dec = math_max(dx, dy) // 2
        State.to_x, State.to_y = to_x, to_y

        local ending = _get_object(self, to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            for _, fluidbox in ipairs(_get_covers_connections(prototype_name, ending)) do
                if fluidbox.dir ~= iprototype.reverse_dir(dir) then
                    goto continue
                end
                succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir,
                    math_abs(from_x - fluidbox.x),
                    math_abs(from_y - fluidbox.y)
                )
                if not succ then
                    goto continue
                end
                if to_x == fluidbox.x and to_y == fluidbox.y then
                    State.ending_connection = fluidbox
                    _builder_end(self, datamodel, State, dir, delta)
                    return State.succ
                end
                ::continue::
            end
            State.succ = false
        end

        --
        local succ
        succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir,
            math_abs(to_x - from_x),
            math_abs(to_y - from_y)
        )
        if not succ then
            State.succ = false
        end
        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)
        _builder_end(self, datamodel, State, dir, delta)
        return State.succ
    end
end

local function _teardown_end(self, datamodel, State, dir, dir_delta)
    local reverse_dir = iprototype.reverse_dir(dir)
    local prototype_name = self.coord_indicator.prototype_name
    local map = {}

    local from_x, from_y
    if State.starting_connection then
        from_x, from_y = State.starting_connection.x, State.starting_connection.y
    else
        from_x, from_y = State.from_x, State.from_y
    end
    local to_x, to_y
    if State.ending_connection then
        to_x, to_y = State.ending_connection.x, State.ending_connection.y
    else
        to_x, to_y = State.to_x, State.to_y
    end
    local x, y = assert(from_x), assert(from_y)

    while true do
        local coord = packcoord(x, y)
        local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)

        if x == from_x and y == from_y then
            if object then
                map[coord] = {_set_endpoint_connection(State, object, State.starting_connection, dir)}
            else
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir = _connect_to_neighbor(self, x, y, endpoint_prototype_name, endpoint_dir)
                if not (x == to_x and y == to_y) then
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                end
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        elseif x == to_x and y == to_y then
            if object then
                map[coord] = {_set_endpoint_connection(State, object, State.ending_connection, reverse_dir)}
            else
                local connected_dir
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir, connected_dir = _connect_to_neighbor(self, x, y, endpoint_prototype_name, endpoint_dir)
                if connected_dir ~= reverse_dir then
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                end
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        else
            if object then
                if not iprototype.is_road(object.prototype_name) then
                    State.succ = false
                    map[coord] = {object.prototype_name, object.dir}
                else
                    local endpoint_prototype_name, endpoint_dir = object.prototype_name, object.dir
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                    map[coord] = {endpoint_prototype_name, endpoint_dir}
                end
            else
                State.succ = false -- TODO: remove this
            end
        end

        if x == to_x and y == to_y then
            break
        end
        x, y = x + dir_delta.x * ROAD_TILE_SCALE_WIDTH, y + dir_delta.y * ROAD_TILE_SCALE_HEIGHT
    end

    if State.succ then
        self.temporary_map = {}
        for coord in pairs(map) do
            local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)
            if object and not iprototype.is_road(object.prototype_name) then -- TODO: remove this check
                goto continue
            end
            local x, y = unpackcoord(coord)
            if x == from_x and y == from_y then
                iroadnet:editor_set("indicator", "invalid", x, y, "U", dir)
            elseif x == to_x and y == to_y then
                iroadnet:editor_set("indicator", "invalid", x, y, "U", reverse_dir)
            else
                iroadnet:editor_set("indicator", "invalid", x, y, "I", dir)
            end
            self.temporary_map[coord] = REMOVE
            ::continue::
        end
    end

    iroadnet:update()
    self.to_x, self.to_y = to_x, to_y
    datamodel.show_finish_teardown = State.succ
end

local function _teardown_start(self, datamodel)
    local from_x, from_y = self.from_x, self.from_y
    local to_x, to_y = self.coord_indicator.x, self.coord_indicator.y
    local prototype_name = self.coord_indicator.prototype_name
    local starting = _get_object(self, from_x, from_y, EDITOR_CACHE_NAMES)
    local dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)

    local State = {
        succ = true,
        starting_connection = nil,
        ending_connection = nil,
        from_x = from_x,
        from_y = from_y,
        to_x = to_x,
        to_y = to_y,
    }

    if starting then
        -- starting object should at least have one connection, promised by _builder_init()
        local connection = _find_starting_connection(prototype_name, starting, to_x, to_y, dir)
        State.starting_connection = connection
        if connection.dir ~= dir then
            State.succ = false
        end

        local succ
        succ, to_x, to_y = terrain:move_coord(connection.x, connection.y, dir,
            math_abs(to_x - connection.x),
            math_abs(to_y - connection.y)
        )
        if not succ then
            State.succ = false
        end

        local ending = _get_object(self, to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            if starting.x == ending.x and starting.y == ending.y then
                State.succ = false
                State.ending_connection = connection
            else
                for _, another in ipairs(_get_covers_connections(prototype_name, ending)) do
                    if another.dir ~= iprototype.reverse_dir(dir) then
                        goto continue
                    end
                    succ, to_x, to_y = terrain:move_coord(connection.x, connection.y, dir,
                        math_abs(another.x - connection.x),
                        math_abs(another.y - connection.y)
                    )
                    if not succ then
                        goto continue
                    end
                    if to_x == another.x and to_y == another.y then
                        State.ending_connection = another
                        _teardown_end(self, datamodel, State, dir, delta)
                        return State.succ
                    end
                    ::continue::
                end
                State.succ = false
            end
        else
            State.succ = false
        end

        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(connection.x, connection.y, to_x, to_y)
        _teardown_end(self, datamodel, State, dir, delta)
        return State.succ
    else
        if not self:check_construct_detector(prototype_name, from_x, from_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end

        State.from_x, State.from_y = from_x, from_y
        local succ
        succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir,
            math_abs(to_x - from_x),
            math_abs(to_y - from_y)
        )
        if not succ then
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y

        local ending = _get_object(self, to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            for _, fluidbox in ipairs(_get_covers_connections(prototype_name, ending)) do
                if fluidbox.dir ~= iprototype.reverse_dir(dir) then
                    goto continue
                end
                succ, to_x, to_y = terrain:move_coord(fluidbox.x, fluidbox.y, dir,
                    math_abs(from_x - fluidbox.x),
                    math_abs(from_y - fluidbox.y)
                )
                if not succ then
                    goto continue
                end
                if to_x == fluidbox.x and to_y == fluidbox.y then
                    State.ending_connection = fluidbox
                    _teardown_end(self, datamodel, State, dir, delta)
                    return State.succ
                end
                ::continue::
            end
            State.succ = false
        end

        --
        local succ
        succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir,
            math_abs(to_x - from_x),
            math_abs(to_y - from_y)
        )
        if not succ then
            State.succ = false
        end
        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)
        _teardown_end(self, datamodel, State, dir, delta)
        return State.succ
    end
end

local function __calc_grid_position(typeobject, x, y)
    local w, h = iprototype.unpackarea(typeobject.area)
    local _, originPosition = coord_system:align(math3d.vector {10, 0, -10}, w, h) -- TODO: remove hardcode
    local buildingPosition = coord_system:get_position_by_coord(x - (x % ROAD_TILE_SCALE_WIDTH), y - (y % ROAD_TILE_SCALE_HEIGHT), w, h)
    return math3d.ref(math3d.add(math3d.sub(buildingPosition, originPosition), GRID_POSITION_OFFSET))
end

local function __align(object)
    local coord_system = terrain

    assert(object)
    local typeobject = iprototype.queryByName(object.prototype_name)
    local coord = coord_system["align"](coord_system, icamera_controller.get_central_position(), iprototype.rotate_area(typeobject.area, object.dir))
    if not coord then
        return object
    end
    coord[1], coord[2] = coord[1] - (coord[1] % ROAD_TILE_SCALE_WIDTH), coord[2] - (coord[2] % ROAD_TILE_SCALE_HEIGHT)
    object.srt.t = math3d.ref(math3d.vector(coord_system:get_position_by_coord(coord[1], coord[2], iprototype.rotate_area(typeobject.area, object.dir))))
    return object, coord[1], coord[2]
end

--------------------------------------------------------------------------------------------------
local function new_entity(self, datamodel, typeobject, x, y)
    local dir = DEFAULT_DIR
    assert(x and y)

    if not self.grid_entity then
        self.grid_entity = igrid_entity.create("polyline_grid", terrain._width // ROAD_TILE_SCALE_WIDTH, terrain._height // ROAD_TILE_SCALE_HEIGHT, terrain.tile_size * ROAD_TILE_SCALE_WIDTH, {t = __calc_grid_position(typeobject, x, y)})
    end
    self.grid_entity:show(true)

    iobject.remove(self.coord_indicator)

    self.typeobject = typeobject
    self.coord_indicator = iobject.new {
        prototype_name = typeobject.name,
        dir = dir,
        x = x,
        y = y,
        srt = {
            t = math3d.ref(math3d.vector(terrain:get_position_by_coord(x, y, iprototype.rotate_area(typeobject.area, dir)))),
            r = ROTATORS[dir],
        },
        group_id = 0,
    }

    self.pickup_components[#self.pickup_components + 1] = create_pickup_selected_box(self.coord_indicator.srt.t, typeobject, dir, true)

    --
    _builder_init(self, datamodel)
end

local function touch_move(self, datamodel, delta_vec)
    if self.coord_indicator then
        iobject.move_delta(self.coord_indicator, delta_vec)
    end
    if self.grid_entity then
        local typeobject = iprototype.queryByName(self.coord_indicator.prototype_name)
        self.grid_entity:send("obj_motion", "set_position", __calc_grid_position(typeobject, self.coord_indicator.x, self.coord_indicator.y))
    end
    for _, c in pairs(self.pickup_components) do
        c:on_position_change(self.coord_indicator.srt, self.coord_indicator.dir)
    end
end

local function touch_end(self, datamodel)
    if not self.coord_indicator then
        return
    end

    local x, y
    self.coord_indicator, x, y = __align(self.coord_indicator)
    self.coord_indicator.x, self.coord_indicator.y = x, y
    iroadnet:clear("indicator")

    for _, c in pairs(self.pickup_components) do
        c:on_position_change(self.coord_indicator.srt, self.coord_indicator.dir)
    end
    if self.state == STATE_NONE then
        _builder_init(self, datamodel)
        return false
    elseif self.state == STATE_START then
        return _builder_start(self, datamodel)
    elseif self.state == STATE_TEARDOWN then
        return _teardown_start(self, datamodel)
    end
end

local REMOVE_ROAD_DIR_MASK = {
    W = 0xE,
    N = 0xD,
    E = 0xB,
    S = 0x7,
}

local function confirm(self, datamodel)
    if self.grid_entity then
        self.grid_entity:remove()
        self.grid_entity = nil
    end

    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil

    local inc = 0
    local dec = 0
    for coord, mask in pairs(self.pending) do
        if mask == REMOVE then
            inc = inc + 1
        else
            local x, y = unpackcoord(coord)
            if not ibuilding.get(x, y) then
                dec = dec + 1
            end
        end
    end
    if inc > dec then
        inc = inc - dec
        dec = 0
    else
        dec = dec - inc
        inc = 0
    end

    ibackpack.pickup(gameplay_core.get_world(), iprototype.queryByName("砖石公路-X型").id, dec)

    for coord, mask in pairs(self.pending) do
        local x, y = unpackcoord(coord)
        if mask == REMOVE then
            ibuilding.remove(x, y)
            iroadnet:editor_del("road", x, y)
        else
            local prototype_name, dir = iroadnet_converter.mask_to_prototype_name_dir(mask) -- TODO: optimize
            ibuilding.set {
                x = x,
                y = y,
                prototype_name = prototype_name,
                dir = dir,
                road = true,
            }
            local shape, dir = iroadnet_converter.mask_to_shape_dir(mask)
            iroadnet:editor_set("road", "normal", x, y, shape, dir)
        end
    end

    iroadnet:update()
    gameplay_core.set_changed(CHANGED_FLAG_ROADNET)
    iroadnet:clear("indicator")

    datamodel.show_finish_laying = false
    datamodel.show_cancel = false
    datamodel.show_start_laying = false
    self.pending = {}

    task.update_progress("road_laying", dec)

    local to_x, to_y = self.to_x, self.to_y
    self.to_x, self.to_y = nil, nil
    return to_x, to_y
end

local function start_laying(self, datamodel)
    iroadnet:clear("indicator")

    datamodel.show_place_one = false
    datamodel.show_start_laying = false
    datamodel.show_start_teardown = false
    datamodel.show_remove_one = false
    datamodel.show_cancel = true

    self.state = STATE_START
    self.from_x = self.coord_indicator.x
    self.from_y = self.coord_indicator.y

    return _builder_start(self, datamodel)
end

local function cancel(self, datamodel)
    iroadnet:clear("indicator")

    self.state = STATE_NONE
    datamodel.show_finish_laying = false
    datamodel.show_finish_teardown = false
    datamodel.show_cancel = false
end

local function finish_laying(self, datamodel)
    self.state = STATE_NONE
    datamodel.show_finish_laying = false
    datamodel.show_confirm = true
    datamodel.show_cancel = false

    iroadnet:clear("indicator")
    for coord, mask in pairs(self.temporary_map) do
        local x, y = unpackcoord(coord)
        local shape, dir = iroadnet_converter.mask_to_shape_dir(mask)
        local road_object = ibuilding.get(x, y)
        if not road_object then
            iroadnet:editor_set("road", "modify", x, y, shape, dir)
            self.pending[coord] = mask
        else
            local m = iroadnet_converter.prototype_name_dir_to_mask(road_object.prototype, road_object.direction)
            if mask ~= m then
                iroadnet:editor_set("road", "modify", x, y, shape, dir)
                self.pending[coord] = mask
            end
        end
    end
    self.temporary_map = {}

    return confirm(self, datamodel)
end



local function place_one(self, datamodel)
    local coord_indicator = self.coord_indicator
    local x, y = coord_indicator.x, coord_indicator.y
    local coord = packcoord(x, y)
    if ibuilding.get(x, y) then
        return
    end

    datamodel.show_confirm = true

    assert(x % 2 == 0 and y % 2 == 0)
    self.pending[coord] = 0 -- {"砖石公路-O型", "N"}

    for _, dir in ipairs(iconstant.ALL_DIR) do
        local dx, dy = iprototype.move_coord(x, y, dir, 2, 2)
        local r = ibuilding.get(dx, dy)
        if r then
            self.pending[coord] = iroad.open(self.pending[coord], iprototype.dir_tonumber(dir))

            local m = iroadnet_converter.prototype_name_dir_to_mask(r.prototype, r.direction)
            self.pending[packcoord(dx, dy)] = iroad.open(m, iprototype.dir_tonumber(iprototype.reverse_dir(dir)))
        end
    end

    _builder_init(self, datamodel)
    return confirm(self, datamodel)
end

local function _road_teardown(self, x, y)
    iroadnet:editor_del("road", x, y)

    for _, dir in ipairs(iconstant.ALL_DIR) do
        local succ, dx, dy = terrain:move_coord(x, y, dir, 1)
        if not succ then
            goto continue
        end
        local object = _get_object(self, dx, dy, EDITOR_CACHE_NAMES)
        if not object then
            goto continue
        end
        if not iprototype.is_road(object.prototype_name) then
            goto continue
        end

        local coord = packcoord(dx, dy)
        local m = self.pending[coord]
        m = m & REMOVE_ROAD_DIR_MASK[iprototype.reverse_dir(dir)]
        self.pending[coord] = m
        ::continue::
    end
end

local function _teardown_end(self, datamodel, State, dir, dir_delta)
    local reverse_dir = iprototype.reverse_dir(dir)
    local prototype_name = self.coord_indicator.prototype_name
    local map = {}

    local from_x, from_y
    if State.starting_connection then
        from_x, from_y = State.starting_connection.x, State.starting_connection.y
    else
        from_x, from_y = State.from_x, State.from_y
    end
    local to_x, to_y
    if State.ending_connection then
        to_x, to_y = State.ending_connection.x, State.ending_connection.y
    else
        to_x, to_y = State.to_x, State.to_y
    end
    local x, y = assert(from_x), assert(from_y)

    while true do
        local coord = packcoord(x, y)
        local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)

        if x == from_x and y == from_y then
            if object then
                map[coord] = {_set_endpoint_connection(State, object, State.starting_connection, dir)}
            else
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir = _connect_to_neighbor(self, x, y, endpoint_prototype_name, endpoint_dir)
                if not (x == to_x and y == to_y) then
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                end
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        elseif x == to_x and y == to_y then
            if object then
                map[coord] = {_set_endpoint_connection(State, object, State.ending_connection, reverse_dir)}
            else
                local connected_dir
                local endpoint_prototype_name, endpoint_dir = iflow_connector.cleanup(prototype_name, DEFAULT_DIR)
                endpoint_prototype_name, endpoint_dir, connected_dir = _connect_to_neighbor(self, x, y, endpoint_prototype_name, endpoint_dir)
                if connected_dir ~= reverse_dir then
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                end
                map[coord] = {endpoint_prototype_name, endpoint_dir}
            end

        else
            if object then
                if not iprototype.is_road(object.prototype_name) then
                    State.succ = false
                    map[coord] = {object.prototype_name, object.dir}
                else
                    local endpoint_prototype_name, endpoint_dir = object.prototype_name, object.dir
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, dir, true)
                    endpoint_prototype_name, endpoint_dir = iflow_connector.set_road_connection(endpoint_prototype_name, endpoint_dir, reverse_dir, true)
                    map[coord] = {endpoint_prototype_name, endpoint_dir}
                end
            else
                State.succ = false -- TODO: remove this
            end
        end

        if x == to_x and y == to_y then
            break
        end
        x, y = x + dir_delta.x * ROAD_TILE_SCALE_WIDTH, y + dir_delta.y * ROAD_TILE_SCALE_HEIGHT
    end

    if State.succ then
        self.temporary_map = {}
        for coord, v in pairs(map) do
            local object = _get_object(self, x, y, EDITOR_CACHE_NAMES)
            if object and not iprototype.is_road(object.prototype_name) then -- TODO: remove this check
                goto continue
            end
            local x, y = unpackcoord(coord)
            if x == from_x and y == from_y then
                iroadnet:editor_set("indicator", "invalid", x, y, "U", dir)
            elseif x == to_x and y == to_y then
                iroadnet:editor_set("indicator", "invalid", x, y, "U", reverse_dir)
            else
                iroadnet:editor_set("indicator", "invalid", x, y, "I", dir)
            end

            self.temporary_map[coord] = iroadnet_converter.prototype_name_dir_to_mask(v[1], v[2])
            ::continue::
        end
    end

    datamodel.show_finish_teardown = State.succ
end

local function _teardown_start(self, datamodel)
    local from_x, from_y = self.from_x, self.from_y
    local to_x, to_y = self.coord_indicator.x, self.coord_indicator.y
    local prototype_name = self.coord_indicator.prototype_name
    local starting = _get_object(self, from_x, from_y, EDITOR_CACHE_NAMES)
    local dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)

    local State = {
        succ = true,
        starting_connection = nil,
        ending_connection = nil,
        from_x = from_x,
        from_y = from_y,
        to_x = to_x,
        to_y = to_y,
    }

    if starting then
        -- starting object should at least have one connection, promised by _builder_init()
        local connection = _find_starting_connection(prototype_name, starting, to_x, to_y, dir)
        State.starting_connection = connection
        if connection.dir ~= dir then
            State.succ = false
        end

        local succ
        succ, to_x, to_y = terrain:move_coord(connection.x, connection.y, dir,
            math_abs(to_x - connection.x),
            math_abs(to_y - connection.y)
        )
        if not succ then
            State.succ = false
        end

        local ending = _get_object(self, to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            if starting.x == ending.x and starting.y == ending.y then
                State.succ = false
                State.ending_connection = connection
            else
                for _, another in ipairs(_get_covers_connections(prototype_name, ending)) do
                    if another.dir ~= iprototype.reverse_dir(dir) then
                        goto continue
                    end
                    succ, to_x, to_y = terrain:move_coord(connection.x, connection.y, dir,
                        math_abs(another.x - connection.x),
                        math_abs(another.y - connection.y)
                    )
                    if not succ then
                        goto continue
                    end
                    if to_x == another.x and to_y == another.y then
                        State.ending_connection = another
                        _teardown_end(self, datamodel, State, dir, delta)
                        return State.succ
                    end
                    ::continue::
                end
                State.succ = false
            end
        end

        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(connection.x, connection.y, to_x, to_y)
        _teardown_end(self, datamodel, State, dir, delta)
        return State.succ
    else
        if not self:check_construct_detector(prototype_name, from_x, from_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end

        State.from_x, State.from_y = from_x, from_y
        local succ
        succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir,
            math_abs(to_x - from_x),
            math_abs(to_y - from_y)
        )
        if not succ then
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y

        local ending = _get_object(self, to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            for _, fluidbox in ipairs(_get_covers_connections(prototype_name, ending)) do
                if fluidbox.dir ~= iprototype.reverse_dir(dir) then
                    goto continue
                end
                succ, to_x, to_y = terrain:move_coord(fluidbox.x, fluidbox.y, dir,
                    math_abs(from_x - fluidbox.x),
                    math_abs(from_y - fluidbox.y)
                )
                if not succ then
                    goto continue
                end
                if to_x == fluidbox.x and to_y == fluidbox.y then
                    State.ending_connection = fluidbox
                    _teardown_end(self, datamodel, State, dir, delta)
                    return State.succ
                end
                ::continue::
            end
            State.succ = false
        end

        --
        local succ
        succ, to_x, to_y = terrain:move_coord(from_x, from_y, dir,
            math_abs(to_x - from_x),
            math_abs(to_y - from_y)
        )
        if not succ then
            State.succ = false
        end
        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then -- cannot pave the road in places with minerals
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)
        _teardown_end(self, datamodel, State, dir, delta)
        return State.succ
    end
end

local function remove_one(self, datamodel)
    local coord_indicator = self.coord_indicator
    local x, y = coord_indicator.x, coord_indicator.y
    datamodel.show_confirm = true

    local coord = packcoord(x, y)
    if self.pending[coord] and self.pending[coord] ~= REMOVE then
        self.pending[coord] = nil

        local road_object = ibuilding.get(x, y)
        if road_object then
            local shape = iroadnet_converter.to_shape(road_object.prototype)
            iroadnet:editor_set("road", "remove", x, y, shape, road_object.direction)

            self.pending[coord] = REMOVE
        else
            _road_teardown(self, x, y)
        end
    else
        local road_object = ibuilding.get(x, y)
        if road_object then
            local shape = iroadnet_converter.to_shape(road_object.prototype)
            iroadnet:editor_set("road", "remove", x, y, shape, road_object.direction)

            self.pending[coord] = REMOVE
        else
            assert(false)
        end
    end

    _builder_init(self, datamodel)
    return confirm(self, datamodel)
end
local function start_teardown(self, datamodel)
    iroadnet:clear("indicator")

    datamodel.show_start_teardown = false
    datamodel.show_start_laying = false
    datamodel.show_place_one = false
    datamodel.show_remove_one = false
    datamodel.show_cancel = true

    self.state = STATE_TEARDOWN
    self.from_x = self.coord_indicator.x
    self.from_y = self.coord_indicator.y

    return _teardown_start(self, datamodel)
end

local function finish_teardown(self, datamodel)
    self.state = STATE_NONE
    datamodel.show_finish_teardown = false
    datamodel.show_cancel = false
    datamodel.show_confirm = true

    iroadnet:clear("indicator")

    for coord in pairs(self.temporary_map) do
        local x, y = unpackcoord(coord)
        local coord = packcoord(x, y)
        if self.pending[coord] and self.pending[coord] ~= REMOVE then
            self.pending[coord] = nil

            local road_object = ibuilding.get(x, y)
            if road_object then
                local shape = iroadnet_converter.to_shape(road_object.prototype)
                iroadnet:editor_set("road", "remove", x, y, shape, road_object.direction)

                self.pending[coord] = REMOVE
            else
                _road_teardown(self, x, y)
            end
        else
            local road_object = ibuilding.get(x, y)
            if road_object then
                local shape = iroadnet_converter.to_shape(road_object.prototype)
                iroadnet:editor_set("road", "remove", x, y, shape, road_object.direction)

                self.pending[coord] = REMOVE
            else
                assert(false)
            end
        end
    end
    self.temporary_map = {}
    return confirm(self, datamodel)
end

local function clean(self, datamodel)
    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil

    iroadnet:clear("indicator")

    self.state = STATE_NONE
    datamodel.show_finish_laying = false
    datamodel.show_finish_teardown = false
    datamodel.show_start_laying = false
    datamodel.show_start_teardown = false
    datamodel.show_cancel = false

    for coord, mask in pairs(self.pending) do
        local x, y = unpackcoord(coord)
        local shape, dir = iroadnet_converter.mask_to_shape_dir(mask)
        iroadnet:editor_set("road", "normal", x, y, shape, dir)
    end

    if self.grid_entity then
        self.grid_entity:remove()
        self.grid_entity = nil
    end
    for _, c in pairs(self.pickup_components) do
        c:remove()
    end
    self.pickup_components = {}
    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil
    self.to_x, self.to_y = nil, nil
    self.temporary_map = {}
    self.pending = {}

    iroadnet:update()
end

local function create()
    local builder = create_builder()

    local M = setmetatable({super = builder}, {__index = builder})
    M.new_entity = new_entity
    M.touch_move = touch_move
    M.touch_end = touch_end

    M.state = STATE_NONE
    M.start_laying = start_laying
    M.finish_laying = finish_laying
    M.remove_one = remove_one
    M.start_teardown = start_teardown
    M.finish_teardown = finish_teardown
    M.cancel = cancel
    M.confirm = place_one
    M.clean = clean

    M.temporary_map = {}
    M.pending = {}
    M.pickup_components = {}
    M.to_x = nil
    M.to_y = nil
    M.typeobject = nil

    return M
end
return create