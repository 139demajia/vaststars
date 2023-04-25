local iprototype = require "gameplay.interface.prototype"

return function ()
    local get_dir_bit do
        local function get_bit_func()
            local dir_bit <const> = {
                N = 0,
                E = 1,
                S = 2,
                W = 3,
            }

            local ground_bit <const> = { -- ground for the pipe
                N = 4,
                E = 5,
                S = 6,
                W = 7,
            }

            return function (dir, ground)
                if ground == true then
                    return ground_bit[dir]
                else
                    return dir_bit[dir]
                end
            end
        end

        local cache = {}
        function get_dir_bit(flow_type, dir, ground)
            cache[flow_type] = cache[flow_type] or get_bit_func()
            return cache[flow_type](dir, ground)
        end
    end

    local function _get_connections(typeobject)
        if iprototype.is_pipe(typeobject.name) or iprototype.is_pipe_to_ground(typeobject.name) then
            return typeobject.fluidbox.connections
        elseif typeobject.crossing then
            return typeobject.crossing.connections
        end
        assert(false)
    end

    local accel = {} -- flow_type + bits -> prototype_name + dir
    local prototype_bits = {} -- prototype_name + dir -> bits
    local max_ground = {} -- flow_type -> max_ground

    for _, typeobject in pairs(iprototype.each_type "building") do
        if not typeobject.flow_type then
            goto continue
        end

        -- flow_direction is a table of all directions that the entity can rotate around.
        for _, entity_dir in ipairs(typeobject.flow_direction) do
            local bits = 0
            for _, connection in ipairs(_get_connections(typeobject)) do
                local dir = iprototype.rotate_dir(connection.position[3], entity_dir)
                bits = bits | (1 << get_dir_bit(typeobject.flow_type, dir, (connection.ground ~= nil) )) -- TODO: special case for pipe-to-ground

                -- 
                if connection.ground then
                    if not max_ground[typeobject.flow_type] then
                        max_ground[typeobject.flow_type] = connection.ground
                    else
                        assert(max_ground[typeobject.flow_type] == connection.ground)
                    end
                end
            end

            accel[typeobject.flow_type] = accel[typeobject.flow_type] or {}
            assert(not accel[typeobject.flow_type][entity_dir])
            accel[typeobject.flow_type][bits] = {prototype_name = typeobject.name, entity_dir = entity_dir}

            prototype_bits[typeobject.name] = prototype_bits[typeobject.name] or {}
            assert(not prototype_bits[typeobject.name][entity_dir])
            prototype_bits[typeobject.name][entity_dir] = bits
        end

        ::continue::
    end

    local function _get_covers(flow_type, pipe_bits)
        local r = pipe_bits
        for bits in pairs(accel[flow_type]) do
            if pipe_bits ~= bits and pipe_bits & bits == pipe_bits then
                r = r | bits
            end
        end
        return assert(accel[flow_type][r])
    end

    local function _get_road_covers(flow_type, pipe_bits)
        local r = pipe_bits & 0xF
        for bits in pairs(accel[flow_type]) do
            if pipe_bits ~= bits and r & bits == r then
                r = r | (bits & 0xF)
            end
        end
        return assert(accel[flow_type][r])
    end

    local function _get_cleanup(prototype_name, entity_dir)
        local typeobject = assert(iprototype.queryByName(prototype_name))
        local bits = 0
        for _, connection in ipairs(_get_connections(typeobject)) do
            if connection.ground then
                local dir = iprototype.rotate_dir(connection.position[3], entity_dir)
                bits = bits | (1 << get_dir_bit(typeobject.flow_type, dir, true))
            end
        end
        return assert(accel[typeobject.flow_type][bits])
    end

    local prototype_covers = {}
    local prototype_cleanup = {}
    for prototype_name, t in pairs(prototype_bits) do
        for entity_dir, bits in pairs(t) do
            local typeobject = iprototype.queryByName(prototype_name)
            prototype_covers[prototype_name] = prototype_covers[prototype_name] or {}

            if iprototype.is_road(typeobject.name) then -- TODO: special case for road
                prototype_covers[prototype_name][entity_dir] = _get_road_covers(typeobject.flow_type, bits)
            else
                prototype_covers[prototype_name][entity_dir] = _get_covers(typeobject.flow_type, bits)
            end

            prototype_cleanup[prototype_name] = prototype_cleanup[prototype_name] or {}
            prototype_cleanup[prototype_name][entity_dir] = _get_cleanup(prototype_name, entity_dir)
        end
    end

    return {
        accel = accel,
        prototype_bits = prototype_bits,
        max_ground = max_ground,
        prototype_covers = prototype_covers,
        prototype_cleanup = prototype_cleanup,
        get_dir_bit = get_dir_bit,
    }
end