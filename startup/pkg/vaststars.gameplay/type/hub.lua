local type = require "register.type"
local prototype = require "prototype"
local iHub = require "interface.hub"

local InvalidChest <const> = 0

local c = type "hub"
    .supply_area "size"

function c:ctor(init, pt)
    local world = self
    local e = {
        hub = {
            id = 0,
            chest = InvalidChest
        }
    }
    local maxslot = 0
    for _, d in ipairs(pt.drone) do
        local name, slot = d[1], d[2]
        assert(slot > 0)
        maxslot = math.max(maxslot, slot)
        world:create_entity(name) {
            x = init.x,
            y = init.y,
            slot = slot - 1,
        }
    end
    if maxslot > 0 then
        local items = {}
        if init.items ~= nil then
            for i = 1, maxslot do
                if init.items[i] == nil or init.items[i] == "" then
                    items[i] = 0
                else
                    local item_prototype = assert(prototype.queryByName(init.items[i]), "Invalid item: " .. init.items[i])
                    items[i] = item_prototype.id
                end
            end
        elseif init.item == nil then
            for i = 1, maxslot do
                items[i] = 0
            end
        else
            local item_prototype = assert(prototype.queryByName(init.item), "Invalid item: " .. init.item)
            for i = 1, maxslot do
                items[i] = item_prototype.id
            end
        end
        iHub.set_item(world, e, items)
    end
    return e
end
