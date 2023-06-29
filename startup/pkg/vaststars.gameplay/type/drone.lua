local type = require "register.type"

local c = type "drone"

function c:ctor(init, pt)
    local home = (init.x << 8) | init.y
    return {
        drone = {
            prototype = pt.id,
            prev = home,
            next = 0,
            mov2 = 0,
            home = 0,
            maxprogress = 0,
            progress = 0,
            item = 0,
            home_item = 0,
            status = 0,
        }
    }
end
