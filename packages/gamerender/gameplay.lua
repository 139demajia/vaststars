local gameplay = import_package "vaststars.gameplay"
local world = gameplay.createWorld()
local m = {}

function m.select(...)
    return world.ecs:select(...)
end

function m.build(...)
    return world:build()
end

local create_entity_cache = {}
local function create(world, prototype, entity)
    if not create_entity_cache[prototype] then
        create_entity_cache[prototype] = world:create_entity(prototype)
        if not create_entity_cache[prototype] then
            log.error(("failed to create entity `%s`"):format(prototype))
            return
        end
    end
    return create_entity_cache[prototype](entity)
end

local function isFluidId(id)
    return id & 0x0C00 == 0x0C00
end

local function get_fluid_list(fluidboxes, classify, s)
    local lst = fluidboxes[classify]
    assert(lst)

    local r = {}
    for idx = 1, #s//4 do
        local id = string.unpack("<I2I2", s, 4*idx-3)
        if isFluidId(id) then
            local pt = gameplay.query(id)
            r[#r + 1] = {pt.name, 0}
        end
    end
    return r
end

local init_func = {}
init_func["assembling"] = function(pt, template)
    if not pt.recipe then
        log.error(("can not found recipe `%s`"):format(pt.name))
        return
    end
    local r = gameplay.queryByName("recipe", pt.recipe)

    local output = get_fluid_list(pt.fluidboxes, "output", r.results)
    if #output > 0 then
        template.fluids = {
            output = output
        }
    end

    return template
end

function m.create_entity(game_object)
    local func
    local template = {
        x = game_object.construct_object.x,
        y = game_object.construct_object.y,
        dir = game_object.construct_object.dir,
        fluid = game_object.construct_object.fluid,
    }

    local pt = gameplay.queryByName("entity", game_object.construct_object.prototype_name)
    for _, entity_type in ipairs(pt.type) do
        func = init_func[entity_type]
        if func then
            template = func(pt, template)
        end
    end

    create(world, game_object.construct_object.prototype_name, template)
end

return m