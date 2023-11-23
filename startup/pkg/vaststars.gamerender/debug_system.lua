local ecs = ...
local world = ecs.world
local w = world.w

local GESTURE_LOG <const> = ecs.require "game_settings".gesture_log
local FLUIDBOXES <const> = ecs.require "gameplay.interface.constant".FLUIDBOXES

local math3d = require "math3d"
local XZ_PLANE <const> = math3d.constant("v4", {0, 1, 0, 0})

local icoord = require "coord"
local gameplay_core = require "gameplay.core"
local iprototype = require "gameplay.interface.prototype"
local igroup = ecs.require "group"
local export_startup = ecs.require "export_startup"
local icamera_controller = ecs.require "engine.system.camera_controller"
local idm = ecs.require "ant.debug|debug_mipmap"
local kb_mb = world:sub {"keyboard"}
local game_debug_mb = world:sub {"game_debug"}
local gesture_tap_mb = world:sub {"gesture", "tap"}
local gesture_mb = world:sub {"gesture"}
local debug_sys = ecs.system "debug_system"

local function __get_capacitance(eid)
    local e = gameplay_core.get_entity(eid)
    if not e then
        return {network = "none", delta = 0, shortage = 0}
    end

    if not e.capacitance then
        return {network = "none", delta = 0, shortage = 0}
    end

    return e.capacitance
end

local function __fluid_str(prefix, fluid, fluidbox_id, box_base_level, box_capacity, box_height)
    local volume = "(none)"
    local capacity = "(none)"
    local flow = "(none)"
    local elevation = "(none)"

    local fluid_name = ""
    if fluid ~= 0 then
        fluid_name = iprototype.queryById(fluid).name
        local r = gameplay_core.fluidflow_query(fluid, fluidbox_id)
        if r then
            volume = r.volume / r.multiple
            capacity = r.capacity / r.multiple
            flow = r.flow / r.multiple
            elevation = volume / (box_capacity / box_height) + box_base_level
        end
    end

    return (([[%s fluidbox: fluid: %s, fluidbox_id: %d fluid_name: [%s], volume: %s, capacity: %s, flow: %s box_base_level: %s, box_capacity: %s, box_height: %s, elevation: %s ]]):format(
        prefix, fluid, fluidbox_id, fluid_name, volume, capacity, flow, box_base_level, box_capacity, box_height, elevation)
    )
end

local function __get_detail_str(eid)
    local e = gameplay_core.get_entity(eid)
    if not e then
        return
    end

    local typeobject = iprototype.queryById(e.building.prototype)
    local res = {}

    if e.fluidbox then
        res[#res+1] = __fluid_str("fluidbox ", e.fluidbox.fluid, e.fluidbox.id, typeobject.fluidbox.base_level, typeobject.fluidbox.capacity, typeobject.fluidbox.height)
    end

    if e.fluidboxes then
        for _, v in ipairs(FLUIDBOXES) do
            local box = typeobject.fluidboxes[v.classify][v.index] or {base_level = 0, capacity = 0, height = 0}
            local fluid = e.fluidboxes[v.fluid]
            local id = e.fluidboxes[v.id]
            res[#res+1] = __fluid_str(("fluidboxes %s%s "):format(v.classify, v.index), fluid, id, box.base_level, box.capacity, box.height)
        end
    end

    if e.chimney then
        res[#res+1] = "chimney recipe: " .. (e.chimney.recipe == 0 and 0 or iprototype.queryById(e.chimney.recipe).name)
    end

    if e.capacitance then
        res[#res+1] = "capacitance: network: " .. e.capacitance.network
    end

    return table.concat(res, "\n\t")
end

function debug_sys:init_world()
end

local ibs           = ecs.require "ant.render|blur_scene.blur_scene"

function debug_sys:ui_update()
    local w = world.w

    for _, key, press, state in kb_mb:unpack() do
        if key == "A" and press == 0 then
            ibs.blur_scene(10)   -- default gaussian blur count is 5
        end

        if key == "B" and press == 0 then
            ibs.restore_scene()
        end

        if key == "T" and press == 0 then
            local gameplay_world = gameplay_core.get_world()
            print(("current tick value of the gameplay world is: %d"):format(gameplay_world:now()))

            for e in gameplay_world.ecs:select "building:in road:absent eid:in solar_panel:in" do
                print(("solar panel %d efficiency: %f"):format(e.eid, e.solar_panel.efficiency))
                break
            end
        end

        if state.CTRL and key == "S" and press == 1 then
            export_startup()
        end

        if state.CTRL and key == "M" and press == 1 then
            idm.reset_texture_mipmap(true, 9)
        end
    end

    for _, _, v in gesture_tap_mb:unpack() do
        local x, y = v.x, v.y
        local pos = icamera_controller.screen_to_world(x, y, XZ_PLANE)
        local coord = icoord.position2coord(pos)
        if coord then
            local pp = icoord.position(coord[1], coord[2], 256, 256)
            log.info(("gesture tap coord: (%d, %d), position: (%.2f, %.2f, %.2f)"):format(coord[1], coord[2], pp[1], pp[2], pp[3]))
            log.info(("group(%s)"):format(igroup.id(coord[1], coord[2])))

            local objects = require "objects"
            local vsobject_manager = ecs.require "vsobject_manager"
            local object = objects:coord(coord[1], coord[2])
            if object then
                local gameplay_eid = object.gameplay_eid
                local vsobject = vsobject_manager:get(object.id) or error(("(%s) vsobject not found"):format(object.prototype_name))
                local game_object = vsobject.game_object
                log.info(("hitch id: %s"):format(game_object.hitchObject.tag.hitch[1]))

                log.info(([[
                    {
                        group_id = %s,
                        id = %d,
                        prototype_name = "%s",
                        dir = "%s",
                        x = %s,
                        y = %s,
                        network = %s,
                        delta = %s,
                    },
                    %s
                    ]]):format(
                        game_object.group_id,
                        object.id,
                        object.prototype_name,
                        object.dir,
                        object.x,
                        object.y,
                        __get_capacitance(gameplay_eid).network,
                        __get_capacitance(gameplay_eid).delta,
                        __get_detail_str(gameplay_eid)
                    ))
            else
                local ibuilding = ecs.require "render_updates.building"
                local road = ibuilding.get(coord[1]//2*2, coord[2]//2*2)
                if road then
                    log.info(("road: (%s,%s)"):format(road.x, road.y))
                end
            end
        end
    end

    for _, cmd, params in game_debug_mb:unpack() do
        log.info("message: ", cmd)
        for k, v in pairs(params) do
            log.info(k, v, type(v))
        end
        if cmd == "mipmap" then
            idm.reset_texture_mipmap((params.debug == "true"), tonumber(params.level))
        else
            log.info("unknown game_debug message: ", cmd)
        end
    end

    if GESTURE_LOG then
        local function stringify(v)
            local t = {}
            for k, v in pairs(v) do
                t[#t+1] = ("%s = %s"):format(k, v)
            end
            table.sort(t, function(a, b) return a < b end)
            return table.concat(t, ", ")
        end
        for _, type, v in gesture_mb:unpack() do
            log.info(type, ",", stringify(v))
        end
    end
end

