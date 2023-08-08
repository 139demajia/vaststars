local ecs = ...
local world = ecs.world
local w = world.w

local ipower_check = ecs.interface "ipower_check"
local power_check_sys = ecs.system "power_check_system"
local gameplay_core = require "gameplay.core"

local mt = {}
mt.__index = function (t, k)
    return rawget(t, k) or 0
end
local counter = setmetatable({}, mt)

function power_check_sys:gameworld_prebuild()
    local gameplay_world = gameplay_core.get_world()
    for e in gameplay_world.ecs:select "REMOVED consumer:in eid:in" do
        counter[e.eid] = nil
    end
end

function power_check_sys:gameworld_update()
    local gameplay_world = gameplay_core.get_world()
    local now = gameplay_world:now()

    if now % 60 == 0 then
        for e in gameplay_world.ecs:select "consumer:in eid:in power_check?update" do
            e.power_check = true
        end
    end

    if now % 2 == 0 then
        for e in gameplay_world.ecs:select "power_check:update eid:in capacitance:in" do
            if e.capacitance.delta < 0 then
                e.power_check = false
                counter[e.eid] = nil
            elseif e.capacitance.delta == 0 then
                counter[e.eid] = counter[e.eid] + 1
            else
                assert(false)
            end
        end
    end
end

function ipower_check.is_powered_on(eid)
    return counter[eid] < 15
end
