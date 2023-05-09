local ecs = ...
local world = ecs.world
local w = world.w

local iui = ecs.import.interface "vaststars.gamerender|iui"
local math3d = require "math3d"
local objects = require "objects"
local iprototype = require "gameplay.interface.prototype"
local idetail = ecs.interface "idetail"
local icamera_controller = ecs.import.interface "vaststars.gamerender|icamera_controller"
local gameplay_core = require "gameplay.core"

local function __get_capacitance_network(eid)
    local e = gameplay_core.get_entity(eid)
    if not e then
        return
    end

    if not e.capacitance then
        return
    end

    return e.capacitance.network
end

function idetail.show(object_id)
    iui.close("help_panel.rml")
    iui.open({"detail_panel.rml"}, object_id)

    --
    local object = assert(objects:get(object_id))
    local typeobject = iprototype.queryByName(object.prototype_name)

    idetail.selected(object)

    local p = icamera_controller.world_to_screen(object.srt.t)
    local ui_x, ui_y = iui.convert_coord(math3d.index(p, 1), math3d.index(p, 2))

    if typeobject.show_arc_menu ~= false then
        iui.open({"building_arc_menu.rml"}, object_id, object.srt.t, ui_x, ui_y)
    end

    do
        log.info(([[
        {
            id = %d,
            prototype_name = "%s",
            dir = "%s",
            x = %s,
            y = %s,
            network = %s,
        },
        ]]):format(
            object.id,
            object.prototype_name,
            object.dir,
            object.x,
            object.y,
            __get_capacitance_network(object.gameplay_eid) or "none"
        ))
    end
    return true
end

do
    local sprites = {}
    local create_sprite = ecs.require "sprite"
    local SPRITE_COLOR = import_package "vaststars.prototype".load("sprite_color")

    function idetail.unselected()
        for _, sprite in ipairs(sprites) do
            sprite:remove()
        end
        sprites = {}
    end

    function idetail.selected(object)
        idetail.unselected()

        local typeobject = iprototype.queryByName(object.prototype_name)
        if typeobject.supply_area then
            for _, object in objects:all() do
                local otypeobject = iprototype.queryByName(object.prototype_name)
                if otypeobject.supply_area then
                    local w, h = iprototype.rotate_area(otypeobject.area, object.dir)
                    local ow, oh = iprototype.rotate_area(otypeobject.supply_area, object.dir)
                    ow, oh = tonumber(ow), tonumber(oh)
                    sprites[#sprites+1] = create_sprite(object.x - (ow - w)//2, object.y - (oh - h)//2, ow, oh, object.dir, SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_OTHER)
                end
            end
        elseif typeobject.power_supply_area and typeobject.power_supply_distance then
            for _, object in objects:all() do
                local otypeobject = iprototype.queryByName(object.prototype_name)
                if otypeobject.power_supply_area then
                    local w, h = iprototype.rotate_area(otypeobject.area, object.dir)
                    local ow, oh = otypeobject.power_supply_area:match("(%d+)x(%d+)")
                    ow, oh = tonumber(ow), tonumber(oh)
                    sprites[#sprites+1] = create_sprite(object.x - (ow - w)//2, object.y - (oh - h)//2, ow, oh, object.dir, SPRITE_COLOR.POWER_SUPPLY_AREA)
                end
            end
        end
    end
end