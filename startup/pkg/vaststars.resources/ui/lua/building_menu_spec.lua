local t = {}

local function show_buttons(start, offsets)
    -- console.log("#start.buttons", #start.buttons)
    if #start.buttons > 0 then
        local def = offsets[#start.buttons]
        assert(def, ("(%s) - (%s)"):format(start.prototype_name, #start.buttons))
        for i = 1, #start.buttons do
            for k, v in pairs(def[i]) do
                start.buttons[i][k] = v
            end
        end
    end
    start("buttons")
end

t["采矿机I"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["采矿机II"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["采矿机III"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["机身残骸"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["机翼残骸"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["机头残骸"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["机尾残骸"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.pickup_item then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "pickup_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

t["空气过滤器I"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    show_buttons(start, offsets)
end

t["空气过滤器II"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    show_buttons(start, offsets)
end

t["空气过滤器III"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    show_buttons(start, offsets)
end

t["地下水挖掘机I"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    show_buttons(start, offsets)
end

t["地下水挖掘机II"] = function(start, offsets, DEFAULT)
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, {__index = DEFAULT})
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu-longpress/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    show_buttons(start, offsets)
end


return t