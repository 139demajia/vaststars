local ecs = ...
local world = ecs.world
local w = world.w

local iprototype = require "gameplay.interface.prototype"
local objects = require "objects"
local building_sys = ecs.system "building_system"
local gameplay_core = require "gameplay.core"
local ibuilding = {}
local gameplay = import_package "vaststars.gameplay"
local igameplay_building = gameplay.interface "building"
local itask = ecs.require "task"
local ichest = require "gameplay.interface.chest"
local itransfer = require "gameplay.interface.transfer"
local iobject = ecs.require "object"
local global = require "global"
local igameplay = ecs.require "gameplay.gameplay_system"
local iui = ecs.require "engine.system.ui_system"
local interval_call = ecs.require "engine.interval_call"
local transfer_source_box = ecs.require "transfer_source_box"
local icoord = require "coord"

local DIRECTION <const> = {
    N = 0,
    E = 1,
    S = 2,
    W = 3,
    [0] = 'N',
    [1] = 'E',
    [2] = 'S',
    [3] = 'W',
}

local check_debris = interval_call(300, function(gameplay_world, gameplay_ecs)
    for e in gameplay_ecs:select "debris:in building:in chest:in eid:in" do
        if ichest.has_item(gameplay_world, e.chest) then
            goto continue
        end
        local typeobject = iprototype.queryById(e.building.prototype)
        if not ichest.has_item(gameplay_world, e.chest) and typeobject.chest_destroy then
            local object = assert(objects:coord(e.building.x, e.building.y))

            iobject.remove(object)
            objects:remove(object.id)
            local building = global.buildings[object.id]
            if building then
                for _, v in pairs(building) do
                    v:remove()
                end
            end

            igameplay.destroy_entity(e.eid)
            itransfer.set_source_eid(nil)
            iui.leave()
            iui.redirect("/pkg/vaststars.resources/ui/construct.html", "unselected", e.eid)

            transfer_source_box.remove()
        end
        ::continue::
    end
end)

function building_sys:gameworld_update()
    local gameplay_world = gameplay_core.get_world()
    local gameplay_ecs = gameplay_world.ecs

    for e in gameplay_ecs:select "building_changed building:in road:absent inner_building:absent" do
        local object = assert(objects:coord(e.building.x, e.building.y))
        local typeobject = iprototype.queryById(e.building.prototype)
        object.prototype_name = typeobject.name
        object.dir = DIRECTION[e.building.direction]
        objects:set(object, "CONSTRUCTED")
    end
    gameplay_ecs:clear("building_changed")

    check_debris(gameplay_world, gameplay_ecs)
end

local building_cache = {}

function building_sys:gameworld_build()
    building_cache = {}
    local gameplay_world = gameplay_core.get_world()
    for e in gameplay_world.ecs:select "road building:in eid:in REMOVED:absent" do
        building_cache[icoord.pack(e.building.x, e.building.y)] = {
            eid = e.eid,
            x = e.building.x,
            y = e.building.y,
            prototype = iprototype.queryById(e.building.prototype).name,
            direction = iprototype.dir_tostring(e.building.direction),
        }
    end
    itask.update_progress("in_one_power_grid")
end

function ibuilding.get(x, y)
    return building_cache[icoord.pack(x, y)]
end

function ibuilding.remove(x, y)
    print("remove building", x, y)
    local gameplay_world = gameplay_core.get_world()
    local coord = icoord.pack(x, y)
    local building = building_cache[coord]
    igameplay_building.destroy(gameplay_world, gameplay_world:fetch_entity(building.eid)) -- TODO: use igameplay.destroy_entity instead

    building_cache[coord] = nil
end

function ibuilding.set(init)
    local coord = icoord.pack(init.x, init.y)
    local building = building_cache[coord]
    if building then
        local gameplay_world = gameplay_core.get_world()
        igameplay_building.destroy(gameplay_world, gameplay_world:fetch_entity(building.eid))
        building_cache[coord] = nil
    end
    local eid = igameplay.create_entity({
        x = init.x,
        y = init.y,
        prototype_name = init.prototype_name,
        dir = init.direction,
    })
    building_cache[icoord.pack(init.x, init.y)] = {
        eid = eid,
        x = init.x,
        y = init.y,
        prototype = init.prototype_name,
        direction = init.direction,
    }
end

return ibuilding
