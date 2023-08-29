local ecs = ...
local world = ecs.world
local w = world.w
local iefk = ecs.require "ant.efk|efk"
local game_object_event = ecs.require "engine.game_object_event"
local ientity_object = ecs.require "engine.system.entity_object_system"
local iani = ecs.require "ant.animation|controller.state_machine"
local iom = ecs.require "ant.objcontroller|obj_motion"
local prefabParser = require("engine.prefab_parser").parse
local irl = ecs.require "ant.render|render_layer"
local imodifier = ecs.require "ant.modifier|modifier"
local RENDER_LAYER <const> = ecs.require("engine.render_layer").RENDER_LAYER
local RESOURCES_BASE_PATH <const> = "/pkg/vaststars.resources/%s"

local function on_prefab_message(prefab, cmd, ...)
    local event = game_object_event[cmd]
    if event then
        event(prefab, ...)
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
    local color_hash = get_hash_func(0xf)
    local animation_name_hash = get_hash_func(0xff)
    local final_frame_hash = get_hash_func(0x1)
    local emissive_color_hash = get_hash_func(0xf)
    local render_layer_hash = get_hash_func(0xf)

    function __calc_param_hash(prefab, color, animation_name, final_frame, emissive_color, render_layer)
        local h1 = prefab_hash(prefab or 0) -- 8 bits
        local h2 = color_hash(color or 0) -- 4 bits
        local h3 = animation_name_hash(animation_name or 0) -- 8 bits
        local h4 = final_frame_hash(final_frame or 0) -- 1 bit
        local h5 = emissive_color_hash(emissive_color or 0) -- 4 bits
        local h6 = render_layer_hash(render_layer or 0) -- 4 bits
        return h1 | h2 << 8 | h3 << 12 | h4 << 16 | h5 << 24 | h6 << 25
    end
end

local __get_hitch_children ; do
    local cache = {}
    local hitch_group_id = 10000 -- see also: terrain.lua -> TERRAIN_MAX_GROUP_ID

    local function __cache_prefab_info(prefab)
        local effects = {auto_play = {}, work = {}, idle = {}, low_power = {}}
        local animations = {}

        for _, v in ipairs(prefabParser(prefab)) do
            if not v.data then
                goto continue
            end

            if v.data.efk then
                local efk = v.data.efk
                local t = {efk = efk, srt = v.data.scene}
                if v.data.efk.auto_play then
                    effects.auto_play[#effects.auto_play+1] = t
                elseif v.data.name:match("^work.*$") then
                    effects.work[#effects.work+1] = t
                elseif v.data.name:match("^idle.*$") then
                    effects.idle[#effects.idle+1] = t
                elseif v.data.name:match("^low_power.*$") then
                    effects.low_power[#effects.low_power+1] = t
                else
                    log.error("unknown efk", prefab, v.data.name)
                end
            elseif v.data.animation then
                for animation_name in pairs(v.data.animation) do
                    animations[animation_name] = true
                end
            end
            ::continue::
        end

        return effects, animations
    end

    function __get_hitch_children(prefab, color, animation_name, final_frame, emissive_color, render_layer)
        render_layer = render_layer or RENDER_LAYER.BUILDING
        local hash = __calc_param_hash(prefab, tostring(color), animation_name, final_frame, tostring(emissive_color), render_layer)
        if cache[hash] then
            return cache[hash]
        end

        hitch_group_id = hitch_group_id + 1
        local effects, animations = __cache_prefab_info(prefab)

        -- log.info(("game_object.new_instance: %s"):format(table.concat({hitch_group_id, prefab, require("math3d").tostring(color), tostring(animation_name), tostring(final_frame)}, " "))) -- TODO: remove this line
        local prefab_instance = world:create_instance(prefab, nil, hitch_group_id)
        function prefab_instance:on_ready()
            for _, eid in ipairs(self.tag["*"]) do
                local e <close> = world:entity(eid, "render_object?update")
                if render_layer and e.render_object then
                    irl.set_layer(e, render_layer)
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
            on_prefab_message(self, ...)
        end
        local prefab_proxy = world:create_object(prefab_instance)
        if color then
            prefab_proxy:send("material", "set_property", "u_basecolor_factor", color)
        end
        if emissive_color then
            prefab_proxy:send("material", "set_property", "u_emissive_factor", emissive_color)
        end

        cache[hash] = {prefab_file_name = prefab, instance = prefab_proxy, hitch_group_id = hitch_group_id, pose = iani.create_pose(), effects = effects, animations = animations}
        return cache[hash]
    end
end

local efk_events = {}
efk_events["play"] = function(o, e)
    if not iefk.is_playing(o.id) then
        iefk.play(o.id)
    end
end
efk_events["stop"] = function(o, e)
    if iefk.is_playing(o.id) then
        iefk.stop(o.id, true)
    end
end

local function __create_efk_object(efk, srt, parent, group_id, auto_play)
    return ientity_object.create(iefk.create(efk.path, {
        auto_play = auto_play,
        loop = efk.loop or false,
        speed = efk.speed or 1.0,
        scene = {
            parent = parent,
            s = srt.s,
            t = srt.t,
            r = srt.r,
        },
        group_id = group_id,
    }), efk_events)
end

local hitch_events = {}
hitch_events["group"] = function(_, e, group)
    w:extend(e, "hitch:update hitch_bounding?out")
    e.hitch.group = group
    e.hitch_bounding = true
end
hitch_events["obj_motion"] = function(_, e, method, ...)
    iom[method](e, ...)
end

local igame_object = {}
--[[
init = {
    prefab, -- the relative path to the prefab file
    group_id, -- the group id of the hitch, used to cull the hitch
    color,
    srt,
    parent, -- the parent of the hitch
    animation_name,
    emissive_color,
    render_layer,
}
--]]
function igame_object.create(init)
    local children = __get_hitch_children(RESOURCES_BASE_PATH:format(init.prefab), init.color, init.animation_name, init.final_frame, init.emissive_color, init.render_layer)
    local srt = init.srt or {}
    local hitch_entity_object = ientity_object.create(world:create_entity({
        policy = {
            "ant.general|name",
            "ant.render|hitch_object",
        },
        data = {
            name = init.prefab, -- for debug
            scene = {
                s = srt.s,
                t = srt.t,
                r = srt.r,
                parent = init.parent,
            },
            hitch = {
                group = children.hitch_group_id,
                hitch_bounding = true,
            },
            visible_state = "main_view|cast_shadow|selectable",
            scene_needchange = true,
        }
    }, init.group_id), hitch_events)

    local function remove(self)
        self.hitch_entity_object:remove()
    end

    -- prefab_file_name, color, animation_name, final_frame, emissive_color
    local function update(self, t)
        for k, v in pairs(t) do
            self.__cache[k] = v
        end

        if self.__cache.color == "null" then
            self.__cache.color = nil
        end
        if self.__cache.emissive_color == "null" then
            self.__cache.emissive_color = nil
        end

        children = __get_hitch_children(
            RESOURCES_BASE_PATH:format(self.__cache.prefab),
            self.__cache.color,
            self.__cache.animation_name,
            self.__cache.final_frame,
            self.__cache.emissive_color,
            self.__cache.render_layer
        )
        self.hitch_entity_object:send("group", children.hitch_group_id)
    end
    local function has_animation(self, animation_name)
        return children.animations[animation_name] ~= nil
    end
    local function send(self, ...)
        self.hitch_entity_object:send(...)
    end
    local function modifier(self, opt, ...)
        imodifier[opt](self.srt_modifier, ...)
    end

    -- special for hitch
    local effects = {auto_play = {}, work = {}, idle = {}, low_power = {}, keyevent = {}}
    for _, v in ipairs(children.effects.auto_play) do
        effects.auto_play[#effects.auto_play + 1] = __create_efk_object(v.efk, v.srt, hitch_entity_object.id, init.group_id, true)
    end
    for _, v in ipairs(children.effects.work) do
        effects.work[#effects.work + 1] = __create_efk_object(v.efk, v.srt, hitch_entity_object.id, init.group_id, false)
    end
    for _, v in ipairs(children.effects.idle) do
        effects.idle[#effects.idle + 1] = __create_efk_object(v.efk, v.srt, hitch_entity_object.id, init.group_id, false)
    end
    for _, v in ipairs(children.effects.low_power) do
        effects.low_power[#effects.low_power + 1] = __create_efk_object(v.efk, v.srt, hitch_entity_object.id, init.group_id, false)
    end

    local outer = {
        __cache = init,
        group_id = init.group_id,
        hitch_entity_object = hitch_entity_object,
        srt_modifier = imodifier.create_bone_modifier(
            hitch_entity_object.id,
            init.group_id,
            "/pkg/vaststars.resources/glbs/animation/Interact_build.glb|animation.prefab",
            "Bone"
        ),
    }
    outer.modifier = modifier
    outer.remove = remove
    outer.update = update
    outer.send   = send
    outer.has_animation = has_animation
    outer.on_work = function ()
        for _, o in ipairs(effects.idle) do
            o:send("stop")
        end
        for _, o in ipairs(effects.work) do
            o:send("play")
        end
    end
    outer.on_idle = function ()
        for _, o in ipairs(effects.work) do
            o:send("stop")
        end
        for _, o in ipairs(effects.idle) do
            o:send("play")
        end
    end
    return outer
end

return igame_object
