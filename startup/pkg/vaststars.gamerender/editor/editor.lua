local ecs = ...
local world = ecs.world

local objects = require "objects"
local iprototype = require "gameplay.interface.prototype"
local iobject = ecs.require "object"
local iflow_connector = require "gameplay.interface.flow_connector"

--
local M = {}

function M:revert_changes(revert_cache_names)
    local t = {}
    for _, cache_name in ipairs(revert_cache_names) do
        for id, object in objects:all(cache_name) do
            t[id] = object
        end
    end
    objects:clear(revert_cache_names)

    for id, object in pairs(t) do
        local old_object = objects:get(id, {"CONFIRM", "CONSTRUCTED"})
        if old_object then
            object.prototype_name = old_object.prototype_name
            object.dir = old_object.dir
            object.state = old_object.state
            object.fluid_name = old_object.fluid_name
            object.fluidflow_id = old_object.fluidflow_id
        else
            iobject.remove(object)
        end
    end
    iobject.flush() -- object is removed from cache, so we need to flush it, else it will keep the old state
end

local function refresh_pipe(prototype_name, dir, entry_dir, value)
    local typeobject = iprototype.queryByName("entity", prototype_name)
    if not typeobject.pipe then
        return
    end

    return iflow_connector.set_connection(prototype_name, dir, entry_dir, value)
end

function M:refresh_pipe(...)
    return refresh_pipe(...)
end

return M