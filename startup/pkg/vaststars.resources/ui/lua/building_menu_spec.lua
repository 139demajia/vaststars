local t = {}

local function set_button_offset(start, offsets)
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

t["采矿机I"] = function(start, offsets, DEFAULT_MT) --采矿建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["采矿机II"] = function(start, offsets, DEFAULT_MT) --采矿建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["采矿机III"] = function(start, offsets, DEFAULT_MT) --采矿建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["机身残骸"] = function(start, offsets, DEFAULT_MT) --废墟建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["机翼残骸"] = function(start, offsets, DEFAULT_MT) --废墟建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["机头残骸"] = function(start, offsets, DEFAULT_MT) --废墟建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["机尾残骸"] = function(start, offsets, DEFAULT_MT) --废墟建筑仅保留获取
    start.buttons = {}
    if start.set_transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer_source then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer_source"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture"
        v.selected = true
        start.buttons[#start.buttons + 1] = v
    end

    set_button_offset(start, offsets)
end

t["空气过滤器I"] = function(start, offsets, DEFAULT_MT) --液体输入/输出建筑仅保留移动和复制
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    set_button_offset(start, offsets)
end

t["空气过滤器II"] = function(start, offsets, DEFAULT_MT) --液体输入/输出建筑仅保留移动和复制
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    set_button_offset(start, offsets)
end

t["空气过滤器III"] = function(start, offsets, DEFAULT_MT) --液体输入/输出建筑仅保留移动和复制
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    set_button_offset(start, offsets)
end

t["地下水挖掘机I"] = function(start, offsets, DEFAULT_MT) --液体输入/输出建筑仅保留移动和复制
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    set_button_offset(start, offsets)
end

t["地下水挖掘机II"] = function(start, offsets, DEFAULT_MT)   --液体输入/输出建筑仅保留移动和复制
    start.buttons = {}
    if start.move then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end
    set_button_offset(start, offsets)
end


return t