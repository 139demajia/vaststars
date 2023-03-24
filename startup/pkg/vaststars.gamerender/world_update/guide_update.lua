local ecs = ...
local world = ecs.world
local w = world.w

local global = require "global"
local iui = ecs.import.interface "vaststars.gamerender|iui"
local iguide = require "gameplay.interface.guide"

local function update_world(world)
    local science = global.science
    if not iguide.is_running() or iguide.is_in_guide() or science.current_tech then
        return
    end
    local guide = iguide.get_guide()
    if not guide then
        return
    end
    local prerequisites = guide.prerequisites
    local run_guide = true
    if prerequisites then
        for _, value in ipairs(prerequisites) do
            if not world:is_researched(value) then
                run_guide = false
            end
        end
    end
    if run_guide then
        -- hide pop ui
        iui.close("detail_panel.rml")
        iui.close("build_function_pop.rml")
        iui.close("assemble.rml")
        iui.close("chest.rml")
        iui.close("lab.rml")
        -- pop guide ui
        iui.open({"guide_pop.rml"}, guide)
        iguide.set_is_in_guide(true)
    end
end
return update_world