local ecs, mailbox = ...
local world = ecs.world

local iui = ecs.require "engine.system.ui_system"

local new_game_mb = mailbox:sub {"new_game"}
local load_resources_mb = mailbox:sub {"load_resources"}
local restore_mb = mailbox:sub {"restore"}
local continue_mb = mailbox:sub {"continue"}
local load_template_mb = mailbox:sub {"load_template"}
local load_tutorial_template_mb = mailbox:sub {"load_tutorial_template"}
local archiving = require "archiving"
local window = import_package "ant.window"
local global = require "global"

---------------
local M = {}
function M.create()
    return {
        show_continue_game = (#archiving.list() > 0),
    }
end

function M.update(datamodel)
    for _ in continue_mb:unpack() do
        local list = archiving.list()
        global.startup_args = {"restore", assert(list[#list])}
        window.reboot {
            feature = {"vaststars.gamerender|gameplay"},
        }
    end

    for _, _, _, template in new_game_mb:unpack() do
        global.startup_args = {"new_game", template}
        window.reboot {
            feature = {"vaststars.gamerender|gameplay"},
        }
    end

    for _ in load_resources_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/loading.rml"})
    end

    for _ in restore_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/option_pop.rml"})
    end

    for _ in load_template_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/template.rml"}, function(s) return not s:match("^tutorial.*$") end)
    end

    for _ in load_tutorial_template_mb:unpack() do
        iui.open({rml = "/pkg/vaststars.resources/ui/tutorial_list.rml"}, function(s) return s:match("^tutorial.*$") end)
    end
end

return M