local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local objects = require "objects"
local gameplay_core = require "gameplay.core"
local iprototype = require "gameplay.interface.prototype"
local ichest = require "gameplay.interface.chest"
local item_category = import_package "vaststars.prototype"("item_category")
local click_category_mb = mailbox:sub {"click_category"}
local set_item_mb = mailbox:sub {"set_item"}
local gameplay = import_package "vaststars.gameplay"
local ihub = gameplay.interface "hub"

local cache = {} -- item_index -> item
local index_cache = {} -- item_id -> item_index
local category_cache = {} -- category_index -> category
local category_index_cache = {} -- item_id -> category_index
local items_cache = {} -- category_index -> items

do
    for _, typeobject in pairs(iprototype.each_maintype("item")) do
        -- "任务" is a special item that is not subject to any checks.
        if typeobject.name == "任务" then
            goto continue
        end

        -- If the 'pile' field is not configured, it is usually a 'building' that cannot be placed in a drone depot.
        if not typeobject.pile then
            goto continue
        end

        local item = {
            id = typeobject.id,
            name = typeobject.name,
            icon = typeobject.icon,
            category = assert(typeobject.group[1]),
            desc = typeobject.item_description,
        }

        cache[#cache+1] = item
        ::continue::
    end
end

do
    local category_name_to_index = {}
    category_cache = item_category

    for index, v in ipairs(category_cache) do
        category_name_to_index[v.category] = index
    end

    for _, item in pairs(cache) do
        category_index_cache[item.id] = assert(category_name_to_index[item.category])
    end
end

do
    for category_index, v in ipairs(category_cache) do
        local items = {}
        for _, item in pairs(cache) do
            if item.category == v.category or v.category == "全部" then
                table.insert(items, item)
            end
        end
        table.sort(items, function(a, b)
            return a.name < b.name
        end)
        items_cache[category_index] = items

        for index, item in ipairs(items) do
            index_cache[item.id] = index
        end
    end
end

local function __get_categories()
    return category_cache
end

local function __get_category_index(item_id)
  return assert(category_index_cache[item_id])
end

local function __get_item_index(item_id)
  return index_cache[item_id]
end

local function __get_items(category_index)
    return items_cache[category_index]
end

local function __get_default_item_indexes()
    local res = {}
    for index, v in ipairs(category_cache) do
        res[index] = 1
    end
    return res
end

local function __get_hub_item(e)
    local slot = ichest.chest_get(gameplay_core.get_world(), e.hub, 1)
    if slot then
        return slot.item
    end
end

---------------
local M = {}

function M:create(object_id)
    local object = assert(objects:get(object_id))
    local e = gameplay_core.get_entity(assert(object.gameplay_eid))
    if not e then
        return
    end
    local item = __get_hub_item(e)
    local category_index, item_indexes
    item_indexes = __get_default_item_indexes()
    if item then
        category_index = __get_category_index(item)
        item_indexes[category_index] = __get_item_index(item)
    else
        category_index = 1
    end


    local datamodel = {
        categories = __get_categories(),
        category_index = category_index,
        items = __get_items(category_index),
        item_indexes = item_indexes,
    }
    return datamodel
end

function M:stage_ui_update(datamodel, object_id)
    for _, _, _, catalog_index in click_category_mb:unpack() do
        datamodel.category_index = catalog_index
        datamodel.items = __get_items(catalog_index)
    end

    for _, _, _, item_index in set_item_mb:unpack() do
        local item = items_cache[datamodel.category_index][item_index]
        local e = gameplay_core.get_entity(assert(objects:get(object_id).gameplay_eid))
        local gameplay_world = gameplay_core.get_world()
        ihub.set_item(gameplay_world, e, item.name)
        gameplay_core.get_world():build()
    end
end

return M