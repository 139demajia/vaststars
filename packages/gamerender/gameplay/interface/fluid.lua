local iprototype = require "gameplay.interface.prototype"
local gameplay = import_package "vaststars.gameplay"
local ifluidbox = gameplay.interface "fluidbox"

local M = {}

do
    local classify_to_iotype <const> = {
        ["input"] = "in",
        ["output"] = "out",
    }

    local iotype_to_classity = {}
    for k, v in pairs(classify_to_iotype) do
        iotype_to_classity[v] = k
    end

    -- input -> in
    function M:classify_to_iotype(s)
        return classify_to_iotype[s]
    end

    -- in -> input
    function M:iotype_to_classity(s)
        return iotype_to_classity[s]
    end
end

function M:need_set_fluid(prototype_name)
    local typeobject = iprototype.queryByName("entity", prototype_name)
    if not iprototype.has_type(typeobject.type, "fluidbox") then
        return false
    end
    return #typeobject.fluidbox.connections > 0
end

function M:update_fluidbox(e, fluid_name)
    assert(e.fluidbox)
    assert(type(fluid_name) == "string")
    local typeobject = iprototype.queryByName("fluid", fluid_name)
    if not typeobject then
        ifluidbox.update_fluidbox(e, 0)
    else
        ifluidbox.update_fluidbox(e, typeobject.id)
    end
end

function M:get_fluidbox(prototype_name, x, y, dir, fluid_name)
    local function get_fluid_name(fluid_name, iotype, index)
        if not fluid_name then
            return
        end
        if fluid_name == "" then
            return ""
        end
        assert(fluid_name[iotype], iotype)
        return fluid_name[iotype][index] or ""
    end

    local funcs = {}
    funcs["fluidbox"] = function(typeobject, x, y, dir, fluid_name, result)
        for _, conn in ipairs(typeobject.fluidbox.connections) do
            local dx, dy, dir = iprototype.rotate_fluidbox(conn.position, dir, typeobject.area)
            result[#result+1] = {x = x + dx, y = y + dy, dir = dir, ground = conn.ground, fluid_name = fluid_name}
        end
        return result
    end

    local iotypes = {"input", "output"}
    funcs["fluidboxes"] = function(typeobject, x, y, dir, fluid_name, result)
        for _, iotype in ipairs(iotypes) do
            local i = 0
            for _, v in ipairs(typeobject.fluidboxes[iotype]) do
                for _, conn in ipairs(v.connections) do
                    i = i + 1
                    local dx, dy, dir = iprototype.rotate_fluidbox(conn.position, dir, typeobject.area)
                    result[#result+1] = {x = x + dx, y = y + dy, dir = dir, ground = conn.ground, fluid_name = get_fluid_name(fluid_name, iotype, i)}
                end
            end
        end
        return result
    end

    local result = {}
    local typeobject = assert(iprototype.queryByName("entity", prototype_name))
    for _, t in ipairs(typeobject.type) do
        local func = funcs[t]
        if func then
            result = func(typeobject, x, y, dir, fluid_name, result)
        end
    end
    return result
end

return M
