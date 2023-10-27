
local ecs = ...
local world = ecs.world
local w = world.w

local CONSTANT = require "gameplay.interface.constant"
local ROTATORS = CONSTANT.ROTATORS

local ientity = ecs.require "ant.render|components.entity"
local iom = ecs.require "ant.objcontroller|obj_motion"
local math3d = require "math3d"
local ivs = ecs.require "ant.render|visible_state"

local delta_vec = {
    ['N'] = math3d.constant("v4", {0, 0, -5}),
    ['E'] = math3d.constant("v4", {-5, 0, 0}),
    ['S'] = math3d.constant("v4", {0, 0, 5}),
    ['W'] = math3d.constant("v4", {5, 0, 0}),
}

local M = {}
function M.create(material, position, quad_num, dir, b)
    local eid = ientity.create_quad_lines_entity({}, material, 10, 10.0, false, "translucent")
    local ready = false
    world:create_entity {
        policy = {},
        data = {
            on_ready = function ()
                ready = true
                local e <close> = world:entity(eid, "render_object:update")
                local ro = e.render_object
                ro.ib_start, ro.ib_num = 0, 0 -- *6
                ro.vb_start, ro.vb_num = 0, 0 -- *4
                if position then
                    ro.ib_num = quad_num * 6
                    ro.vb_num = quad_num * 4
                    ivs.set_state(e, "main_view", b)
                    iom.set_position(e, math3d.add(position, delta_vec[dir]))
                    iom.set_rotation(e, ROTATORS[dir])
                end
            end
        }
    }
    local outer = {}
    function outer:show(b)
        if not ready then
            return
        end
        local e <close> = world:entity(eid)
        ivs.set_state(e, "main_view", b)
    end
    function outer:update(position, quad_num, dir)
        if not ready then
            return
        end
        local e <close> = world:entity(eid, "render_object:update")
        iom.set_position(e, math3d.add(position, delta_vec[dir]))
        local ro = e.render_object
        ro.ib_num = quad_num * 6
        ro.vb_num = quad_num * 4
        iom.set_rotation(e, ROTATORS[dir])
    end
    function outer:remove()
        world:remove_entity(eid)
    end
    return outer
end
return M