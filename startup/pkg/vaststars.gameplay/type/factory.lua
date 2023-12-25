local type = require "register.type"
local prototype = require "prototype"
local iChest = require "interface.chest"

local c = type "factory"
    .starting "position"
    .road "network"
    .check_area "size"
    .lorry_track "lorry_track"

function c:ctor(init, pt)
    local world = self
    local typeobject = prototype.queryByName(pt.lorry)
    local chest = iChest.create(world, {{
        type = "supply",
        item = typeobject.id,
        amount = init.amount,
        limit = typeobject.station_limit,
    }})
    return {
        factory = true,
        chest = {
            chest = chest,
        },
        starting = {
            neighbor = 0xffff,
        },
    }
end
