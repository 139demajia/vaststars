local ecs = ...
local world = ecs.world

local create_builder = ecs.require "editor.builder"
local iprototype = require "gameplay.interface.prototype"
local packcoord = iprototype.packcoord
local unpackcoord = iprototype.unpackcoord
local ifluid = require "gameplay.interface.fluid"
local global = require "global"
local iobject = ecs.require "object"
local iprototype = require "gameplay.interface.prototype"
local iflow_connector = require "gameplay.interface.flow_connector"
local objects = require "objects"
local terrain = ecs.require "terrain"
local math_abs = math.abs
local EDITOR_CACHE_NAMES = {"TEMPORARY", "CONFIRM", "CONSTRUCTED"}
local iquad_lines_entity = ecs.require "engine.quad_lines_entity" -- NOTE: different from pipe_builder
local dotted_line_material <const> = "/pkg/vaststars.resources/materials/dotted_line.material" -- NOTE: different from pipe_builder
local igrid_entity = ecs.require "engine.grid_entity"

local DEFAULT_DIR <const> = require("gameplay.interface.constant").DEFAULT_DIR
local STATE_NONE  <const> = 0
local STATE_START <const> = 1

local function _show_dotted_line(self, from_x, from_y, to_x, to_y, dir, dir_delta)
    from_x, from_y = from_x + dir_delta.x, from_y + dir_delta.y
    local quad_num
    if from_x == to_x then
        quad_num = math_abs(from_y - to_y)
    elseif from_y == to_y then
        quad_num = math_abs(from_x - to_x)
    else
        assert(false)
    end

    if quad_num <= 1 then
        return
    end

    local position = terrain:get_position_by_coord(from_x, from_y, 1, 1)
    self.dotted_line:update(position, quad_num, dir)
    self.dotted_line:show(true)
end

local function _check_dotted_line(from_x, from_y, to_x, to_y, dir, dir_delta) -- TODO: remove this function
    from_x, from_y = from_x + dir_delta.x, from_y + dir_delta.y
    local quad_num
    if from_x == to_x then
        quad_num = math_abs(from_y - to_y)
    elseif from_y == to_y then
        quad_num = math_abs(from_x - to_x)
    else
        assert(false)
    end
end

-- fluidflow_id may be nil, only used for fluidbox
local function _update_fluid_name(State, fluid_name, fluidflow_id)
    if State.fluid_name ~= "" then
        if fluid_name ~= "" then
            if State.fluid_name ~= fluid_name then
                State.succ = false
            end
        end
        if fluidflow_id then
            State.fluidflow_ids[fluidflow_id] = true
        end
    else
        if fluid_name ~= "" then
            State.fluid_name = fluid_name
        end
        if fluidflow_id then
            State.fluidflow_ids[fluidflow_id] = true
        end
    end
end

-- Note: different from pipe_builder
-- automatically connects to its neighbors which has fluidbox, except for pipe or pipe to ground
local function _connect_to_neighbor(State, x, y, neighbor_dir, prototype_name, dir)
    local succ, neighbor_x, neighbor_y, dx, dy
    succ, neighbor_x, neighbor_y = terrain:move_coord(x, y, neighbor_dir, 1)
    if not succ then
        return prototype_name, dir
    end

    local object = objects:coord(neighbor_x, neighbor_y, EDITOR_CACHE_NAMES)
    if not object then
        return prototype_name, dir
    end

    if iprototype.is_pipe(object.prototype_name) or iprototype.is_pipe_to_ground(object.prototype_name) then
        return prototype_name, dir
    end

    for _, fb in ipairs(ifluid:get_fluidbox(object.prototype_name, object.x, object.y, object.dir, object.fluid_name)) do
        succ, dx, dy = terrain:move_coord(fb.x, fb.y, fb.dir, 1)
        if succ and dx == x and dy == y then
            prototype_name, dir = iflow_connector.set_connection(prototype_name, dir, neighbor_dir, true)
            assert(prototype_name and dir) -- TODO:remove this assert
            _update_fluid_name(State, fb.fluid_name, object.fluidflow_id) -- TODO: different fluid just don't connect automatically, but it doesn't cause fatal error
            return prototype_name, dir -- only one fluidbox can be connected to the endpoint
        end
    end

    return prototype_name, dir
end

-- NOTE: different from pipe_builder
local function _get_covers_fluidbox(object)
    local prototype_name
    if iprototype.is_pipe(object.prototype_name) or iprototype.is_pipe_to_ground(object.prototype_name) then
        prototype_name = iflow_connector.covers(object.prototype_name, object.dir)
    else
        prototype_name = object.prototype_name
    end

    local t = {}
    for _, fb in ipairs(ifluid:get_fluidbox(prototype_name, object.x, object.y, object.dir, object.fluid_name)) do
        if fb.ground then
            goto continue
        end

        t[#t+1] = fb
        ::continue::
    end
    return t
end

-- check if the neighbor pipe can be replaced with a pipe to ground
local function _can_replace(object, forward_dir)
    if not iprototype.is_pipe(object.prototype_name) and not iprototype.is_pipe_to_ground(object.prototype_name) then
        return false
    end

    local reverse_dir = iprototype.reverse_dir(forward_dir)
    local _prototype_name, _dir
    _prototype_name, _dir = iflow_connector.set_connection(object.prototype_name, object.dir, forward_dir, true)
    if not (_prototype_name == object.prototype_name and _dir == object.dir) then
        return false
    end

    _prototype_name, _dir = iflow_connector.set_connection(object.prototype_name, object.dir, reverse_dir, true)
    if not (_prototype_name == object.prototype_name and _dir == object.dir) then
        return false
    end

    return true
end

local function _set_starting(prototype_name, State, PipeToGroundState, x, y, dir)
    local object = objects:coord(x, y, EDITOR_CACHE_NAMES)
    local typeobject = iprototype.queryByName("entity", prototype_name)

    if x == PipeToGroundState.to_x and y == PipeToGroundState.to_y then
        return
    end

    if not object then
        local endpoint_prototype_name, endpoint_dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, nil, dir)
        endpoint_prototype_name, endpoint_dir = _connect_to_neighbor(State, x, y, iprototype.reverse_dir(dir), endpoint_prototype_name, endpoint_dir)
        PipeToGroundState.map[packcoord(x, y)] = {assert(endpoint_prototype_name), assert(endpoint_dir)}
        return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
    end

    if iprototype.is_pipe(object.prototype_name) then
        _update_fluid_name(State, object.fluid_name, object.fluidflow_id)

        local coord = packcoord(x, y)
        local _prototype_name, _dir
        if _can_replace(object, dir) then
            -- replace the neighbor pipe with a pipe to ground
            _prototype_name, _dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, iprototype.reverse_dir(dir), dir)
            PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}
            return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
        end

        -- the neighbor pipe can not be replaced with a pipe to ground, so we need to change the shape of the pipe
        _prototype_name, _dir = iflow_connector.set_connection(object.prototype_name, object.dir, dir, true)
        PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}

        local x, y = object.x + PipeToGroundState.dir_delta.x, object.y + PipeToGroundState.dir_delta.y
        if x == PipeToGroundState.to_x and y == PipeToGroundState.to_y then
            State.succ = false
            return
        end

        _prototype_name, _dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, iprototype.reverse_dir(dir), dir)

        coord = packcoord(x, y)
        local next_object = objects:coord(x, y, EDITOR_CACHE_NAMES)
        if not next_object then
            PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}
            return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
        end

        if not _can_replace(next_object, dir) then
            State.succ = false
            PipeToGroundState.map[coord] = {assert(next_object.prototype_name), assert(next_object.dir)}
            return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
        end

        PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}
        return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y

    elseif iprototype.is_pipe_to_ground(object.prototype_name) then
        _update_fluid_name(State, object.fluid_name, object.fluidflow_id)

        local _prototype_name, _dir
        -- the pipe to ground can certainly be replaced with the new pipe to ground, promise by _builder_init()
        assert(_can_replace(object, dir))
        _prototype_name, _dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, iprototype.reverse_dir(dir), dir)
        local coord = packcoord(x, y)
        PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}
        return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y

    else
        _update_fluid_name(State, State.starting_fluidbox.fluid_name, object.fluidflow_id)

        local _prototype_name, _dir
        local typeobject = iprototype.queryByName("entity", prototype_name)
        _prototype_name, _dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, iprototype.reverse_dir(dir), dir)

        x, y = x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
        if x == PipeToGroundState.to_x and y == PipeToGroundState.to_y then
            State.succ = false
            return
        end

        local coord = packcoord(x, y)
        local next_object = objects:coord(x, y, EDITOR_CACHE_NAMES)
        if not next_object then
            PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}
            return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
        end

        if not _can_replace(next_object, dir) then
            State.succ = false
            PipeToGroundState.map[coord] = {assert(next_object.prototype_name), assert(next_object.dir)}
            return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
        end

        PipeToGroundState.map[coord] = {assert(_prototype_name), assert(_dir)}
        return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
    end
end

local function _set_section(prototype_name, State, PipeToGroundState, x, y, dir)
    local typeobject = iprototype.queryByName("entity", prototype_name)
    local reverse_dir = iprototype.reverse_dir(dir)

    if PipeToGroundState.distance + 1 < PipeToGroundState.max_distance then
        local object = objects:coord(x, y, EDITOR_CACHE_NAMES)
        if object then
            if _can_replace(object, dir) then
                PipeToGroundState.replace_object[object.id] = true
            else
                PipeToGroundState.replace = false
            end
        end

        PipeToGroundState.distance = PipeToGroundState.distance + 1
        return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
    end

    PipeToGroundState.distance = 0
    State.dotted_line_coord = {x, y, PipeToGroundState.to_x, PipeToGroundState.to_y, dir, PipeToGroundState.dir_delta}
    _check_dotted_line(table.unpack(State.dotted_line_coord))

    local object = objects:coord(x, y, EDITOR_CACHE_NAMES)
    if object then
        if not _can_replace(object, dir) then
            State.succ = false
            return
        end
    end

    local _prototype_name, _dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, dir, reverse_dir)
    PipeToGroundState.map[packcoord(x, y)] = {assert(_prototype_name), assert(_dir)}

    x, y = x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
    State.dotted_line_coord = {x, y, PipeToGroundState.to_x, PipeToGroundState.to_y, dir, PipeToGroundState.dir_delta}
    _check_dotted_line(table.unpack(State.dotted_line_coord))

    local last = false
    if x == PipeToGroundState.to_x and y == PipeToGroundState.to_y then
        last = true
    end

    object = objects:coord(x, y, EDITOR_CACHE_NAMES)
    if object then
        if not _can_replace(object, dir) then
            State.succ = false
            return
        end
    end
    local _prototype_name, _dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, reverse_dir, dir)
    PipeToGroundState.map[packcoord(x, y)] = {assert(_prototype_name), assert(_dir)}

    if last then
        return
    else
        return x + PipeToGroundState.dir_delta.x, y + PipeToGroundState.dir_delta.y
    end
end

local function _set_ending(prototype_name, State, PipeToGroundState, x, y, dir)
    local typeobject = iprototype.queryByName("entity", prototype_name)
    local endpoint_prototype_name, endpoint_dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, nil, iprototype.reverse_dir(dir))
    assert(endpoint_prototype_name and endpoint_dir)
    endpoint_prototype_name, endpoint_dir = _connect_to_neighbor(State, x, y, dir, endpoint_prototype_name, endpoint_dir)
    assert(endpoint_prototype_name and endpoint_dir)

    local object = objects:coord(x, y, EDITOR_CACHE_NAMES)
    if not object then
        PipeToGroundState.map[packcoord(x, y)] = {assert(endpoint_prototype_name), assert(endpoint_dir)}
        return
    end

    if _can_replace(object, dir) then
        PipeToGroundState.map[packcoord(x, y)] = {assert(endpoint_prototype_name), assert(endpoint_dir)}
        return
    end

    if not iprototype.is_pipe(object.prototype_name) and not iprototype.is_pipe_to_ground(object.prototype_name) then
        State.succ = false
        return
    end

    local px, py = x - PipeToGroundState.dir_delta.x, y - PipeToGroundState.dir_delta.y
    local coord

    coord = packcoord(px, py)
    if PipeToGroundState.map[coord] then
        State.succ = false
        return
    end

    endpoint_prototype_name, endpoint_dir = iflow_connector.covers_pipe_to_ground(typeobject.flow_type, dir, iprototype.reverse_dir(dir))
    PipeToGroundState.map[coord] = {assert(endpoint_prototype_name), assert(endpoint_dir)}

    coord = packcoord(x, y)
    local _prototype_name, _dir = iflow_connector.set_connection(object.prototype_name, object.dir, iprototype.reverse_dir(dir), true)
    if not _prototype_name then
        State.succ = false
        return
    end

    PipeToGroundState.map[coord] = {_prototype_name, _dir}
end

local function _get_item_name(prototype_name)
    local typeobject = iprototype.queryByName("item", iflow_connector.covers(prototype_name, DEFAULT_DIR))
    return typeobject.name
end

-- NOTE: different from pipe_builder
local function _builder_end(self, datamodel, State, dir, dir_delta)
    local prototype_name = self.coord_indicator.prototype_name
    local typeobject = iprototype.queryByName("entity", prototype_name)
    local item_typeobject = iprototype.queryByName("item", iflow_connector.covers(prototype_name, DEFAULT_DIR))

    if State.starting_fluidbox then -- TODO: optimize
        if State.ending_fluidbox then
            State.dotted_line_coord = {State.starting_fluidbox.x, State.starting_fluidbox.y, State.ending_fluidbox.x, State.ending_fluidbox.y, dir, dir_delta}
        else
            State.dotted_line_coord = {State.starting_fluidbox.x, State.starting_fluidbox.y, State.to_x, State.to_y, dir, dir_delta}
        end
    else
        State.dotted_line_coord = {State.from_x, State.from_y, State.to_x, State.to_y, dir, dir_delta}
    end
    _check_dotted_line(table.unpack(State.dotted_line_coord))

    local from_x, from_y
    if State.starting_fluidbox then
        from_x, from_y = State.starting_fluidbox.x, State.starting_fluidbox.y
    else
        from_x, from_y = State.from_x, State.from_y
    end
    local to_x, to_y
    if State.ending_fluidbox then
        to_x, to_y = State.ending_fluidbox.x, State.ending_fluidbox.y
    else
        to_x, to_y = State.to_x, State.to_y
    end
    local x, y = assert(from_x), assert(from_y)

    local PipeToGroundState = {}
    PipeToGroundState.dir_delta = dir_delta
    PipeToGroundState.to_x = to_x
    PipeToGroundState.to_y = to_y
    PipeToGroundState.distance = 0
    PipeToGroundState.max_distance = iflow_connector.ground(typeobject.flow_type) -- The maximum distance at which an underground pipe can connect is 10 tiles, resulting in a gap of 9 tiles in between.
    PipeToGroundState.remove = {}
    PipeToGroundState.replace_object = {}
    PipeToGroundState.replace = true
    PipeToGroundState.map = {}

    while true do
        if x == from_x and y == from_y then
            x, y = _set_starting(prototype_name, State, PipeToGroundState, x, y, dir)

        elseif x == to_x and y == to_y then
            local last_x, last_y = x, y -- TODO: optimize
            x, y = _set_ending(prototype_name, State, PipeToGroundState, x, y, dir)

            -- refresh the shape of the neighboring pipe
            -- TODO: optimize
            do
                local dx, dy = last_x + dir_delta.x, last_y + dir_delta.y
                local coord = packcoord(dx, dy)
                local object = objects:coord(dx, dy, EDITOR_CACHE_NAMES)
                if object and (iprototype.is_pipe(object.prototype_name) or iprototype.is_pipe_to_ground(object.prototype_name)) then
                    local _prototype_name, _dir = iflow_connector.set_connection(object.prototype_name, object.dir, iprototype.reverse_dir(dir), false)
                    if object.prototype_name ~= _prototype_name or object.dir ~= _dir then
                        PipeToGroundState.map[coord] = {assert(_prototype_name), _dir}
                    end
                end
            end

        else
            x, y = _set_section(prototype_name, State, PipeToGroundState, x, y, dir)
        end

        if not x and not y then
            break
        end
    end

    local new_fluidflow_id = 0
    if State.succ then
        global.fluidflow_id = global.fluidflow_id + 1
        new_fluidflow_id = global.fluidflow_id
    end
    local object_state = State.succ and "construct" or "invalid_construct"
    self.coord_indicator.state = object_state

    -- TODO: pipe to ground can be replaced by pipe
    if PipeToGroundState.replace then
        for object_id in pairs(PipeToGroundState.replace_object) do
            local object = assert(objects:get(object_id))
            object = assert(objects:modify(object.x, object.y, EDITOR_CACHE_NAMES, iobject.clone))

            local item_name = _get_item_name(object.prototype_name)
            PipeToGroundState.remove[item_name] = (PipeToGroundState.remove[item_name] or 0) + 1

            iobject.remove(object)
        end
    end

    for coord, v in pairs(PipeToGroundState.map) do
        local x, y = unpackcoord(coord)
        local object = objects:coord(x, y, EDITOR_CACHE_NAMES)
        if object then
            object = assert(objects:modify(object.x, object.y, EDITOR_CACHE_NAMES, iobject.clone))
            if object.prototype_name ~= v[1] or object.dir ~= v[2] then
                if _get_item_name(object.prototype_name) ~= _get_item_name(v[1]) then
                    local item_name = _get_item_name(object.prototype_name)
                    PipeToGroundState.remove[item_name] = (PipeToGroundState.remove[item_name] or 0) + 1
                end
                object.prototype_name = v[1]
                object.dir = v[2]
            end

            object.state = object_state
        else
            object = iobject.new {
                prototype_name = v[1],
                dir = v[2],
                x = x,
                y = y,
                srt = {
                    t = terrain:get_position_by_coord(x, y, iprototype.rotate_area(typeobject.area, dir)),
                },
                fluid_name = State.fluid_name,
                fluidflow_id = new_fluidflow_id,
                state = object_state,
                object_state = "none",
            }
            objects:set(object, EDITOR_CACHE_NAMES[1])
        end
    end

    if State.succ then
        for fluidflow_id in pairs(State.fluidflow_ids) do
            for _, object in objects:selectall("fluidflow_id", fluidflow_id, EDITOR_CACHE_NAMES) do
                local _object = objects:modify(object.x, object.y, EDITOR_CACHE_NAMES, iobject.clone)
                assert(iprototype.has_type(iprototype.queryByName("entity", _object.prototype_name).type, "fluidbox"))
                _object.fluid_name = State.fluid_name
                _object.fluidflow_id = new_fluidflow_id
            end
        end
    end

    _show_dotted_line(self, table.unpack(State.dotted_line_coord))

    datamodel.show_laying_pipe_confirm = State.succ
end

local function _builder_init(self, datamodel)
    local coord_indicator = self.coord_indicator
    local prototype_name = self.coord_indicator.prototype_name

    local function show_indicator(prototype_name, object)
        local succ, dx, dy, obj, _prototype_name, _dir
        for _, fb in ipairs(_get_covers_fluidbox(object)) do
            succ, dx, dy = terrain:move_coord(fb.x, fb.y, fb.dir, 1)
            if not succ then
                goto continue
            end
            if not self:check_construct_detector(prototype_name, dx, dy) then
                goto continue
            end

            obj = objects:coord(dx, dy, EDITOR_CACHE_NAMES)
            if obj then
                -- pipe can replace other pipe
                if not iprototype.is_pipe(obj.prototype_name) and not iprototype.is_pipe_to_ground(obj.prototype_name) then
                    goto continue
                end
            end

            -- NOTE: different from pipe_builder
            _prototype_name, _dir = iflow_connector.set_connection(prototype_name, fb.dir, iprototype.reverse_dir(fb.dir), true)
            if _prototype_name then
                local typeobject = iprototype.queryByName("entity", _prototype_name)
                obj = iobject.new {
                    prototype_name = _prototype_name,
                    dir = _dir,
                    x = dx,
                    y = dy,
                    srt = {
                        t = terrain:get_position_by_coord(dx, dy, iprototype.rotate_area(typeobject.area, _dir)),
                    },
                    fluid_name = "",
                    state = "indicator",
                    object_state = "none",
                }
                objects:set(obj, "INDICATOR")
            end
            ::continue::
        end
    end

    local function is_valid_starting(x, y)
        local object = objects:coord(x, y, EDITOR_CACHE_NAMES)
        if not object then
            return true
        end
        return #_get_covers_fluidbox(object) > 0
    end

    if is_valid_starting(coord_indicator.x, coord_indicator.y) then
        datamodel.show_laying_pipe_begin = true
        coord_indicator.state = "construct"

        local object = objects:coord(coord_indicator.x, coord_indicator.y, EDITOR_CACHE_NAMES)
        if object then
            show_indicator(prototype_name, object)
        end
    else
        datamodel.show_laying_pipe_begin = false
        coord_indicator.state = "invalid_construct"
    end
end

-- sort by distance and direction
local function _find_starting_fluidbox(object, dx, dy, dir)
    local fluidboxes = _get_covers_fluidbox(object)
    assert(#fluidboxes > 0) -- promised by _builder_init()

    local function _get_distance(x1, y1, x2, y2)
        return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
    end

    table.sort(fluidboxes, function(a, b)
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
    return fluidboxes[1]
end

local function _builder_start(self, datamodel)
    local from_x, from_y = self.from_x, self.from_y
    local to_x, to_y = self.coord_indicator.x, self.coord_indicator.y
    local prototype_name = self.coord_indicator.prototype_name
    local starting = objects:coord(from_x, from_y, EDITOR_CACHE_NAMES)
    local dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)

    local State = {
        succ = true,
        fluid_name = "",
        fluidflow_ids = {},
        starting_fluidbox = nil,
        starting_fluidflow_id = nil,
        ending_fluidbox = nil,
        ending_fluidflow_id = nil,
        from_x = from_x,
        from_y = from_y,
        to_x = to_x,
        to_y = to_y,
        dotted_line_coord = {},
    }

    if starting then
        -- starting object should at least have one fluidbox, promised by _builder_init()
        local fluidbox = _find_starting_fluidbox(starting, to_x, to_y, dir)
        State.starting_fluidbox, State.starting_fluidflow_id = fluidbox, starting.fluidflow_id
        if fluidbox.dir ~= dir then
            State.succ = false
        end

        local succ
        succ, to_x, to_y = terrain:move_coord(fluidbox.x, fluidbox.y, dir,
            math_abs(to_x - fluidbox.x),
            math_abs(to_y - fluidbox.y)
        )

        if not succ then
            State.succ = false
        end

        local ending = objects:coord(to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            if starting.id == ending.id then
                State.succ = false
                State.ending_fluidbox, State.ending_fluidflow_id = fluidbox, ending.fluidflow_id
            else
                for _, another in ipairs(_get_covers_fluidbox(ending)) do
                    if another.dir ~= iprototype.reverse_dir(dir) then
                        goto continue
                    end
                    succ, to_x, to_y = terrain:move_coord(fluidbox.x, fluidbox.y, dir,
                        math_abs(another.x - fluidbox.x),
                        math_abs(another.y - fluidbox.y)
                    )
                    if not succ then
                        goto continue
                    end
                    if to_x == another.x and to_y == another.y then
                        State.ending_fluidbox, State.ending_fluidflow_id = another, ending.fluidflow_id
                        _builder_end(self, datamodel, State, dir, delta)
                        return
                    end
                    ::continue::
                end
                State.succ = false
            end
        end

        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(fluidbox.x, fluidbox.y, to_x, to_y)
        _builder_end(self, datamodel, State, dir, delta)
        return
    else
        if not self:check_construct_detector(prototype_name, from_x, from_y, DEFAULT_DIR) then
            State.succ = false
        end
        State.from_x, State.from_y = from_x, from_y

        local ending = objects:coord(to_x, to_y, EDITOR_CACHE_NAMES)
        if ending then
            -- find one fluidbox that is matched with the direction specified, not the pipe to ground
            for _, fluidbox in ipairs(_get_covers_fluidbox(ending)) do
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
                    State.ending_fluidbox, State.ending_fluidflow_id = fluidbox, ending.fluidflow_id
                    _builder_end(self, datamodel, State, dir, delta)
                    return
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
        if not self:check_construct_detector(prototype_name, to_x, to_y, DEFAULT_DIR) then
            State.succ = false
        end
        State.to_x, State.to_y = to_x, to_y
        dir, delta = iprototype.calc_dir(from_x, from_y, to_x, to_y)
        _builder_end(self, datamodel, State, dir, delta)
        return
    end
end

--------------------------------------------------------------------------------------------------
local function new_entity(self, datamodel, typeobject)
    if not self.grid_entity then
        self.grid_entity = igrid_entity.create("polyline_grid", terrain._width, terrain._height, terrain.tile_size, {t = {0, 8.5, 0}})
        self.grid_entity:show(true)
    end

    iobject.remove(self.coord_indicator)
    local dir = DEFAULT_DIR
    local x, y = iobject.central_coord(typeobject.name, dir)
    self.coord_indicator = iobject.new {
        prototype_name = typeobject.name,
        dir = dir,
        x = x,
        y = y,
        srt = {
            t = terrain:get_position_by_coord(x, y, iprototype.rotate_area(typeobject.area, dir)),
        },
        fluid_name = "",
        state = "construct",
        object_state = "none",
    }

    --
    _builder_init(self, datamodel)
end

local function touch_move(self, datamodel, delta_vec)
    if self.coord_indicator then
        iobject.move_delta(self.coord_indicator, delta_vec)
    end
end

local function touch_end(self, datamodel)
    if not self.coord_indicator then
        return
    end
    local x, y
    self.coord_indicator, x, y = iobject.align(self.coord_indicator)
    self.coord_indicator.x, self.coord_indicator.y = x, y

    self:revert_changes({"INDICATOR", "TEMPORARY"})
    self.dotted_line:show(false) -- NOTE: different from pipe_builder

    if self.state ~= STATE_START then
        _builder_init(self, datamodel)
    else
        _builder_start(self, datamodel)
    end
end

local function complete(self, datamodel)
    self.super.complete(self)
    if self.grid_entity then
        self.grid_entity:remove()
    end

    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil

    self:revert_changes({"INDICATOR", "TEMPORARY"})

    datamodel.show_rotate = false
    datamodel.show_laying_pipe_confirm = false
    datamodel.show_laying_pipe_cancel = false
    datamodel.show_laying_pipe_begin = false
end

local function laying_pipe_begin(self, datamodel)
    local x, y
    self.coord_indicator, x, y = iobject.align(self.coord_indicator)
    self.coord_indicator.x, self.coord_indicator.y = x, y

    self:revert_changes({"INDICATOR", "TEMPORARY"})
    datamodel.show_laying_pipe_begin = false
    datamodel.show_laying_pipe_cancel = true

    self.state = STATE_START
    self.from_x = self.coord_indicator.x
    self.from_y = self.coord_indicator.y

    _builder_start(self, datamodel)
end

local function laying_pipe_cancel(self, datamodel)
    self:revert_changes({"INDICATOR", "TEMPORARY"})
    local typeobject = iprototype.queryByName("entity", self.coord_indicator.prototype_name)
    self:new_entity(datamodel, typeobject)

    self.state = STATE_NONE
    datamodel.show_laying_pipe_confirm = false
    datamodel.show_laying_pipe_cancel = false
end

local function laying_pipe_confirm(self, datamodel)
    for _, object in objects:all("TEMPORARY") do
        object.state = "confirm"
        object.PREPARE = true
    end
    objects:commit("TEMPORARY", "CONFIRM")

    if self.dotted_line then -- NOTE: different from pipe_builder
        self.dotted_line:show(false)
    end

    local typeobject = iprototype.queryByName("entity", self.coord_indicator.prototype_name)
    self:new_entity(datamodel, typeobject)

    self.state = STATE_NONE
    datamodel.show_laying_pipe_confirm = false
    datamodel.show_laying_pipe_cancel = false
end

local function clean(self, datamodel)
    if self.grid_entity then
        self.grid_entity:remove()
    end

    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil

    if self.dotted_line then -- NOTE: different from pipe_builder
        self.dotted_line:remove()
        self.dotted_line = nil
    end

    self:revert_changes({"INDICATOR", "TEMPORARY"})
    datamodel.show_rotate = false
    self.state = STATE_NONE
    datamodel.show_laying_pipe_confirm = false
    datamodel.show_laying_pipe_cancel = false
    datamodel.show_laying_pipe_begin = false
    self.super.clean(self, datamodel)
end

local function create()
    local builder = create_builder()

    local M = setmetatable({super = builder}, {__index = builder})
    M.new_entity = new_entity
    M.touch_move = touch_move
    M.touch_end = touch_end
    M.complete = complete

    M.clean = clean

    M.prototype_name = ""
    M.state = STATE_NONE
    M.laying_pipe_begin = laying_pipe_begin
    M.laying_pipe_cancel = laying_pipe_cancel
    M.laying_pipe_confirm = laying_pipe_confirm
    M.dotted_line = iquad_lines_entity.create(dotted_line_material) -- NOTE: different from pipe_builder

    return M
end
return create