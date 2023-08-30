local ecs = ...
local world = ecs.world

local ims = ecs.require "ant.motion_sampler|motion_sampler"
local ientity_object = ecs.require "engine.system.entity_object_system"

local events = {
    ["motion"] = function(_, e, method, ...)
        ims[method](e, ...)
    end
}

local motion = {}
function motion.create_motion_object(s, r, t, parent, ev)
    if not motion.sampler_group then
        local sampler_group = ims.sampler_group()
        world:group_enable_tag("view_visible", sampler_group)
        world:group_flush "view_visible"
        motion.sampler_group = sampler_group
    end
    local m_eid = world:create_entity {
        group = motion.sampler_group,
        policy = {
            "ant.scene|scene_object",
            "ant.motion_sampler|motion_sampler",
            "ant.general|name",
        },
        data = {
            scene = {
                parent = parent,
                s = s,
                r = r,
                t = t,
            },
            motion_sampler = {},
            name = "motion_sampler",
        }
    }
    return ev and ientity_object.create(m_eid, events) or m_eid
end
return motion