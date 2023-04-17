local ecs = ...
local world = ecs.world
local w = world.w

local iefk = ecs.import.interface "ant.efk|iefk"
local game_object_event = ecs.require "engine.game_object_event"
local ientity_object = ecs.import.interface "vaststars.gamerender|ientity_object"
local iani = ecs.import.interface "ant.animation|ianimation"
local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
local math3d = require "math3d"
local COLOR_INVALID <const> = math3d.constant "null"
local RESOURCES_BASE_PATH <const> = "/pkg/vaststars.resources/%s"
local prefab_parse = require("engine.prefab_parser").parse
local replace_material = require("engine.prefab_parser").replace_material
local irl = ecs.import.interface "ant.render|irender_layer"

local function replace_outline_material(template)
    local res = {}
    for _, v in ipairs(template) do
        if v.data and v.data.mesh then
            v.data.material = "/pkg/ant.resources/materials/outline/scale.material"
            v.data.render_layer = "translucent"
        end
        if not v.prefab then
            res[#res+1] = v
        end
    end
    return res
end

local function on_prefab_message(prefab, inner, cmd, ...)
    local event = game_object_event[cmd]
    if event then
        event(prefab, inner, ...)
    else
        log.error(("game_object unknown event `%s`"):format(cmd))
    end
end

local __calc_param_hash ; do
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
    local material_type_hash = get_hash_func(0xf)
    local color_hash = get_hash_func(0xf)
    local animation_name_hash = get_hash_func(0xff)
    local final_frame_hash = get_hash_func(0x1)
    local emissive_color_hash = get_hash_func(0xf)
    local render_layer_hash = get_hash_func(0xf)
    local outline_scale_hash = get_hash_func(0xf)

    function __calc_param_hash(prefab, material_type, color, animation_name, final_frame, emissive_color, render_layer, outline_scale)
        local h1 = prefab_hash(prefab or 0) -- 8 bits
        local h2 = material_type_hash(material_type or 0) -- 4 bits
        local h3 = color_hash(color or 0) -- 4 bits
        local h4 = animation_name_hash(animation_name or 0) -- 8 bits
        local h5 = final_frame_hash(final_frame or 0) -- 1 bit
        local h6 = emissive_color_hash(emissive_color or 0) -- 4 bits
        local h7 = render_layer_hash(render_layer or 0) -- 4 bits
        local h8 = outline_scale_hash(outline_scale or 0) -- 4 bits
        return h1 | h2 << 8 | h3 << 12 | h4 << 16 | h5 << 24 | h6 << 25 | h7 << 29 | h8 << 33
    end
end

local __get_hitch_children ; do
    local cache = {}
    local hitch_group_id = 10000 -- see also: terrain.lua -> TERRAIN_MAX_GROUP_ID

    local function __cache_prefab_info(template)
        local effects = {}
        local slots = {}
        local scene = {}
        local animations = {}
        for _, v in ipairs(template) do
            if v.data then
                if v.data.slot then
                    slots[v.data.name] = v.data
                elseif v.data.efk and not v.data.efk.auto_play then
                    -- work effects
                    effects[#effects + 1] = {efk = v.data.efk, slotname = v.mount and template[v.mount].data.name}
                end
                if v.data.name == "Scene" and v.data.scene then -- TODO: special for hitch which attach to slot
                    scene = v.data.scene
                end
                if v.data.animation then
                    for animation_name in pairs(v.data.animation) do
                        animations[animation_name] = true
                    end
                end
            end
        end
        return scene, slots, effects, animations
    end

    function __get_hitch_children(prefab, material_type, color, animation_name, final_frame, emissive_color, render_layer, outline_scale)
        local hash = __calc_param_hash(prefab, material_type, tostring(color), animation_name, final_frame, tostring(emissive_color), render_layer, outline_scale)
        if cache[hash] then
            return cache[hash]
        end

        hitch_group_id = hitch_group_id + 1
        local g = ecs.group(hitch_group_id)
        g:enable "scene_update"

        local template = prefab_parse(prefab)
        if material_type == "translucent" then
            template = replace_material(template, "/pkg/vaststars.resources/materials/translucent.material")
        elseif material_type == "opacity" then
            template = replace_material(template, "/pkg/vaststars.resources/materials/opacity.material")
        elseif material_type == "outline" then
            template = replace_outline_material(template)
        elseif material_type == "opaque" then
            template = template
        else
            assert(false)
        end

        -- cache all slots & srt of the prefab
        local scene, slots, effects, animations = __cache_prefab_info(template)

        log.info(("game_object.new_instance: %s"):format(table.concat({hitch_group_id, prefab, material_type, require("math3d").tostring(color), tostring(animation_name), tostring(final_frame)}, " "))) -- TODO: remove this line

        local inner = { tags = {} } -- tag -> eid
        local prefab_instance = g:create_instance(template)
        function prefab_instance:on_init()
            for _, eid in ipairs(self.tag["*"]) do
                local e <close> = w:entity(eid, "scene_update_once?out")
                e.scene_update_once = true
            end
        end
        function prefab_instance:on_ready()
            for _, eid in ipairs(self.tag["*"]) do
                local e <close> = w:entity(eid, "tag?in anim_ctrl?in render_object?update")
                if e.tag then
                    for _, tag in ipairs(e.tag) do
                        inner.tags[tag] = inner.tags[tag] or {}
                        table.insert(inner.tags[tag], eid)
                    end
                end
                if e.anim_ctrl then
                    e.anim_ctrl.hitchs = {}
                    e.anim_ctrl.group_id = cache[hash].hitch_group_id
                    iani.load_events(eid, prefab:match("^(.*)%.prefab$") .. ".event")
                end
                if render_layer and e.render_object then
                    w:extend(e, "render_layer?update")
                    e.render_layer = render_layer
                    e.render_object.render_layer = irl.layeridx(e.render_layer)
                end
            end

            animation_name = animation_name or "idle_start"
            if final_frame == nil then
                final_frame = true
            end
            if animations[animation_name] then
                if final_frame then
                    iani.play(self, {name = animation_name, loop = false, speed = 1.0, manual = true, forwards = true})
                    iani.set_time(self, iani.get_duration(self, animation_name))
                else
                    iani.play(self, {name = animation_name, loop = true, speed = 1.0, manual = false})
                end
            end
        end
        function prefab_instance:on_message(...)
            on_prefab_message(self, inner, ...)
        end
        local prefab_proxy = world:create_object(prefab_instance)
        if material_type == "translucent" or material_type == "opacity" then
            prefab_proxy:send("material", "set_property", "u_basecolor_factor", color)
        elseif material_type == "outline" then
            prefab_proxy:send("material", "set_property", "u_outlinescale", math3d.ref(math3d.vector(outline_scale, 0, 0)))
            prefab_proxy:send("material", "set_property", "u_outlinecolor", color)
        end
        if emissive_color then -- see also: meno/u_emissive_factor
            prefab_proxy:send("material_tag", "set_property", "u_emissive_factor", "u_emissive_factor", emissive_color)
        end

        cache[hash] = {prefab_file_name = prefab, instance = prefab_proxy, hitch_group_id = hitch_group_id, scene = scene, slots = slots, pose = iani.create_pose(), effects = effects, animations = animations}
        return cache[hash]
    end
end

local igame_object = ecs.interface "igame_object"
--[[
init = {
    prefab, -- the relative path to the prefab file
    effect, -- the relative path to the effect file
    group_id, -- the group id of the hitch, used to cull the hitch
    state, -- "translucent", "opaque", "opacity"
    color,
    srt,
    parent, -- the parent of the hitch
    slot, -- the slot of the hitch
    animation_name,
    emissive_color,
    render_layer,
}
--]]
function igame_object.create(init)
    local children = __get_hitch_children(RESOURCES_BASE_PATH:format(init.prefab), init.state, init.color, init.animation_name, init.final_frame, init.emissive_color, init.render_layer, init.outline_scale)
    local hitch_events = {}
    hitch_events["group"] = function(_, e, group)
        w:extend(e, "hitch:update")
        e.hitch.group = group
    end
    hitch_events["slot_pose"] = function(_, e, pose)
        w:extend(e, "slot:in")
        e.slot.pose = pose
    end
    hitch_events["obj_motion"] = function(_, e, method, ...)
        iom[method](e, ...)
    end

    local policy = {
        "ant.general|name",
        "ant.scene|hitch_object",
    }
    if init.slot then
        policy[#policy+1] = "ant.animation|slot"
    end

    local hitch_entity_object = ientity_object.create(ecs.group(init.group_id):create_entity{
        policy = policy,
        data = {
            name = init.prefab, -- for debug
            scene = {
                s = init.srt.s,
                t = init.srt.t,
                r = init.srt.r,
                parent = init.parent,
            },
            hitch = {
                group = children.hitch_group_id,
            },
            slot = init.slot,
            scene_needchange = true,
        }
    }, hitch_events)

    local function remove(self)
        self.hitch_entity_object:remove()
    end

    local function update(self, prefab_file_name, state, color, animation_name, final_frame, emissive_color)
        children.instance:send("detach_hitch", hitch_entity_object.id)
        children = __get_hitch_children(RESOURCES_BASE_PATH:format(prefab_file_name), state, color, animation_name, final_frame, emissive_color)
        children.instance:send("attach_hitch", hitch_entity_object.id)

        self.hitch_entity_object:send("group", children.hitch_group_id)
        for _, slot_game_object in pairs(self.slot_attach) do
            slot_game_object.hitch_entity_object:send("slot_pose", children.pose)
        end
    end
    local function has_animation(self, animation_name)
        return children.animations[animation_name] ~= nil
    end
    local function attach(self, slot_name, model, state, color)
        local s = children.slots[slot_name]
        if not s then
            log.error(("game_object.attach: slot %s not found"):format(slot_name))
            return
        end
        local _slot = {}
        for k, v in pairs(s.slot) do
            _slot[k] = v
        end
        _slot.pose = children.pose

        -- TODO: create a new entity for hitch's parent
        -- slot.offset_srt is the offset of the slot when the slot is attached to the bone
        -- slot.scene is the offset of the slot when the slot not attached to the bone
        -- children.scene: offset of the parent
        self.slot_attach[slot_name] = igame_object.create {
            prefab = model,
            group_id = init.group_id,
            state = state or "opaque",
            color = color or COLOR_INVALID,
            srt = children.scene, -- TODO: slot scene
            parent = self.hitch_entity_object.id,
            slot = _slot,
        }
    end
    local function detach(self)
        for _, v in pairs(self.slot_attach) do
            v:remove()
        end
        self.slot_attach = {}
    end
    local function send(self, ...)
        self.hitch_entity_object:send(...)
    end

    -- special for hitch
    local effects = {}
    local efk_events = {}
    efk_events["play"] = function(o, e)
        if not iefk.is_playing(o.id) then
            iefk.play(o.id)
        end
    end
    efk_events["stop"] = function(o, e)
        if iefk.is_playing(o.id) then
            iefk.stop(o.id)
        end
    end

    for _, efkinfo in ipairs(children.effects) do
        effects[#effects + 1] = ientity_object.create(iefk.create(efkinfo.efk.path, {
            auto_play = efkinfo.efk.auto_play or false,
            loop = efkinfo.efk.loop or false,
            speed = efkinfo.efk.loop or 1.0,
            scene = {
                parent = hitch_entity_object.id
            }
        }), efk_events)
    end

    children.instance:send("attach_hitch", hitch_entity_object.id)

    local outer = {hitch_entity_object = hitch_entity_object, slot_attach = {}}
    outer.remove = remove
    outer.update = update
    outer.attach = attach
    outer.detach = detach
    outer.send   = send
    outer.has_animation = has_animation
    outer.on_work = function ()
        for _, o in ipairs(effects) do
            o:send("play")
        end
    end
    outer.on_idle = function ()
        for _, o in ipairs(effects) do
            o:send("stop")
        end
    end
    return outer
end
