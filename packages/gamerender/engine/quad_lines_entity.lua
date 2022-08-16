
local ecs = ...
local world = ecs.world
local w = world.w

local ientity_object = ecs.import.interface "vaststars.gamerender|ientity_object"
local ientity = ecs.import.interface "ant.render|ientity"
local constant = require "gameplay.interface.constant"
local ROTATORS = constant.ROTATORS
local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
local math3d = require "math3d"
local ivs = ecs.import.interface "ant.scene|ivisible_state"

local delta_vec = {
    ['N'] = math3d.constant("v4", {0, 0, -5}),
    ['E'] = math3d.constant("v4", {-5, 0, 0}),
    ['S'] = math3d.constant("v4", {0, 0, 5}),
    ['W'] = math3d.constant("v4", {5, 0, 0}),
}

local events = {}
events["init"] = function(_, e)
    w:extend(e, "render_object:in")
    local ro = e.render_object
    ro.ib_start, ro.ib_num = 0, 0 -- *6
    ro.vb_start, ro.vb_num = 0, 0 -- *4
end

events["update"] = function(_, e, position, quad_num, dir)
    iom.set_position(e, math3d.add(position, delta_vec[dir]))
    w:extend(e, "render_object:in")
    local ro = e.render_object
    ro.ib_num = quad_num * 6
    ro.vb_num = quad_num * 4

    iom.set_rotation(e, ROTATORS[dir])
end

events["show"] = function(_, e, b)
    ivs.set_state(e, "main_view", b)
end

local M = {}
function M.create(material)
    local entity_object = ientity_object.create(ientity.create_quad_lines_entity("quads", {}, material, 10, 10.0, false), events)
    entity_object:send("init")

    local outer = {}
    function outer:show(b)
        entity_object:send("show", b)
    end
    function outer:update(position, len, dir)
        entity_object:send("update", position, len, dir)
    end
    function outer:remove()
        entity_object:remove()
    end

    return outer
end
return M