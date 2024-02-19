
local ecs = ...
local world = ecs.world
local w = world.w

local CONSTANT = require "gameplay.interface.constant"
local ROTATORS = CONSTANT.ROTATORS
local MATERIAL <const> = "/pkg/vaststars.resources/materials/dotted_line.material"

local math3d = require "math3d"
local DELTA_VEC <const> = {
    ['N'] = math3d.constant("v4", {0, 0, -5}),
    ['E'] = math3d.constant("v4", {-5, 0, 0}),
    ['S'] = math3d.constant("v4", {0, 0, 5}),
    ['W'] = math3d.constant("v4", {5, 0, 0}),
}

local ientity = ecs.require "ant.entity|entity"
local iom = ecs.require "ant.objcontroller|obj_motion"

local M = {}
function M.create(position, quad_num, dir)
    local ids = {}
    local eid = ientity.create_quad_lines_entity({}, MATERIAL, 10, 10.0, false, "translucent")

    ids[#ids+1] = eid
    ids[#ids+1] = world:create_entity {
        policy = {},
        data = {
            on_ready = function ()
                local e <close> = world:entity(eid, "render_object:update")
                local ro = e.render_object
                ro.ib_start, ro.ib_num = 0, 0 -- *6
                ro.vb_start, ro.vb_num = 0, 0 -- *4
                ro.ib_num = quad_num * 6
                ro.vb_num = quad_num * 4
                iom.set_position(e, math3d.add(position, DELTA_VEC[dir]))
                iom.set_rotation(e, ROTATORS[dir])
            end
        }
    }

    return {
        remove = function()
            for _, id in ipairs(ids) do
                world:remove_entity(id)
            end
        end
    }
end
return M
