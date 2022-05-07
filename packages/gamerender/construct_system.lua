local ecs = ...
local world = ecs.world

local gameplay_core = require "gameplay.core"
local camera = ecs.require "engine.camera"
local construct_editor = ecs.require "construct_editor"
local get_recipe_menu = require "gameplay.utility.get_recipe_menu"
local building_menu = ecs.require "building_menu"

local construct_sys = ecs.system "construct_system"
local iconstruct = ecs.interface "iconstruct"
local iui = ecs.import.interface "vaststars.gamerender|iui"
local idetail = ecs.import.interface "vaststars.gamerender|idetail"

local ui_construct_entity_mb = world:sub {"ui", "construct", "construct_entity"}
local ui_construct_begin_mb = world:sub {"ui", "construct", "construct_begin"} -- 建造模式
local ui_construct_confirm_mb = world:sub {"ui", "construct", "construct_confirm"} -- 确认建造
local ui_construct_complete_mb = world:sub {"ui", "construct", "construct_complete"} -- 开始施工
local ui_construct_rotate_mb = world:sub {"ui", "construct", "rotate"}
local ui_construct_cancel_mb = world:sub {"ui", "construct", "cancel"}
local ui_construct_dismantle_begin_mb = world:sub {"ui", "construct", "dismantle_begin"}
local ui_construct_dismantle_complete_mb = world:sub {"ui", "construct", "dismantle_complete"}
local ui_construct_fluidbox_update_mb = world:sub {"ui", "construct", "fluidbox_update"}

local ui_menu_rotate_mb = world:sub {"ui", "build_function_pop", "rotate"}
local ui_menu_recipe_mb = world:sub {"ui", "build_function_pop", "recipe"}
local ui_menu_detail_mb = world:sub {"ui", "build_function_pop", "detail"}
local ui_recipe_pop_set_recipe_mb = world:sub {"ui", "recipe_pop", "set_recipe"}

local single_touch_mb = world:sub {"single_touch"}
local pickup_mapping_mb = world:sub {"pickup_mapping"}
local dragdrop_camera_mb = world:sub {"dragdrop_camera"}
local pickup_mb = world:sub {"pickup"}
local single_touch_move_mb = world:sub {"single_touch", "MOVE"}
local global = require "global"
local cache_names = global.cache_names
local objects = global.objects
local iprototype = require "gameplay.prototype"
local irecipe = require "gameplay.utility.recipe"

local mode = "normal" -- normal/construct/teardown

function construct_sys:camera_usage()
    for _, _, _, prototype_name in ui_construct_entity_mb:unpack() do
        construct_editor:new_pickup_object(prototype_name)
    end

    for _, state in single_touch_mb:unpack() do
        if state == "END" or state == "CANCEL" then
            construct_editor:adjust_pickup_object()
        end
    end

    local leave = true
    for _, vsobject_id in pickup_mapping_mb:unpack() do
        if mode == "teardown" then
            construct_editor:teardown(vsobject_id)
        elseif mode == "normal" then
            if idetail.show(vsobject_id) then
                leave = false
            end
        end
    end

    -- 点击其它建筑 或 拖动时, 将弹出窗口隐藏
    for _ in pickup_mb:unpack() do
        if leave then
            world:pub {"ui_message", "leave"}
            leave = false
            break
        end
    end

    for _ in single_touch_move_mb:unpack() do
        if leave then
            world:pub {"ui_message", "leave"}
            leave = false
            break
        end
    end
end

function construct_sys:data_changed()
    for _, delta in dragdrop_camera_mb:unpack() do
        construct_editor:move_pickup_object(delta)
    end

    for _, _, _, double_confirm in ui_construct_begin_mb:unpack() do
        if construct_editor:check_unconfirmed(double_confirm) then
            world:pub {"ui_message", "show_unconfirmed_double_confirm"}
            goto continue
        end
        if not double_confirm then
            world:pub {"ui_message", "unconfirmed_double_confirm_continuation"}
            goto continue
        end

        construct_editor:construct_begin()
        gameplay_core.world_update = false
        mode = "construct"
        camera.set("camera_construct.prefab")
        ::continue::
    end

    for _ in ui_construct_rotate_mb:unpack() do
        assert(gameplay_core.world_update == false)
        construct_editor:rotate_pickup_object()
    end

    for _ in ui_construct_confirm_mb:unpack() do
        assert(gameplay_core.world_update == false)
        if construct_editor:confirm() then
            world:pub {"ui_message", "show_construct_complete", true}
        end
    end

    for _ in ui_construct_complete_mb:unpack() do
        construct_editor:complete()
        gameplay_core.world_update = true
        mode = "normal"
        camera.set("camera_default.prefab")
    end

    for _, _, _, double_confirm in ui_construct_cancel_mb:unpack() do
        if construct_editor:check_unconfirmed(double_confirm) then
            world:pub {"ui_message", "show_unconfirmed_double_confirm"}
            goto continue
        end
        if not double_confirm then
            world:pub {"ui_message", "unconfirmed_double_confirm_continuation"}
            goto continue
        end

        construct_editor:cancel()
        gameplay_core.world_update = true
        mode = "normal"
        camera.set("camera_default.prefab")
        ::continue::
    end

    for _, _, _, double_confirm in ui_construct_dismantle_begin_mb:unpack() do
        if construct_editor:check_unconfirmed(double_confirm) then
            world:pub {"ui_message", "show_unconfirmed_double_confirm"}
            goto continue
        end
        if not double_confirm then
            world:pub {"ui_message", "unconfirmed_double_confirm_continuation"}
            goto continue
        end

        construct_editor:teardown_begin()
        mode = "teardown"
        gameplay_core.world_update = false
        camera.set("camera_construct.prefab")
        ::continue::
    end

    for _ in ui_construct_dismantle_complete_mb:unpack() do
        construct_editor:teardown_complete()
        mode = "normal"
        gameplay_core.world_update = true
        camera.set("camera_default.prefab")
    end

    for _, _, _, fluid_name in ui_construct_fluidbox_update_mb:unpack() do
        construct_editor:set_pickup_object_fluid(fluid_name)
    end

    --
    for _, _, _, vsobject_id in ui_menu_rotate_mb:unpack() do
        building_menu:rotate_object(vsobject_id)
    end

    for _, _, _, vsobject_id, recipe_name in ui_menu_recipe_mb:unpack() do
        iui.open("recipe_pop.rml", get_recipe_menu(), vsobject_id, recipe_name)
    end

    for _, _, _, vsobject_id, recipe_name in ui_menu_detail_mb:unpack() do
        local object = assert(objects:get(cache_names, vsobject_id))
        local typeobject = iprototype:queryByName("entity", object.prototype_name)
        if iprototype:has_type(typeobject.type, "assembling") then
            local recipe_typeobject = iprototype:queryByName("recipe", recipe_name)
            iui.open("assemble_2.rml", vsobject_id, recipe_name, irecipe:get_elements(recipe_typeobject.ingredients), irecipe:get_elements(recipe_typeobject.results))
        else
            log.error("not assembling")
        end
    end

    for _, _, _, vsobject_id, recipe_name in ui_recipe_pop_set_recipe_mb:unpack() do
        building_menu:set_recipe(vsobject_id, recipe_name)
    end
end

function construct_sys:pickup_mapping()
end

function iconstruct.reset()
    mode = "normal"
end
