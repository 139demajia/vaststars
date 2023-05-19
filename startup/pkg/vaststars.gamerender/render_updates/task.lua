local ecs = ...
local world = ecs.world
local w = world.w

local itask = ecs.require "task"
local interval_call = ecs.require "engine.interval_call"
local task_sys = ecs.system "task_system"

local update = interval_call(300, function()
    itask.update_progress("lorry_count")
    itask.update_progress("auto_complete_task")
end)

function task_sys:update_world()
    update()
end