local ecs = ...
local world = ecs.world
local w = world.w

local iui = ecs.require "engine.system.ui_system"
local objects = require "objects"
local iprototype = require "gameplay.interface.prototype"
local idetail = {}
local gameplay_core = require "gameplay.core"
local create_selected_boxes = ecs.require "selected_boxes"
local terrain = ecs.require "terrain"
local audio = import_package "ant.audio"

function idetail.show(object_id)
    local object = assert(objects:get(object_id))
    local gameplay_eid = object.gameplay_eid
    local typeobject = iprototype.queryByName(object.prototype_name)

    idetail.selected(object.gameplay_eid)
    if typeobject.building_menu ~= false then
        iui.open({rml = "/pkg/vaststars.resources/ui/building_menu.rml"}, gameplay_eid)
    end
    return true
end

do
    local temp_objects = {}
    local create_sprite = ecs.require "sprite"
    local SPRITE_COLOR <const> = import_package "vaststars.prototype"("sprite_color")
    local DOTTED_LINE_MATERIAL <const> = "/pkg/vaststars.resources/materials/dotted_line.material"
    local iquad_lines_entity = ecs.require "engine.quad_lines_entity"

    local function __check_pipe_to_ground(object, dir)
        local typeobject = iprototype.queryByName(object.prototype_name)
        for _, connection in ipairs(typeobject.fluidbox.connections) do
            if connection.ground then
                local _, _, connection_dir = iprototype.rotate_connection(connection.position, object.dir, typeobject.area)
                if connection_dir == dir then
                    return true
                end
            end
        end
    end

    local function __find_ground_neighbor(prototype_name, x, y, dir)
        local typeobject = iprototype.queryByName(prototype_name)
        for _, connection in ipairs(typeobject.fluidbox.connections) do
            if connection.ground then
                local connection_x, connection_y, connection_dir = iprototype.rotate_connection(connection.position, dir, typeobject.area)
                local succ, dx, dy = false, x + connection_x, y + connection_y
                for _ = 1, connection.ground do
                    succ, dx, dy = terrain:move_coord(dx, dy, connection_dir, 1)
                    if not succ then
                        return
                    end

                    local neighbor = objects:coord(dx, dy)
                    if not neighbor then
                        goto continue
                    end

                    if not iprototype.is_pipe_to_ground(neighbor.prototype_name) then
                        goto continue
                    end

                    if __check_pipe_to_ground(neighbor, iprototype.reverse_dir(connection_dir)) then
                        return neighbor, connection_dir
                    end

                    ::continue::
                end
                return
            end
        end
        assert(false)
    end

    function idetail.unselected()
        for _, o in ipairs(temp_objects) do
            o:remove()
        end
        temp_objects = {}
    end

    function idetail.focus_non_building(x, y, w, h)
        idetail.unselected()

        local pos = terrain:get_position_by_coord(x, y, w, h)
        temp_objects[#temp_objects+1] = create_selected_boxes(
            {
                "/pkg/vaststars.resources/glbs/selected-box-no-animation.glb|mesh.prefab",
                "/pkg/vaststars.resources/glbs/selected-box-no-animation-line.glb|mesh.prefab",
            },
            pos, SPRITE_COLOR.SELECTED_OUTLINE, w, h
        )
    end

    function idetail.focus(gameplay_eid)
        idetail.unselected()

        local e = assert(gameplay_core.get_entity(gameplay_eid))
        do
            local typeobject = iprototype.queryById(e.building.prototype)
            local w, h = iprototype.rotate_area(typeobject.area, e.building.direction)
            local pos = terrain:get_position_by_coord(e.building.x, e.building.y, w, h)
            temp_objects[#temp_objects+1] = create_selected_boxes(
                {
                    "/pkg/vaststars.resources/glbs/selected-box-no-animation.glb|mesh.prefab",
                    "/pkg/vaststars.resources/glbs/selected-box-no-animation-line.glb|mesh.prefab",
                },
                pos, SPRITE_COLOR.SELECTED_OUTLINE, w, h
            )
        end
    end

    function idetail.selected(gameplay_eid)
        local e = assert(gameplay_core.get_entity(gameplay_eid))
        local typeobject = e.lorry and iprototype.queryById(e.lorry.prototype) or iprototype.queryById(e.building.prototype)
        local object
        if e.building then
            object = assert(objects:coord(e.building.x, e.building.y))
        end

        if typeobject.sound then
            audio.play_background("event:/" .. typeobject.sound)
        end
        temp_objects[#temp_objects+1] = {
            remove = function (self)
                audio.stop_background(true)
            end
        }

        --
        if typeobject.supply_area then
            for _, o in objects:all() do
                local otypeobject = iprototype.queryByName(o.prototype_name)
                if otypeobject.supply_area and o.id ~= object.id then
                    local w, h = iprototype.rotate_area(otypeobject.area, o.dir)
                    local ow, oh = iprototype.rotate_area(otypeobject.supply_area, o.dir)
                    ow, oh = tonumber(ow), tonumber(oh)
                    temp_objects[#temp_objects+1] = create_sprite(o.x - (ow - w)//2, o.y - (oh - h)//2, ow, oh, o.dir, SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_OTHER)
                end
            end
            local w, h = iprototype.rotate_area(typeobject.area, object.dir)
            local ow, oh = iprototype.rotate_area(typeobject.supply_area, object.dir)
            ow, oh = tonumber(ow), tonumber(oh)
            temp_objects[#temp_objects+1] = create_sprite(object.x - (ow - w)//2, object.y - (oh - h)//2, ow, oh, object.dir, SPRITE_COLOR.CONSTRUCT_DRONE_DEPOT_SUPPLY_AREA_SELF_VALID)

        elseif typeobject.power_supply_area and typeobject.power_supply_distance then
            for _, o in objects:all() do
                if o.id ~= object.id then
                    local otypeobject = iprototype.queryByName(o.prototype_name)
                    if otypeobject.power_supply_area then
                        local w, h = iprototype.rotate_area(otypeobject.area, o.dir)
                        local ow, oh = iprototype.rotate_area(otypeobject.power_supply_area, o.dir)
                        temp_objects[#temp_objects+1] = create_sprite(o.x - (ow - w)//2, o.y - (oh - h)//2, ow, oh, o.dir, SPRITE_COLOR.POWER_SUPPLY_AREA)
                    end
                end
            end
            local w, h = iprototype.rotate_area(typeobject.area, object.dir)
            local ow, oh = iprototype.rotate_area(typeobject.power_supply_area, object.dir)
            temp_objects[#temp_objects+1] = create_sprite(object.x - (ow - w)//2, object.y - (oh - h)//2, ow, oh, object.dir, SPRITE_COLOR.POWER_SUPPLY_AREA_SELF)
        end

        --
        if iprototype.is_pipe_to_ground(typeobject.name) then
            local neighbor, connection_dir = __find_ground_neighbor(object.prototype_name, object.x, object.y, object.dir)
            if neighbor then
                temp_objects[#temp_objects+1] = create_selected_boxes(
                    {
                        "/pkg/vaststars.resources/glbs/selected-box-no-animation.glb|mesh.prefab",
                        "/pkg/vaststars.resources/glbs/selected-box-no-animation-line.glb|mesh.prefab",
                    },
                    neighbor.srt.t, SPRITE_COLOR.SELECTED_OUTLINE, iprototype.rotate_area(typeobject.area, neighbor.dir)
                )

                local quad_num
                if object.x == neighbor.x then
                    quad_num = math.abs(object.y - neighbor.y) - 1
                elseif object.y == neighbor.y then
                    quad_num = math.abs(object.x - neighbor.x) - 1
                else
                    log.error("invalid quad line")
                end

                if quad_num > 0 then
                    local dotted_line = iquad_lines_entity.create(DOTTED_LINE_MATERIAL)
                    local succ, dx, dy = terrain:move_coord(object.x, object.y, connection_dir, 1)
                    if succ then
                        local position = terrain:get_position_by_coord(dx, dy, 1, 1)
                        dotted_line:update(position, quad_num, connection_dir)
                        dotted_line:show(true)

                        temp_objects[#temp_objects+1] = dotted_line
                    end
                end
            end
        end
    end
end

return idetail
