local create_buildings = require "building_components"

return {
    removed = {},
    science = {},
    statistic = {
        valid = false,
    },
    coord_system = require "coord_transform"(256, 256),
    roadnet = {}, -- = {[coord] = {prototype_name, dir}, ...}
    buildings = create_buildings(), -- { object-id = {}, ...}
}
