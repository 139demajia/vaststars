local iBuilding = require "interface.building"
local iBackpack = require "interface.backpack"
local cChest = require "vaststars.chest.core"
local prototype = require "prototype"

local m = {}

local InvalidChest <const> = 0

local CHEST_TYPE <const> = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    red = 0,
    blue = 1,
    green = 2,
    none = 3,
}
local function chest_slot(t)
    assert(t.type)
    assert(t.item)
    local id = t.item
    if type(id) == "string" then
        assert(prototype.queryByName(id), ("item %s not found"):format(id))
        id = prototype.queryByName(id).id
    end
    return string.pack("<I1I1I2I2I2I2I2",
        CHEST_TYPE[t.type],
        0,
        id,
        t.amount or 0,
        t.limit or 2,
        t.lock_item or 0,
        t.lock_space or 0
    )
end

function m.create(world, items)
    local t = {}
    for _, item in ipairs(items) do
        t[#t+1] = chest_slot(item)
    end
    return cChest.create(world._cworld, table.concat(t))
end

local function chest_destroy(world, chest, recycle)
    return cChest.destroy(world._cworld, chest.chest, recycle)
end

local function chest_dirty(world, e)
    iBuilding.dirty(world, "hub")
    if e.station_consumer then
        iBuilding.dirty(world, "station_consumer")
    end
end

local function chest_reset(world, e, chest)
    if chest.chest ~= InvalidChest then
        chest_destroy(world, chest, true)
        chest.chest = InvalidChest
        chest_dirty(world, e)
    end
end

local function isFluidId(id)
    local pt = prototype.queryById(id)
    for _, t in ipairs(pt.type) do
        if t == "fluid" then
            return true
        end
    end
    return false
end

local function assembling_reset_items(world, recipe, chest, option, maxslot)
    local ingredients_n <const> = #recipe.ingredients//4 - 1
    local results_n <const> = #recipe.results//4 - 1
    local hash = {}
    local olditems = {}
    local newitems = {}
    if chest.chest ~= InvalidChest then
        for i = 1, 256 do
            local slot = cChest.get(world._cworld, chest.chest, i)
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
        local v = olditems[i]
        if #newitems > maxslot + ingredients_n then
            iBackpack.place(world, v.item, v.amount)
        else
            if v and v.type == "red" then
                create_slot(v.type, v.item, v.amount)
            end
        end
    end
    return newitems
end

local function assembling_set(world, e, recipe, option, maxslot)
    local chest = e.chest
    option = option or {
        ingredientsLimit = 2,
        resultsLimit = 2,
    }
    local items = assembling_reset_items(world, recipe, chest, option, maxslot)
    if chest.chest ~= InvalidChest then
        chest_destroy(world, chest, false)
    end
    chest.chest = m.create(world, items)
    iBuilding.dirty(world, "hub")
end

function m.assembling_set(world, e, recipe, option, maxslot)
    if recipe == nil then
        chest_reset(world, e, e.chest)
        return
    end
    assembling_set(world, e, recipe, option, maxslot)
end

local function chest_set(world, e, chest, item, type, limit)
    if chest.chest == InvalidChest then
        chest.chest = m.create(world, {{
            type = type,
            item = item,
            limit = limit,
            amount = 0,
        }})
        chest_dirty(world, e)
        return
    end
    local slot = cChest.get(world._cworld, chest.chest, 1)
    assert(slot)
    if slot.item == item then
        if slot.limit ~= limit then
            cChest.set(world._cworld, chest.chest, 1, {
                limit = limit,
            })
        end
        return
    end
    cChest.set(world._cworld, chest.chest, 1, {
        item = item,
        limit = limit,
        amount = 0,
    })
    chest_dirty(world, e)
end

function m.station_set(world, e, item)
    if item == nil then
        chest_reset(world, e, e.chest)
        return
    end
    local limit = prototype.queryById(item).stack
    chest_set(world, e, e.chest, item, e.station_producer and "blue" or "red", limit)
end

function m.hub_set(world, e, item)
    if item == nil then
        chest_reset(world, e, e.hub)
        return
    end
    local limit = prototype.queryById(item).pile & 0xffffff
    chest_set(world, e, e.hub, item, "blue", limit)
end

function m.get(world, c, i)
    return cChest.get(world._cworld, c.chest, i)
end
function m.set(world, c, i, t)
    return cChest.set(world._cworld, c.chest, i, t)
end

return m
