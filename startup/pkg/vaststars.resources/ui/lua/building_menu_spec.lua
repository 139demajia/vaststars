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
        v.number = start.pickup_item_count
        v.show_number = true
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/pickup-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start, offsets)
end

return t