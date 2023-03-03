local ecs = ...
local world = ecs.world

local icanvas = ecs.require "engine.canvas"
local vsobject_manager = ecs.require "vsobject_manager"
local iprototype = require "gameplay.interface.prototype"
local get_assembling_canvas_items = ecs.require "ui_datamodel.common.assembling_canvas".get_assembling_canvas_items
local get_fluid_canvas_items = ecs.require "ui_datamodel.common.fluid_canvas".get_fluid_canvas_items
local get_building_base_canvas_items = ecs.require "ui_datamodel.common.building_base_canvas".get_building_base_canvas_items
local math3d = require "math3d"
local terrain = ecs.require "terrain"
local camera = ecs.require "engine.camera"
local changeset = {}
local removed = {}

local _new_object_id; do
    local id = 0
    function _new_object_id()
        id = id + 1
        return id
    end
end

local mt = {
    __index = function(t, k)
        return t.__lastversion[k]
    end,
    __newindex = function(t, k, v)
        t.__change_keys[k] = true
        t.__lastversion[k] = v
        changeset[t.__lastversion.id] = t
    end,
    __pairs = function (t)
        return function(t, key)
            return next(t.__lastversion, key)
        end, t
    end,
}

local function new(init)
    local t = {}
    t.__change_keys = {}
	t.__lastversion = {
        id = _new_object_id(),
        prototype_name = assert(init.prototype_name),
        dir = assert(init.dir), 
        x = assert(init.x),
        y = assert(init.y),
        fluid_name = init.fluid_name,
        fluidflow_id = init.fluidflow_id,
        state = assert(init.state),
        object_state = assert(init.object_state),
        recipe = init.recipe,
        fluid_icon = init.fluid_icon,
        srt = init.srt,
    }

    local outer = setmetatable(t, mt)
    changeset[t.__lastversion.id] = outer
    return outer
end

local function clone(outer)
    local t = {}
    t.__change_keys = {}
	t.__lastversion = {
        id = outer.id or _new_object_id(),
        prototype_name = assert(outer.prototype_name),
        dir = assert(outer.dir),
        x = assert(outer.x),
        y = assert(outer.y),
        fluid_name = outer.fluid_name,
        fluidflow_id = outer.fluidflow_id,
        state = assert(outer.state),
        gameplay_eid = outer.gameplay_eid,
        recipe = outer.recipe,
        fluid_icon = outer.fluid_icon,
        srt = {s = outer.srt.s, r = outer.srt.r, t = outer.srt.t},
    }

    local outer = setmetatable(t, mt)
    changeset[t.__lastversion.id] = outer
    return outer
end

local function remove(outer)
    if not outer then
        return
    end

    removed[outer.id] = true
end

local function flush()
    local funcs = {
        prototype_name = function(outer)
            local vsobject = assert(vsobject_manager:get(outer.id))
            vsobject:update {prototype_name = outer.prototype_name, srt = outer.srt}
        end,
        dir = function(outer)
            local vsobject = assert(vsobject_manager:get(outer.id))
            vsobject:set_dir(outer.dir)
        end,
        state = function(outer)
            local vsobject = assert(vsobject_manager:get(outer.id))
            vsobject:update {type = outer.state, srt = outer.srt}
        end,
        srt = function(outer)
            local vsobject = assert(vsobject_manager:get(outer.id))
            vsobject:set_position(outer.srt.t)
        end,
    }

    local prepare = {}
    local appear = {}

    local vsobject
    for object_id, outer in pairs(changeset) do
        if removed[object_id] then
            goto continue
        end
        vsobject = vsobject_manager:get(object_id)
        local typeobject = iprototype.queryByName(outer.prototype_name)
        outer.srt = outer.srt or {}
        local w, h = iprototype.unpackarea(typeobject.area) -- TODO: duplicate code

        if not vsobject then
            vsobject = vsobject_manager:create {
                id = outer.id,
                prototype_name = outer.prototype_name,
                dir = outer.dir,
                position = outer.srt.t,
                type = outer.state,
                group_id = terrain:get_group_id(outer.x, outer.y),
            }

            -- display recipe icon of assembling machine
            if outer.recipe then
                vsobject:add_canvas(icanvas.types().ICON, get_assembling_canvas_items(outer, outer.x, outer.y, w, h))
            end
            if outer.fluid_icon and type(outer.fluid_name) == "string" and outer.fluid_name ~= "" then
                vsobject:add_canvas(icanvas.types().ICON, get_fluid_canvas_items(outer, outer.x, outer.y, w, h))
            end
        else
            for k in pairs(outer.__change_keys) do
                local func = funcs[k]
                if func then
                    func(outer)
                end
            end

            -- display recipe icon of assembling machine
            -- TODO: special case for mining & chimney
            -- refresh recipe icon of assembling machine when recipe changed or direction changed
            if (outer.__change_keys.recipe or outer.__change_keys.dir) and not iprototype.has_type(typeobject.type, "mining") and not iprototype.has_type(typeobject.type, "chimney") and iprototype.has_type(typeobject.type, "assembling") and not typeobject.recipe then
                if outer.recipe then
                    vsobject:add_canvas(icanvas.types().ICON, get_assembling_canvas_items(outer, outer.x, outer.y, w, h))
                end
            end
            if outer.__change_keys.fluid_icon and type(outer.fluid_name) == "string" and outer.fluid_name ~= "" then
                vsobject:add_canvas(icanvas.types().ICON, get_fluid_canvas_items(outer, outer.x, outer.y, w, h))
            end
        end
        if typeobject.building_base ~= false then
            vsobject:add_canvas(icanvas.types().BUILDING_BASE, get_building_base_canvas_items(outer.srt, w, h))
        end

        if outer.PREPARE then
            prepare[#prepare+1] = outer
            outer.PREPARE = nil
        end

        if outer.APPEAR then
            appear[#appear+1] = outer
            outer.APPEAR = nil
        end

        outer.__change_keys = {}
        ::continue::
    end
    changeset = {}

    for object_id in pairs(removed) do
        vsobject_manager:remove(object_id)
    end
    removed = {}

    for _, outer in ipairs(prepare) do
        local vsobject = vsobject_manager:get(outer.id)
        if vsobject then
            vsobject:modifier("start", {name = "confirm"})
        end
    end

    for _, outer in ipairs(appear) do
        local vsobject = vsobject_manager:get(outer.id)
        if vsobject then
            vsobject:modifier("start", {name = "appear", forwards = true})
        end
    end
end

local function move_delta(object, delta_vec, coord_system, area_inc)
    coord_system = coord_system or terrain
    local vsobject = vsobject_manager:get(object.id)
    if not vsobject then
        return
    end

    local typeobject = iprototype.queryByName(object.prototype_name)
    local position = math3d.ref(math3d.add(object.srt.t, delta_vec))
    local coord = coord_system["align"](coord_system, position, iprototype.rotate_area(typeobject.area, object.dir, area_inc, area_inc))
    if not coord then
        log.error(("can not get coord"))
        return
    end

    object.x, object.y = coord[1], coord[2]
    object.srt.t = position
    vsobject:set_position(position)
    return object
end

local function central_coord(prototype_name, dir, coord_system, area_inc)
    coord_system = coord_system or terrain
    local typeobject = iprototype.queryByName(prototype_name)
    local coord = coord_system["align"](coord_system, camera.get_central_position(), iprototype.rotate_area(typeobject.area, dir, area_inc, area_inc))
    if not coord then
        return
    end
    return coord[1], coord[2]
end

local function align(object)
    local coord_system = terrain

    assert(object)
    local typeobject = iprototype.queryByName(object.prototype_name)
    local coord = coord_system["align"](coord_system, camera.get_central_position(), iprototype.rotate_area(typeobject.area, object.dir))
    if not coord then
        return object
    end
    object.srt.t = coord_system:get_position_by_coord(coord[1], coord[2], iprototype.rotate_area(typeobject.area, object.dir))
    return object, coord[1], coord[2]
end

local function coord(object, x, y, coord_system)
    coord_system = coord_system or terrain
    assert(object)
    assert(object.prototype_name ~= "")
    local vsobject = assert(vsobject_manager:get(object.id))
    local typeobject = iprototype.queryByName(object.prototype_name)
    local position = coord_system:get_position_by_coord(x, y, iprototype.rotate_area(typeobject.area, object.dir))
    if not position then
        log.error(("can not get position"))
        return
    end
    object.x, object.y = x, y
    vsobject:set_position(position)
end

return {
    new = new,
    new_object_id = _new_object_id,
    clone = clone,
    flush = flush,
    move_delta = move_delta,
    align = align,
    central_coord = central_coord,
    coord = coord,
    remove = remove,
}