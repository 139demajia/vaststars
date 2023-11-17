local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local CHEST_TYPE_CONVERT <const> = {
    [0] = "none",
    [1] = "supply",
    [2] = "demand",
    [3] = "transit",
}

local PICKUP_COMPONENTS <const> = {
    "assembling",
    "chest",
}

local PLACE_COMPONENTS <const> = {
    "assembling",
    "laboratory",
    "chest",
}

local SET_ITEM_COMPONENTS <const> = {
    "station",
}

local CONSTANT <const> = require "gameplay.interface.constant"
local CHANGED_FLAG_STATION <const> = CONSTANT.CHANGED_FLAG_STATION
local CHANGED_FLAG_DEPOT <const> = CONSTANT.CHANGED_FLAG_DEPOT

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
local remove_lorry_mb = mailbox:sub {"remove_lorry"}
local inventory_mb = mailbox:sub {"inventory"}

local move_mb = mailbox:sub {"move"}
local copy_md = mailbox:sub {"copy"}
local ichest = require "gameplay.interface.chest"
local iinventory = require "gameplay.interface.inventory"
local global = require "global"
local iobject = ecs.require "object"
local igameplay = ecs.require "gameplay_system"
local interval_call = ecs.require "engine.interval_call"
local gameplay = import_package "vaststars.gameplay"
local iGameplayStation = gameplay.interface "station"
local iGameplayChest = gameplay.interface "chest"

local function hasComponent(e, components)
    for _, v in ipairs(components) do
        if e[v] then
            return true
        end
    end
    return false
end

local function hasSetItem(e, typeobject)
    return hasComponent(e, SET_ITEM_COMPONENTS) or (e.chest and CHEST_TYPE_CONVERT[typeobject.chest_type] == "transit" or false)
end

local function hasPickupItem(e, typeobject)
    return hasComponent(e, PICKUP_COMPONENTS)
end

local function hasPlaceItem(e, typeobject)
    return hasComponent(e, PLACE_COMPONENTS) or (e.chest and CHEST_TYPE_CONVERT[typeobject.chest_type] == "transit" or false)
end

local function getPickableCount(e)
    local gameplay_world = gameplay_core.get_world()

    if e.assembling then
        if e.assembling.recipe == 0 then
            return 0
        end

        local recipe = iprototype.queryById(e.assembling.recipe)
        local ingredients_n <const> = #recipe.ingredients//4 - 1
        local results_n <const> = #recipe.results//4 - 1

        local c
        for i = 1, results_n do
            local idx = ingredients_n + i
            local slot = assert(ichest.get(gameplay_world, e.chest, idx))
            if iprototype.is_fluid_id(slot.item) then
                goto continue
            end
            assert(slot.item ~= 0)
            if c then -- the number of non-fluid outputs is greater than 1
                return "+"
            end
            c = math.min(iinventory.get_capacity(gameplay_world, slot.item), ichest.get_amount(slot))
            ::continue::
        end
        return c or 0

    elseif hasComponent(e, PICKUP_COMPONENTS) then
        local c
        for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
            local slot = ichest.get(gameplay_world, e.chest, i)
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
            c = math.min(iinventory.get_capacity(gameplay_world, slot.item), ichest.get_amount(slot))
            ::continue::
        end

        return c or 0
    else
        assert(false)
    end
end

local function getPlaceableCount(e, typeobject)
    local gameplay_world = gameplay_core.get_world()

    if e.assembling then
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

        local slot = assert(ichest.get(gameplay_world, e.chest, ingredient_idx))
        local available = ingredient_c - ichest.get_amount(slot)
        if available <= 0 then
            return 0
        end
        return math.min(iinventory.query(gameplay_world, ingredient), available)

    elseif hasPlaceItem(e, typeobject) then
        local c
        for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
            local slot = ichest.get(gameplay_world, e.chest, i)
            if not slot then
                break
            end
            if slot.item == 0 then
                goto continue
            end
            assert(not iprototype.is_fluid_id(slot.item))

            local space = ichest.get_space(slot)
            local available = math.min(iinventory.query(gameplay_world, slot.item), space)
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

local updateItemCount = interval_call(300, function(datamodel, e, typeobject)
    datamodel.pickup_item_count = datamodel.pickup_item and getPickableCount(e) or 0
    datamodel.place_item_count = datamodel.place_item and getPlaceableCount(e, typeobject) or 0
end)

---------------
local M = {}
function M.create(gameplay_eid)
    iui.register_leave("/pkg/vaststars.resources/ui/building_menu.rml")

    local e = assert(gameplay_core.get_entity(gameplay_eid))
    local typeobject
    if e.lorry then
        typeobject = iprototype.queryById(e.lorry.prototype)
    else
        typeobject = iprototype.queryById(e.building.prototype)
    end

    local set_item = hasSetItem(e, typeobject)
    local pickup_item = hasPickupItem(e, typeobject)
    local place_item = hasPlaceItem(e, typeobject)
    local lorry_factory_inc_lorry = (e.factory == true)
    local show_set_recipe = false
    if e.assembling then
        show_set_recipe = typeobject.allow_set_recipt and true or false
    end

    local move = typeobject.move ~= false
    local copy = typeobject.copy ~= false

    local datamodel = {
        prototype_name = typeobject.name,
        show_set_recipe = show_set_recipe,
        lorry_factory_inc_lorry = lorry_factory_inc_lorry,
        pickup_item = pickup_item,
        place_item = place_item,
        pickup_item_count = pickup_item and getPickableCount(e) or 0,
        place_item_count = place_item and getPlaceableCount(e, typeobject) or 0,
        set_item = set_item,
        remove_lorry = (e.lorry ~= nil),
        move = move,
        copy = copy,
        inventory = iprototype.has_type(typeobject.type, "base"),
    }

    return datamodel
end

local function station_set_item(gameplay_world, e, type, item)
    local items = {}
    local found = false

    for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
        local slot = ichest.get(gameplay_world, e.station, i)
        if not slot then
            break
        end

        local limit = slot.limit
        if slot.item == item then
            limit = limit + 1
            found = true
        end
        items[#items+1] = {slot.type, slot.item, limit}
    end

    if not found then
        local typeobject = iprototype.queryById(item)
        items[#items+1] = {type, item, typeobject.station_capacity or 1}
    end

    iGameplayStation.set_item(gameplay_world, e, items)
    gameplay_core.set_changed(CHANGED_FLAG_STATION)
end

local function station_remove_item(gameplay_world, e, slot_index, item)
    local items = {}

    for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
        local slot = ichest.get(gameplay_world, e.station, i)
        if not slot then
            break
        end

        if slot.item == item and slot.limit - 1 > 0 then
            items[#items+1] = {slot.type, slot.item, slot.limit - 1}
        elseif i ~= slot_index then
            items[#items+1] = {slot.type, slot.item, slot.limit}
        end
    end

    iGameplayStation.set_item(gameplay_world, e, items)
    gameplay_core.set_changed(CHANGED_FLAG_STATION)
end

local function chest_set_item(gameplay_world, e, type, item)
    local items = {}
    local typeobject = iprototype.queryById(e.building.prototype)
    for i = 1, ichest.get_max_slot(typeobject) do
        local slot = ichest.get(gameplay_world, e.chest, i)
        if not slot then
            break
        end
        items[#items+1] = {slot.type, slot.item}
    end

    items[#items+1] = {CHEST_TYPE_CONVERT[typeobject.chest_type], item}
    ichest.set(gameplay_world, e, items)
    gameplay_core.set_changed(CHANGED_FLAG_DEPOT)
end

local function chest_remove_item(gameplay_world, e, slot_index)
    local items = {}

    for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
        local slot = ichest.get(gameplay_world, e.chest, i)
        if not slot then
            break
        end

        if i ~= slot_index then
            items[#items+1] = {slot.type, slot.item}
        end
    end

    ichest.set(gameplay_world, e, items)
    gameplay_core.set_changed(CHANGED_FLAG_DEPOT)
end

function M.update(datamodel, gameplay_eid)
    local e = assert(gameplay_core.get_entity(gameplay_eid))
    local typeobject
    if e.lorry then
        typeobject = iprototype.queryById(e.lorry.prototype)
    else
        typeobject = iprototype.queryById(e.building.prototype)
    end
    if typeobject then
        updateItemCount(datamodel, e, typeobject)
    end

    for _ in move_mb:unpack() do
        iui.leave()
        local object = assert(objects:coord(e.building.x, e.building.y))
        iui.redirect("/pkg/vaststars.resources/ui/construct.rml", "move", object.id)
    end
    for _ in copy_md:unpack() do
        assert(e.building)
        local typeobject = iprototype.queryById(e.building.prototype)
        iui.redirect("/pkg/vaststars.resources/ui/construct.rml", "copy", typeobject.name)
    end

    for _ in set_recipe_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/recipe_config.rml"}, gameplay_eid)
    end

    for _ in set_item_mb:unpack() do
        assert(hasSetItem(e, typeobject))
        local interface = {}
        if e.station then
            interface.set_item = station_set_item
            interface.remove_item = station_remove_item
            interface.supply_button = true
            interface.demand_button = true
            interface.show_add = false
        else
            interface.set_item = chest_set_item
            interface.remove_item = chest_remove_item
            interface.show_add = true
        end
        iui.open({rml = "/pkg/vaststars.resources/ui/item_config.rml"}, gameplay_eid, interface)
    end

    for _ in lorry_factory_inc_lorry_mb:unpack() do
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
        if not iinventory.pickup(gameplay_core.get_world(), slot.item, 1) then
            print("failed to place")
            goto continue
        end
        ichest.place_at(gameplay_core.get_world(), e, 1, 1)
        ::continue::
    end

    for _, _, _, message in ui_click_mb:unpack() do
        itask.update_progress("click_ui", message, typeobject.name)
    end

    for _ in pickup_item_mb:unpack() do
        local object = assert(objects:coord(e.building.x, e.building.y))
        local gameplay_world = gameplay_core.get_world()

        local msgs = {}
        if e.assembling then
            iinventory.assembling_to_inventory(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs + 1] = {icon = item.item_icon, name = item.name, count = n}

                itask.update_progress("pickup_item", object.prototype_name, item.name, n)
            end)

        elseif hasComponent(e, PICKUP_COMPONENTS) then
            iinventory.chest_to_inventory(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs + 1] = {icon = assert(item.item_icon), name = item.name, count = n}

                itask.update_progress("pickup_item", object.prototype_name, item.name, n)
            end)

            if typeobject.chest_destroy then
                if not ichest.has_item(gameplay_world, e.chest) then
                    iobject.remove(object)
                    objects:remove(object.id)
                    local building = global.buildings[object.id]
                    if building then
                        for _, v in pairs(building) do
                            v:remove()
                        end
                    end

                    igameplay.destroy_entity(gameplay_eid)
                    iui.leave()
                    iui.redirect("/pkg/vaststars.resources/ui/construct.rml", "unselected")
                end
            end
        else
            assert(false)
        end

        local sp_x, sp_y = math3d.index(icamera_controller.world_to_screen(object.srt.t), 1, 2)
        iui.send("/pkg/vaststars.resources/ui/message_pop.rml", "item", {action = "up", left = sp_x, top = sp_y, items = msgs})
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/construct.rml", "update_item_bar", msgs)
    end

    for _ in place_item_mb:unpack() do
        local object = assert(objects:coord(e.building.x, e.building.y))
        local gameplay_world = gameplay_core.get_world()

        local msgs = {}
        if e.assembling then
            iinventory.inventory_to_assembling(gameplay_world, e, function(id, n)
                local item = iprototype.queryById(id)
                msgs[#msgs+1] = {icon = item.item_icon, name = item.name, count = n}
            end)

        elseif hasPlaceItem(e, typeobject) then
            iinventory.inventory_to_chest(gameplay_world, e, function(id, n)
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
        iui.call_datamodel_method("/pkg/vaststars.resources/ui/construct.rml", "update_item_bar", msgs)

        for i = 1, ichest.get_max_slot(iprototype.queryById(e.building.prototype)) do
            local slot = ichest.get(gameplay_world, e.chest, i)
            if not slot then
                break
            end
            if slot.item == 0 then
                goto continue
            end
            itask.update_progress("place_item", object.prototype_name, iprototype.queryById(slot.item).name, slot.amount)
            ::continue::
        end
    end

    for _ in remove_lorry_mb:unpack() do
        e.lorry_willremove = true
        iui.leave()
        iui.redirect("/pkg/vaststars.resources/ui/construct.rml", "unselected")
    end

    for _ in inventory_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/inventory.rml"})
    end
end

return M