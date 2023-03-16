local ecs = ...
local world = ecs.world
local w = world.w

local iprototype = require "gameplay.interface.prototype"
local objects = require "objects"
local assembling_common = require "ui_datamodel.common.assembling"
local cr = import_package "ant.compile_resource"
local serialize = import_package "ant.serialize"
local iprinter = ecs.import.interface "mod.printer|iprinter"

local RESOURCES_BASE_PATH <const> = "/pkg/vaststars.resources/%s"

local progresses = {} --TODO: when an object is destroyed, clear it.

local __get_meshbins; do
    local meshbin_caches = {}
    function __get_meshbins(prefab)
        if not meshbin_caches[prefab] then
            local res = {}
            for _, v in ipairs(serialize.parse(prefab, cr.read_file(prefab))) do
                if v.data.mesh then
                    res[#res+1] = v.data.mesh
                end
            end
            meshbin_caches[prefab] = res
        end
        return meshbin_caches[prefab]
    end
end

local function update_world(world)
    local t = {}
    for e in world.ecs:select "assembling:in building:in chest:in eid:in" do
        local typeobject = iprototype.queryById(e.building.prototype)
        if typeobject.construction_center ~= true then
            goto continue
        end

        local _, results, progress, total_progress = assembling_common.get(world, e)
        if #results == 0 then -- Not yet set recipe
            goto continue
        end

        local object = assert(objects:coord(e.building.x, e.building.y))
        local srt = object.srt
        local t = {srt.t[1], 10, srt.t[3]} --TODO: change the height to be configured in the slot of prefab

        progresses[e.eid] = progresses[e.eid] or {progress = 0, printer_eids = {}}
        if progress > progresses[e.eid].progress then
            progresses[e.eid].progress = progress
            local eids = progresses[e.eid].printer_eids

            if #eids == 0 then
                local res_typeobject = iprototype.queryById(results[1].id)
                local meshbins = __get_meshbins(RESOURCES_BASE_PATH:format(res_typeobject.model))

                for _, meshbin in ipairs(meshbins) do
                    eids[#eids+1] = ecs.create_entity {
                        policy = {
                            "ant.render|render",
                            "ant.general|name",
                            "mod.printer|printer",
                        },
                        data = {
                            name = "printer",
                            scene = {s = srt.s, t = t},
                            material = "/pkg/mod.printer/assets/printer.material",
                            visible_state = "main_view",
                            mesh = meshbin,
                            render_layer= "postprocess_obj",
                            printer = {
                                percent = (total_progress - progress)/total_progress
                            }
                        },
                    }
                end
            else
                for _, eid in ipairs(progresses[e.eid].printer_eids) do
                    local percent = (total_progress - progress)/total_progress
                    iprinter.update_printer_percent(eid, percent)
                end
            end
        else
            for _, eid in ipairs(progresses[e.eid].printer_eids) do
                local percent = (total_progress - progress)/total_progress
                iprinter.update_printer_percent(eid, percent)
            end
        end
        ::continue::
    end
    return t
end
return update_world