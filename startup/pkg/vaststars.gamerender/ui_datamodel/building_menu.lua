local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local gameplay_core = require "gameplay.core"
local objects = require "objects"
local iprototype = require "gameplay.interface.prototype"
local iui = ecs.require "engine.system.ui_system"
local itask = ecs.require "task"
local icamera_controller = ecs.require "engine.system.camera_controller"
local math3d = require "math3d"

local set_recipe_mb = mailbox:sub {"set_recipe"}
local set_item_mb = mailbox:sub {"set_item"}
local lorry_factory_inc_lorry_mb = mailbox:sub {"lorry_factory_inc_lorry"}
local ui_click_mb = mailbox:sub {"ui_click"}
local pickup_item_mb = mailbox:sub {"pickup_item"}
local place_item_mb = mailbox:sub {"place_item"}

local ichest = require "gameplay.interface.chest"
local ibackpack = require "gameplay.interface.backpack"
local gameplay = import_package "vaststars.gameplay"
local ihub = gameplay.interface "hub"
local global = require "global"
local iobject = ecs.require "object"
local igameplay = ecs.require "gameplay_system"
local interval_call = ecs.require "engine.interval_call"
local gameplay = import_package "vaststars.gameplay"
local istation = gameplay.interface "station"

local PICKUP_TYPES <const> = {
    "assembling",
    "chest",
}

local PLACE_TYPES <const> = {
    "assembling",
    "laboratory",
}

local SET_ITEM_COMPONENT <const> = {
    "airport",
    "station",
}

local function hasComponent(e, components)
    for _, v in ipairs(components) do
        if e[v] then
            return true
        end
    end
end

local function __get_moveable_count(gameplay_eid)
    local e = gameplay_core.get_entity(gameplay_eid)
    local typeobject = iprototype.queryById(e.building.prototype)
    local gameplay_world = gameplay_core.get_world()

    if iprototype.has_type(typeobject.type, "assembling") then
        if e.assembling.recipe == 0 then
            return 0
        end

        local recipe = iprototype.queryById(e.assembling.recipe)
        local ingredients_n <const> = #recipe.ingredients//4 - 1
        local results_n <const> = #recipe.results//4 - 1
        local chest_component = ichest.get_chest_component(e)

        local c
        for i = 1, results_n do
            local idx = ingredients_n + i
            local slot = assert(ichest.get(gameplay_world, e[chest_component], idx))
            if iprototype.is_fluid_id(slot.item) then
                goto continue
            end
            assert(slot.item ~= 0)
            if c then -- the number of non-fluid outputs is greater than 1
                return "+"
            end
            c = ibackpack.get_moveable_count(gameplay_world, slot.item, ichest.get_amount(slot))
            ::continue::
        end
        return c or 0

    elseif iprototype.check_types(typeobject.name, PICKUP_TYPES) then
        local chest_component = ichest.get_chest_component(e)
        local c
        for i = 1, ichest.MAX_SLOT do
            local slot = gameplay_world:container_get(e[chest_component], i)
            if not slot then
                break
            end
            if slot.item == 0 then
                goto continue
            end
            assert(not iprototype.is_fluid_id(slot.item))
            if c then -- the number of non-fluid outputs is greater than 1
                return "+"
            end
            c = ibackpack.get_moveable_count(gameplay_world, slot.item, ichest.get_amount(slot))
            ::continue::
        end

        return c or 0
    else
        assert(false)
    end
end

local function __get_placeable_count(gameplay_eid)
    local e = gameplay_core.get_entity(assert(gameplay_eid))
    local typeobject = iprototype.queryById(e.building.prototype)
    local gameplay_world = gameplay_core.get_world()

    if iprototype.has_type(typeobject.type, "assembling") then
        if e.assembling.recipe == 0 then
            return 0
        end

        local recipe = iprototype.queryById(e.assembling.recipe)
        local ingredients_n <const> = #recipe.ingredients//4 - 1
        local ingredient, ingredient_c, ingredient_idx
        for idx = 1, ingredients_n do
            local id, n = string.unpack("<I2I2", recipe.ingredients, 4*idx+1)
            if not iprototype.is_fluid_id(id) then
                if ingredient then -- the number of non-fluid inputs is greater than 1
                    return "+"
                end
                ingredient, ingredient_c, ingredient_idx = id, n, idx
            end
        end

        if not ingredient then
            return 0
        end

        local chest_component = ichest.get_chest_component(e)
        local slot = assert(ichest.get(gameplay_world, e[chest_component], ingredient_idx))
        local available = ingredient_c - ichest.get_amount(slot)
        if available <= 0 then
            return 0
        end
        return ibackpack.get_placeable_count(gameplay_world, ingredient, available)

    elseif iprototype.check_types(typeobject.name, PLACE_TYPES) then
        local chest_component = ichest.get_chest_component(e)
        local c
        for i = 1, ichest.MAX_SLOT do
            local slot = gameplay_world:container_get(e[chest_component], i)
            if not slot then
                break
            end
            if slot.item == 0 then
                goto continue
            end
            assert(not iprototype.is_fluid_id(slot.item))

            local space = ichest.get_space(slot)
            local available = ibackpack.get_placeable_count(gameplay_world, slot.item, space)
            if available < 0 then
                goto continue
            end

            if c then
                return "+"
            end
            c = available
            ::continue::
        end

        return c or 0
    else
        assert(false)
    end
end

local __moveable_count_update = interval_call(300, function(datamodel, gameplay_eid)
    datamodel.pickup_item_count = datamodel.pickup_item and __get_moveable_count(gameplay_eid) or 0
    datamodel.place_item_count = datamodel.place_item and __get_placeable_count(gameplay_eid) or 0
end, false)

---------------
local M = {}
function M:create(object_id)
    iui.register_leave("/pkg/vaststars.resources/ui/building_menu.rml")

    local object = assert(objects:get(object_id))
    local e = gameplay_core.get_entity(assert(object.gameplay_eid))
    if not e then
        return
    end
    local typeobject = iprototype.queryById(e.building.prototype)

    local show_set_recipe = false
    local lorry_factory_inc_lorry = false
    local pickup_item, place_item = false, false
    local set_item = false

    if iprototype.check_types(typeobject.name, PICKUP_TYPES) then
        pickup_item = true
    end
    if iprototype.check_types(typeobject.name, PLACE_TYPES) then
        place_item = true
    end

    if e.assembling then
        show_set_recipe = typeobject.allow_set_recipt and true or false
    end
    if e.factory then
        lorry_factory_inc_lorry = true
    end
    if hasComponent(e, SET_ITEM_COMPONENT) then
        set_item = true
    end

    local datamodel = {
        object_id = object_id,
        prototype_name = typeobject.name,
        show_set_recipe = show_set_recipe,
        lorry_factory_inc_lorry = lorry_factory_inc_lorry,
        lorry_factory_dec_lorry = false,
        pickup_item = pickup_item,
        place_item = place_item,
        pickup_item_count = pickup_item and __get_moveable_count(object.gameplay_eid) or 0,
        place_item_count = place_item and __get_placeable_count(object.gameplay_eid) or 0,
        set_item = set_item,
    }

    return datamodel
end

local function station_set_item(gameplay_world, e, type, item)
    local chest = e[ichest.get_chest_component(e)]
    local items = {}

    for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
        local slot = gameplay_world:container_get(chest, i)
        if not slot then
            break
        end
        items[#items+1] = {slot.type, slot.item, slot.limit}
    end

    local typeobject = iprototype.queryById(item)
    items[#items+1] = {type, item, typeobject.station_limit}
    istation.set_item(gameplay_world, e, items)
end

local function station_remove_item(gameplay_world, e, slot_index)
    local chest = e[ichest.get_chest_component(e)]
    local items = {}

    for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
        local slot = gameplay_world:container_get(chest, i)
        if not slot then
            break
        end

        if i ~= slot_index then
            items[#items+1] = {slot.type, slot.item, slot.limit}
        end
    end

    istation.set_item(gameplay_world, e, items)
end

local function airport_set_item(gameplay_world, e, _, item)
    -- local items = {}
    -- items[#items+1] = item
    -- ihub.set_item(gameplay_world, e, items)
end

local function airport_remove_item(gameplay_world, e, _, _)
    -- local items = {}
    -- items[#items+1] = 0
    -- ihub.set_item(gameplay_world, e, items)
end

function M:stage_ui_update(datamodel, object_id)
    local object = assert(objects:get(object_id))

    __moveable_count_update(datamodel, assert(object.gameplay_eid))

    for _ in set_recipe_mb:unpack() do
        iui.open({"/pkg/vaststars.resources/ui/recipe_config.rml"}, object.gameplay_eid)
    end

    for _, _, _, object_id in set_item_mb:unpack() do
        local typeobject = iprototype.queryByName(object.prototype_name)
        local interface = {}
        if iprototype.has_type(typeobject.type, "airport") then
            interface.set_item = airport_set_item
            interface.remove_item = airport_remove_item
            interface.supply_button = false
            interface.demand_button = true

        elseif iprototype.has_types(typeobject.type, "station") then
            interface.set_item = station_set_item
            interface.remove_item = station_remove_item
            interface.supply_button = true
            interface.demand_button = true
        else
            assert(false)
        end
        iui.open({"/pkg/vaststars.resources/ui/item_config.rml"}, object_id, interface)
    end

    for _ in lorry_factory_inc_lorry_mb:unpack() do
        local e = gameplay_core.get_entity(assert(object.gameplay_eid))

        local component = "chest"
        local slot = ichest.get(gameplay_core.get_world(), e[component], 1)
        if not slot then
            print("item not set yet")
            goto continue
        end
        local c = ichest.get_amount(slot)
        if slot.limit <= c then
            print("item already full")
            goto continue
        end
        if not ibackpack.pickup(gameplay_core.get_world(), slot.item, 1) then
            print("failed to place")
            goto continue
        end
        ichest.set(gameplay_core.get_world(), e[component], 1, {amount = slot.amount + 1})
        ::continue::
    end

    for _, _, _, message in ui_click_mb:unpack() do
        itask.update_progress("click_ui", message, object.prototype_name)
    end

    for _, _, _, object_id in pickup_item_mb:unpack() do
        local gameplay_world = gameplay_core.get_world()
        local e = gameplay_core.get_entity(assert(object.gameplay_eid))
        local typeobject = iprototype.queryById(e.building.prototype)

        local msgs = {}
        if iprototype.has_type(typeobject.type, "assembling") then
            ibackpack.assembling_to_backpack(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs + 1] = {icon = item.item_icon, name = item.name, count = n}
            end)

        elseif iprototype.check_types(typeobject.name, PICKUP_TYPES) then
            ibackpack.chest_to_backpack(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs + 1] = {icon = assert(item.item_icon), name = item.name, count = n}
            end)

            if typeobject.chest_destroy then
                local chest_component = ichest.get_chest_component(e)
                if not ichest.has_item(gameplay_world, e[chest_component]) then
                    iobject.remove(object)
                    objects:remove(object_id)
                    local building = global.buildings[object_id]
                    if building then
                        for _, v in pairs(building) do
                            v:remove()
                        end
                    end

                    igameplay.destroy_entity(object.gameplay_eid)
                    iui.leave()
                    iui.redirect("/pkg/vaststars.resources/ui/construct.rml", "unselected")
                end
            end
        else
            assert(false)
        end

        local sp_x, sp_y = math3d.index(icamera_controller.world_to_screen(object.srt.t), 1, 2)
        iui.send("/pkg/vaststars.resources/ui/message_pop.rml", "item", {action = "up", left = sp_x, top = sp_y, items = msgs})
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/construct.rml", "update_inventory_bar", msgs)
    end

    for _ in place_item_mb:unpack() do
        local gameplay_world = gameplay_core.get_world()
        local typeobject = iprototype.queryByName(object.prototype_name)
        local e = gameplay_core.get_entity(assert(object.gameplay_eid))

        local msgs = {}
        if iprototype.has_type(typeobject.type, "assembling") then
            ibackpack.backpack_to_assembling(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs+1] = {icon = item.item_icon, name = item.name, count = n}
            end)

        elseif iprototype.check_types(typeobject.name, PLACE_TYPES) then
            ibackpack.backpack_to_chest(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs+1] = {icon = item.item_icon, name = item.name, count = n}
            end)

            if e.station then
                e.station_changed = true
            end
        else
            assert(false)
        end

        local sp_x, sp_y = math3d.index(icamera_controller.world_to_screen(object.srt.t), 1, 2)
        iui.send("/pkg/vaststars.resources/ui/message_pop.rml", "item", {action = "down", left = sp_x, top = sp_y, items = msgs})
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/construct.rml", "update_inventory_bar", msgs)
    end
end

return M