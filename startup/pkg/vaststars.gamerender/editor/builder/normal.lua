local ecs = ...
local world = ecs.world

local CONSTANT <const> = require "gameplay.interface.constant"
local ROTATORS <const> = CONSTANT.ROTATORS
local DEFAULT_DIR <const> = CONSTANT.DEFAULT_DIR
local SPRITE_COLOR <const> = ecs.require "vaststars.prototype|sprite_color"
local MAP_WIDTH <const> = CONSTANT.MAP_WIDTH
local MAP_HEIGHT <const> = CONSTANT.MAP_HEIGHT
local TILE_SIZE <const> = CONSTANT.TILE_SIZE
local CHANGED_FLAG_BUILDING <const> = CONSTANT.CHANGED_FLAG_BUILDING
local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER

local math3d = require "math3d"
local GRID_POSITION_OFFSET <const> = math3d.constant("v4", {0, 0.2, 0, 0.0})

local iprototype = require "gameplay.interface.prototype"
local icamera_controller = ecs.require "engine.system.camera_controller"
local objects = require "objects"
local iobject = ecs.require "object"
local imining = require "gameplay.interface.mining"
local igrid_entity = ecs.require "engine.grid_entity"
local isprite = ecs.require "sprite"
local create_sprite = isprite.create
local flush_sprite = isprite.flush
local create_selected_boxes = ecs.require "selected_boxes"
local icoord = require "coord"
local gameplay_core = require "gameplay.core"
local create_fluid_indicators = ecs.require "fluid_indicators".create
local iinventory = require "gameplay.interface.inventory"
local ichest = require "gameplay.interface.chest"
local srt = require "utility.srt"
local imineral = ecs.require "mineral"
local igameplay = ecs.require "gameplay.gameplay_system"
local show_message = ecs.require "show_message".show_message

local function __create_self_sprite(typeobject, x, y, dir, sprite_color)
    local sprite
    local offset_x, offset_y = 0, 0
    if typeobject.supply_area then
        local aw, ah = iprototype.rotate_area(typeobject.supply_area, dir)
        local w, h = iprototype.rotate_area(typeobject.area, dir)
        offset_x, offset_y = -((aw - w)//2), -((ah - h)//2)
        sprite = create_sprite(x + offset_x, y + offset_y, aw, ah, sprite_color)
    end
    return sprite
end

local function __show_self_selected_boxes(self, position, typeobject, dir, valid)
    --
    local color
    if valid then
        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_SELF_VALID
    else
        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_SELF_INVALID
    end
    if not self.self_selected_boxes then
        self.self_selected_boxes = create_selected_boxes(
            {
                "/pkg/vaststars.resources/glbs/selected-box-no-animation.glb|mesh.prefab",
                "/pkg/vaststars.resources/glbs/selected-box-no-animation-line.glb|mesh.prefab",
            },
            position, color, iprototype.rotate_area(typeobject.area, dir)
        )
    else
        self.self_selected_boxes:set_wh(iprototype.rotate_area(typeobject.area, dir))
        self.self_selected_boxes:set_position(position)
        self.self_selected_boxes:set_color_transition(color, 400)
    end
end

local function _get_mineral_recipe(prototype_name, x, y, w, h)
    local typeobject = iprototype.queryByName(prototype_name)
    if not iprototype.has_type(typeobject.type, "mining") then
        return
    end
    local succ, mineral = imineral.can_place(x, y, w, h)
    if not succ then
        return
    end
    return imining.get_mineral_recipe(prototype_name, mineral)
end

local function __calc_grid_position(self, typeobject, dir)
    local _, originPosition = icoord.align(math3d.vector {0, 0, 0}, iprototype.rotate_area(typeobject.area, dir))
    local buildingPosition = icoord.position(self.pickup_object.x, self.pickup_object.y, iprototype.rotate_area(typeobject.area, dir))
    return math3d.add(math3d.sub(buildingPosition, originPosition), GRID_POSITION_OFFSET)
end

local function __get_nearby_buldings(x, y, w, h)
    local r = {}
    local begin_x, begin_y = icoord.bound(x - ((10 - w) // 2), y - ((10 - h) // 2))
    local end_x, end_y = icoord.bound(x + ((10 - w) // 2) + w, y + ((10 - h) // 2) + h)
    for x = begin_x, end_x do
        for y = begin_y, end_y do
            local object = objects:coord(x, y)
            if object then
                r[object.id] = object
            end
        end
    end
    return r
end

local function __is_building_intersect(x1, y1, w1, h1, x2, y2, w2, h2)
    local x1_1, y1_1 = x1, y1
    local x1_2, y1_2 = x1 + w1 - 1, y1
    local x1_3, y1_3 = x1, y1 + h1 - 1
    local x1_4, y1_4 = x1 + w1 - 1, y1 + h1 - 1

    if (x1_1 >= x2 and x1_1 <= x2 + w2 - 1 and y1_1 >= y2 and y1_1 <= y2 + h2 - 1) or
        (x1_2 >= x2 and x1_2 <= x2 + w2 - 1 and y1_2 >= y2 and y1_2 <= y2 + h2 - 1) or
        (x1_3 >= x2 and x1_3 <= x2 + w2 - 1 and y1_3 >= y2 and y1_3 <= y2 + h2 - 1) or
        (x1_4 >= x2 and x1_4 <= x2 + w2 - 1 and y1_4 >= y2 and y1_4 <= y2 + h2 - 1) then
        return true
    end

    local x2_1, y2_1 = x2, y2
    local x2_2, y2_2 = x2 + w2 - 1, y2
    local x2_3, y2_3 = x2, y2 + h2 - 1
    local x2_4, y2_4 = x2 + w2 - 1, y2 + h2 - 1

    if (x2_1 >= x1 and x2_1 <= x1 + w1 - 1 and y2_1 >= y1 and y2_1 <= y1 + h1 - 1) or
        (x2_2 >= x1 and x2_2 <= x1 + w1 - 1 and y2_2 >= y1 and y2_2 <= y1 + h1 - 1) or
        (x2_3 >= x1 and x2_3 <= x1 + w1 - 1 and y2_3 >= y1 and y2_3 <= y1 + h1 - 1) or
        (x2_4 >= x1 and x2_4 <= x1 + w1 - 1 and y2_4 >= y1 and y2_4 <= y1 + h1 - 1) then
        return true
    end

    return false
end

local function __show_nearby_buildings_selected_boxes(self, x, y, dir, typeobject)
    local nearby_buldings = __get_nearby_buldings(x, y, iprototype.rotate_area(typeobject.area, dir))
    local w, h = iprototype.rotate_area(typeobject.area, dir)

    local redraw = {}
    for object_id, object in pairs(nearby_buldings) do
        redraw[object_id] = object
    end

    for object_id, o in pairs(self.selected_boxes) do
        o:remove()
        self.selected_boxes[object_id] = nil
    end

    for object_id, object in pairs(redraw) do
        local otypeobject = iprototype.queryByName(object.prototype_name)
        local ow, oh = iprototype.rotate_area(otypeobject.area, object.dir)

        local color
        if __is_building_intersect(x, y, w, h, object.x, object.y, ow, oh) then
            color = SPRITE_COLOR.CONSTRUCT_OUTLINE_FARAWAY_BUILDINGS_INTERSECTION
        else
            if typeobject.supply_area then
                local aw, ah = iprototype.rotate_area(typeobject.area, object.dir)
                local sw, sh = iprototype.rotate_area(typeobject.supply_area, object.dir)
                if __is_building_intersect(x - (sw - aw) // 2, y - (sh - ah) // 2, sw, sh, object.x, object.y, ow, oh) then
                    color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS_DRONE_DEPOT_SUPPLY_AREA
                else
                    color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                end
            else
                if iprototype.has_types(typeobject.type, "station") then
                    if otypeobject.supply_area then
                        local aw, ah = iprototype.rotate_area(typeobject.area, object.dir)
                        local sw, sh = iprototype.rotate_area(typeobject.supply_area, object.dir)
                        if __is_building_intersect(x, y, ow, oh, object.x  - (sw - aw) // 2, object.y - (sh - ah) // 2, sw, sh) then
                            color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS_DRONE_DEPOT_SUPPLY_AREA
                        else
                            color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                        end
                    else
                        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                    end
                else
                    color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                end
            end
        end

        self.selected_boxes[object_id] = create_selected_boxes(
            {
                "/pkg/vaststars.resources/glbs/selected-box-no-animation.glb|mesh.prefab",
                "/pkg/vaststars.resources/glbs/selected-box-no-animation-line.glb|mesh.prefab",
            },
            object.srt.t, color, iprototype.rotate_area(otypeobject.area, object.dir)
        )
    end

    for object_id, o in pairs(self.selected_boxes) do
        local object = assert(objects:get(object_id))
        local otypeobject = iprototype.queryByName(object.prototype_name)
        local ow, oh = iprototype.rotate_area(otypeobject.area, object.dir)

        local color
        if __is_building_intersect(x, y, w, h, object.x, object.y, ow, oh) then
            color = SPRITE_COLOR.CONSTRUCT_OUTLINE_FARAWAY_BUILDINGS_INTERSECTION
        else
            if typeobject.supply_area then
                local aw, ah = iprototype.rotate_area(typeobject.area, object.dir)
                local sw, sh = iprototype.rotate_area(typeobject.supply_area, object.dir)
                if __is_building_intersect(x - (sw - aw) // 2, y - (sh - ah) // 2, sw, sh, object.x, object.y, ow, oh) then
                    color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS_DRONE_DEPOT_SUPPLY_AREA
                else
                    color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                end
            else
                if iprototype.has_types(typeobject.type, "station") then
                    if otypeobject.supply_area then
                        local aw, ah = iprototype.rotate_area(typeobject.area, object.dir)
                        local sw, sh = iprototype.rotate_area(typeobject.supply_area, object.dir)
                        if __is_building_intersect(x, y, ow, oh, object.x  - (sw - aw) // 2, object.y - (sh - ah) // 2, sw, sh) then
                            color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS_DRONE_DEPOT_SUPPLY_AREA
                        else
                            color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                        end
                    else
                        color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                    end
                else
                    color = SPRITE_COLOR.CONSTRUCT_OUTLINE_NEARBY_BUILDINGS
                end
            end
        end
        o:set_color_transition(color, 400)
    end
end

local function __new_entity(self, datamodel, typeobject, x, y, position, dir)
    if ichest.has_chest(typeobject.type) then
        local sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_OTHER
        for _, object in objects:all() do
            local otypeobject = iprototype.queryByName(object.prototype_name)
            if otypeobject.supply_area then
                local w, h = iprototype.rotate_area(otypeobject.area, object.dir)
                local ow, oh = iprototype.rotate_area(otypeobject.supply_area, object.dir)
                if not self.sprites[object.id] then
                    self.sprites[object.id] = create_sprite(object.x - (ow - w)//2, object.y - (oh - h)//2, ow, oh, sprite_color)
                end
            end
        end
    end

    __show_nearby_buildings_selected_boxes(self, x, y, dir, typeobject)

    local sprite_color
    local valid
    if not self._check_coord(x, y, dir, self.typeobject) then
        if typeobject.supply_area then
            sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_INVALID
        end
        datamodel.show_confirm = false
        valid = false
    else
        if typeobject.supply_area then
            sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_VALID
        end
        datamodel.show_confirm = true
        valid = true
    end
    datamodel.show_rotate = (typeobject.rotate_on_build == true)

    __show_self_selected_boxes(self, position, typeobject, dir, valid)
    local w, h = iprototype.rotate_area(typeobject.area, dir)
    local recipe = _get_mineral_recipe(typeobject.name, x, y, w, h)

    iobject.remove(self.pickup_object)
    self.pickup_object = iobject.new {
        prototype_name = typeobject.name,
        dir = dir,
        x = x,
        y = y,
        srt = srt.new {
            t = math3d.vector(position),
            r = ROTATORS[dir],
        },
        group_id = 0,
        recipe = recipe,
        state = "translucent",
        color = SPRITE_COLOR.CONSTRUCT_SELF,
        emissive_color = SPRITE_COLOR.CONSTRUCT_SELF_EMISSIVE,
        render_layer = RENDER_LAYER.TRANSLUCENT_BUILDING,
    }

    if typeobject.fluid_indicators ~= false and iprototype.has_types(typeobject.type, "chimney", "fluidbox", "fluidboxes") then
        self.pickup_components.fluid_indicators = create_fluid_indicators(dir, self.pickup_object.srt, typeobject)
    end

    if self.sprite then
        self.sprite:remove()
    end

    self.sprite = __create_self_sprite(typeobject, x, y, dir, sprite_color)

    flush_sprite()
    self.pickup_object.APPEAR = true

    if not self.grid_entity then
        self.grid_entity = igrid_entity.create(MAP_WIDTH, MAP_HEIGHT, TILE_SIZE, {t = __calc_grid_position(self, typeobject, dir)})
    end
end

local function align(position_type, area, dir)
    local p = icamera_controller.get_screen_world_position(position_type)
    local coord, pos = icoord.align(p, iprototype.rotate_area(area, dir))
    if not coord then
        return
    end
    return coord[1], coord[2], math3d.vector(pos)
end

local function touch_move(self, datamodel, delta_vec)
    if not self.pickup_object then
        return
    end
    local pickup_object = self.pickup_object
    iobject.move_delta(pickup_object, delta_vec)

    local x, y, pos = align(self.position_type, self.typeobject.area, self.pickup_object.dir)
    if not x then
        datamodel.show_confirm = false
        return
    end
    pickup_object.srt.t, pickup_object.x, pickup_object.y = pos, x, y

    local typeobject = iprototype.queryByName(pickup_object.prototype_name)

    for _, c in pairs(self.pickup_components) do
        c:on_position_change(self.pickup_object.srt, self.pickup_object.dir)
    end

    if self.grid_entity then
        self.grid_entity:set_position(__calc_grid_position(self, typeobject, pickup_object.dir))
    end

    if self.last_x == x and self.last_y == y then
        return
    end
    self.last_x, self.last_y = x, y

    local sprite_color
    local valid
    local offset_x, offset_y = 0, 0
    local w, h = iprototype.rotate_area(typeobject.area, pickup_object.dir)
    if not self._check_coord(x, y, pickup_object.dir, self.typeobject) then
        datamodel.show_confirm = false
        valid = false

        if typeobject.supply_area then
            sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_INVALID
            local aw, ah = iprototype.rotate_area(typeobject.supply_area, pickup_object.dir)
            offset_x, offset_y = -((aw - w)//2), -((ah - h)//2)
        end
        if self.sprite then
            self.sprite:move(pickup_object.x + offset_x, pickup_object.y + offset_y, sprite_color)
        end
        __show_self_selected_boxes(self, pickup_object.srt.t, typeobject, pickup_object.dir, valid)
        __show_nearby_buildings_selected_boxes(self, x, y, pickup_object.dir, typeobject)

        for _, c in pairs(self.pickup_components) do
            c:on_status_change(datamodel.show_confirm)
        end
        return
    else
        datamodel.show_confirm = true
        valid = true

        if typeobject.supply_area then
            sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_VALID
            local aw, ah = iprototype.rotate_area(typeobject.supply_area, pickup_object.dir)
            offset_x, offset_y = -((aw - w)//2), -((ah - h)//2)
        end
        if self.sprite then
            self.sprite:move(pickup_object.x + offset_x, pickup_object.y + offset_y, sprite_color)
        end
        __show_self_selected_boxes(self, pickup_object.srt.t, typeobject, pickup_object.dir, valid)
        __show_nearby_buildings_selected_boxes(self, x, y, pickup_object.dir, typeobject)

        for _, c in pairs(self.pickup_components) do
            c:on_status_change(datamodel.show_confirm)
        end
    end
    flush_sprite()
end

local function touch_end(self, datamodel)
    touch_move(self, datamodel, {0, 0, 0})
end

local function complete(object_id)
    assert(object_id)
    local object = objects:get(object_id, {"CONFIRM"})
    local old = objects:get(object_id, {"CONSTRUCTED"})
    if not old then
        object.gameplay_eid = igameplay.create_entity(object)
    else
        if old.prototype_name ~= object.prototype_name then
            igameplay.destroy_entity(object.gameplay_eid)
            object.gameplay_eid = igameplay.create_entity(object)
        elseif old.dir ~= object.dir then
            igameplay.rotate(object.gameplay_eid, object.dir)
        end
    end

    objects:remove(object_id, "CONFIRM")
    objects:set(object, "CONSTRUCTED")
    gameplay_core.set_changed(CHANGED_FLAG_BUILDING)
end

local function confirm(self, datamodel)
    local pickup_object = self.pickup_object
    if not pickup_object then
        return
    end

    local w, h = iprototype.rotate_area(self.typeobject.area, pickup_object.dir)
    local succ, msg = self._check_coord(pickup_object.x, pickup_object.y, pickup_object.dir, self.typeobject)
    if not succ then
        show_message(msg)
        return
    end

    local gameplay_world = gameplay_core.get_world()
    if iinventory.query(gameplay_world, self.typeobject.id) < 1 then
        print("can not place, not enough " .. self.typeobject.name) --TODO: show error message
        return
    end
    assert(iinventory.pickup(gameplay_world, self.typeobject.id, 1))

    pickup_object.recipe = _get_mineral_recipe(pickup_object.prototype_name, pickup_object.x, pickup_object.y, w, h)

    objects:set(pickup_object, "CONFIRM")
    pickup_object.PREPARE = true

    datamodel.show_confirm = false
    datamodel.show_rotate = false

    local vsobject_manager = ecs.require "vsobject_manager"
    local vsobject = assert(vsobject_manager:get(pickup_object.id))
    vsobject:update {state = "opaque", color = "null", emissive_color = "null"}

    self.pickup_object = nil
    complete(pickup_object.id)

    __new_entity(self, datamodel, self.typeobject, pickup_object.x, pickup_object.y, pickup_object.srt.t, pickup_object.dir)
end

local function rotate(self, datamodel, dir, delta_vec)
    local pickup_object = assert(self.pickup_object)
    dir = dir or iprototype.rotate_dir_times(pickup_object.dir, -1)
    pickup_object.dir = iprototype.dir_tostring(dir)
    pickup_object.srt.r = ROTATORS[pickup_object.dir]

    local x, y, pos = align(self.position_type, self.typeobject.area, self.pickup_object.dir)
    if not x then
        datamodel.show_confirm = false
        return
    end
    pickup_object.srt.t, pickup_object.x, pickup_object.y = pos, x, y

    local typeobject = iprototype.queryByName(pickup_object.prototype_name)
    for _, c in pairs(self.pickup_components) do
        c:on_position_change(self.pickup_object.srt, self.pickup_object.dir)
    end
    local sprite_color
    local valid
    if not self._check_coord(pickup_object.x, pickup_object.y, pickup_object.dir, typeobject) then
        valid = false
        if typeobject.supply_area then
            sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_INVALID
        end
        datamodel.show_confirm = false
    else
        valid = true
        if typeobject.supply_area then
            sprite_color = SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_VALID
        end
        datamodel.show_confirm = true
    end

    __show_self_selected_boxes(self, pickup_object.srt.t, typeobject, pickup_object.dir, valid)

    if self.sprite then
        self.sprite:remove()
    end
    self.sprite = __create_self_sprite(typeobject, x, y, pickup_object.dir, sprite_color)
    flush_sprite()
end

local function clean(self, datamodel)
    if self.grid_entity then
        self.grid_entity:remove()
        self.grid_entity = nil
    end

    for _, sprite in pairs(self.sprites) do
        sprite:remove()
    end
    self.sprites = {}

    if self.sprite then
        self.sprite:remove()
        self.sprite = nil
    end
    flush_sprite()

    for _, o in pairs(self.selected_boxes) do
        o:remove()
    end
    self.selected_boxes = {}

    for _, c in pairs(self.pickup_components) do
        c:remove()
    end

    if self.self_selected_boxes then
        self.self_selected_boxes:remove()
        self.self_selected_boxes = nil
    end

    datamodel.show_confirm = false
    datamodel.show_rotate = false
    if self.pickup_object then
        iobject.remove(self.pickup_object)
    end
end

local function _get_check_coord(typeobject)
    local funcs = {}
    for _, v in ipairs(typeobject.check_coord) do
        funcs[#funcs+1] = ecs.require(("editor.rules.check_coord.%s"):format(v))
    end
    return function(...)
        for _, v in ipairs(funcs) do
            local succ, reason = v(...)
            if not succ then
                return succ, reason
            end
        end
        return true
    end
end

local function new(self, datamodel, typeobject, position_type)
    self._check_coord = _get_check_coord(typeobject)

    self.typeobject = typeobject
    self.position_type = position_type

    local x, y, pos = align(self.position_type, self.typeobject.area, DEFAULT_DIR)
    __new_entity(self, datamodel, typeobject, x, y, pos, DEFAULT_DIR)
end

local function build(self, v)
    igameplay.create_entity(v)
end

local function create()
    local m = {}
    m.new = new
    m.touch_move = touch_move
    m.touch_end = touch_end
    m.confirm = confirm
    m.rotate = rotate
    m.clean = clean
    m.build = build
    m.sprites = {}
    m.self_selected_boxes = nil
    m.selected_boxes = {}
    m.last_x, m.last_y = -1, -1
    m.pickup_components = {}
    return m
end
return create