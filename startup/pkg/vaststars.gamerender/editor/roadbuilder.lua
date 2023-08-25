local ecs = ...
local world = ecs.world

local create_builder = ecs.require "editor.builder"
local iprototype = require "gameplay.interface.prototype"
local iconstant = require "gameplay.interface.constant"
local iobject = ecs.require "object"
local objects = require "objects"
local terrain = ecs.require "terrain"
local EDITOR_CACHE_NAMES = {"TEMPORARY", "CONFIRM", "CONSTRUCTED"}
local task = ecs.require "task"
local iroadnet_converter = require "roadnet_converter"
local igrid_entity = ecs.require "engine.grid_entity"
local iroadnet = ecs.require "roadnet"
local math3d = require "math3d"
local gameplay_core = require "gameplay.core"
local create_pickup_selected_box = ecs.require "editor.common.pickup_selected_box"
local create_road_next_box = ecs.require "editor.common.road_next_box"
local ROTATORS <const> = require("gameplay.interface.constant").ROTATORS
local GRID_POSITION_OFFSET <const> = math3d.constant("v4", {0, 0.2, 0, 0.0})
local DEFAULT_DIR <const> = require("gameplay.interface.constant").DEFAULT_DIR
local ibuilding = ecs.require "render_updates.building"
local icamera_controller = ecs.require "engine.system.camera_controller"
local iroad = ecs.require "vaststars.gamerender|render_updates.road"
local ROAD_SIZE <const> = 2
local CHANGED_FLAG_ROADNET <const> = require("gameplay.interface.constant").CHANGED_FLAG_ROADNET
local imountain = ecs.require "engine.mountain"

local function isValidRoadCoord(x, y, cache_names)
    for i = 0, ROAD_SIZE - 1 do
        for j = 0, ROAD_SIZE - 1 do
            local object = objects:coord(x + i, y + j, cache_names)
            if object then
                return false
            end
        end
    end
    if terrain:get_mineral(x, y) then
        return false
    end
    if imountain:has_mountain(x, y) then
        return false
    end
    return true
end

local function updateComponentsStatus(self)
    local coord_indicator = self.coord_indicator
    local show_confirm = isValidRoadCoord(coord_indicator.x, coord_indicator.y, EDITOR_CACHE_NAMES)
    for _, c in pairs(self.pickup_components) do
        c:on_status_change(show_confirm)
    end
end

local function updateComponentsPosition(self)
    local coord_indicator = self.coord_indicator
    for _, c in pairs(self.pickup_components) do
        c:on_position_change(coord_indicator.srt, coord_indicator.dir)
    end
end

local function __align(position, area, dir)
    local coord_system = terrain
    local coord = coord_system["align"](coord_system, position, iprototype.rotate_area(area, dir))
    if not coord then
        return
    end
    coord[1], coord[2] = coord[1] - (coord[1] % ROAD_SIZE), coord[2] - (coord[2] % ROAD_SIZE)
    local t = math3d.ref(math3d.vector(coord_system:get_position_by_coord(coord[1], coord[2], iprototype.rotate_area(area, dir))))
    return t, coord[1], coord[2]
end

local function setRoad(x, y, mask)
    local prototype_name, dir = iroadnet_converter.mask_to_prototype_name_dir(mask)
    ibuilding.set {
        x = x,
        y = y,
        prototype_name = prototype_name,
        direction = dir,
        road = true,
    }
    iroadnet:set("road", "normal", x, y, mask)
end

local function getRoad(x, y)
    local road = ibuilding.get(x, y)
    if not road then
        return
    end
    return iroadnet_converter.prototype_name_dir_to_mask(road.prototype, road.direction)
end

local function packarea(w, h)
    return (w << 8) | h
end

--------------------------------------------------------------------------------------------------
local function new_entity(self, datamodel, typeobject, x, y)
    local dir = DEFAULT_DIR
    assert(x and y)

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

    if not self.pickup_components.grid_entity then
        local position = __align(self.coord_indicator.srt.t, packarea(8 * ROAD_SIZE, 8 * ROAD_SIZE), dir)
        position = math3d.add(position, GRID_POSITION_OFFSET)
        local offset = math3d.ref(math3d.sub(self.coord_indicator.srt.t, position))
        self.pickup_components.grid_entity = igrid_entity.create(
            terrain._width // ROAD_SIZE,
            terrain._height // ROAD_SIZE,
            terrain.tile_size * ROAD_SIZE,
            {t = self.coord_indicator.srt.t},
            offset
        )
    end
    if not self.pickup_components.selected_box then
        self.pickup_components.selected_box = create_pickup_selected_box(self.coord_indicator.srt.t, typeobject.area, dir, true)
    end
    if not self.pickup_components.next_box then
        local dx, dy = iprototype.move_coord(x, y, self.forward_dir, ROAD_SIZE)
        local position = math3d.ref(math3d.vector(terrain:get_position_by_coord(dx, dy, iprototype.rotate_area(typeobject.area, dir))))
        self.pickup_components.next_box = create_road_next_box(position, typeobject.area, dir, true, self.forward_dir)
    end

    datamodel.show_rotate = true
    --
    updateComponentsPosition(self)
    updateComponentsStatus(self)
end

local function touch_move(self, datamodel, delta_vec)
    if self.coord_indicator then
        iobject.move_delta(self.coord_indicator, delta_vec)
    end
    updateComponentsPosition(self)
end

local function touch_end(self, datamodel)
    local coord_indicator = self.coord_indicator
    if not coord_indicator then
        return
    end

    local typeobject = iprototype.queryByName(coord_indicator.prototype_name)
    coord_indicator.srt.t, coord_indicator.x, coord_indicator.y = __align(icamera_controller.get_central_position(), typeobject.area, coord_indicator.dir)

    updateComponentsPosition(self)
    updateComponentsStatus(self)
    return false
end

local function place(self, datamodel)
    local coord_indicator = self.coord_indicator
    local x, y = coord_indicator.x, coord_indicator.y
    if not isValidRoadCoord(coord_indicator.x, coord_indicator.y, EDITOR_CACHE_NAMES) then
        return
    end
    assert(x % 2 == 0 and y % 2 == 0)

    local mask = getRoad(x, y) or 0
    for _, dir in ipairs(iconstant.ALL_DIR_NUM) do
        local dx, dy = iprototype.move_coord(x, y, dir, ROAD_SIZE, ROAD_SIZE)
        local m = getRoad(dx, dy)
        if m then
            local rev = iprototype.reverse_dir(dir)
            if not iroad.check(m, rev) then
                setRoad(dx, dy, iroad.open(m, rev))
            end

            --
            if not iroad.check(mask, dir) then
                mask = iroad.open(mask, dir)
            end
        end
    end

    setRoad(x, y, mask)
    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil

    iroadnet:update()
    gameplay_core.set_changed(CHANGED_FLAG_ROADNET)
    task.update_progress("road_laying", 0)

    local dx, dy = iprototype.move_coord(x, y, self.forward_dir, ROAD_SIZE)
    self:new_entity(datamodel, self.typeobject, dx, dy)

    icamera_controller.focus_on_position(terrain:get_position_by_coord(dx, dy, ROAD_SIZE, ROAD_SIZE))
end

local function clean(self, datamodel)
    iobject.remove(self.coord_indicator)
    self.coord_indicator = nil

    for _, c in pairs(self.pickup_components) do
        c:remove()
    end
    self.pickup_components = {}

    datamodel.show_rotate = false
    iroadnet:update()
end

local function rotate(self)
    self.forward_dir = iprototype.rotate_dir_times(self.forward_dir, -1)
    for _, c in pairs(self.pickup_components) do
        if c.set_forward_dir then
            c:set_forward_dir(self.forward_dir)
            c:on_position_change(self.coord_indicator.srt, self.coord_indicator.dir)
        end
    end
end

local function remove_one(self, datamodel, x, y)
    ibuilding.remove(x, y)
    iroadnet:del("road", x, y)

    iroadnet:update()
    gameplay_core.set_changed(CHANGED_FLAG_ROADNET)
end

local function create()
    local builder = create_builder()

    local M = setmetatable({super = builder}, {__index = builder})
    M.new_entity = new_entity
    M.touch_move = touch_move
    M.touch_end = touch_end
    M.rotate = rotate
    M.remove_one = remove_one

    M.confirm = place
    M.clean = clean

    M.pickup_components = {}
    M.typeobject = nil
    M.forward_dir = DEFAULT_DIR

    return M
end
return create