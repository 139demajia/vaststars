local ecs, mailbox = ...
local world = ecs.world

local iui = ecs.import.interface "vaststars.gamerender|iui"
local gameplay_core = require "gameplay.core"
local click_button_mb = mailbox:sub {"click_button"}
local click_main_button_mb = mailbox:sub {"click_main_button"}

local MAX_SHORTCUT_COUNT <const> = 5
local iprototype = require "gameplay.interface.prototype"

local function __default_shortcut()
    return {prototype_name = "", icon = "", last_timestamp = 0, selected = false, unknown = true}
end

local function __update_shortcur_timestamp(index)
    local storage = gameplay_core.get_storage()
    storage.shortcut[index] = storage.shortcut[index] or __default_shortcut()
    storage.shortcut[index].last_timestamp = os.time()
end

local M = {}

function M:create()
    local storage = gameplay_core.get_storage()
    storage.shortcut = storage.shortcut or {}

    local main_button_icon = ""
    local shortcut = {}

    local min_idx = 1
    local first_unknown_idx
    local min_timestamp = math.maxinteger

    for i = 1, MAX_SHORTCUT_COUNT do
        local s = storage.shortcut[i]
        if not s or (s and s.prototype_name == "") or (s and s.prototype_name == nil) then
            shortcut[i] = __default_shortcut()
            if not first_unknown_idx then
                first_unknown_idx = i
            end
        else
            local typeobject = iprototype.queryByName(s.prototype_name)
            shortcut[i] = {prototype_name = s.prototype_name, icon = typeobject.item_icon, last_timestamp = s.last_timestamp or 0, selected = false, unknown = false}
        end

        if shortcut[i].last_timestamp < min_timestamp then
            min_timestamp = shortcut[i].last_timestamp
            min_idx = i
        end
    end
    if first_unknown_idx then
        shortcut[first_unknown_idx].unknown = true
    else
        shortcut[min_idx].unknown = true
    end

    -- select the last used building
    local max_idx
    local max_timestamp = math.mininteger
    for i = 1, MAX_SHORTCUT_COUNT do
        if shortcut[i].prototype_name ~= "" and shortcut[i].last_timestamp > max_timestamp then
            max_timestamp = shortcut[i].last_timestamp
            max_idx = i
        end
    end

    if max_idx then
        shortcut[max_idx].selected = true
        __update_shortcur_timestamp(max_idx)
        iui.redirect("ui/construct.rml", "construct_entity", shortcut[max_idx].prototype_name)

        main_button_icon = shortcut[max_idx].icon
    end

    return {
        shortcut_index = max_idx or 0,
        shortcut = shortcut,
        main_button_icon = main_button_icon,
    }
end

function M:stage_ui_update(datamodel)
    for _, _, _, index in click_button_mb:unpack() do
        local shortcut = assert(datamodel.shortcut[index])
        if shortcut.unknown == true then
            iui.close("ui/build.rml")
            iui.open({"ui/build_setting.rml"})
        else
            if datamodel.shortcut_index ~= 0 then
                datamodel.shortcut[datamodel.shortcut_index].selected = false
            end

            datamodel.shortcut_index = index
            datamodel.shortcut[index].selected = true
            __update_shortcur_timestamp(index)

            iui.redirect("ui/construct.rml", "construct_entity", datamodel.shortcut[index].prototype_name)
            datamodel.main_button_icon = datamodel.shortcut[index].icon
        end
    end

    for _ in click_main_button_mb:unpack() do
        iui.redirect("ui/construct.rml", "build")
    end
end

return M