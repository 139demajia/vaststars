local type = require "register.type"
local prototype = require "prototype"

local c = type "station_consumer"
    .chest_type "chest_type"
    .maxlorry "integer"
    .endpoint "position"

function c:ctor(init, pt)
    local world = self
    local item = 0
    local stack = 0
    if init.item then
        local typeobject = assert(prototype.queryByName(init.item), "Invalid item: " .. init.item)
        item = typeobject.id
        stack = typeobject.stack
    end
    local c = {}
    c[#c+1] = world:chest_slot {
        type = pt.chest_type,
        item = item,
        amount = 0,
        limit = stack,
    }
    local chest = world:container_create(table.concat(c))
    return {
        chest = {
            chest = chest,
        },
        station_consumer = {
            maxlorry = pt.maxlorry,
        },
        endpoint = {
            neighbor = 0xffff,
            rev_neighbor = 0xffff,
            lorry = 0,
        }
    }
end
