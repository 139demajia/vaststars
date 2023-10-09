local ecs, mailbox = ...
local world = ecs.world

local statistical_data_mb = mailbox:sub {"statistical_data"}
local game_settings_mb = mailbox:sub {"game_settings"}
local quit_mb = mailbox:sub {"quit"}

local iui = ecs.require "engine.system.ui_system"
local gameplay_core = require "gameplay.core"

local M = {}
function M.create()
    return {}
end

function M.stage_camera_usage(datamodel)
    for _ in statistical_data_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/statistics.rml"})
    end

    for _ in game_settings_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/option_pop.rml"})
    end

    for _ in quit_mb:unpack() do
        gameplay_core.world_update = true
        iui.close("/pkg/vaststars.resources/ui/main_menu.rml")
    end
end

return M