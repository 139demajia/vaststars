local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local CONSTANT <const> = require "gameplay.interface.constant"
local CHANGED_FLAG_BUILDING <const> = CONSTANT.CHANGED_FLAG_BUILDING
local COLOR <const> = ecs.require "vaststars.prototype|color"
local SELECTION_BOX_MODEL <const> = ecs.require "vaststars.prototype|selection_box_model"

local ipick_object = ecs.require "pick_object_system"
local CLASS <const> = ipick_object.CLASS

local math3d = require "math3d"
local XZ_PLANE <const> = math3d.constant("v4", {0, 1, 0, 0})

local icamera_controller = ecs.require "engine.system.camera_controller"
local gameplay_core = require "gameplay.core"
local iui = ecs.require "engine.system.ui_system"
local iprototype = require "gameplay.interface.prototype"
local irecipe = require "gameplay.interface.recipe"
local objects = require "objects"
local global = require "global"
local iobject = ecs.require "object"
local idetail = ecs.require "detail_system"
local icoord = require "coord"
local ibackpack = require "gameplay.interface.backpack"
local gesture_longpress_mb = world:sub{"gesture", "longpress"}
local ilorry = ecs.require "render_updates.lorry"
local igame_object = ecs.require "engine.game_object"
local rotate_mb = mailbox:sub {"rotate"}
local build_mb = mailbox:sub {"build"}
local quit_mb = mailbox:sub {"quit"}
local dragdrop_camera_mb = world:sub {"dragdrop_camera"}
local click_techortaskicon_mb = mailbox:sub {"click_techortaskicon"}
local guide_on_going_mb = mailbox:sub {"guide_on_going"}
local move_md = mailbox:sub {"move"}
local teardown_mb = mailbox:sub {"teardown"}
local construct_entity_mb = mailbox:sub {"construct_entity"}
local copy_mb = mailbox:sub {"copy"}
local build_mode_mb = mailbox:sub {"build_mode"}
local main_button_tap_mb = mailbox:sub {"main_button_tap"}
local main_button_longpress_mb = mailbox:sub {"main_button_longpress"}
local unselected_mb = mailbox:sub {"unselected"}
local gesture_tap_mb = world:sub{"gesture", "tap"}
local gesture_pan_mb = world:sub {"gesture", "pan"}
local gesture_pinch = world:sub {"gesture", "pinch"}
local focus_transfer_source_mb = mailbox:sub {"focus_transfer_source"}
local set_continuity_mb = mailbox:sub {"set_continuity"}
local click_recipe_mb = mailbox:sub {"click_recipe"}
local bulk_select_mb = mailbox:sub {"bulk_select"}
local bulk_opt_exit_mb = mailbox:sub {"bulk_opt_exit"}
local iguide_tips = ecs.require "guide_tips"
local create_selection_box = ecs.require "selection_box"
local interval_call = ecs.require "engine.interval_call"
local itransfer = require "gameplay.interface.transfer"
local show_message = ecs.require "show_message".show_message
local teardown = ecs.require "editor.teardown"

local tech_recipe_unpicked_dirty_mb = world:sub {"tech_recipe_unpicked_dirty"}
local builder, builder_datamodel
local selected_obj

local function toggle_view(s, pos, cb)
    pos = math3d.set_index(pos, 2, 0)

    if s == "default" then
        icamera_controller.toggle_view("default", pos, cb)
        igame_object.restart_world()
    elseif s == "construct" then
        icamera_controller.toggle_view("construct", pos, cb)
        igame_object.stop_world()
    else
        assert(false)
    end
end

local function _clean(datamodel)
    if builder then
        builder:clean(builder_datamodel)
        builder, builder_datamodel = nil, nil
    end
    iui.close("/pkg/vaststars.resources/ui/build.html")

    idetail.unselected()
    datamodel.focus_building_icon = ""
    datamodel.status = "NORMAL"
    itransfer.set_dest_eid(nil)
    selected_obj = nil

    iui.leave()
end

local function _get_daynight_image(gameplay_world)
    local time = gameplay_world:now() % CONSTANT.DayTick
    if time < CONSTANT.DuskTick then
        return "/pkg/vaststars.resources/ui/textures/construct/daynight/dusk.texture"
    elseif time < CONSTANT.NightTick then
        return "/pkg/vaststars.resources/ui/textures/construct/daynight/night.texture"
    elseif time < CONSTANT.DawnTick then
        return "/pkg/vaststars.resources/ui/textures/construct/daynight/dawn.texture"
    else
        return "/pkg/vaststars.resources/ui/textures/construct/daynight/day.texture"
    end
end

local MAX_ELECTRICITY_LEN <const> = 3
local function _format_MG_number(n)
    local int_part = math.floor(n)
    local decimal_part = n - int_part

    if int_part >= 1000 or decimal_part == 0 then
        return tostring(int_part)
    else
        local num_digits = MAX_ELECTRICITY_LEN - string.len(tostring(int_part))
        local format_str = "%." .. tostring(num_digits) .. "f"
        return string.format(format_str, n)
    end
end

local function _format_number(negative, n)
    if n > 1000000000 then
        local v = _format_MG_number(n / 1000000000)
        return negative and "-" .. v or v, "G"
    elseif n > 1000000 then
        local v = _format_MG_number(n / 1000000)
        return negative and "-" .. v or v, "M"
    elseif n > 1000 then
        return negative and -(n // 1000) or n // 1000, "k"
    else
        return negative and -n or n, ""
    end
end

local function _get_electricity(gameplay_world)
    local consumer = 0
    local generator = 0

    for i = 1, 255 do
        local pg = gameplay_world.ecs:object("powergrid", i+1)
        if pg.active == 0 then
            break
        end
        consumer = consumer + pg.consumer_power1 + pg.consumer_power2
        generator = generator + pg.generator_power1 + pg.generator_power2
    end

    local electricity = generator - consumer
    local negative = electricity < 0
    electricity = math.abs(electricity)

    local n, unit = _format_number(negative, electricity)
    return n, unit .. "W", negative
end

local function _get_pollution(gameplay_world)
    local e = assert(gameplay_world.ecs:first("global_state:in"))
    local n, unit = _format_number(false, e.global_state.pollution)
    return n, unit .. "μg", e.global_state.pollution
end

local function _get_new_tech_count(tech_list)
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
local function get_recipe_list()
    local recipe_list = {}
    for _, recipe in ipairs(global.science.tech_recipe_unpicked) do
        recipe_list[#recipe_list + 1] = recipe
        --TODO: show 3 recipe
        if #recipe_list > 3 then
            break
        end
    end
    return recipe_list
end
function M.create()
    local gameplay_world = gameplay_core.get_world()
    return {
        status = "NORMAL",
        show_tech_progress = false,
        current_tech_icon = "none",    --当前科技图标
        current_tech_name = "none",    --当前科技名字
        current_tech_progress = "0%",  --当前科技进度
        current_tech_progress_detail = "0/0",  --当前科技进度(数量),
        ingredient_icons = {},
        show_ingredient = false,
        category_idx = 0,
        item_idx = 0,
        item_bar = {},
        transfer_id = 0,
        show_construct_button = false,
        is_task = false,                --是否是任务
        guide_progress = 0,             --引导进度
        focus_building_icon = "",
        recipe_list = get_recipe_list(),
        pollution = 0,
        pollution_raw = 0,
        pollution_unit = "μg",
        daynight = _get_daynight_image(gameplay_world),
        electricity = 0,
        electricity_unit = "W",
        electricity_negative = false,
        new_tech_count = _get_new_tech_count(global.science.tech_list),
    }
end

local current_techname = ""
function M.update_tech(datamodel, tech)
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
        datamodel.new_tech_count = _get_new_tech_count(global.science.tech_list)
    end
end

local function _construct_entity(typeobject, position_type, continuity)
    idetail.unselected()
    gameplay_core.world_update = false
    builder_datamodel = iui.get_datamodel("/pkg/vaststars.resources/ui/build.html")

    local create_builder = ecs.require("editor.builder." .. typeobject.builder)
    builder = create_builder("build")
    builder:new(builder_datamodel, typeobject, position_type, continuity)
end

local function show_selectbox(x, y, w, h)
    local pos = icoord.position(x, y, w, h)
    local o = create_selection_box(
        SELECTION_BOX_MODEL,
        pos, COLOR.SELECTED_OUTLINE, w, h
    )
    idetail.add_tmp_object(o)
end

local function pickupObjectOnBuild(datamodel, position, blur)
    local coord = icoord.position2coord(position)
    if not coord then
        return
    end
    idetail.unselected()

    local o = ipick_object.pick(coord[1], coord[2], blur)
    if o and o.class == CLASS.Lorry then
        local typeobject = iprototype.queryByName(o.name)
        iui.open({rml = "/pkg/vaststars.resources/ui/non_building_detail_panel.html"}, typeobject.icon, typeobject.mineral_name and typeobject.mineral_name or iprototype.display_name(typeobject), o.eid)

        local lorry = assert(ilorry.get(o.id))
        lorry:show_arrow(true)
        idetail.add_tmp_object({remove = function()
            local lorry = ilorry.get(o.id)
            if lorry then
                lorry:show_arrow(false)
            end
        end})
        return

    elseif o and o.class == CLASS.Object then
        local object = o.object
        local excluded_pickup_id = iguide_tips.get_excluded_pickup_id()
        if excluded_pickup_id and excluded_pickup_id ~= object.id then
            return
        end

        iui.open({rml = "/pkg/vaststars.resources/ui/detail_panel.html"}, object.id)

        local e = assert(gameplay_core.get_entity(object.gameplay_eid))
        local typeobject = iprototype.queryById(e.building.prototype)
        local w, h = iprototype.rotate_area(typeobject.area, e.building.direction)
        show_selectbox(e.building.x, e.building.y, w, h)
        return

    elseif o and (o.class == CLASS.Mountain or o.class == CLASS.Road) then
        local typeobject = iprototype.queryByName(o.name)
        iui.open({rml = "/pkg/vaststars.resources/ui/non_building_detail_panel.html"}, typeobject.icon, iprototype.display_name(typeobject), o.eid)

        if o.x and o.y and o.w and o.h then
            show_selectbox(o.x, o.y, o.w, o.h)
        end
        return

    elseif o and o.class == CLASS.Mineral then
        local typeobject = iprototype.queryByName(o.name)
        iui.open({rml = "/pkg/vaststars.resources/ui/non_building_detail_panel.html"}, typeobject.icon, typeobject.mineral_name and typeobject.mineral_name or iprototype.display_name(typeobject), o.eid)

        show_selectbox(o.x, o.y, o.w, o.h)
        return
    else
        _clean(datamodel)
        toggle_view("default", icamera_controller.get_screen_world_position("CENTER"), function()
            gameplay_core.world_update = true
            _clean(datamodel)
        end)
    end
end

local function pickupObject(datamodel, position, blur)
    local coord = icoord.position2coord(position)
    if not coord then
        return
    end
    idetail.unselected()

    local o = ipick_object.pick(coord[1], coord[2], blur)
    assert(o)
    local building_eid

    if o and o.class == CLASS.Lorry then
        local typeobject = iprototype.queryByName(o.name)
        iui.open({rml = "/pkg/vaststars.resources/ui/non_building_detail_panel.html"}, typeobject.icon, typeobject.mineral_name and typeobject.mineral_name or iprototype.display_name(typeobject), o.eid)

        local e = gameplay_core.get_entity(o.id)
        local item_name = e.lorry.item_prototype == 0 and "" or iprototype.queryById(e.lorry.item_prototype).name
        log.info(("lorry: id(%s) item(%s) count(%s)"):format(o.id, item_name, e.lorry.item_amount))

        local lorry = assert(ilorry.get(o.id))
        lorry:show_arrow(true)
        idetail.add_tmp_object({remove = function()
            local lorry = ilorry.get(o.id)
            if lorry then
                lorry:show_arrow(false)
            end
        end})

        --
        selected_obj = o
        datamodel.focus_building_icon = typeobject.item_icon
        datamodel.status = "FOCUS"

        iui.open({rml = "/pkg/vaststars.resources/ui/building_menu.html"}, o.id, false)

    elseif o and o.class == CLASS.Object then
        local object = o.object
        local excluded_pickup_id = iguide_tips.get_excluded_pickup_id()
        if excluded_pickup_id and excluded_pickup_id ~= object.id then
            return
        end

        iui.open({rml = "/pkg/vaststars.resources/ui/detail_panel.html"}, object.id)

        local gameplay_eid = object.gameplay_eid
        local e = assert(gameplay_core.get_entity(gameplay_eid))
        local typeobject = iprototype.queryById(e.building.prototype)
        local w, h = iprototype.rotate_area(typeobject.area, e.building.direction)
        show_selectbox(e.building.x, e.building.y, w, h)

        --
        selected_obj = o
        datamodel.focus_building_icon = iprototype.item(typeobject).item_icon
        datamodel.status = "FOCUS"

        iui.open({rml = "/pkg/vaststars.resources/ui/building_menu.html"}, gameplay_eid, false)
        building_eid = gameplay_eid

    elseif o and (o.class == CLASS.Mountain or o.class == CLASS.Road) then
        local typeobject = iprototype.queryByName(o.name)
        iui.open({rml = "/pkg/vaststars.resources/ui/non_building_detail_panel.html"}, typeobject.icon, iprototype.display_name(typeobject), o.eid)

        show_selectbox(o.x, o.y, o.w, o.h)

        --
        selected_obj = o
        datamodel.focus_building_icon = iprototype.item(typeobject).item_icon
        datamodel.status = "FOCUS"

        if o.class == CLASS.Road then
            iui.open({rml = "/pkg/vaststars.resources/ui/building_menu.html"}, o.id, false)
        end

    elseif o and o.class == CLASS.Mineral then
        local typeobject = iprototype.queryByName(o.name)
        iui.open({rml = "/pkg/vaststars.resources/ui/non_building_detail_panel.html"}, typeobject.icon, typeobject.mineral_name and typeobject.mineral_name or iprototype.display_name(typeobject), o.eid)

        show_selectbox(o.x, o.y, o.w, o.h)

        selected_obj = o

        --
        datamodel.show_construct_button = true
        idetail.add_tmp_object({remove = function()
            datamodel.show_construct_button = false
        end})

    elseif o and o.class == CLASS.Empty then
        show_selectbox(o.x, o.y, o.w, o.h)

        selected_obj = o
        datamodel.focus_building_icon = ""

        --
        datamodel.show_construct_button = true
        idetail.add_tmp_object({remove = function()
            datamodel.show_construct_button = false
        end})
    end

    itransfer.set_dest_eid(building_eid)
end

local update = interval_call(300, function(datamodel)
    datamodel.transfer_id = itransfer.get_source_eid() or 0

    local gameplay_world = gameplay_core.get_world()
    datamodel.pollution, datamodel.pollution_unit, datamodel.pollution_raw = _get_pollution(gameplay_world)
    datamodel.daynight = _get_daynight_image(gameplay_world)
    datamodel.electricity, datamodel.electricity_unit, datamodel.electricity_negative = _get_electricity(gameplay_world)

    if not itransfer.get_source_eid() then
        if #datamodel.item_bar > 0 then
            datamodel.item_bar = {}
        end
        return
    end

    local item_bar = {}
    local info = itransfer.get_transfer_info(gameplay_world)
    for idx, slot in itransfer.get_source_slots(gameplay_world) do
        local typeobject = iprototype.queryById(slot.item)
        local is_transfer = info[slot.item] ~= nil
        local item_icon = typeobject.item_icon or error("no item icon for " .. typeobject.name)
        item_bar[#item_bar + 1] = {icon = item_icon, name = typeobject.name, count = slot.amount, is_transfer = is_transfer, value = is_transfer and 1 or 0, idx = idx}
    end
    table.sort(item_bar, function(a, b)
        if a.value > b.value then
            return true
        elseif a.value < b.value then
            return false
        else
            return a.idx < b.idx
        end
    end)

    datamodel.item_bar = {}
    for i = 1, 4 do
        datamodel.item_bar[i] = item_bar[i]
    end
end)

function M.update(datamodel)
    update(datamodel)

    for _ in rotate_mb:unpack() do
        if builder and builder.rotate then
            builder:rotate(builder_datamodel)
        end
    end

    for _ in build_mb:unpack() do
        if builder and builder.confirm then
            builder:confirm(builder_datamodel)
            if not builder.continuity then
                _clean(datamodel)
                toggle_view("default", icamera_controller.get_screen_world_position("CENTER"), function()
                    gameplay_core.world_update = true
                    _clean(datamodel)
                end)
            end
        end
    end

    for _, _, _, c in set_continuity_mb:unpack() do
        if builder then
            assert(builder.set_continuity)
            builder:set_continuity(c)
        end
    end

    for _ in quit_mb:unpack() do
        _clean(datamodel)
        toggle_view("default", icamera_controller.get_screen_world_position("CENTER"), function()
            gameplay_core.world_update = true
            _clean(datamodel)
        end)
    end

    for _ in guide_on_going_mb:unpack() do
        _clean(datamodel)
        toggle_view("default", icamera_controller.get_screen_world_position("CENTER"), function()
            gameplay_core.world_update = true
            _clean(datamodel)
        end)
    end

    for _ in click_techortaskicon_mb:unpack() do
        gameplay_core.world_update = false
        iui.open({rml = "/pkg/vaststars.resources/ui/science.html"})
    end

    local dragdrop_delta
    for _, delta in dragdrop_camera_mb:unpack() do
        dragdrop_delta = delta
    end
    if dragdrop_delta then
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_select.html", "gesture_pan_changed", dragdrop_delta)
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_opt.html", "gesture_pan_changed", dragdrop_delta)
        if builder then
            builder:touch_move(builder_datamodel, dragdrop_delta)
        end
    end

    for _, _, e in gesture_pan_mb:unpack() do
        if e.state == "began" then
            idetail.unselected()
            selected_obj = nil
            iui.leave()

            -- not in copy mode
            if datamodel.status ~= "BUILD" and datamodel.status ~= "BULK_OPT" then
                datamodel.focus_building_icon = ""
                datamodel.status = "NORMAL"
                itransfer.set_dest_eid(nil)
                selected_obj = nil
            end
        elseif e.state == "ended" then
            iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_select.html", "gesture_pan_ended", dragdrop_delta)
            iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_opt.html", "gesture_pan_ended", dragdrop_delta)
        end

        if builder then
            if e.state == "ended" then
                builder:touch_end(builder_datamodel)
            end
        end
    end

    for _ in gesture_pinch:unpack() do
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_select.html", "gesture_pinch")
    end

    for _, _, v in gesture_tap_mb:unpack() do
        if datamodel.status == "BULK_OPT" then
            iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_select.html", "gesture_tap")
            iui.call_datamodel_method("/pkg/vaststars.resources/ui/bulk_opt.html", "gesture_tap")
            goto continue
        end

        iui.leave()
        local pos = icamera_controller.screen_to_world(v.x, v.y, XZ_PLANE)

        -- don't respond to tap in build mode
        if datamodel.status == "BUILD" then
            pickupObjectOnBuild(datamodel, pos, false)
        else
            pickupObject(datamodel, pos, true)
        end
        ::continue::
    end

    local longpress_startpoint = {}
    for _, _, e in gesture_longpress_mb:unpack() do
        -- don't respond to long press in build mode
        if datamodel.status == "BUILD" or datamodel.status == "BULK_OPT" then
            goto continue
        end
        if e.state == "began" then
            local pos = icamera_controller.screen_to_world(e.x, e.y, XZ_PLANE)
            pickupObject(datamodel, pos)
            icamera_controller.toggle_view("pickup", math3d.set_index(pos, 2, 0))

        elseif e.state == "changed" then
            longpress_startpoint.x = e.x
            longpress_startpoint.y = e.y

        elseif e.state == "ended" then
            longpress_startpoint = nil

            local pos = icamera_controller.get_screen_world_position("CENTER")
            pos = math3d.set_index(pos, 2, 0)
            icamera_controller.toggle_view("default", math3d.set_index(pos, 2, 0))
        end
        ::continue::
    end

    if longpress_startpoint and longpress_startpoint.x and longpress_startpoint.y then
        log.info("longpress_startpoint", longpress_startpoint.x, longpress_startpoint.y)
        _clean(datamodel)
        local pos = icamera_controller.screen_to_world(longpress_startpoint.x, longpress_startpoint.y, XZ_PLANE)
        pickupObject(datamodel, pos)
    end

    for _, _, _, gameplay_eid in teardown_mb:unpack() do
        iui.leave()
        idetail.unselected()
        datamodel.focus_building_icon = ""
        datamodel.status = "NORMAL"
        itransfer.set_dest_eid(nil)
        selected_obj = nil

        local e = assert(gameplay_core.get_entity(gameplay_eid))
        teardown(gameplay_eid)
        gameplay_core.set_changed(CHANGED_FLAG_BUILDING)

        -- the building directly go into the backpack
        local base = ibackpack.get_base_entity(gameplay_core.get_world())
        if not ibackpack.place(gameplay_core.get_world(), base, e.building.prototype, 1) then
            show_message("backpack is full")
        end
    end

    for _, _, _, object_id in move_md:unpack() do
        datamodel.status = "BUILD"
        toggle_view("construct", icamera_controller.get_screen_world_position("CENTER"), function()
            if builder then
                builder:clean(builder_datamodel)
            end

            local object = assert(objects:get(object_id))
            local typeobject = iprototype.queryByName(object.prototype_name)
            gameplay_core.world_update = false

            idetail.unselected()
            builder_datamodel = iui.open({rml = "/pkg/vaststars.resources/ui/build.html"}, object.gameplay_eid, typeobject.id, true)
            assert(typeobject.builder == "normal" or typeobject.builder == "factory" or typeobject.builder == "station", "invalid builder type")
            local create_builder = ecs.require("editor.builder." .. typeobject.builder)
            builder = create_builder("move")
            builder:new(object_id, builder_datamodel, typeobject, "CENTER")
        end)
    end

    for _, _, _, name, continuity in construct_entity_mb:unpack() do
        assert(datamodel.status == "BUILD")
        local typeobject = iprototype.queryByName(name)
        idetail.unselected()
        gameplay_core.world_update = false

        -- we may click the button repeatedly, so we need to clear the old model first
        if builder then
            builder:clean(builder_datamodel)
            builder, builder_datamodel = nil, nil
        end
        _construct_entity(typeobject, "CENTER", continuity)
    end

    for _, _, _, name, position in copy_mb:unpack() do
        math3d.unmark(position)

        local typeobject = iprototype.queryByName(name)
        local gameplay_world = gameplay_core.get_world()
        local count = ibackpack.query(gameplay_world, ibackpack.get_base_entity(gameplay_world), typeobject.id)
        if count <= 0 then
            show_message("item not enough")
            goto continue
        end

        datamodel.status = "BUILD"
        idetail.unselected()

        icamera_controller.focus_on_position("CENTER", position)
        toggle_view("construct", position, function()
            iui.leave()
            iui.open({rml = "/pkg/vaststars.resources/ui/build.html"}, ibackpack.get_base_entity(gameplay_world).eid, typeobject.id)
            gameplay_core.world_update = false

            assert(builder == nil)
            _construct_entity(typeobject, "CENTER", iprototype.continuity(typeobject))
        end)
        ::continue::
    end

    for _, _, _, gameplay_eid in build_mode_mb:unpack() do
        print(gameplay_eid)
        local gameplay_world = gameplay_core.get_world()
        local base = ibackpack.get_base_entity(gameplay_world)
        gameplay_world.ecs:extend(base, "eid:in")
        gameplay_eid = gameplay_eid or base.eid
        assert(gameplay_eid)

        idetail.unselected()
        datamodel.status = "BUILD"
        assert(selected_obj)

        local function f()
            iui.leave()
            iui.open({rml = "/pkg/vaststars.resources/ui/build.html"}, gameplay_eid)
            gameplay_core.world_update = false
        end

        if gameplay_eid then
            toggle_view("construct", icamera_controller.get_screen_world_position("CENTER"), f)
        else
            local pos = math3d.vector(icoord.position(selected_obj.x, selected_obj.y, selected_obj.w, selected_obj.h))
            icamera_controller.focus_on_position("CENTER", pos)
            toggle_view("construct", pos, f)
        end
    end

    for _ in main_button_tap_mb:unpack() do
        if datamodel.status == "SELECTED" then
            iui.leave()
            idetail.unselected()
            datamodel.focus_building_icon = ""
            datamodel.status = "NORMAL"
            itransfer.set_dest_eid(nil)
            selected_obj = nil

        else
            if selected_obj then
                datamodel.status = "SELECTED"

                if selected_obj.class == CLASS.Lorry then
                    local e = assert(gameplay_core.get_entity(selected_obj.id))
                    icamera_controller.focus_on_position("CENTER", math3d.vector(icoord.position(e.lorry.x, e.lorry.y, 1, 1)))

                elseif selected_obj.class == CLASS.Object then
                    local object = selected_obj.object
                    icamera_controller.focus_on_position("CENTER", object.srt.t)

                    idetail.selected(object.gameplay_eid)
                else
                    if selected_obj.get_pos then
                        icamera_controller.focus_on_position("CENTER", math3d.vector(selected_obj:get_pos()))
                    end
                end
            else
                log.error("no target selected")
            end
        end
    end

    for _, _, _, eid in unselected_mb:unpack() do
        if eid then
            if selected_obj and selected_obj.class == CLASS.Object and selected_obj.object.gameplay_eid ~= eid then
               goto continue
            end
        end
        iui.leave()
        idetail.unselected()
        datamodel.focus_building_icon = ""
        datamodel.status = "NORMAL"
        itransfer.set_dest_eid(nil)
        selected_obj = nil
        ::continue::
    end

    for _ in main_button_longpress_mb:unpack() do
        assert(selected_obj)
        if selected_obj.class == CLASS.Object then
            iui.leave()
            local object = selected_obj.object
            if iguide_tips.get_excluded_pickup_id() == object.id then
                goto continue
            end

            local prototype_name = object.prototype_name
            local typeobject = iprototype.queryByName(prototype_name)
            if typeobject.teardown == false then
                goto continue
            end
            iui.open({rml = "/pkg/vaststars.resources/ui/building_menu.html"}, selected_obj.object.gameplay_eid, true)
        elseif selected_obj.class == CLASS.Lorry or selected_obj.class == CLASS.Road then
            iui.leave()
            iui.open({rml = "/pkg/vaststars.resources/ui/building_menu.html"}, selected_obj.id, true)
        end
        ::continue::
    end

    for _ in focus_transfer_source_mb:unpack() do
        local source_eid = itransfer.get_source_eid()
        if source_eid then
            local e = assert(gameplay_core.get_entity(source_eid))
            icamera_controller.focus_on_position("CENTER", math3d.vector(icoord.position(e.building.x, e.building.y, 1, 1)))
            pickupObject(datamodel, math3d.vector(icoord.position(e.building.x, e.building.y, 1, 1)), true)
        end
    end

    local function tech_recipe_unpicked_by_name(name)
        local unpicked = global.science.tech_recipe_unpicked
        for index, value in ipairs(unpicked) do
            if value.recipe_name == name then
                return index, unpicked[index]
            end
        end
    end
    for _, remove_recipe in tech_recipe_unpicked_dirty_mb:unpack() do
        if remove_recipe then
            local index, _ = tech_recipe_unpicked_by_name(remove_recipe)
            table.remove(global.science.tech_recipe_unpicked, index)
        end
        datamodel.recipe_list = get_recipe_list()
    end
    for _, _, _, recipe_name in click_recipe_mb:unpack() do
        local index, recipe = tech_recipe_unpicked_by_name(recipe_name)
        iui.open({rml = "/pkg/vaststars.resources/ui/science.html"}, recipe)
        table.remove(global.science.tech_recipe_unpicked, index)
        datamodel.recipe_list = get_recipe_list()
    end

    for _ in bulk_select_mb:unpack() do
        idetail.unselected()

        datamodel.status = "BULK_OPT"
        toggle_view("construct", icamera_controller.get_screen_world_position("CENTER"), function()
            iui.leave()
            iui.open({rml = "/pkg/vaststars.resources/ui/bulk_select.html"})
        end)
    end

    for _ in bulk_opt_exit_mb:unpack() do
        iui.close("/pkg/vaststars.resources/ui/bulk_select.html")
        iui.close("/pkg/vaststars.resources/ui/bulk_opt.html")
        datamodel.status = "NORMAL"
        toggle_view("default", icamera_controller.get_screen_world_position("CENTER"))
    end

    iobject.flush()
end
return M