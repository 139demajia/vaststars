local ecs = ...
local world = ecs.world

local ibuilding = ecs.require "render_updates.building"
local imineral = ecs.require "mineral"
local objects = require "objects"
local iprototype = require "gameplay.interface.prototype"

return function (x, y, dir, typeobject, object_id)
    local w, h = iprototype.rotate_area(typeobject.area, dir)

    for i = 0, w - 1 do
        for j = 0, h - 1 do
            local object = objects:coord(x + i, y + j)

            -- building
            if object and object.id ~= object_id then
                local typeobject = iprototype.queryByName(object.prototype_name)
                -- pipes can be placed on existing pipe locations for replacement
                if iprototype.has_types(typeobject.type, "pipe", "pipe_to_ground") then
                    goto continue
                end
                return false, "cannot place here"
            end

            -- road
            if ibuilding.get((x + i)//2*2, (y + j)//2*2) then
                return false, "cannot place here"
            end

            -- mineral
            if imineral.get(x + i, y + j) then
                return false, "cannot place here"
            end
            ::continue::
        end
    end
    return true
end