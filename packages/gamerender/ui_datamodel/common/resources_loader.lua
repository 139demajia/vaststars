local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local assetmgr = import_package "ant.asset"
local imaterial = ecs.import.interface "ant.asset|imaterial"
local fs = require "filesystem"

local M = {}

function M.load(filename)
    local skip = {"glb", "sc"}
    local handler = {
        ["prefab"] = function(f)
            local fs = require "filesystem"
            local datalist  = require "datalist"
            local lf = assert(fs.open(fs.path(f)))
            local data = lf:read "a"
            lf:close()
            local prefab_resource = {"material", "mesh", "skeleton", "meshskin", "animation"}
            for _, d in ipairs(datalist.parse(data)) do
                if d.prefab then -- TODO: special case for prefab
                    goto continue
                end
                for _, field in ipairs(prefab_resource) do
                    if d.data[field] then
                        if field == "material" then
                            length = #imaterial.load_res(d.data.material)
                        elseif field == "animation" then
                            for _, v in pairs(d.data.animation) do
                                length = #assetmgr.resource(v, world)
                                local f <close> = fs.open(fs.path(v:match("^(.+%.).*$") .. "event"), "r")
                            end
                        else
                            length = #assetmgr.resource(d.data[field])
                        end
                    end
                end
                ::continue::
            end
        end,
        ["texture"] = function (f)
            length = #assetmgr.resource(f)
        end,
        ["png"] = function (f)
            length = #assetmgr.resource(f)
        end,
        ["material"] = function (f)
            local res = imaterial.load_res(f)
            local obj = res.object
        end
    }

    local ext = filename:match(".*%.(.*)$")
    for _, _ext in ipairs(skip) do
        if ext == _ext then
            return
        end
    end

    log.info(("resources_loader|load %s"):format(filename))
    if not handler[ext] then
        local f <close> = assert(fs.open(fs.path(filename), "r"))
        return
    end
    handler[ext](filename)
    return true
end

return M