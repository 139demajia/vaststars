local ecs, mailbox = ...
local world = ecs.world

local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER
local SPRITE_COLOR <const> = ecs.require "vaststars.prototype|sprite_color"
local CONSTANT <const> = require "gameplay.interface.constant"
local CHANGED_FLAG_BUILDING <const> = CONSTANT.CHANGED_FLAG_BUILDING

local math3d = require "math3d"
local XZ_PLANE <const> = math3d.constant("v4", {0, 1, 0, 0})

local icoord = require "coord"
local COORD_BOUNDARY <const> = icoord.boundary()

local CONSTANT <const> = require "gameplay.interface.constant"
local ROTATORS <const> = CONSTANT.ROTATORS

local select_mb = mailbox:sub {"select"}
local teardown_mb = mailbox:sub {"teardown"}
local move_mb = mailbox:sub {"move"}
local close_mb = mailbox:sub {"close"}
local move_confirm_mb = mailbox:sub {"move_confirm"}
local move_cancel_mb = mailbox:sub {"move_cancel"}
local icamera_controller = ecs.require "engine.system.camera_controller"
local icoord = require "coord"
local objects = require "objects"
local vsobject_manager = ecs.require "vsobject_manager"
local ibuilding = ecs.require "render_updates.building"
local iprototype = require "gameplay.interface.prototype"
local iroadnet_converter = require "roadnet_converter"
local iroadnet = ecs.require "engine.roadnet"
local teardown = ecs.require "editor.teardown"
local gameplay_core = require "gameplay.core"
local iinventory = require "gameplay.interface.inventory"
local show_message = ecs.require "show_message".show_message
local iui = ecs.require "engine.system.ui_system"
local isrt = require "utility.srt"
local igame_object = ecs.require "engine.game_object"

local selected = {}
local moving_objs = {}
local moving = false

local M = {}
function M.create()
    return {
        teardown = true,
        move = true,
        move_confirm = false,
        move_cancel = false,
    }
end

local function _update_object_state(coord, state, color, emissive_color, render_layer)
    local x, y = iprototype.unpackcoord(coord)
    local object = objects:coord(x, y)
    if object then
        local vsobject = assert(vsobject_manager:get(object.id))
        vsobject:update {state = state, color = color, emissive_color = emissive_color, render_layer = render_layer}
    end
end

local function _update_road_state(coord, color)
    local x, y = iprototype.unpackcoord(coord)
    local v = ibuilding.get(x, y)
    if v then
        local typeobject = iprototype.queryByName(v.prototype)
        local shape = iroadnet_converter.to_shape(typeobject.name)
        iroadnet:set("road", v.x, v.y, color, shape, v.direction)
    end
end

local function _to_road_color(color)
    if color == "null" then
        return 0xffffffff
    end
    local r, g, b, a = math3d.index(color, 1, 2, 3, 4)
    r, g, b, a = math.floor(r*255), math.floor(g*255), math.floor(b*255), math.floor(a*255)
    return r | g<<8 | b<<16 | a<<24
end

local function _update_selected_coords(coords, state, color, render_layer)
    for _, coord in ipairs(coords) do
        _update_object_state(coord, state, color, color, render_layer)
        _update_road_state(coord, _to_road_color(color))
    end
end

function M.update(datamodel)
    for _, _, _, left, top, width, height in select_mb:unpack() do
        local lefttop = icamera_controller.screen_to_world(left, top, XZ_PLANE)
        local rightbottom = icamera_controller.screen_to_world(left + width, top + height, XZ_PLANE)

        local ltcoord = icoord.position2coord(lefttop) or {0, 0}
        local rbcoord = icoord.position2coord(rightbottom) or {COORD_BOUNDARY[2][1], COORD_BOUNDARY[2][2]}

        local new = {}
        for x = ltcoord[1], rbcoord[1] do
            for y = ltcoord[2], rbcoord[2] do
                local object = objects:coord(x, y)
                if object then
                    local e = assert(gameplay_core.get_entity(object.gameplay_eid))
                    local typeobject = iprototype.queryById(e.building.prototype)
                    if not e.debris and typeobject.teardown ~= false then
                        new[iprototype.packcoord(object.x, object.y)] = true
                    end
                end
                local road_x, road_y = x//2*2, y//2*2
                local v = ibuilding.get(road_x, road_y)
                if v then
                    new[iprototype.packcoord(road_x, road_y)] = true
                end
            end
        end

        local old = selected
        local add, del = {}, {}

        for coord in pairs(old) do
            if new[coord] == nil then
                del[#del+1] = coord
            end
        end

        for coord in pairs(new) do
            if old[coord] == nil then
                add[#add+1] = coord
            end
        end

        _update_selected_coords(add, "translucent", SPRITE_COLOR.SELECTED, RENDER_LAYER.TRANSLUCENT_BUILDING)
        _update_selected_coords(del, "opaque", "null", RENDER_LAYER.BUILDING)

        selected = new
        iroadnet:flush()
    end

    for _ in teardown_mb:unpack() do
        local full = false
        for coord in pairs(selected) do
            local x, y = iprototype.unpackcoord(coord)
            local object = objects:coord(x, y)
            if object then
                teardown(object.gameplay_eid)
                local e = assert(gameplay_core.get_entity(object.gameplay_eid))
                if not iinventory.place(gameplay_core.get_world(), e.building.prototype, 1) then
                    full = true
                end
            end
            local road_x, road_y = x//2*2, y//2*2
            local v = ibuilding.get(road_x, road_y)
            if v then
                teardown(v.eid)
                local e = assert(gameplay_core.get_entity(v.eid))
                if not iinventory.place(gameplay_core.get_world(), e.building.prototype, 1) then
                    full = true
                end
            end
        end

        gameplay_core.set_changed(CHANGED_FLAG_BUILDING)

        -- the building directly go into the backpack
        if full then
            show_message("backpack is full")
        end

        selected = {}
    end

    for _ in move_mb:unpack() do
        datamodel.teardown = false
        datamodel.move = false
        datamodel.move_confirm = true
        datamodel.move_cancel = true

        local t = {}
        for coord in pairs(selected) do
            t[#t+1] = coord
        end
        _update_selected_coords(t, "translucent", SPRITE_COLOR.MOVE_SELF, RENDER_LAYER.TRANSLUCENT_BUILDING)
        iroadnet:flush()

        moving = true

        for coord in pairs(selected) do
            local x, y = iprototype.unpackcoord(coord)
            local object = objects:coord(x, y)
            if object then
                local typeobject = iprototype.queryByName(object.prototype_name)
                local srt = isrt.new(object.srt)
                moving_objs[coord] = {
                    obj = igame_object.create {
                        prefab = typeobject.model,
                        group_id = 0,
                        srt = srt,
                    },
                    srt = srt,
                }
            end
            local v = ibuilding.get(x, y)
            if v then
                local typeobject = iprototype.queryByName(v.prototype)
                local srt = isrt.new {r = ROTATORS[v.direction], t = icoord.position(x, y, iprototype.rotate_area(typeobject.area, v.direction))}
                moving_objs[coord] = {
                    obj = igame_object.create {
                        prefab = typeobject.model,
                        group_id = 0,
                        srt = srt,
                    },
                    srt = srt,
                }
            end
        end
    end

    for _ in move_confirm_mb:unpack() do
        datamodel.teardown = true
        datamodel.move = true
        datamodel.move_confirm = false
        datamodel.move_cancel = false
    end

    for _ in move_cancel_mb:unpack() do
        datamodel.teardown = true
        datamodel.move = true
        datamodel.move_confirm = false
        datamodel.move_cancel = false
    end

    for _ in close_mb:unpack() do
        local t = {}
        for coord in pairs(selected) do
            t[#t+1] = coord
        end
        _update_selected_coords(t, "opaque", "null", RENDER_LAYER.BUILDING)
        iroadnet:flush()

        selected = {}
        iui.redirect("/pkg/vaststars.resources/ui/construct.html", "bulk_move_exit")
    end
end

function M.gesture_pinch()
    if not moving then
        iui.send("/pkg/vaststars.resources/ui/bulk_move.html", "select")
    end
end

function M.gesture_pan(datamodel, delta_vec)
    if moving then
        for _, v in pairs(moving_objs) do
            v.srt = isrt.new {t = math3d.add(v.srt.t, delta_vec), r = v.srt.r}
            v.obj:send("obj_motion", "set_position", math3d.live(v.srt.t))
            v.obj:send("obj_motion", "set_rotation", math3d.live(v.srt.r))
        end
    else
        iui.send("/pkg/vaststars.resources/ui/bulk_move.html", "select")
    end
end

return M