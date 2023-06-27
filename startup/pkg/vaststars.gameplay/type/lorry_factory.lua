local type = require "register.type"
local prototype = require "prototype"

local c = type "lorry_factory"
    .starting "position"
    .road "network"

function c:ctor(init, pt)
    local world = self
    local typeobject = prototype.queryByName(pt.item)
    local chest = world:container_create {{
        type = "red",
        item = typeobject.id,
        amount = 0,
        limit = typeobject.stack,
    }}
    return {
        lorry_factory = true,
        chest = {
            chest = chest,
        },
        starting = {
            neighbor = 0xffff,
        },
    }
end
