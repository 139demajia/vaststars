local ecs, mailbox = ...
local world = ecs.world

local math3d = require "math3d"
local PLANES <const> = {math3d.constant("v4", {0, 1, 0, 0})}
local icamera_controller = ecs.interface "icamera_controller"
local gameplay_core = require "gameplay.core"
local iui = ecs.import.interface "vaststars.gamerender|iui"
local iprototype = require "gameplay.interface.prototype"
local irecipe = require "gameplay.interface.recipe"
local create_normalbuilder = ecs.require "editor.normalbuilder"
local create_movebuilder = ecs.require "editor.movebuilder"
local create_roadbuilder = ecs.require "editor.roadbuilder"
local create_pipebuilder = ecs.require "editor.pipebuilder"
local create_pipetogroundbuilder = ecs.require "editor.pipetogroundbuilder"
local objects = require "objects"
local global = require "global"
local iobject = ecs.require "object"
local terrain = ecs.require "terrain"
local idetail = ecs.import.interface "vaststars.gamerender|idetail"
local EDITOR_CACHE_NAMES = {"CONFIRM", "CONSTRUCTED"}
local create_station_builder = ecs.require "editor.stationbuilder"
local coord_system = ecs.require "terrain"
local selected_boxes = ecs.require "selected_boxes"
local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER
local COLOR_INVALID <const> = math3d.constant "null"
local igameplay = ecs.import.interface "vaststars.gamerender|igameplay"
local COLOR_GREEN = math3d.constant("v4", {0.3, 1, 0, 1})
local construct_menu_cfg = import_package "vaststars.prototype"("construct_menu")
local ichest = require "gameplay.interface.chest"
local create_event_handler = require "ui_datamodel.common.event_handler"
local ipower_line = ecs.require "power_line"
local iupdate = ecs.import.interface "vaststars.gamerender|iupdate"
local ipick_object = ecs.import.interface "vaststars.gamerender|ipick_object"
local ilorry = ecs.import.interface "vaststars.gamerender|ilorry"
local gameplay = import_package "vaststars.gameplay"

local rotate_mb = mailbox:sub {"rotate"}
local build_mb = mailbox:sub {"build"}
local quit_mb = mailbox:sub {"quit"}
local dragdrop_camera_mb = world:sub {"dragdrop_camera"}
local click_techortaskicon_mb = mailbox:sub {"click_techortaskicon"}
local guide_on_going_mb = mailbox:sub {"guide_on_going"}
local help_mb = mailbox:sub {"help"}
local move_md = mailbox:sub {"move"}
local teardown_mb = mailbox:sub {"teardown"}
local construct_entity_mb = mailbox:sub {"construct_entity"}
local inventory_mb = mailbox:sub {"inventory"}
local switch_concise_mode_mb = mailbox:sub {"switch_concise_mode"}
local gesture_tap_mb = world:sub{"gesture", "tap"}
local gesture_long_press_mb = world:sub{"gesture", "long_press"}
local gesture_pan_mb = world:sub {"gesture", "pan"}
local focus_tips_event = world:sub {"focus_tips"}
local remove_lorry_mb = mailbox:sub {"remove_lorry"}
local DIRTY_BUILDING <const> = require("gameplay.interface.constant").DIRTY_BUILDING
local construct_mb = mailbox:sub {"construct"}
local selected_mb = mailbox:sub {"selected"}
local unselected_mb = mailbox:sub {"unselected"}

local ipower = ecs.require "power"
local now = require "engine.time".now

local CLASS = {
    Lorry = 1,
    Object = 2,
    Mineral = 3,
    Mountain = 4,
}

local builder, builder_datamodel, builder_ui
local excluded_pickup_id -- object id
local pick_lorry_id
local handle_pickup = true
local selected_obj

local event_handler = create_event_handler(
    mailbox,
    {
        "start_laying",
        "finish_laying",
        "start_teardown",
        "finish_teardown",
        "cancel",
        "place_one",
        "remove_one",
        -- "quit", -- "quit" event is handled in the same way as construct building
    },
    function(event)
        if builder then
            builder[event](builder, builder_datamodel)
        end
    end
)

local function __on_pick_object(datamodel, o)
    local object = o.object
    if datamodel.status == "normal" or datamodel.status == "focus" then
        local prototype_name = object.prototype_name
        local typeobject = iprototype.queryByName(prototype_name)
        datamodel.status = "focus"
        datamodel.focus_building_icon = typeobject.icon

        selected_obj = o
        idetail.focus(object.id)
    elseif datamodel.status == "selected" then
        if o.class == CLASS.Object then
            local object = o.object
            icamera_controller.focus_on_position(object.srt.t)

            idetail.show(object.id)
            idetail.focus(object.id)
            idetail.selected(object)
            selected_obj = o
        end
    end
    iui.open({"detail_panel.rml"}, object.id)
end

local function __on_pick_building(datamodel, o)
    local object = o.object
    if not excluded_pickup_id or excluded_pickup_id == object.id then
        __on_pick_object(datamodel, o)
        return true
    end
end

local function __on_pick_mineral(datamodel, mineral)
    iui.close "detail_panel.rml"
    iui.close "building_menu.rml"
    local typeobject = iprototype.queryByName(mineral)
    iui.open({"mine_detail_panel.rml"}, typeobject.icon, typeobject.mineral_name or typeobject.name)
    return true
end

local function __on_pick_ground(datamodel)
    iui.open({"main_menu.rml"})
    gameplay_core.world_update = false
    return true
end

local function __unpick_lorry(lorry_id)
    local lorry = ilorry.get(lorry_id)
    if lorry then
        lorry:set_outline(false)
    end
end

local function __get_construct_menu()
    local construct_menu = {}
    for _, menu in ipairs(construct_menu_cfg) do
        local m = {}
        m.name = menu.name
        m.icon = menu.icon
        m.detail = {}

        for _, prototype_name in ipairs(menu.detail) do
            local typeobject = assert(iprototype.queryByName(prototype_name))
            local count = ichest.get_inventory_item_count(gameplay_core.get_world(), typeobject.id)
            m.detail[#m.detail + 1] = {
                show_prototype_name = iprototype.show_prototype_name(typeobject),
                prototype_name = prototype_name,
                icon = typeobject.icon,
                count = count,
            }
        end

        construct_menu[#construct_menu+1] = m
    end
    return construct_menu
end

local status = "default"
local function __switch_status(s, cb)
    if status == s then
        if cb then
            cb()
        end
        return
    end
    status = s

    if status == "default" then
        icamera_controller.toggle_view("default", cb)
    elseif status == "construct" then
        icamera_controller.toggle_view("construct", cb)
    end
end

local function __clean(datamodel)
    if builder then
        builder:clean(builder_datamodel)
        builder, builder_datamodel = nil, nil
        iui.close(builder_ui)
    end
    idetail.unselected()
    datamodel.is_concise_mode = false
    handle_pickup = true
end

local function __get_new_tech_count(tech_list)
    local count = 0
    for _, tech in ipairs(tech_list) do
        if global.science.tech_picked_flag[tech.detail.name] then
            count = count + 1
        end
    end
    return count
end

---------------
local M = {}

function M:create()
    return {
        is_concise_mode = false,
        show_tech_progress = false,
        current_tech_icon = "none",    --当前科技图标
        current_tech_name = "none",    --当前科技名字
        current_tech_progress = "0%",  --当前科技进度
        current_tech_progress_detail = "0/0",  --当前科技进度(数量),
        ingredient_icons = {},
        show_ingredient = false,
        construct_menu = __get_construct_menu(),
        status = "normal",
    }
end

function M:update_construct_menu(datamodel)
    datamodel.construct_menu = __get_construct_menu()
end

local current_techname = ""
function M:update_tech(datamodel, tech)
    if tech then
        if current_techname ~= tech.name then
            local ingredient_icons = {}
            local ingredients = irecipe.get_elements(tech.detail.ingredients)
            for _, ingredient in ipairs(ingredients) do
                if ingredient.tech_icon ~= '' then
                    ingredient_icons[#ingredient_icons + 1] = {icon = assert(ingredient.tech_icon), count = ingredient.count}
                end
            end
            current_techname = tech.name
            datamodel.ingredient_icons = ingredient_icons
            if #ingredient_icons > 0 then
                datamodel.show_ingredient = true
            else
                datamodel.show_ingredient = false
            end
        end
        datamodel.show_tech_progress = true
        datamodel.is_task = tech.task
        datamodel.current_tech_name = tech.name
        datamodel.current_tech_icon = tech.detail.icon
        datamodel.current_tech_progress = (tech.progress * 100) // tech.detail.count .. '%'
        datamodel.current_tech_progress_detail = tech.progress.."/"..tech.detail.count
    else
        datamodel.show_tech_progress = false
        datamodel.tech_count = __get_new_tech_count(global.science.tech_list)
    end
end

function M:stage_ui_update(datamodel)
    event_handler()

    for _ in rotate_mb:unpack() do
        if builder then
            builder:rotate_pickup_object(builder_datamodel)
        end
    end

    for _ in build_mb:unpack() do
        assert(builder)
        if not builder:confirm(builder_datamodel) then
            __clean(datamodel)
            __switch_status("default", function()
                gameplay_core.world_update = true
                __clean(datamodel)
            end)
        end
    end

    for _ in quit_mb:unpack() do
        __clean(datamodel)
        __switch_status("default", function()
            gameplay_core.world_update = true
            __clean(datamodel)
        end)
    end

    for _ in guide_on_going_mb:unpack() do
        __clean(datamodel)
        __switch_status("default", function()
            gameplay_core.world_update = true
            __clean(datamodel)
        end)
    end

    for _, _, _, is_task in click_techortaskicon_mb:unpack() do
        if gameplay_core.world_update and global.science.current_tech then
            gameplay_core.world_update = false
            iui.open(is_task and {"task_pop.rml"} or {"science.rml"})
        end
    end

    for _ in help_mb:unpack() do
        if not iui.is_open("help_panel.rml") then
            iui.open({"help_panel.rml"})
        else
            iui.close("help_panel.rml")
        end
    end
end

local function open_focus_tips(tech_node)
    local focus = tech_node.detail.guide_focus
    if not focus then
        return
    end
    local width, height
    for _, nd in ipairs(focus) do
        if nd.prefab then
            if not width or not height then
                width, height = nd.w, nd.h
            end
            if not tech_node.selected_tips then
                tech_node.selected_tips = {}
            end

            local prefab
            local center = coord_system:get_position_by_coord(nd.x, nd.y, 1, 1)
            if nd.show_arrow then
                prefab = assert(igame_object.create({
                    state = "opaque",
                    color = COLOR_INVALID,
                    prefab = "prefabs/arrow-guide.prefab",
                    group_id = 0,
                    srt = {
                        t = center,
                    },
                    animation_name = "ArmatureAction",
                    final_frame = false,
                    render_layer = RENDER_LAYER.SELECTED_BOXES,
                }))
            end
            if nd.force then
                local object = objects:coord(nd.x, nd.y, EDITOR_CACHE_NAMES)
                if object then
                    excluded_pickup_id = object.id
                end
            end
            tech_node.selected_tips[#tech_node.selected_tips + 1] = {selected_boxes({"/pkg/vaststars.resources/" .. nd.prefab}, center, COLOR_GREEN, nd.w, nd.h), prefab}
        elseif nd.camera_x and nd.camera_y then
            icamera_controller.focus_on_position(coord_system:get_position_by_coord(nd.camera_x, nd.camera_y, width, height))
        end
    end
end

local function close_focus_tips(tech_node)
    local selected_tips = tech_node.selected_tips
    if not selected_tips then
        return
    end
    for _, tip in ipairs(selected_tips) do
        for _, o in ipairs(tip) do
            o:remove()
        end
    end
    tech_node.selected_tips = {}
    excluded_pickup_id = nil
end

local function __construct_entity(typeobject)
    iui.close("building_menu.rml")
    iui.close("detail_panel.rml")
    idetail.unselected()
    gameplay_core.world_update = false
    handle_pickup = false

    if iprototype.has_type(typeobject.type, "road") then
        builder_ui = "construct_road_or_pipe.rml"
        builder_datamodel = iui.open({"construct_road_or_pipe.rml", "construct_road_or_pipe.lua"})
        builder = create_roadbuilder()
        builder:new_entity(builder_datamodel, typeobject)
    elseif iprototype.has_type(typeobject.type, "pipe") then
        builder_ui = "construct_road_or_pipe.rml"
        builder_datamodel = iui.open({"construct_road_or_pipe.rml", "construct_road_or_pipe.lua"})
        builder = create_pipebuilder()
        builder:new_entity(builder_datamodel, typeobject)
    elseif iprototype.has_type(typeobject.type, "pipe_to_ground") then
        builder_ui = "construct_road_or_pipe.rml"
        builder_datamodel = iui.open({"construct_road_or_pipe.rml", "construct_road_or_pipe.lua"})
        builder = create_pipetogroundbuilder()
        builder:new_entity(builder_datamodel, typeobject)
    elseif iprototype.has_types(typeobject.type, "station_producer", "station_consumer") then
        builder_ui = "construct_building.rml"
        builder_datamodel = iui.open({"construct_building.rml"})
        builder = create_station_builder()
        builder:new_entity(builder_datamodel, typeobject)
    else
        builder_ui = "construct_building.rml"
        builder_datamodel = iui.open({"construct_building.rml"})
        builder = create_normalbuilder(typeobject.id)
        builder:new_entity(builder_datamodel, typeobject)
    end
end

function M:stage_camera_usage(datamodel)
    for _, delta in dragdrop_camera_mb:unpack() do
        if builder then
            builder:touch_move(builder_datamodel, delta)
            self:flush()
        end
    end

    for _ in gesture_pan_mb:unpack() do
        if builder then
            builder:touch_end(builder_datamodel)
            self:flush()
        end
    end

    local leave = true

    local function __get_building(x, y)
        for _, pos in ipairs(icamera_controller.screen_to_world(x, y, PLANES)) do
            local coord = terrain:get_coord_by_position(pos)
            if coord then
                local r = objects:coord(coord[1], coord[2], EDITOR_CACHE_NAMES)
                if r then
                    return r
                end
            end
        end
    end

    local gesture_changed = false
    for _, _, v in gesture_tap_mb:unpack() do
        gesture_changed = true

        local x, y = v.x, v.y
        if not handle_pickup then
            goto continue
        end

        for _, pos in ipairs(icamera_controller.screen_to_world(x, y, PLANES)) do
            local coord = terrain:get_coord_by_position(pos)
            if coord then
                local o = ipick_object.blur_pick(coord[1], coord[2])
                if o and o.class == CLASS.Lorry then
                    if pick_lorry_id then
                        __unpick_lorry(pick_lorry_id)
                    end
                    idetail.unselected()
                    datamodel.is_concise_mode = false

                    pick_lorry_id = o.id

                    o.lorry:set_outline(true)
                    local t = now()
                    local lorry_id = o.id
                    -- iupdate.add(function()
                    --     if t + 2000 > now() then
                    --         return true
                    --     end
                    --     __unpick_lorry(lorry_id)
                    --     datamodel.remove_lorry = false
                    --     return false
                    -- end)
                    datamodel.remove_lorry = true
                elseif o and o.class == CLASS.Object then
                    if __on_pick_building(datamodel, o) then
                        __unpick_lorry(pick_lorry_id)
                        datamodel.remove_lorry = false
                        pick_lorry_id = nil
                        leave = false

                        datamodel.is_concise_mode = false
                    end
                elseif o and o.class == CLASS.Mineral then
                    if __on_pick_mineral(datamodel, o.mineral) then
                        __unpick_lorry(pick_lorry_id)
                        datamodel.remove_lorry = false
                        pick_lorry_id = nil
                        leave = false

                        idetail.unselected()
                        datamodel.is_concise_mode = false
                    end
                elseif o and o.class == CLASS.Mountain then
                    if __on_pick_mineral(datamodel, o.mountain) then
                        __unpick_lorry(pick_lorry_id)
                        datamodel.remove_lorry = false
                        pick_lorry_id = nil
                        leave = false

                        idetail.unselected()
                        datamodel.is_concise_mode = false
                    end
                else
                    __unpick_lorry(pick_lorry_id)
                    datamodel.remove_lorry = false
                    pick_lorry_id = nil

                    idetail.unselected()
                    datamodel.is_concise_mode = false
                end
                break
            end
        end
        ::continue::
    end

    for _, _, v in gesture_long_press_mb:unpack() do
        local x, y = v.x, v.y
        if not handle_pickup then
            goto continue
        end

        leave = false
        local object = __get_building(x, y)
        if object then -- object may be nil, such as when user click on empty space
            if not excluded_pickup_id or excluded_pickup_id == object.id then
                local prototype_name = object.prototype_name
                local typeobject = iprototype.queryByName(prototype_name)
                if typeobject.move == false and typeobject.teardown == false then
                    goto continue1
                end

                idetail.focus(object.id)
                iui.close("building_menu.rml")
                idetail.selected(object)

                iui.open({"building_menu_longpress.rml"}, object.id)
                datamodel.status = "selected"
            end
            ::continue1::
        else
            idetail.unselected()
            __on_pick_ground(datamodel)
        end
        ::continue::
    end

    for _, _, _, object_id in teardown_mb:unpack() do
        iui.close("building_menu_longpress.rml")
        iui.close("detail_panel.rml")
        idetail.unselected()

        local object = assert(objects:get(object_id))
        local gw = gameplay_core.get_world()
        local typeobject = iprototype.queryByName(object.prototype_name)

        local chest_component = iprototype.get_chest_component(object.prototype_name)
        if chest_component then
            local e = gameplay_core.get_entity(object.gameplay_eid)
            if not ichest.can_move_to_inventory(gameplay_core.get_world(), e[chest_component]) then
                log.error("can not teardown")
                goto continue
            end

            -- TODO: optimize
            local slots = ichest.collect_item(gameplay_core.get_world(), e[chest_component])
            for _, slot in pairs(slots) do
                ichest.move_to_inventory(gameplay_core.get_world(), e[chest_component], slot.item, ichest.get_amount(slot))
            end
        end

        local gameworld = gameplay_core.get_world()
        local building = gameplay.interface "building"
        building.destroy(gameworld, gameworld.entity[object.gameplay_eid])
        igameplay.dirty(DIRTY_BUILDING)

        if typeobject.power_network_link or typeobject.power_supply_distance then
            ipower:build_power_network(gw)
            ipower_line.update_line(ipower:get_pole_lines())
        end

        iobject.remove(object)
        objects:remove(object_id)
        local building = global.buildings[object_id]
        if building then
            for _, v in pairs(building) do
                v:remove()
            end
        end
        ::continue::
    end

    if gesture_changed and leave then
        selected_obj = nil
        datamodel.status = "normal"
        idetail.unselected()
        world:pub {"ui_message", "leave"}
    end

    for _, _, _, object_id in move_md:unpack() do
        datamodel.is_concise_mode = true
        handle_pickup = false
        __switch_status("construct", function()
            assert(builder == nil)

            local object = assert(objects:get(object_id))
            local typeobject = iprototype.queryByName(object.prototype_name)
            idetail.unselected()
            builder_ui = "move_building.rml"
            builder_datamodel = iui.open({"move_building.rml"}, object.prototype_name)
            builder = create_movebuilder(object_id)
            builder:new_entity(builder_datamodel, typeobject)
        end)
    end

    for _, _, _, item in construct_entity_mb:unpack() do
        local typeobject = iprototype.queryByName(item)
        if ichest.get_inventory_item_count(gameplay_core.get_world(), typeobject.id) >= 1 then
            iui.close("building_menu.rml")
            iui.close("detail_panel.rml")
            idetail.unselected()
            gameplay_core.world_update = false
            handle_pickup = false
            __switch_status("construct", function()
                -- we may click the button repeatedly, so we need to clear the old model first
                if builder then
                    builder:clean(builder_datamodel)
                    builder, builder_datamodel = nil, nil
                    iui.close(builder_ui)
                end
                __construct_entity(typeobject)
            end)
        end
    end

    -- TODO: 多个UI的stage_ui_update中会产生focus_tips_event事件，focus_tips_event处理逻辑涉及到要修改相机位置，所以暂时放在这里处理
    for _, action, tech_node in focus_tips_event:unpack() do
        if action == "open" then
            open_focus_tips(tech_node)
        elseif action == "close" then
            close_focus_tips(tech_node)
        end
    end

    for _ in inventory_mb:unpack() do
        for _, object in objects:all() do -- TODO: optimize
            local typeobject = iprototype.queryByName(object.prototype_name)
            if iprototype.has_type(typeobject.type, "base") then
                iui.open({"inventory.rml"}, object.id)
                break
            end
        end
    end

    for _ in switch_concise_mode_mb:unpack() do
        datamodel.is_concise_mode = not datamodel.is_concise_mode
    end

    for _ in remove_lorry_mb:unpack() do
        if pick_lorry_id then
            gameplay_core.get_world().entity[pick_lorry_id].lorry_willremove = true

            __unpick_lorry(pick_lorry_id)
            pick_lorry_id = nil
            datamodel.remove_lorry = false
        end
    end

    for _ in construct_mb:unpack() do
        datamodel.is_concise_mode = not datamodel.is_concise_mode
    end

    for _ in selected_mb:unpack() do
        if selected_obj then
            datamodel.status = "selected"
            __on_pick_object(datamodel, selected_obj)
        else
            log.error("no target selected")
        end
    end

    for _ in unselected_mb:unpack() do
        selected_obj = nil
        datamodel.status = "normal"
        idetail.unselected()
        iui.close "detail_panel.rml"
        iui.close "building_menu.rml"
    end

    iobject.flush()
end
return M