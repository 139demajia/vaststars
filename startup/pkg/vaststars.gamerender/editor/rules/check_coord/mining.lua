local ecs = ...
local world = ecs.world

local CONSTANT <const> = require "gameplay.interface.constant"
local DEFAULT_DIR <const> = CONSTANT.DEFAULT_DIR

local ibuilding = ecs.require "render_updates.building"
local imineral = ecs.require "mineral"
local iprototype = require "gameplay.interface.prototype"
local objects = require "objects"
local imining = require "gameplay.interface.mining"

return function (prototype_name, x, y, dir, exclude_object_id)
    assert(dir)
    local typeobject = iprototype.queryByName(prototype_name)
    local w, h = iprototype.rotate_area(typeobject.area, dir)

    local found_mineral
    for i = 0, w - 1 do
        for j = 0, h - 1 do
            local object = objects:coord(x + i, y + j)

            -- building
            if object and object.id ~= exclude_object_id then
                return false
            end

            -- road
            if ibuilding.get(x + i, y + j) then
                return false
            end

            --TODO: this assumes that each coordinate will only have one type of mineral
            if not found_mineral then
                found_mineral = imineral.get(x + i, y + j)
            end
        end
    end

    if not found_mineral then
        return false
    else
        local succ, mineral = imineral.can_place(x, y, w, h)
        if not succ then
            return false
        end
        return imining.get_mineral_recipe(prototype_name, mineral)
    end
end