local ecs = ...
local world = ecs.world
local w = world.w

local NOTHING <const> = require "debugger".nothing
local TERRAIN_ONLY <const> = require "debugger".terrain_only
local icamera_controller = ecs.require "engine.system.camera_controller"
local icanvas = ecs.require "engine.canvas"
local audio = import_package "ant.audio"
local rhwi = import_package "ant.hwi"
local gameplay_core = require "gameplay.core"
local iguide = require "gameplay.interface.guide"
local iui = ecs.require "engine.system.ui_system"
local terrain = ecs.require "terrain"
local iroadnet = ecs.require "roadnet"
local saveload = ecs.require "saveload"
local global = require "global"
local math3d = require "math3d"

local m = ecs.system 'game_init_system'
local gameworld_prebuild
local gameworld_build
local gameworld

function m:init_world()
    gameworld_prebuild = world:pipeline_func "gameworld_prebuild"
    gameworld_build = world:pipeline_func "gameworld_build"
    gameworld = world:pipeline_func "gameworld"

    world:create_instance {
        prefab = "/pkg/vaststars.resources/daynight.prefab"
    }
    world:create_instance {
        prefab = "/pkg/vaststars.resources/light.prefab"
    }
    world:create_instance {
        prefab = "/pkg/vaststars.resources/sky.prefab"
    }
    terrain:create()

    if NOTHING or TERRAIN_ONLY then
        icamera_controller.set_camera_from_prefab("camera_default.prefab")
        return
    end

    rhwi.set_profie(gameplay_core.settings_get("debug", true))

    icanvas.create(icanvas.types().ICON, gameplay_core.settings_get("info", true), 10)
    icanvas.create(icanvas.types().PICKUP_ICON, false, 10)
    icanvas.create(icanvas.types().ROAD_ENTRANCE_MARKER, false, 0.02)

    -- audio test (Master.strings.bank must be first)
    audio.load {
        "/pkg/vaststars.resources/sounds/Master.strings.bank",
        "/pkg/vaststars.resources/sounds/Master.bank",
        "/pkg/vaststars.resources/sounds/Building.bank",
        "/pkg/vaststars.resources/sounds/Function.bank",
        "/pkg/vaststars.resources/sounds/UI.bank",
    }

    -- audio.play("event:/openui1")
    audio.play("event:/background")

    iroadnet:create()

    local args = global.startup_args
    if args[1] == "new_game" then
        icamera_controller.set_camera_from_prefab("camera_default.prefab")
        local mode, game_template = args[2], args[3]
        saveload:restart(mode, game_template)
        iguide.world = gameplay_core.get_world()
        iui.set_guide_progress(iguide.get_progress())
    elseif args[1] == "continue_game" then
        local index = args[2]
        saveload:restore(index)
        iguide.world = gameplay_core.get_world()
        iui.set_guide_progress(iguide.get_progress())
    elseif args[1] == "load_game" then
        local index = args[2]
        saveload:restore(index)
        iguide.world = gameplay_core.get_world()
        iui.set_guide_progress(iguide.get_progress())
    else
        assert(false)
    end
    global.startup_args = {}
end

local TAGS <const> = {
    "building_new",
    "building_changed",
    "base_changed",
    "lorry_changed",
    "drone_changed",
}

function m:gameworld_end()
    local gameplay_ecs = gameplay_core.get_world().ecs
    for _, tag in ipairs(TAGS) do
        gameplay_ecs:clear(tag)
    end
end

function m:camera_usage()
    local mq = w:first "main_queue camera_ref:in"
    local ce = world:entity(mq.camera_ref, "camera_changed?in camera:in scene:in")
    if ce.camera_changed then
        local points = icamera_controller.get_interset_points()
        terrain:enable_terrain(points[2], math3d.set_index(points[3], 1, math3d.index(points[4], 1)))
    end
end

function m:frame_update()
    if NOTHING then
        return
    end

    if gameplay_core.system_changed_flags ~= 0 then
        print("build world")
        gameplay_core.system_changed_flags = 0
        gameworld_prebuild()
        gameplay_core.update()
        gameworld_build()
    else
        if gameplay_core.world_update then
            gameplay_core.update()
            gameworld()
        end
    end
end