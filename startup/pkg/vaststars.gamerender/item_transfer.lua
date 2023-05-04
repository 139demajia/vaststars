local iprototype = require "gameplay.interface.prototype"
local gameplay_core = require "gameplay.core"
local ichest = require "gameplay.interface.chest"

local function get_movable_items(e)
    local items = {}
    local hash = {}
    if e.hub then
        local slot = gameplay_core.get_world():container_get(e.hub, 1)
        if slot.item ~= 0 and ichest.get_amount(slot) >= 0 then
            items[#items + 1] = {chest = e.hub, item = slot.item, count = ichest.get_amount(slot)}
            hash[slot.item] = #items
        end
    end
    if e.assembling then
        local recipe = e.assembling.recipe
        if recipe ~= 0 then
            local recipe_typeobject = iprototype.queryById(recipe)
            local ingredients_n <const> = #recipe_typeobject.ingredients//4 - 1
            local results_n <const> = #recipe_typeobject.results//4 - 1
            for i = 1, results_n do
                local slot = gameplay_core.get_world():container_get(e.chest, ingredients_n + i)
                if ichest.get_amount(slot) >= 0 then
                    items[#items + 1] = {chest = e.chest, item = slot.item, count = ichest.get_amount(slot)}
                    hash[slot.item] = #items
                end
            end
        end
    else
        if e.chest then
            for _, slot in pairs(ichest.collect_item(gameplay_core.get_world(), e.chest)) do
                if ichest.get_amount(slot) > 0 then
                    items[#items + 1] = {chest = e.chest, item = slot.item, count = ichest.get_amount(slot)}
                    hash[slot.item] = #items
                end
            end
        end
    end
    return items, hash
end
local function get_placeable_items(e)
    local items = {}
    if e.hub then
        local slot = gameplay_core.get_world():container_get(e.hub, 1)
        if slot.item ~= 0 and ichest.get_space(slot) > 0 then
            items[#items + 1] = {chest = e.hub, item = slot.item, count = ichest.get_space(slot)}
        end
    end
    if e.assembling then
        local recipe = e.assembling.recipe
        if recipe ~= 0 then
            local recipe_typeobject = iprototype.queryById(recipe)
            local ingredients_n <const> = #recipe_typeobject.ingredients//4 - 1
            for idx = 1, ingredients_n do
                local _, n = string.unpack("<I2I2", recipe_typeobject.ingredients, 4*idx+1)
                local slot = gameplay_core.get_world():container_get(e.chest, idx)
                if slot.amount + slot.lock_space < n then
                    items[#items + 1] = {chest = e.chest, item = slot.item, count = n - slot.amount + slot.lock_space}
                end
            end
        end
    end
    return items
end

return {
    get_movable_items = get_movable_items,
    get_placeable_items = get_placeable_items,
}
