local prototype = require "prototype"
local query = require "prototype".queryById
local iFluidbox = require "interface.fluidbox"
local iChest = require "interface.chest"

local STATUS_IDLE <const> = 0
local STATUS_DONE <const> = 1

local function isFluidId(id)
    local pt = query(id)
    for _, t in ipairs(pt.type) do
        if t == "fluid" then
            return true
        end
    end
    return false
end

local function findFluidbox(init, id)
    local name = query(id).name
    for i, v in ipairs(init) do
        if name == v then
            return i
        end
    end
    return 0
end

local function createFluidBox(init, recipe)
    local input_fluids = {}
    local output_fluids = {}
    local ingredients_n <const> = #recipe.ingredients//4 - 1
    local results_n <const> = #recipe.results//4 - 1
    assert(ingredients_n <= 16 and results_n <= 16)
    for idx = 1, ingredients_n do
        local MAX <const> = 4
        local id = string.unpack("<I2I2", recipe.ingredients, 4*idx+1)
        if isFluidId(id) then
            local fluid_idx = findFluidbox(init.input, id)
            if fluid_idx > MAX then
                error "The assembling does not support this recipe."
            end
            input_fluids[fluid_idx] = idx
        end
    end
    for idx = 1, results_n do
        local MAX <const> = 3
        local id = string.unpack("<I2I2", recipe.results, 4*idx+1)
        if isFluidId(id) then
            local fluid_idx = findFluidbox(init.output, id)
            if fluid_idx > MAX then
                error "The assembling does not support this recipe."
            end
            output_fluids[fluid_idx] = idx + ingredients_n
        end
    end
    local fluidbox_in = 0
    local fluidbox_out = 0
    for i = 4, 1, -1 do
        fluidbox_in = (fluidbox_in << 4) | (input_fluids[i] or 0)
    end
    for i = 3, 1, -1 do
        fluidbox_out = (fluidbox_out << 4) | (output_fluids[i] or 0)
    end
    return fluidbox_in, fluidbox_out
end

local function del_recipe(world, e)
    local assembling = e.assembling
    assembling.progress = 0
    assembling.status = STATUS_IDLE
    assembling.recipe = 0
    assembling.fluidbox_in = 0
    assembling.fluidbox_out = 0
    iChest.assembling_set(world, e)
end

local function set_recipe(world, e, pt, recipe_name, fluids, option)
    iFluidbox.update_fluidboxes(world, e, pt, fluids)

    if recipe_name == nil then
        del_recipe(world, e)
        return
    end
    local assembling = e.assembling
    local recipe = assert(prototype.queryByName(recipe_name), "unknown recipe: "..recipe_name)
    if assembling.recipe == recipe.id then
        return
    end
    assembling.recipe = recipe.id
    assembling.progress = 0
    assembling.status = STATUS_IDLE
    iChest.assembling_set(world, e, recipe, option, pt.maxslot)
    if fluids and pt.fluidboxes then
        local fluidbox_in, fluidbox_out = createFluidBox(fluids, recipe)
        assembling.fluidbox_in = fluidbox_in
        assembling.fluidbox_out = fluidbox_out
    else
        assembling.fluidbox_in = 0
        assembling.fluidbox_out = 0
    end
end

local function set_direction(_, e, dir)
    local DIRECTION <const> = {
        N = 0, North = 0,
        E = 1, East  = 1,
        S = 2, South = 2,
        W = 3, West  = 3,
    }
    local d = assert(DIRECTION[dir])
    local building = e.building
    if building.direction ~= d then
        building.direction = d
        e.fluidbox_changed = true
    end
end

return {
    set_recipe = set_recipe,
    set_direction = set_direction,
}
