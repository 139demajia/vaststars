
local ecs = ...
local world = ecs.world
local w = world.w

local LINE_WIDTH <const> = 70
local COLOR <const> = {0.0, 1.0, 0.0, 0.4}
local MATERIAL <const> = "/pkg/vaststars.resources/materials/polylinelist.material"
local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER
local CONSTANT <const> = require "gameplay.interface.constant"
local ROAD_SIZE <const> = CONSTANT.ROAD_SIZE

local math3d = require "math3d"
local GRID_POSITION_OFFSET <const> = math3d.constant("v4", {0, 0.2, 0, 0.0})

local ipl = ecs.require "ant.polyline|polyline"
local iom = ecs.require "ant.objcontroller|obj_motion"
local ientity_object = ecs.require "engine.system.entity_object_system"
local icoord = require "coord"
local icamera_controller = ecs.require "engine.system.camera_controller"

local events = {}
events["remove"] = function(_, e)
	w:remove(e)
end
events["obj_motion"] = function(_, e, method, ...)
    iom[method](e, ...)
end

local M = {}
function M.create(width, height, unit, srt, pos_offset, material)
	local hw = width * 0.5
	local hw_len = hw * unit

	local hh = height * 0.5
	local hh_len = hh * unit

	local vertices = {}

	local function add_vertex(t, x, y, z)
		t[#t+1] = {x, y, z}
	end

	local function add_line(t, x0, z0, x1, z1)
		add_vertex(t, x0, 0, z0)
		add_vertex(t, x1, 0, z1)
	end

	for i=0, width do
        local x = -hw_len + i * unit
	    add_line(vertices, x, -hh_len, x, hh_len)
	end

	for i=0, height do
        local y = -hh_len + i * unit
      	add_line(vertices, -hw_len, y, hw_len, y)
	end

	if pos_offset then
		srt.t = math3d.add(srt.t, pos_offset)
	end

	local objects = {}
	objects[#objects+1] = ientity_object.create(ipl.add_linelist(vertices, LINE_WIDTH, COLOR, material or MATERIAL, srt, RENDER_LAYER.GRID), events)

	local outer_proxy = {
		objects = objects,
		remove = function(self)
			assert(#self.objects > 0)
			for _, obj in ipairs(self.objects) do
				obj:send("remove")
			end
			self.objects = {}
		end,
		on_position_change = function(self, srt)
			local coord = icoord.align(icamera_controller.get_central_position(), ROAD_SIZE, ROAD_SIZE)
			if not coord then
				return
			end

			local _, originPosition = icoord.align(math3d.vector {10, 0, -10}, ROAD_SIZE, ROAD_SIZE)
			coord[1], coord[2] = coord[1] - (coord[1] % ROAD_SIZE), coord[2] - (coord[2] % ROAD_SIZE)
			local t = icoord.position(coord[1], coord[2], ROAD_SIZE, ROAD_SIZE)
			local p = math3d.live(math3d.add(math3d.sub(t, originPosition), GRID_POSITION_OFFSET))

			for _, obj in ipairs(self.objects) do
				obj:send("obj_motion", "set_position", p)
			end
		end,
		-- TODO: remove this function
		set_position = function(self, position)
			for _, obj in ipairs(self.objects) do
				obj:send("obj_motion", "set_position", math3d.live(position))
			end
		end,
		on_status_change = function(self)
			-- do nothing
		end
	}

	return outer_proxy
end
return M