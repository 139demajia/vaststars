local ecs = ...
local world = ecs.world
local w = world.w

local igame_object = ecs.require "engine.game_object"
local iprototype = require "gameplay.interface.prototype"
local ROTATORS <const> = require("gameplay.interface.constant").ROTATORS

local function set_position(self, position)
    self.game_object:send("obj_motion", "set_position", position)
end

local function set_dir(self, dir)
    self.game_object:send("obj_motion", "set_rotation", ROTATORS[dir])
end

local function remove(self)
    if self.game_object then
        self.game_object:remove()
    end
end

local function update(self, t)
    self.prototype_name = t.prototype_name or self.prototype_name
    local typeobject = iprototype.queryByName(self.prototype_name)
    local model
    if t.state == "translucent" then
        model = assert(typeobject.model:match("(.*%.glb|).*%.prefab"))
        model = model .. "translucent.prefab"
    else
        model = typeobject.model
    end

    self.game_object:update {
        prefab = model,
        color = t.color,
        animation_name = t.animation_name,
        final_frame = t.final_frame,
        emissive_color = t.emissive_color,
    }
end

local function has_animation(self, animation_name)
    return self.game_object:has_animation(animation_name)
end

local function modifier(self, ...)
    self.game_object:modifier(...)
end

-- init = {
--     prototype_name = prototype_name,
--     type = xxx,
--     position = position,
--     dir = 'N',
-- }
return function (init)
    local typeobject = iprototype.queryByName(init.prototype_name)
    local game_object = assert(igame_object.create({
        prefab = typeobject.model,
        group_id = init.group_id,
        color = init.color,
        srt = {r = ROTATORS[init.dir], t = init.position},
        parent = nil,
        slot = nil,
    }))

    local vsobject = {
        id = init.id,
        prototype_name = init.prototype_name,
        type = init.type,
        group_id = init.group_id,
        slots = {}, -- slot_name -> model
        game_object = game_object,

        --
        update = update,
        set_position = set_position,
        set_dir = set_dir,
        remove = remove,
        modifier = modifier,
        has_animation = has_animation,
    }
    return vsobject
end
