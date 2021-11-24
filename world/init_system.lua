local ecs = ...
local world = ecs.world
local m = ecs.system 'init_system'
local irq = ecs.import.interface "ant.render|irenderqueue"

function m:init_world()
    irq.set_view_clear_color("main_queue", 0xff0000ff)
    ecs.create_instance "/res/light_directional.prefab"
    ecs.create_instance "/res/skybox.prefab"

    local camera = ecs.require "camera"
    world:call(camera.root, "set_position", {1, 1, 1})
    camera:send "hello"
end
