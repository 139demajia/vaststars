local ecs, mailbox = ...
local world = ecs.world

local iui = ecs.import.interface "vaststars.gamerender|iui"

local start_mode_mb = mailbox:sub {"start_mode"}
local load_resources_mb = mailbox:sub {"load_resources"}
local load_archive_mb = mailbox:sub {"load_archive"}
local continue_mb = mailbox:sub {"continue"}
local reboot_mb = mailbox:sub {"reboot"}
local load_template_mb = mailbox:sub {"load_template"}
local new_game = ecs.require "main_menu_manager".new_game
local continue_game = ecs.require "main_menu_manager".continue_game
local debugger <const> = require "debugger"
local saveload = ecs.require "saveload"
---------------
local M = {}
function M:create()
    return {
        show_continue_game = #saveload:get_archival_list() > 0
    }
end

function M:stage_camera_usage(datamodel)
    for _ in continue_mb:unpack() do
        iui.close("login.rml")
        continue_game()
    end

    for _, _, _, mode in start_mode_mb:unpack() do
        debugger.set_free_mode(mode == "free")
        iui.close("login.rml")
        new_game(mode)
    end
    
    for _ in reboot_mb:unpack() do
        local window = import_package "ant.window"
        window.reboot {
            import = {
                "@vaststars.gamerender"
            },
            pipeline = {
                "init",
                "update",
                "exit",
            },
            system = {
                "vaststars.gamerender|init_system",
            },
            interface = {
                "ant.objcontroller|iobj_motion",
            },
            policy = {
                "ant.general|name",
                "ant.scene|scene_object",
                "ant.render|render",
                "ant.render|render_queue",
                "ant.objcontroller|pickup",
            }
        }
    end

    for _ in load_resources_mb:unpack() do
        iui.open({"loading.rml"})
    end

    for _ in load_archive_mb:unpack() do
        iui.close("login.rml")
        iui.open({"option_pop.rml"})
    end

    for _ in load_template_mb:unpack() do
        iui.close("login.rml")
        iui.open({"template.rml"})
    end
end

return M