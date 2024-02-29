local ecs = ...
local world = ecs.world
local w = world.w

local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER

local game_object_event = ecs.require "engine.game_object_event"
local iom               = ecs.require "ant.objcontroller|obj_motion"
local irl               = ecs.require "ant.render|render_layer.render_layer"
local ig                = ecs.require "ant.group|group"
local imodifier         = ecs.require "ant.modifier|modifier"
local itl               = ecs.require "ant.timeline|timeline"

local _calc_hash ; do
    local function get_hash_func(max_value)
        local n = 0
        local cache = {}
        return function(s)
            if cache[s] then
                return cache[s]
            else
                assert(n <= max_value)
                cache[s] = n
                n = n + 1
                return cache[s]
            end
        end
    end

    local prefab_hash = get_hash_func(0xff)
    local color_hash = get_hash_func(0xf)
    local work_status_hash = get_hash_func(0xf)
    local emissive_color_hash = get_hash_func(0xf)
    local render_layer_hash = get_hash_func(0xf)

    function _calc_hash(prefab, color, work_status, emissive_color, render_layer)
        local h1 = prefab_hash(prefab or 0) -- 8 bits
        local h2 = color_hash(color or 0) -- 4 bits
        local h3 = work_status_hash(work_status or 0) -- 1 bits
        local h4 = emissive_color_hash(emissive_color or 0) -- 4 bits
        local h5 = render_layer_hash(render_layer or 0) -- 4 bits
        return h1 | (h2 << 8) | (h3 << 12) | (h4 << 13) | (h5 << 17)
    end
end

local _get_hitch_group_id, _stop_world, _restart_world ; do
    local cache = {}
    local next_hitch_group = 1

    function _get_hitch_group_id(prefab, color, work_status, emissive_color, render_layer, dynamic_mesh)
        if not dynamic_mesh then
            prefab = prefab:gsub("(%.[^%.]+)$", "_di%1")
        end
        render_layer = render_layer or RENDER_LAYER.BUILDING
        local hash = _calc_hash(prefab, tostring(color), work_status, tostring(emissive_color), render_layer)
        if cache[hash] then
            return assert(cache[hash].hitch_group_id), true
        end

        local hitch_group_id = ig.register("HITCH_GROUP_" .. next_hitch_group)
        next_hitch_group = next_hitch_group + 1

        local inst = world:create_instance {
            prefab = prefab,
            group = hitch_group_id,
            on_ready = function (self)
                for _, eid in ipairs(self.tag["*"]) do
                    local e <close> = world:entity(eid, "render_object?update dynamic_mesh?out")
                    e.dynamic_mesh = dynamic_mesh
                    if render_layer and e.render_object then
                        irl.set_layer(e, render_layer)
                    end
                end

                for _, eid in ipairs(self.tag["timeline"] or {}) do
                    local e <close> = world:entity(eid, "timeline?in loop_timeline?out")
                    e.timeline.eid_map = self.tag
                    itl:start(e)

                    if e.timeline.loop == true then
                        e.loop_timeline = true
                    end
                end
            end,
            on_message = function (self, cmd, ...)
                local event = game_object_event[cmd]
                if event then
                    event(self, ...)
                else
                    log.error(("game_object unknown event `%s`"):format(cmd))
                end
            end
        }
        if color then
            world:instance_message(inst, "material", "set_property", "u_basecolor_factor", color)
        end
        if emissive_color then
            world:instance_message(inst, "material", "set_property", "u_emissive_factor", emissive_color)
        end

        cache[hash] = {instance = inst, hitch_group_id = hitch_group_id}
        return hitch_group_id
    end

    function _stop_world()
        for _, v in pairs(cache) do
            world:instance_message(v.instance, "stop_world")
        end
    end

    function _restart_world()
        for _, v in pairs(cache) do
            world:instance_message(v.instance, "restart_world")
        end
    end
end

local hitch_events = {}
hitch_events["create_group"] = function(self, group)
    local e <close> = world:entity(self.tag["hitch"][1])
    w:extend(e, "hitch:update hitch_create?out")
    e.hitch.group = group
    e.hitch_create = true
end
hitch_events["update_group"] = function(self, group)
    local e <close> = world:entity(self.tag["hitch"][1])
    w:extend(e, "hitch:update hitch_update?out")
    e.hitch.group = group
    e.hitch_update = true
end
hitch_events["obj_motion"] = function(self, method, ...)
    local e <close> = world:entity(self.tag["hitch"][1])
    iom[method](e, ...)
end
hitch_events["modifier"] = function(self, ...)
    imodifier.start(imodifier.create_bone_modifier(self.tag["hitch"][1], 0, "/pkg/vaststars.resources/glbs/animation/Interact_build.glb|mesh.prefab", "Bone"), ...)
end
hitch_events["attach"] = function(self, slot_name, instance)
    local eid = assert(self.tag[slot_name][1])
    world:instance_set_parent(instance, eid)
end

local function _on_message(self, event, ...)
    assert(hitch_events[event])(self, ...)
end

local function set_srt(e, srt)
    if srt.s then
        iom.set_scale(e, srt.s)
    end
    if srt.r then
        iom.set_rotation(e, srt.r)
    end
    if srt.t then
        iom.set_position(e, srt.t)
    end
end

local igame_object = {}
--[[
init = {
    prefab, -- the relative path to the prefab file
    group_id, -- the group id of the hitch, used to cull the hitch
    color,
    srt,
    parent, -- the parent of the hitch
    emissive_color,
    render_layer,
    on_ready,
    on_message,
}
--]]
function igame_object.create(init)
    local prefab = init.prefab
    local hitch_group_id = _get_hitch_group_id(prefab, init.color, init.work_status or "idle", init.emissive_color, init.render_layer, init.dynamic)
    local srt = init.srt or {}

    local hitch_instance = world:create_instance {
        group = init.group_id,
        prefab = prefab:gsub("^(.*%.glb|)(.*%.prefab)$", "%1hitch.prefab"),
        parent = init.parent,
        on_ready = function(self)
            local root <close> = world:entity(self.tag["hitch"][1])
            set_srt(root, srt)
            assert(hitch_events["create_group"])(self, hitch_group_id)
            if init.on_ready then
                init.on_ready(self)
            end
        end,
        on_message = init.on_message or _on_message
    }

    local function remove(self)
        world:remove_instance(self.hitch_instance)
    end

    local function update(self, t)
        for k, v in pairs(t) do
            if v == "null" then
                self.data[k] = nil
            else
                self.data[k] = v
            end
        end

        local hitch_group_id, existed = _get_hitch_group_id(
            self.data.prefab,
            self.data.color,
            self.data.work_status,
            self.data.emissive_color,
            self.data.render_layer,
            self.data.dynamic
        )

        if existed then
            world:instance_message(self.hitch_instance, "update_group", hitch_group_id)
        else
            world:instance_message(self.hitch_instance, "create_group", hitch_group_id)
        end
        self.hitch_group_id = hitch_group_id
    end
    local function send(self, ...)
        world:instance_message(self.hitch_instance, ...)
    end
    local function modifier(self, method, ...)
        world:instance_message(self.hitch_instance, "modifier", method, ...)
    end
    local function get_slot_position(self, slot_name)
        assert(self.hitch_instance)
        local eid = assert(self.hitch_instance.tag[slot_name][1])
        local e <close> = assert(world:entity(eid))
        return iom.worldmat(e)
    end

    local outer = {
        data = init,
        group_id = init.group_id,
        hitch_instance = hitch_instance,
        hitch_group_id = hitch_group_id,
    }
    outer.modifier = modifier
    outer.remove = remove
    outer.update = update
    outer.send   = send
    outer.get_slot_position = get_slot_position
    return outer
end

function igame_object.stop_world()
    _stop_world()
end

function igame_object.restart_world()
    _restart_world()
end

return igame_object
