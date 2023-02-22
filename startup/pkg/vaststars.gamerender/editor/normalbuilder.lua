local ecs = ...
local world = ecs.world

local iprototype = require "gameplay.interface.prototype"
local camera = ecs.require "engine.camera"
local create_builder = ecs.require "editor.builder"
local ieditor = ecs.require "editor.editor"
local objects = require "objects"
local DEFAULT_DIR <const> = 'N'
local irecipe = require "gameplay.interface.recipe"
local global = require "global"
local iobject = ecs.require "object"
local ipower = ecs.require "power"
local ipower_line = ecs.require "power_line"
local imining = require "gameplay.interface.mining"
local math3d = require "math3d"
local iconstant = require "gameplay.interface.constant"
local logistic_coord = ecs.require "terrain"
local building_coord = require "global".building_coord_system
local ROTATORS <const> = require("gameplay.interface.constant").ROTATORS
local ALL_DIR = iconstant.ALL_DIR
local igrid_entity = ecs.require "engine.grid_entity"
local iui = ecs.import.interface "vaststars.gamerender|iui"
local mc = import_package "ant.math".constant
local create_road_entrance = ecs.require "editor.road_entrance"
local ichest = require "gameplay.interface.chest"
local gameplay_core = require "gameplay.core"
local DIRECT_BUILD <const> = require "debugger".direct_build

local function _get_state(prototype_name, ok)
    local typeobject = iprototype.queryByName("building", prototype_name)
    if typeobject.supply_area then
        if ok then
            return ("power_pole_construct_%s"):format(typeobject.supply_area)
        else
            return ("power_pole_invalid_construct_%s"):format(typeobject.supply_area)
        end
    else
        if ok then
            return "construct"
        else
            return "invalid_construct"
        end
    end
end

local function _building_to_logisitic(x, y)
    local nposition = assert(building_coord:get_begin_position_by_coord(x, y))
    nposition[1] = nposition[1] + 5
    nposition[3] = nposition[3] - 5
    local ncoord = logistic_coord:get_coord_by_position(math3d.vector(nposition)) -- building layer to logisitc layer
    if not ncoord then
        return
    end
    return ncoord[1], ncoord[2]
end

-- TODO: duplicate from roadbuilder.lua
local function _get_connections(prototype_name, x, y, dir)
    local typeobject = iprototype.queryByName("building", prototype_name)
    local r = {}
    if not typeobject.crossing then
        return r
    end

    for _, conn in ipairs(typeobject.crossing.connections) do
        local dx, dy, ddir = iprototype.rotate_connection(conn.position, dir, typeobject.area)
        r[#r+1] = {x = x + dx, y = y + dy, dir = ddir, roadside = conn.roadside}
    end
    return r
end

local function _get_road_entrance_position(typeobject, x, y, dir)
    if not typeobject.crossing then
        return
    end
    local connections = _get_connections(typeobject.name, x, y, dir)
    local conn = connections[1]
    local succ, neighbor_x, neighbor_y = logistic_coord:move_coord(conn.x, conn.y, conn.dir, 1)
    if not succ then
        return
    end
    return logistic_coord:get_position_by_coord(neighbor_x, neighbor_y, 1, 1), neighbor_x, neighbor_y, conn.dir
end

local function __new_entity(self, datamodel, typeobject)
    iobject.remove(self.pickup_object)
    local dir = DEFAULT_DIR
    local x, y = iobject.central_coord(typeobject.name, dir, building_coord, 1)
    if not x or not y then
        return
    end

    local state
    if not self:check_construct_detector(typeobject.name, x, y, dir) then
        state = _get_state(typeobject.name, false)
        datamodel.show_confirm = false
        datamodel.show_rotate = true
    else
        state = _get_state(typeobject.name, true)
        datamodel.show_confirm = true
        datamodel.show_rotate = true
    end

    -- some assembling machine have default recipe
    local fluid_name = ""
    if typeobject.recipe then
        local recipe_typeobject = iprototype.queryByName("recipe", typeobject.recipe)
        if recipe_typeobject then
            fluid_name = irecipe.get_init_fluids(recipe_typeobject) or "" -- maybe no fluid in recipe
        else
            fluid_name = ""
        end
    end

    self.pickup_object = iobject.new {
        prototype_name = typeobject.name,
        dir = dir,
        x = x,
        y = y,
        srt = {
            t = building_coord:get_position_by_coord(x, y, iprototype.rotate_area(typeobject.area, dir, 1, 1)),
        },
        fluid_name = fluid_name,
        state = state,
        object_state = "none",
    }
    iui.open({"construct_pop.rml"}, self.pickup_object.srt.t)

    local dx, dy = _building_to_logisitic(x, y)
    local road_entrance_position, _, _, road_entrance_dir = _get_road_entrance_position(typeobject, dx, dy, dir)
    if road_entrance_position then
        local srt = {t = road_entrance_position, r = ROTATORS[road_entrance_dir]}
        if datamodel.show_confirm then
            self.road_entrance = create_road_entrance(srt, "valid")
        else
            self.road_entrance = create_road_entrance(srt, "invalid")
        end
    end
end

local function new_entity(self, datamodel, typeobject)
    __new_entity(self, datamodel, typeobject)
    self.pickup_object.APPEAR = true

    if not self.grid_entity then
        self.grid_entity = igrid_entity.create("polyline_grid", building_coord.tile_width, building_coord.tile_height, logistic_coord.tile_size, {t = {0, 1, 0}})
        self.grid_entity:show(true)
    end
end

-- TODO: duplicate from builder.lua
local function _get_mineral_recipe(prototype_name, x, y, dir)
    local typeobject = iprototype.queryByName("building", prototype_name)
    local w, h = iprototype.rotate_area(typeobject.area, dir)

    if not iprototype.has_type(typeobject.type, "mining") then
        return
    end
    local found
    for i = 0, w - 1 do
        for j = 0, h - 1 do
            local mineral = logistic_coord:get_mineral(x + i, y + j) -- TODO: maybe have multiple minerals in the area
            if mineral then
                found = mineral
            end
        end
    end

    if not found then
        return
    end

    return imining.get_mineral_recipe(prototype_name, found)
end

local function __align(object)
    assert(object)
    local typeobject = iprototype.queryByName("building", object.prototype_name)
    local coord, srt = building_coord:align(camera.get_central_position(), iprototype.rotate_area(typeobject.area, object.dir, 1, 1))
    if not coord then
        return object
    end
    object.srt.t = srt
    return object, coord[1], coord[2]
end

local function touch_move(self, datamodel, delta_vec)
    if not self.pickup_object then
        return
    end
    local pickup_object = self.pickup_object
    iobject.move_delta(pickup_object, delta_vec, building_coord, 1)

    local x, y
    self.pickup_object, x, y = __align(self.pickup_object)
    x, y = _building_to_logisitic(x, y)
    if not x then
        pickup_object.state = _get_state(pickup_object.prototype_name, false)
        datamodel.show_confirm = false
        return
    end
    pickup_object.x, pickup_object.y = x, y

    local typeobject = iprototype.queryByName("building", pickup_object.prototype_name)

    if self.road_entrance then
        local road_entrance_position, _, _, road_entrance_dir = _get_road_entrance_position(typeobject, x, y, pickup_object.dir)
        self.road_entrance:set_srt(mc.ONE, ROTATORS[road_entrance_dir], road_entrance_position)

        local t = {}
        for _, dir in ipairs(ALL_DIR) do
            local _, dx, dy = _get_road_entrance_position(typeobject, x, y, dir)
            if dx and dy then
                if global.roadnet[iprototype.packcoord(dx, dy)] then
                    t[#t+1] = dir
                end
            end
        end
        if #t == 1 and t[1] ~= pickup_object.dir then
            self:rotate_pickup_object(datamodel, t[1], delta_vec)
        end
    end

    if not self:check_construct_detector(pickup_object.prototype_name, x, y, pickup_object.dir) then
        pickup_object.state = _get_state(pickup_object.prototype_name, false)
        datamodel.show_confirm = false

        if self.road_entrance then
            self.road_entrance:set_state("invalid")
        end
        return
    else
        if self.road_entrance then
            self.road_entrance:set_state("valid")
        end
    end

    pickup_object.recipe = _get_mineral_recipe(pickup_object.prototype_name, x, y, pickup_object.dir) -- TODO: maybe set recipt according to entity type?

    -- update temp pole
    if typeobject.supply_area and typeobject.supply_distance then
        local aw, ah = iprototype.unpackarea(typeobject.area)
        local sw, sh = typeobject.supply_area:match("(%d+)x(%d+)")
        ipower:merge_pole({key = pickup_object.id, targets = {}, x = x, y = y, w = aw, h = ah, sw = tonumber(sw), sh = tonumber(sh), sd = typeobject.supply_distance, smooth_pos = true})
        ipower_line.update_temp_line(ipower:get_temp_pole())
    end
end

local function touch_end(self, datamodel)
    ieditor:revert_changes({"TEMPORARY"})

    local pickup_object = self.pickup_object
    if not pickup_object then
        return
    end

    local x, y
    self.pickup_object, x, y = __align(self.pickup_object)
    x, y = _building_to_logisitic(x, y)
    if not x then
        return
    end
    pickup_object.x, pickup_object.y = x, y

    local typeobject = iprototype.queryByName("building", pickup_object.prototype_name)

    if self.road_entrance then
        local road_entrance_position, _, _, road_entrance_dir = _get_road_entrance_position(typeobject, x, y, pickup_object.dir)
        self.road_entrance:set_srt(mc.ONE, ROTATORS[road_entrance_dir], road_entrance_position)
    end

    if not self:check_construct_detector(pickup_object.prototype_name, pickup_object.x, pickup_object.y, pickup_object.dir) then
        pickup_object.state = _get_state(pickup_object.prototype_name, false)
        datamodel.show_confirm = false
        if self.road_entrance then
            self.road_entrance:set_state("invalid")
        end
        return
    else
        pickup_object.state = _get_state(pickup_object.prototype_name, true)
        datamodel.show_confirm = true
        if self.road_entrance then
            self.road_entrance:set_state("valid")
        end
    end

    pickup_object.recipe = _get_mineral_recipe(pickup_object.prototype_name, pickup_object.x, pickup_object.y, pickup_object.dir) -- TODO: maybe set recipt according to entity type?

    -- update temp pole
    if typeobject.supply_area and typeobject.supply_distance then
        local aw, ah = iprototype.unpackarea(typeobject.area)
        local sw, sh = typeobject.supply_area:match("(%d+)x(%d+)")
        ipower:merge_pole({key = pickup_object.id, targets = {}, x = self.pickup_object.x, y = self.pickup_object.y, w = aw, h = ah, sw = tonumber(sw), sh = tonumber(sh), sd = typeobject.supply_distance})
        ipower_line.update_temp_line(ipower:get_temp_pole())
    end
end

local function confirm(self, datamodel)
    local pickup_object = assert(self.pickup_object)
    local succ = self:check_construct_detector(pickup_object.prototype_name, pickup_object.x, pickup_object.y, pickup_object.dir)
    if not succ then
        log.info("can not construct")
        return
    end

    local typeobject = iprototype.queryByName("building", pickup_object.prototype_name)
    if typeobject.supply_area then
        pickup_object.state = ("power_pole_confirm_%s"):format(typeobject.supply_area)
    else
        pickup_object.state = "confirm"
    end
    objects:set(pickup_object, "CONFIRM")
    pickup_object.PREPARE = true
    pickup_object.object_state = "confirm"

    datamodel.show_confirm = false
    datamodel.show_rotate = false
    --
    if typeobject.supply_area and typeobject.supply_distance then
        local aw, ah = iprototype.unpackarea(typeobject.area)
        local sw, sh = typeobject.supply_area:match("(%d+)x(%d+)")
        ipower:merge_pole({key = pickup_object.id, targets = {}, x = pickup_object.x, y = pickup_object.y, w = aw, h = ah, sw = tonumber(sw), sh = tonumber(sh), sd = typeobject.supply_distance}, true)
        ipower_line.update_temp_line(ipower:get_temp_pole())
    end

    do
        global.construct_queue:put(pickup_object.prototype_name, pickup_object.id)
        local typeobject = iprototype.queryByName("item", pickup_object.prototype_name)
        local slot = global.base_chest_cache[typeobject.id] or {amount = 0}
        local count = slot.amount
        local request_count = global.construct_queue:size(pickup_object.prototype_name)
        if count < request_count then
            if DIRECT_BUILD then
                ichest.base_add_req_force(gameplay_core.get_world(), pickup_object.prototype_name, 1)
            else
                ichest.base_add_req(gameplay_core.get_world(), pickup_object.prototype_name, 1)
            end
        end
        gameplay_core.build()
    end

    self.pickup_object = nil
    if self.road_entrance then
        self.road_entrance:remove()
        self.road_entrance = nil
    end
    __new_entity(self, datamodel, typeobject)
end

local function complete(self, datamodel, object_id)
    if self.grid_entity then
        self.grid_entity:remove()
        self.grid_entity = nil
    end
    iobject.remove(self.pickup_object)
    self.pickup_object = nil

    ieditor:revert_changes({"TEMPORARY", "POWER_AREA"})
    datamodel.show_rotate = false
    datamodel.show_confirm = false

    self.super.complete(self, object_id)
end

local function check_construct_detector(self, prototype_name, x, y, dir)
    local succ = self.super:check_construct_detector(prototype_name, x, y, dir)
    if not succ then
        return false
    end

    local typeobject = iprototype.queryByName("building", prototype_name)
    if typeobject.crossing then
        local valid = false
        for _, conn in ipairs(_get_connections(prototype_name, x, y, dir)) do
            if not conn.roadside then
                goto continue
            end

            local succ, dx, dy = logistic_coord:move_coord(conn.x, conn.y, conn.dir, 1)
            if not succ then
                goto continue
            end

            if global.roadnet[iprototype.packcoord(dx, dy)] then
                valid = true
                break
            end
            ::continue::
        end

        if not valid then
            return false
        end
    end

    return true
end

local function rotate_pickup_object(self, datamodel, dir, delta_vec)
    local pickup_object = assert(self.pickup_object)

    ieditor:revert_changes({"TEMPORARY"})
    dir = dir or iprototype.rotate_dir_times(pickup_object.dir, -1)

    local typeobject = iprototype.queryByName("building", pickup_object.prototype_name)
    local coord = building_coord:align(camera.get_central_position(), iprototype.rotate_area(typeobject.area, dir, 1, 1))
    if not coord then
        return
    end

    if not self:check_construct_detector(pickup_object.prototype_name, pickup_object.x, pickup_object.y, dir) then
        pickup_object.state = _get_state(pickup_object.prototype_name, false)
        datamodel.show_confirm = false
        datamodel.show_rotate = true
    else
        pickup_object.state = _get_state(pickup_object.prototype_name, true)
        datamodel.show_confirm = true
        datamodel.show_rotate = true
    end

    pickup_object.dir = dir

    local x, y = _building_to_logisitic(coord[1], coord[2])
    if not x then
        return
    end
    pickup_object.x, pickup_object.y = x, y

    local road_entrance_position, dx, dy, ddir = _get_road_entrance_position(typeobject, x, y, pickup_object.dir)
    if road_entrance_position then
        self.road_entrance:set_srt(mc.ONE, ROTATORS[ddir], road_entrance_position)
    end
end

local function clean(self, datamodel)
    if self.grid_entity then
        self.grid_entity:remove()
        self.grid_entity = nil
    end

    ieditor:revert_changes({"TEMPORARY", "POWER_AREA"})
    datamodel.show_confirm = false
    datamodel.show_rotate = false
    self.super.clean(self, datamodel)
    -- clear temp pole
    ipower:clear_all_temp_pole()
    ipower_line.update_temp_line(ipower:get_temp_pole())

    if self.road_entrance then
        self.road_entrance:remove()
        self.road_entrance = nil
    end

    iui.close("construct_pop.rml")
end

local function create()
    local builder = create_builder()

    local M = setmetatable({super = builder}, {__index = builder})
    M.new_entity = new_entity
    M.touch_move = touch_move
    M.touch_end = touch_end
    M.confirm = confirm
    M.complete = complete
    M.rotate_pickup_object = rotate_pickup_object
    M.clean = clean
    M.check_construct_detector = check_construct_detector

    return M
end
return create