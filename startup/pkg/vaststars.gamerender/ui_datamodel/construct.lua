local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local math3d = require "math3d"
local YAXIS_PLANE_B <const> = math3d.constant("v4", {0, 1, 0, 0})
local YAXIS_PLANE_T <const> = math3d.constant("v4", {0, 1, 0, 20})
local PLANES <const> = {YAXIS_PLANE_T, YAXIS_PLANE_B}
local camera = ecs.require "engine.camera"
local gameplay_core = require "gameplay.core"
local iui = ecs.import.interface "vaststars.gamerender|iui"
local iprototype = require "gameplay.interface.prototype"
local irecipe = require "gameplay.interface.recipe"
local create_normalbuilder = ecs.require "editor.normalbuilder"
local create_movebuilder = ecs.require "editor.movebuilder"
local objects = require "objects"
local ieditor = ecs.require "editor.editor"
local global = require "global"
local iobject = ecs.require "object"
local terrain = ecs.require "terrain"
local icamera = ecs.require "engine.camera"
local idetail = ecs.import.interface "vaststars.gamerender|idetail"
local SHOW_LOAD_RESOURCE <const> = not require "debugger".disable_load_resource
local EDITOR_CACHE_NAMES = {"CONFIRM", "CONSTRUCTED"}
local create_station_builder = ecs.require "editor.stationbuilder"
local interval_call = ecs.require "engine.interval_call"
local item_transfer = require "item_transfer"
local logistic_coord = ecs.require "terrain"
local selected_boxes = ecs.require "selected_boxes"
local igame_object = ecs.import.interface "vaststars.gamerender|igame_object"
local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER
local COLOR_INVALID <const> = math3d.constant "null"
local mu = import_package "ant.math".util
local igameplay = ecs.import.interface "vaststars.gamerender|igameplay"

local rotate_mb = mailbox:sub {"rotate"} -- construct_pop.rml -> 旋转
local build_mb = mailbox:sub {"build"}   -- construct_pop.rml -> 修建
local cancel_mb = mailbox:sub {"cancel"} -- construct_pop.rml -> 取消
local dragdrop_camera_mb = world:sub {"dragdrop_camera"}
local show_statistic_mb = mailbox:sub {"statistic"} -- 主界面左下角 -> 统计信息
local show_setting_mb = mailbox:sub {"show_setting"} -- 主界面左下角 -> 游戏设置
local technology_mb = mailbox:sub {"technology"} -- 主界面左下角 -> 科研中心
local click_techortaskicon_mb = mailbox:sub {"click_techortaskicon"}
local guide_on_going_mb = mailbox:sub {"guide_on_going"}
local load_resource_mb = mailbox:sub {"load_resource"}
local help_mb = mailbox:sub {"help"}
local single_touch_mb = world:sub {"single_touch"}
local move_md = mailbox:sub {"move"}
local move_finish_mb = mailbox:sub {"move_finish"}
local teardown_mb = mailbox:sub {"teardown"}
local builder_back_mb = mailbox:sub {"builder_back"}
local construction_center_menu_place_mb = mailbox:sub {"construction_center_menu_place"}
local item_transfer_src_inventory_mb = mailbox:sub {"item_transfer_src_inventory"}

local pickup_gesture_mb = world:sub {"pickup_gesture"}
local pickup_long_press_gesture_mb = world:sub {"pickup_long_press_gesture"}
local single_touch_move_mb = world:sub {"single_touch", "MOVE"}
local focus_tips_event = world:sub {"focus_tips"}

local builder
local item_transfer_dst
local pickup_id -- object id
local excluded_pickup_id -- object id
local manual_item_transfer_src_inventory = false
local handle_pickup = true
local help_open = false

local item_transfer_placement_interval = interval_call(300, function(datamodel, object_id)
    if not global.item_transfer_src then
        datamodel.item_transfer_src_inventory = {}
        return
    end

    local object = assert(objects:get(global.item_transfer_src))
    local e = assert(gameplay_core.get_entity(assert(object.gameplay_eid)))
    local movable_items, movable_items_hash = item_transfer.get_movable_items(e)
    if item_transfer_dst then
        local object = assert(objects:get(item_transfer_dst))
        local e = assert(gameplay_core.get_entity(assert(object.gameplay_eid)))
        local placeable_items = item_transfer.get_placeable_items(e)
        local ci = 1
        for _, slot in ipairs(placeable_items) do
            local j = movable_items_hash[slot.item]
            if j then
                movable_items[j].movable = true
                movable_items[ci], movable_items[j] = movable_items[j], movable_items[ci]
                ci = ci + 1
            end
        end
    end

    local items = {}
    for _, slot in ipairs(movable_items) do
        local typeobject_item = assert(iprototype.queryById(slot.item))
        items[#items + 1] = {icon = typeobject_item.icon, count = slot.count, movable = (slot.movable == true)}
        if #items >= 5 then
            break
        end
    end
    datamodel.item_transfer_src_inventory = items

    if manual_item_transfer_src_inventory then
        return
    end
    ------
    if pickup_id == global.item_transfer_src then
        datamodel.show_item_transfer_src_inventory = true
    else
        datamodel.show_item_transfer_src_inventory = false

        local movable_items, movable_items_hash, placeable_items
        do
            if global.item_transfer_src then
                local object = assert(objects:get(global.item_transfer_src))
                local e = gameplay_core.get_entity(assert(object.gameplay_eid))
                movable_items, movable_items_hash = item_transfer.get_movable_items(e)
                assert(movable_items and movable_items_hash)
            end
        end

        do
            if object_id then
                local object = assert(objects:get(object_id))
                local e = gameplay_core.get_entity(assert(object.gameplay_eid))
                placeable_items = assert(item_transfer.get_placeable_items(e))
            end
        end
        do
            for _, slot in ipairs(placeable_items or {}) do
                if movable_items_hash[slot.item] then
                    datamodel.show_item_transfer_src_inventory = true
                    break
                end
            end
        end
    end
end)

local function reverse(array)
    local i, j = 1, #array
    while i < j do
        array[i], array[j] = array[j], array[i]
        i = i + 1
        j = j - 1
    end
end

local construction_center_menu_interval = interval_call(500, function(datamodel, object_id)
    if not object_id then
        datamodel.construction_center_menu = {}
        return
    end
    local object = assert(objects:get(object_id))
    local typeobject = iprototype.queryByName(object.prototype_name)
    if not typeobject.construction_center then
        datamodel.construction_center_menu = {}
        return
    end

    local res = {}
    local e = assert(gameplay_core.get_entity(assert(object.gameplay_eid)))
    if e.chest.chest ~= 0 then
        for index = 1, 256 do
            local slot = gameplay_core.get_world():container_get(e.chest, index)
            if not slot then
                break
            end
            if slot.item == 0 then
                goto continue
            end

            local typeobject_item = assert(iprototype.queryById(slot.item))
            if not iprototype.has_type(typeobject_item.type, "building") then
                goto continue
            end

            if slot.amount > 0 then
                res[#res+1] = {icon = typeobject_item.icon, count = slot.amount, name = iprototype.show_prototype_name(typeobject_item), object_id = object_id, index = index}
                assert(#res <= 6, "construction_center_menu too long")
            end
            ::continue::
        end
    end

    reverse(res)
    for i = 1, 6 do
        if not res[i] then
            res[i] = {icon = "", count = 0, name = ""}
        end
    end
    datamodel.construction_center_menu = res
end)

---------------
local M = {}
local function get_new_tech_count(tech_list)
    local count = 0
    for _, tech in ipairs(tech_list) do
        if global.science.tech_picked_flag[tech.detail.name] then
            count = count + 1
        end
    end
    return count
end
function M:create()
    return {
        cur_edit_mode = "",
        show_load_resource = SHOW_LOAD_RESOURCE,
        tech_count = get_new_tech_count(global.science.tech_list),
        show_tech_progress = false,
        current_tech_icon = "none",    --当前科技图标
        current_tech_name = "none",    --当前科技名字
        current_tech_progress = "0%",  --当前科技进度
        current_tech_progress_detail = "0/0",  --当前科技进度(数量),
        ingredient_icons = {},
        show_ingredient = false,
        item_transfer_src_inventory = {},
        construction_center_menu = {},
    }
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
        datamodel.tech_count = get_new_tech_count(global.science.tech_list)
    end
end

function M:stage_ui_update(datamodel)
    for _ in rotate_mb:unpack() do
        if builder then
            builder:rotate_pickup_object(datamodel)
        end
    end

    for _ in build_mb:unpack() do
        if builder then
            builder:confirm(datamodel)
        end
        self:flush()
    end

    for _ in cancel_mb:unpack() do
        if builder then
            builder:clean(datamodel)
            builder = nil
        end
        handle_pickup = true
    end

    for _, _, _, is_task in click_techortaskicon_mb:unpack() do
        if gameplay_core.world_update and global.science.current_tech then
            gameplay_core.world_update = false
            iui.open(is_task and {"task_pop.rml"} or {"science.rml"})
        end
    end

    --任务完成提示界面
    for _ in technology_mb:unpack() do
        gameplay_core.world_update = false
        iui.open({"science.rml"})
    end

    for _ in show_statistic_mb:unpack() do
        iui.open({"statistics.rml"})
    end

    for _ in show_setting_mb:unpack() do
        iui.open({"option_pop.rml"})
    end

    for _ in help_mb:unpack() do
        if not help_open then
            help_open = true
            iui.open({"help_panel.rml"})
        else
            help_open = false
            iui.close({"help_panel.rml"})
        end
    end

    for _ in load_resource_mb:unpack() do
        iui.open({"loading.rml"}, false)
        camera.init("camera_default.prefab")
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
            local center = logistic_coord:get_position_by_coord(nd.x, nd.y, 1, 1)
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
            tech_node.selected_tips[#tech_node.selected_tips + 1] = {selected_boxes(nd.prefab, center, nd.w, nd.h), prefab}
        elseif nd.camera_x and nd.camera_y then
            camera.focus_on_position(logistic_coord:get_position_by_coord(nd.camera_x, nd.camera_y, width, height))
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

local function __construct_entity(datamodel, gameplay_eid, item)
    local typeobject = iprototype.queryById(item)
    if iprototype.has_type(typeobject.type, "road") then
        iui.close("building_arc_menu.rml")
        iui.close("detail_panel.rml")
        datamodel.cur_edit_mode = "construct"
        idetail.unselected()
        gameplay_core.world_update = false
        iui.open({"road_or_pipe_build.rml", "road_build.lua"})
    elseif iprototype.has_type(typeobject.type, "pipe") then
        iui.close("building_arc_menu.rml")
        iui.close("detail_panel.rml")
        datamodel.cur_edit_mode = "construct"
        idetail.unselected()
        gameplay_core.world_update = false
        iui.open({"road_or_pipe_build.rml", "pipe_build.lua"})
    elseif iprototype.has_type(typeobject.type, "pipe_to_ground") then
        iui.close("building_arc_menu.rml")
        iui.close("detail_panel.rml")
        datamodel.cur_edit_mode = "construct"
        idetail.unselected()
        gameplay_core.world_update = false
        iui.open({"road_or_pipe_build.rml", "pipe_to_ground_build.lua"})
    elseif iprototype.has_type(typeobject.type, "station") then
        builder = create_station_builder()
        builder:new_entity(datamodel, typeobject)
    else
        builder = create_normalbuilder(gameplay_eid, item)
        builder:new_entity(datamodel, typeobject)
    end
    handle_pickup = false
end

function M:stage_camera_usage(datamodel)
    for _, delta in dragdrop_camera_mb:unpack() do
        if builder then
            builder:touch_move(datamodel, delta)
            self:flush()
        end
    end

    for _, state in single_touch_mb:unpack() do
        if state == "END" or state == "CANCEL" then
            if builder then
                builder:touch_end(datamodel)
                self:flush()
            end
        end
    end

    local leave = true

    local function _get_object(pickup_x, pickup_y)
        for _, pos in ipairs(icamera.screen_to_world(pickup_x, pickup_y, PLANES)) do
            local coord = terrain:get_coord_by_position(pos)
            if coord then
                local object = objects:coord(coord[1], coord[2], EDITOR_CACHE_NAMES)
                if object then
                    return object
                end
            end
        end
    end

    -- 点击其它建筑 或 拖动时, 将弹出窗口隐藏
    for _, _, x, y in pickup_gesture_mb:unpack() do
        if not handle_pickup then
            goto continue
        end

        local object = _get_object(x, y)
        if object then -- object may be nil, such as when user click on empty space
            if not excluded_pickup_id or excluded_pickup_id == object.id then
                if idetail.show(object.id) then
                    leave = false
                    item_transfer_dst = object.id
                    pickup_id = object.id

                    local prototype_name = object.prototype_name
                    local typeobject = iprototype.queryByName(prototype_name)
                    if typeobject.construction_center then
                        datamodel.cur_edit_mode = "construct"
                    end
                end
            end
        else
            idetail.unselected()
            item_transfer_dst = nil
            pickup_id = nil
            datamodel.cur_edit_mode = ""
        end

        if leave then
            world:pub {"ui_message", "leave"}
            leave = false
            datamodel.show_item_transfer_src_inventory = false
            manual_item_transfer_src_inventory = false
            break
        end
        ::continue::
    end

    for _, _, x, y in pickup_long_press_gesture_mb:unpack() do
        if not handle_pickup then
            goto continue
        end

        local object = _get_object(x, y)
        if object then -- object may be nil, such as when user click on empty space
            if not excluded_pickup_id or excluded_pickup_id == object.id then
                local prototype_name = object.prototype_name
                local typeobject = iprototype.queryByName(prototype_name)
                if typeobject.move == false and typeobject.teardown == false then
                    goto continue1
                end

                idetail.selected(object)

                local mq = w:first("main_queue camera_ref:in render_target:in")
                local ce <close> = w:entity(mq.camera_ref, "camera:in")
                local vp = ce.camera.viewprojmat
                local vr = mq.render_target.view_rect
                local p = mu.world_to_screen(vp, vr, object.srt.t) -- the position always in the center of the screen after move camera
                local ui_x, ui_y = iui.convert_coord(vr, math3d.index(p, 1), math3d.index(p, 2))
                iui.open({"building_md_arc_menu.rml"}, object.id, object.srt.t, ui_x, ui_y)

                leave = false
            end
            ::continue1::
        else
            idetail.unselected()
            item_transfer_dst = nil
        end

        if leave then
            world:pub {"ui_message", "leave"}
            leave = false
            datamodel.show_item_transfer_src_inventory = false
            manual_item_transfer_src_inventory = false
            break
        end
        ::continue::
    end

    for _, _, _, object_id in move_md:unpack() do
        if builder then
            builder:clean(datamodel)
        end

        local object = assert(objects:get(object_id))
        local typeobject = iprototype.queryByName(object.prototype_name)
        idetail.unselected()
        ieditor:revert_changes({"TEMPORARY"})
        builder = create_movebuilder(object.id)

        builder:new_entity(datamodel, typeobject)
        self:flush()
    end

    for _ in move_finish_mb:unpack() do
        if builder then
            builder:clean(datamodel)
            builder = nil
        end
        handle_pickup = true
    end

    for _, _, _, object_id in teardown_mb:unpack() do
        iui.close("building_md_arc_menu.rml")
        idetail.unselected()

        local object = assert(objects:get(object_id))
        igameplay.remove_entity(object.gameplay_eid)
        gameplay_core.remove_entity(object.gameplay_eid)
        gameplay_core.build()

        iobject.remove(object)
        objects:remove(object_id)
        local building = global.buildings[object_id]
        if building then
            for _, v in pairs(building) do
                v:remove()
            end
        end
    end

    for _ in single_touch_move_mb:unpack() do
        if leave then
            world:pub {"ui_message", "leave"}
            leave = false
            datamodel.show_item_transfer_src_inventory = false
            manual_item_transfer_src_inventory = false
            break
        end
    end

    for _ in builder_back_mb:unpack() do
        datamodel.cur_edit_mode = ""
        handle_pickup = true
        gameplay_core.world_update = true
        iui.close("road_or_pipe_build.rml")
    end

    for _, _, _, object_id, index in construction_center_menu_place_mb:unpack() do
        if builder then
            builder:clean(datamodel)
        end

        local object = assert(objects:get(object_id))
        local e = gameplay_core.get_entity(assert(object.gameplay_eid))
        assert(e.chest.chest ~= 0)
        local slot = assert(gameplay_core.get_world():container_get(e.chest, index))
        assert(slot.item ~= 0)

        __construct_entity(datamodel, object.gameplay_eid, slot.item)
    end

    -- TODO: 多个UI的stage_ui_update中会产生focus_tips_event事件，focus_tips_event处理逻辑涉及到要修改相机位置，所以暂时放在这里处理
    for _, action, tech_node in focus_tips_event:unpack() do
        if action == "open" then
            open_focus_tips(tech_node)
        elseif action == "close" then
            close_focus_tips(tech_node)
        end
    end

    for _ in guide_on_going_mb:unpack() do
        pickup_id = nil
        idetail.unselected()
        datamodel.cur_edit_mode = ""
    end

    for _ in item_transfer_src_inventory_mb:unpack() do
        datamodel.show_item_transfer_src_inventory = not datamodel.show_item_transfer_src_inventory
        manual_item_transfer_src_inventory = true
    end

    item_transfer_placement_interval(datamodel, pickup_id)
    construction_center_menu_interval(datamodel, pickup_id)

    iobject.flush()
end
return M