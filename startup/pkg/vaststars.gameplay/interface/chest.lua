local iBuilding = require "interface.building"
local query = require "prototype".queryById

local m = {}

local InvalidChest <const> = 0

local function assembling_reset(world, e)
    local chest = e.chest
    if chest.chest ~= InvalidChest then
        world:container_destroy(chest)
        chest.chest = InvalidChest
        iBuilding.dirty(world, "hub")
    end
end

local function isFluidId(id)
    local pt = query(id)
    for _, t in ipairs(pt.type) do
        if t == "fluid" then
            return true
        end
    end
    return false
end

local function resetItems(world, recipe, chest, option, maxslot)
    local ingredients_n <const> = #recipe.ingredients//4 - 1
    local results_n <const> = #recipe.results//4 - 1
    local hash = {}
    local olditems = {}
    local newitems = {}
    if chest.chest ~= InvalidChest then
        for i = 1, 256 do
            local slot = world:container_get(chest, i)
            if not slot then
                break
            end
            if slot.type ~= "none" then
                assert(not olditems[slot.item])
                olditems[i] = slot
                hash[slot.item] = i
            end
        end
    end
    local count = #olditems
    local function create_slot(type, id, limit)
        local o = {}
        if hash[id] then
            local i = hash[id]
            o = olditems[i]
            olditems[i] = nil
            hash[id] = nil
        end
        newitems[#newitems+1] = {
            type = type,
            item = id,
            limit = limit,
            amount = o.amount,
            lock_item = type ~= "blue" and o.lock_item or nil,
            lock_space = o.lock_space,
        }
    end
    for idx = 1, ingredients_n do
        local id, n = string.unpack("<I2I2", recipe.ingredients, 4*idx+1)
        create_slot(isFluidId(id) and "none" or "blue", id, n * option.ingredientsLimit)
    end
    for idx = 1, results_n do
        local id, n = string.unpack("<I2I2", recipe.results, 4*idx+1)
        create_slot(isFluidId(id) and "none" or "red", id, n * option.resultsLimit)
    end
    for i = count, 1, -1 do
        if #newitems > maxslot + ingredients_n then
            break
        end
        local v = olditems[i]
        if v and v.type == "red" then
            create_slot(v.type, v.item, v.amount)
        end
    end
    return newitems
end

local function assembling_set(world, e, recipe, option, maxslot)
    local chest = e.chest
    if chest.chest ~= InvalidChest then
        world:container_destroy(chest)
    end
    option = option or {
        ingredientsLimit = 2,
        resultsLimit = 2,
    }
    local items = resetItems(world, recipe, chest, option, maxslot)
    chest.chest = world:container_create(items)
    iBuilding.dirty(world, "hub")
end

function m.assembling_set(world, e, recipe, option, maxslot)
    if recipe == nil then
        assembling_reset(world, e)
        return
    end
    assembling_set(world, e, recipe, option, maxslot)
end

local function station_reset(world, e)
    local chest = e.chest
    if chest.chest ~= InvalidChest then
        world:container_destroy(chest)
        chest.chest = InvalidChest
        iBuilding.dirty(world, "hub")
    end
end

local function station_set(world, e, item, limit)
    local chest = e.chest
    if chest.chest == InvalidChest then
        chest.chest = world:container_create {{
            type = e.station_producer and "blue" or "red",
            item = item,
            amount = 0,
            limit = limit,
        }}
        iBuilding.dirty(world, "hub")
        return
    end
    local slot = world:container_get(chest, 1)
    assert(slot)
    if slot.item == item then
        if slot.limit ~= limit then
            slot.limit = limit
            world:container_set(chest, 1, slot)
        end
        return
    end
    slot.item = item
    slot.amount = 0
    slot.limit = limit
    world:container_set(chest, 1, slot)
    iBuilding.dirty(world, "hub")
end

function m.station_set(world, e, item, limit)
    if item == nil then
        station_reset(world, e)
        return
    end
    assert(limit)
    station_set(world, e, item, limit)
end

return m
