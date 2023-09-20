local ecs = ...
local world = ecs.world

local math3d = require "math3d"
local ientity = ecs.require "ant.render|components.entity"
local imesh = ecs.require "ant.asset|mesh"
local ivs = ecs.require "ant.render|visible_state"
local imaterial = ecs.require "ant.asset|material"
local ientity_object = ecs.require "engine.system.entity_object_system"
local iom = ecs.require "ant.objcontroller|obj_motion"
local MATH3D_NULL <const> = math3d.constant "null"

local gen_id do
    local id = 0
    function gen_id()
        id = id + 1
        return id
    end
end

local plane_vb <const> = {
	-0.5, 0,  0.5, 0, 1, 0,	--left top
	0.5,  0,  0.5, 0, 1, 0,	--right top
	-0.5, 0, -0.5, 0, 1, 0,	--left bottom
	-0.5, 0, -0.5, 0, 1, 0,
	0.5,  0,  0.5, 0, 1, 0,
	0.5,  0, -0.5, 0, 1, 0,	--right bottom
}

local entity_events = {}
entity_events["obj_motion"] = function(_, e, method, ...)
    iom[method](e, ...)
end
entity_events["material"] = function(_, e, method, ...)
    imaterial[method](e, ...)
end
entity_events["set_color"] = function(_, e, color)
	imaterial.set_property(e, "u_color", color)
end

local function create(material, property, color, srt, render_layer)
	assert(color and color ~= MATH3D_NULL)
    local eid = world:create_entity {
		policy = {
			"ant.render|simplerender",
		},
		data = {
			scene = { s = srt.s, r = srt.r, t = srt.t },
			material = material,
			visible_state = "main_view",
			render_layer = render_layer or "translucent",
			simplemesh = imesh.init_mesh(ientity.create_mesh({"p3|n3", plane_vb}, nil, math3d.live(math3d.aabb({-0.5, 0, -0.5}, {0.5, 0, 0.5}))), true),
			on_ready = function (e)
                imaterial.set_property(e, property, color)
			end
		},
	}

    return ientity_object.create(eid, entity_events)
end
return {
    create = create,
}