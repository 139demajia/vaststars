local ecs = ...
local world = ecs.world
local w = world.w

local gameplay_core = require "gameplay.core"
local fs = require "bee.filesystem"
local json = import_package "ant.json"
local debugger = require "debugger"
local iprototype_cache = require "gameplay.prototype_cache.init"
local iBackpack = import_package "vaststars.gameplay".interface "backpack"
local archiving = require "archiving"
local iprototype = require "gameplay.interface.prototype"
local iroadnet_converter = require "roadnet_converter"
local objects = require "objects"
local ifluid = require "gameplay.interface.fluid"
local iscience = require "gameplay.interface.science"
local iguide = require "gameplay.interface.guide"
local iui = ecs.require "engine.system.ui_system"
local global = require "global"
local create_buildings = require "building_components"
local igameplay = ecs.require "gameplay_system"
local irq = ecs.require "ant.render|render_system.renderqueue"
local iom = ecs.require "ant.objcontroller|obj_motion"
local ic = ecs.require "ant.camera|camera"
local math3d = require "math3d"
local iobject = ecs.require "object"
local terrain = ecs.require "terrain"
local ipower = ecs.require "power"
local ipower_line = ecs.require "power_line"
local iroadnet = ecs.require "roadnet"

local MAX_ARCHIVING_COUNT <const> = 9
local PROTOTYPE_VERSION <const> = import_package("vaststars.prototype")("version")
local CAMERA_CONFIG = archiving.path() .. "camera.json"
local ROTATORS <const> = require("gameplay.interface.constant").ROTATORS
local CHANGED_FLAG_ALL <const> = require("gameplay.interface.constant").CHANGED_FLAG_ALL

local function clean()
    global.buildings = create_buildings()
    objects:clear()
    iroadnet:clear("road")
end

local function restore_world()
    local function _finish_task(task)
        local typeobject = iprototype.queryByName(task)
        gameplay_core.get_world():research_progress(task, typeobject.count)
    end

    local f = import_package("vaststars.prototype")(gameplay_core.get_storage().game_template).guide
    local guide = import_package("vaststars.prototype")(f)

    local function _debug()
        if debugger.skip_guide then
            print("skip guide")
            gameplay_core.get_storage().guide_id = #guide
            iui.set_guide_progress(guide[#guide].narrative_end.guide_progress)

            for _, guide in ipairs(guide) do
                if next(guide.narrative_end.task) then
                    for _, task in ipairs(guide.narrative_end.task) do
                        _finish_task(task)
                    end
                end
            end
        end
    end
    _debug()

    --
    local function restore_object(gameplay_eid, prototype_name, dir, x, y, fluid_name)
        local typeobject = iprototype.queryByName(prototype_name)
        local object = iobject.new {
            prototype_name = prototype_name,
            dir = dir,
            x = x,
            y = y,
            srt = {
                t = math3d.ref(math3d.vector(terrain:get_position_by_coord(x, y, iprototype.rotate_area(typeobject.area, dir)))),
                r = ROTATORS[dir],
            },
            fluid_name = fluid_name,
        }
        object.gameplay_eid = gameplay_eid
        objects:set(object)
    end

    -- restore
    local all_object = {}
    local map = {} -- coord -> id
    local fluidbox_map = {} -- coord -> id -- only for fluidbox
    for v in gameplay_core.select("eid:in building:in road:absent fluidbox?in fluidboxes?in assembling?in") do
        local e = v.building
        local typeobject = iprototype.queryById(e.prototype)
        local fluid_name = ""
        if v.fluidbox then
            fluid_name = ""
            if v.fluidbox.fluid == 0 then
                fluid_name = ""
            else
                local typeobject_fluid = assert(iprototype.queryById(v.fluidbox.fluid))
                fluid_name = typeobject_fluid.name
            end
            local w, h = iprototype.rotate_area(typeobject.area, e.direction)
            for i = 0, w - 1 do
                for j = 0, h - 1 do
                    local coord = iprototype.packcoord(e.x + i, e.y + j)
                    assert(fluidbox_map[coord] == nil, ("duplicate fluidbox coord: %d, %d"):format(e.x + i, e.y + j))
                    fluidbox_map[coord] = v.eid
                end
            end
        end
        if v.fluidboxes then
            fluid_name = {}
            for id, fluid in pairs(v.fluidboxes) do
                if fluid ~= 0 then
                    local iotype, index = id:match("(%a+)(%d+)%_fluid")
                    if iotype then
                        local classity = ifluid:iotype_to_classity(iotype)
                        local typeobject_fluid = assert(iprototype.queryById(fluid))

                        fluid_name[classity] = fluid_name[classity] or {}
                        fluid_name[classity][tonumber(index)] = typeobject_fluid.name
                    end
                end
            end
        end

        assert(iprototype.has_type(typeobject.type, "road") == false)
        all_object[v.eid] = {
            prototype_name = typeobject.name,
            dir = iprototype.dir_tostring(e.direction),
            x = e.x,
            y = e.y,
            fluid_name = fluid_name,
        }

        local w, h = iprototype.rotate_area(typeobject.area, e.direction)
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                local coord = iprototype.packcoord(e.x + i, e.y + j)
                assert(map[coord] == nil, ("duplicate fluidbox coord: %d, %d"):format(e.x + i, e.y + j))
                map[coord] = v.eid
            end
        end

        world:pub {"gameplay", "create_entity", v.eid, typeobject}
    end

    -----------
    for id, v in pairs(all_object) do
        restore_object(id, v.prototype_name, v.dir, v.x, v.y, v.fluid_name)
    end

    iobject.flush()
    iscience.update_tech_list(gameplay_core.get_world())
    -- update power network
    ipower:build_power_network(gameplay_core.get_world())
    ipower_line.update_line(ipower:get_pole_lines())
    global.statistic.valid = false
end

local function writeall(file, content)
    local f <close> = assert(io.open(file, "wb"))
    f:write(content)
end

local function readall(file)
    local f <close> = assert(io.open(file, "rb"))
    return f:read "a"
end

local function get_camera_setting()
    local ce <close> = world:entity(irq.main_camera())
    local t = {
        s = math3d.tovalue(iom.get_scale(ce)),
        r = math3d.tovalue(iom.get_rotation(ce)),
        t = math3d.tovalue(iom.get_position(ce)),
        frustum = ic.get_frustum(ce),
    }
    return t
end

local function restore_camera_setting()
    if fs.exists(fs.path(CAMERA_CONFIG)) then
        local camera_setting = json.decode(readall(CAMERA_CONFIG))
        local ce <close> = world:entity(irq.main_camera())
        iom.set_srt(ce, camera_setting.s, camera_setting.r, camera_setting.t)
        ic.set_frustum(ce, camera_setting.frustum)
    end
end

local M = {running = false}

function M:backup()
    if not self.running then
        log.error("not running")
        return false
    end

    local list = archiving.list()
    while #list + 1 > MAX_ARCHIVING_COUNT do
        local archival = table.remove(list, 1)
        local fullpath = archiving.path() .. ("%s"):format(archival.dir)
        print("remove", fullpath)
        fs.remove_all(fullpath)
    end

    local t = os.date("*t")
    local dn = ("%04d-%02d-%02d-%02d-%02d-%02d"):format(t.year, t.month, t.day, t.hour, t.min, t.sec)
    local fullpath = archiving.path() .. ("%s"):format(dn)

    list[#list + 1] = {dir = dn}
    gameplay_core.backup(fullpath)

    writeall(fullpath .. "/version", json.encode({PROTOTYPE_VERSION = PROTOTYPE_VERSION}))
    writeall(archiving.config(), json.encode(list))
    writeall(CAMERA_CONFIG, json.encode(get_camera_setting()))
    print("save success", fullpath)
    return true
end

function M:restore(index)
    local list = archiving.list()
    assert(#list > 0)
    assert(#list >= index)

    local fullpath = archiving.path() .. ("%s"):format(list[index].dir)
    assert(fs.exists(fs.path(fullpath)))
    assert(fs.exists(fs.path(fullpath .. "/version")))

    local version = json.decode(readall(fullpath .. "/version"))
    assert(version.PROTOTYPE_VERSION == PROTOTYPE_VERSION)

    restore_camera_setting()

    self.running = true
    world:pipeline_func "gameworld_clean" ()
    gameplay_core.restore(fullpath)
    iprototype_cache.reload()
    world:pipeline_func "prototype" ()
    iguide.init(import_package("vaststars.prototype")(gameplay_core.get_storage().game_template).guide)

    clean()
    local renderData = {}
    for v in gameplay_core.select("road building:in") do
        local typeobject = iprototype.queryById(v.building.prototype)
        local shape = iroadnet_converter.to_shape(typeobject.name)
        renderData[iprototype.packcoord(v.building.x, v.building.y)] = {v.building.x, v.building.y, "normal", shape, iprototype.dir_tostring(v.building.direction)}
    end
    iroadnet:init(renderData, true)

    local game_template = assert(gameplay_core.get_storage().game_template)
    local game_template_mineral = import_package("vaststars.prototype")(game_template).mineral
    terrain:reset_mineral(game_template_mineral)

    iscience.update_tech_list(gameplay_core.get_world())
    debugger.set_free_mode(gameplay_core.get_storage().game_mode == "free")
    restore_world()
    gameplay_core.set_changed(CHANGED_FLAG_ALL)
    gameplay_core.world_update = true

    iui.open({rml = "/pkg/vaststars.resources/ui/construct.rml"})
    iui.open({rml = "/pkg/vaststars.resources/ui/message_pop.rml"})
    print("restore success", fullpath)
    return true
end

function M:restart(mode, game_template)
    world:pipeline_func "gameworld_clean" ()
    gameplay_core.restart()
    iprototype_cache.reload()
    world:pipeline_func "prototype" ()

    self.running = true
    local cw = gameplay_core.get_world()
    iscience.update_tech_list(cw)
    iguide.world = cw
    iui.set_guide_progress(iguide.get_progress())

    gameplay_core.get_storage().game_template = assert(game_template)
    local config = import_package("vaststars.prototype")(game_template)

    --
    clean()
    local game_template_mineral = import_package("vaststars.prototype")(game_template).mineral
    terrain:reset_mineral(game_template_mineral)

    --
    for _, e in ipairs(config.entities or {}) do
        igameplay.create_entity(e)
    end

    local renderData = {}
    for _, road in ipairs(config.road or {}) do
        igameplay.create_entity(road)
        local shape, dir = iroadnet_converter.to_shape(road.prototype_name), road.dir
        renderData[iprototype.packcoord(road.x, road.y)] = {road.x, road.y, "normal", shape, dir}
    end
    iroadnet:init(renderData, true)

    for _, e in ipairs(config.backpack or {}) do
        local typeobject = iprototype.queryByName(e.prototype_name)
        iBackpack.place(gameplay_core.get_world(), typeobject.id, e.count)
    end

    local prepare = import_package("vaststars.prototype")(game_template).prepare
    if prepare then
        prepare(gameplay_core.get_world())
    end

    restore_world()
    gameplay_core.set_changed(CHANGED_FLAG_ALL)
    gameplay_core.world_update = true

    iui.open({rml = "/pkg/vaststars.resources/ui/construct.rml"})
    iui.open({rml = "/pkg/vaststars.resources/ui/message_pop.rml"})
    if mode then
        gameplay_core.get_storage().game_mode = mode
    end

end

return M