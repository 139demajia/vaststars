local spec = require "lua.building_menu_spec"

local TRANSFORM_DELTA <const> = 18
local LINE_MARGIN_RIGHT_DELTA <const> = -2
local LINE_TRANSFORM_DELTA <const> = -5
local BUILDING_MENU_POSITIONS = {}
for i = 1, 5 do
    BUILDING_MENU_POSITIONS[i] = {
        outer_transform = ("rotate(%sdeg)"):format(-TRANSFORM_DELTA * (i - 1)),
        inner_transform = ("rotate(%sdeg)"):format(TRANSFORM_DELTA * (i - 1)),
        line_margin_right = ("%svmin"):format(LINE_MARGIN_RIGHT_DELTA * (i - 1)),
        line_transform = ("rotate(%sdeg)"):format(LINE_TRANSFORM_DELTA * (i - 1))
    }
end

local DEFAULT_OFFSETS = {
    [1] = {
        [1] = BUILDING_MENU_POSITIONS[3],
    },
    [2] = {
        [1] = BUILDING_MENU_POSITIONS[2],
        [2] = BUILDING_MENU_POSITIONS[4],
    },
    [3] = {
        [1] = BUILDING_MENU_POSITIONS[2],
        [2] = BUILDING_MENU_POSITIONS[3],
        [3] = BUILDING_MENU_POSITIONS[4],
    },
    [4] = {
        [1] = BUILDING_MENU_POSITIONS[2],
        [2] = BUILDING_MENU_POSITIONS[3],
        [3] = BUILDING_MENU_POSITIONS[4],
        [4] = BUILDING_MENU_POSITIONS[5],
    },
    [5] = {
        [1] = BUILDING_MENU_POSITIONS[1],
        [2] = BUILDING_MENU_POSITIONS[2],
        [3] = BUILDING_MENU_POSITIONS[3],
        [4] = BUILDING_MENU_POSITIONS[4],
        [5] = BUILDING_MENU_POSITIONS[5],
    }
}

local DEFAULT_MT <const> = {__index = {
    command = " ",
    number = -1,
    show_number = false,
    show_background = false,
    disabled = false,
    selected = false,
}}

local function show_buttons(start)
    -- console.log("#start.buttons", #start.buttons)
    if #start.buttons > 0 then
        local def = DEFAULT_OFFSETS[#start.buttons]
        assert(def, ("(%s) - (%s)"):format(start.prototype_name, #start.buttons))
        for i = 1, #start.buttons do
            for k, v in pairs(def[i]) do
                start.buttons[i][k] = v
            end
        end
    end
    start("buttons")
end

local function test(start, count)
    local buttons = {
        [1] = {
            background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-transfer-source.texture",
            command = "test",
        },
        [2] = {
            background_image = "/pkg/vaststars.resources/ui/textures/building-menu/transfer.texture",
            command = "test",
        },
        [3] = {
            background_image = "/pkg/vaststars.resources/ui/textures/building-menu/teardown.texture",
            command = "test",
        }, 
        [4] = {
            background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture",
            command = "test",
        },
        [5] = {
            background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture",
            command = "test",
        },
    }

    for i = 1, count do
        start.buttons[i] = buttons[i]
    end
    show_buttons(start)
end

return function(start)
    -- if test then
    --     return test(start, 5)
    -- end

    if spec[start.prototype_name] then
        spec[start.prototype_name](start, DEFAULT_OFFSETS, DEFAULT_MT)
        return
    end

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

    if start.remove_lorry then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "remove_lorry"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/remove-lorry.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.move then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "move"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/move.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.lorry_factory_inc_lorry then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "lorry_factory_inc_lorry"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/lorry-factory-inc-lorry.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.set_item then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_item"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-item.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.set_recipe then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "set_recipe"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-recipe.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.copy then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "copy"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/clone.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.inventory then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "inventory"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/set-recipe.texture"
        start.buttons[#start.buttons + 1] = v
    end

    if start.transfer then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "transfer"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/transfer.texture"
        v.number = start.transfer_count
        v.show_number = true
        start.buttons[#start.buttons + 1] = v
    end

    if start.teardown then
        local v = setmetatable({}, DEFAULT_MT)
        v.command = "teardown"
        v.background_image = "/pkg/vaststars.resources/ui/textures/building-menu/teardown.texture"
        start.buttons[#start.buttons + 1] = v
    end

    show_buttons(start)
end