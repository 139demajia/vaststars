local ecs = ...
local world = ecs.world

local FRAMES_PER_SECOND <const> = 30
local bgfx = require 'bgfx'
local gameplay_core = require "gameplay.core"
local icamera_controller = ecs.require "engine.system.camera_controller"
local audio = import_package "ant.audio"
local rhwi = import_package "ant.hwi"
local font = import_package "ant.font"
local iom = ecs.require "ant.objcontroller|obj_motion"
local iani = ecs.require "ant.animation|controller.state_machine"
local iui = ecs.require "engine.system.ui_system"
local NOTHING <const> = require "debugger".nothing
local TERRAIN_ONLY <const> = require "debugger".terrain_only

local m = ecs.system 'init_system'

bgfx.maxfps(FRAMES_PER_SECOND)
font.import "/pkg/vaststars.resources/ui/font/Alibaba-PuHuiTi-Regular.ttf"

local function createPrefabInst(prefab)
    world:create_instance {
        prefab = prefab,
        on_ready = function (self)
            local root <close> = world:entity(self.tag['*'][1])
            iom.set_position(root, {0, 0, 0})
            for _, eid in ipairs(self.tag['*']) do
                local e <close> = world:entity(eid, "animation_birth?in")
                if e.animation_birth then
                    iani.play(self, {name = e.animation_birth, loop = true, speed = 1.0, manual = false})
                end
            end
        end
    }
end

function m:init_world()
    if NOTHING or TERRAIN_ONLY then
        ecs.require "main_menu_manager".new_game()
        return
    end

    world:create_instance {
        prefab = "/pkg/vaststars.resources/daynight.prefab",
    }
    world:create_instance {
        prefab = "/pkg/vaststars.resources/light.prefab",
    }
    rhwi.set_profie(gameplay_core.settings_get("debug", true))

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

    --
    icamera_controller.set_camera_from_prefab("camera_gamecover.prefab")
    createPrefabInst("/pkg/vaststars.resources/glbs/game-cover.glb|mesh.prefab")
    iui.open({"/pkg/vaststars.resources/ui/login.rml"})
end