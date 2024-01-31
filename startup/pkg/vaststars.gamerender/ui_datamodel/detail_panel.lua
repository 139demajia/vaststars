local ecs, mailbox = ...
local world = ecs.world
local w = world.w

local UPS <const> = require("gameplay.interface.constant").UPS
local FLUIDBOXES <const> = ecs.require "gameplay.interface.constant".FLUIDBOXES
local STATUS_NO_POWER <const> = 1
local STATUS_IDLE <const> = 2
local STATUS_WORK <const> = 3
local STATUS_WAIT_INPUT <const> = 4
local STATUS_WAIT_OUTPUT <const> = 5
local STATUS_WAIT_OUTPUT2 <const> = 6
local STATUS_SHORT_OF_POWER <const> = 7
local STATUS_STACK_FULL <const> = 8
local STATUS_CHARGE <const> = 9
local STATUS_DISCHARGE <const> = 10
local STATUS_NO_ENERGY <const> = 11
local STATUS_STOP_DISCHARGE <const> = 12
local STATUS_POLE_OFFLINE <const> = 13
local STATUS_NO_RECIPE <const> = 14
local detail_panel_status = {
    {desc = "断电停机", icon = "/pkg/vaststars.resources/ui/textures/detail/stop.texture"},
    {desc = "待机空闲", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
    {desc = "正常工作", icon = "/pkg/vaststars.resources/ui/textures/detail/work.texture"},
    {desc = "等待供料", icon = "/pkg/vaststars.resources/ui/textures/detail/stop.texture"},
    {desc = "等待出货", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
    {desc = "无出货物流", icon = "/pkg/vaststars.resources/ui/textures/detail/stop.texture"},
    {desc = "供电不足", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
    {desc = "存货已满", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
    {desc = "正常充电", icon = "/pkg/vaststars.resources/ui/textures/detail/work.texture"},
    {desc = "正常供电", icon = "/pkg/vaststars.resources/ui/textures/detail/work.texture"},
    {desc = "电量耗尽", icon = "/pkg/vaststars.resources/ui/textures/detail/stop.texture"},
    {desc = "停止供电", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
    {desc = "脱网连接", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
    {desc = "无配方", icon = "/pkg/vaststars.resources/ui/textures/detail/idle.texture"},
}

local property_list = ecs.require "vaststars.prototype|property_list"
local objects = require "objects"
local iprototype = require "gameplay.interface.prototype"
local gameplay_core = require "gameplay.core"
local itypes = require "gameplay.interface.types"
local ilaboratory = require "gameplay.interface.laboratory"
local ichest = require "gameplay.interface.chest"
local building_detail = ecs.require "vaststars.prototype|building_detail_config"
local assembling_common = require "ui_datamodel.common.assembling"
local iui = ecs.require "engine.system.ui_system"
local itimer = ecs.require "utility.timer"

local timer

-- optimize for pole status
local power_statistic

local function format_vars(fmt, vars)
    return string.gsub(fmt, "%$([%w%._]+)%$", vars)
end

local function get_property_list(entity)
    local r = {}
    local prop_list = {}
    for property_name in pairs(entity) do
        local cfg = property_list[property_name]
        if not cfg then
            goto continue
        end

        local color = "#ffffff"
        if property_list.converter[property_name] then
            entity.values[property_name], color = property_list.converter[property_name](entity.values[property_name])
        end

        local t = {}
        t.icon = cfg.icon
        t.desc = cfg.desc
        t.value = cfg.value and format_vars(cfg.value, entity.values) or ""
        t.color = color
        t.pos = cfg.pos

        prop_list[#prop_list + 1] = t
        ::continue::
    end
    table.sort(prop_list, function(a, b) return a.pos < b.pos end)
    r.prop_list = prop_list
    r.chest_list_1 = entity.chest_list_1
    r.chest_list_2 = entity.chest_list_2
    r.chest_style = entity.chest_style
    r.status = entity.status
    return r
end

local function get_solar_panel_power(total)
    local gameplayWorld = gameplay_core.get_world()
    local t = gameplayWorld:now() % 25000
    if t <= 6250 or t > 18750 then
        return total
    elseif t <= 11250  then
        return -total/5000 * t + total * (1 + 6250/5000)
    elseif t <= 13750 then
        return 0
    elseif t <= 18750 then
        return total/5000 * t - total * (6250 + 7500) / 5000
    end
end

local next_unit = { k = "M", M = "G" }
local function get_display_info(e, typeobject, t)
    local key = string.match(typeobject.name, "([^%u%d]+)")
    local tname = key and key or typeobject.name
    local detail = building_detail[tname]
    if not detail then
        return
    end
    local values = t.values
    local status = STATUS_WORK
    for _, propertyName in ipairs(detail) do
        local cfg = property_list[propertyName]
        if cfg.value then
            local cn, vn = string.match(cfg.value, "%$([%w_]*)%.?([%w_]*)%$")
            local total
            local key = cn
            if #vn > 0 then
                total = e[cn][vn]
                key = cn.. "." .. vn
            else
                total = typeobject[cn]
                if cn == "power" or cn == "capacitance" or cn == "charge_power" then
                    local current = 0
                    if cn == "power" or cn == "charge_power" then
                        local st = power_statistic--global.statistic["power"][e.eid]
                        if e.solar_panel then
                            current = get_solar_panel_power(total) * UPS
                            status = (e.solar_panel.efficiency > 0 and STATUS_DISCHARGE or STATUS_STOP_DISCHARGE)
                        elseif st then
                            -- power is sum of 50 tick
                            current = st["power"] * UPS
                            if st.power_count ~= 0 then
                                current = current / st.power_count
                            end
                            if typeobject.name == "蓄电池I" then
                                if (cn == "charge_power" and e.capacitance.delta > 0) or (cn == "power" and e.capacitance.delta < 0) then
                                    current = 0
                                end
                                if e.capacitance.delta > 0 then
                                    status = STATUS_DISCHARGE
                                elseif e.capacitance.delta < 0 then
                                    status = STATUS_CHARGE
                                elseif e.capacitance.shortage > 0 then
                                    status = STATUS_NO_ENERGY
                                else
                                    status = STATUS_STOP_DISCHARGE
                                end
                            end
                        end
                        if typeobject.drain then
                            if current <= 0 then
                                status = STATUS_NO_POWER
                            elseif current <= typeobject.drain * UPS then
                                status = STATUS_IDLE
                            elseif st.no_power_count > 25 then
                                status = STATUS_SHORT_OF_POWER
                            end
                        end
                        total = total * UPS
                    elseif cn == "capacitance" then
                        current = total - e.capacitance.shortage
                    end
                    local function power_format(value, eu)
                        local unit = "k"
                        local divisor = 1000
                        if value >= 999999990 then
                            divisor = 1000000000
                            unit = "G"
                        elseif value >= 999990 then
                            divisor = 1000000
                            unit = "M"
                        end
                        value = value / divisor
                        local clamp_value = math.floor(value + 0.05)
                        if clamp_value == 1000 then
                            clamp_value = 1
                            unit = next_unit[unit]
                        end
                        return string.format("%d", clamp_value) .. unit .. eu
                    end
                    local eu = (cn == "capacitance") and "J" or "W"
                    total = power_format(current, eu) .. "/" .. power_format(total, eu)
                elseif cn == "speed" then
                    total = e.assembling.speed
                end
            end
            if cn == "speed" or vn == "speed" then
                total = string.format("%d%%", math.floor(total))
            end
            values[key] = total
        end
        t[propertyName] = cfg
    end
    t.status = status
end

local function getChestSlots(gameplay_world, chest, max_slot, res, show_zero_count)
    for i = 1, max_slot do
        local slot = ichest.get(gameplay_world, chest, i)
        if not slot then
            break
        end

        local show = false
        if show_zero_count then
            show = slot.item ~= 0
        else
            show = slot.item ~= 0 and slot.amount > 0
        end

        if show then
            local typeobject_item = assert(iprototype.queryById(slot.item))
            res[#res + 1] = {slot_index = i, icon = typeobject_item.item_icon, name = typeobject_item.name, count = ichest.get_amount(slot), max_count = slot.limit, type = slot.type}
        end
    end
    return res
end

local function processStationSlots(max_slot, items)
    table.sort(items, function(a, b)
        local v1 = a.type == "supply" and 0 or 1
        local v2 = b.type == "supply" and 0 or 1
        return v1 == v2 and a.slot_index < b.slot_index or v1 < v2
    end)
    for i = 1, max_slot - #items do
        items[#items + 1] = {slot_index = i, icon = "", name = "", count = 0, max_count = 0, type = "none"}
    end
    return items
end

local function get_property(e, typeobject)
    local t = {
        values = {}
    }
    -- 显示建筑详细信息
    get_display_info(e, typeobject, t)
    local gameplay_world = gameplay_core.get_world()
    if e.chest then
        t.chest_style = typeobject.chest_style or "chest"
        local max_slot = ichest.get_max_slot(typeobject)

        if e.station then
            t.chest_list_1 = {}
            t.chest_list_1 = getChestSlots(gameplay_world, e.station, max_slot, t.chest_list_1, true)
            t.chest_list_1 = processStationSlots(max_slot, t.chest_list_1)

            t.chest_list_2 = {}
            t.chest_list_2 = getChestSlots(gameplay_world, e.chest, max_slot, t.chest_list_2, true)
            t.chest_list_2 = processStationSlots(max_slot, t.chest_list_2)
        elseif e.depot then
            t.chest_list_1 = {}
            t.chest_list_1 = getChestSlots(gameplay_world, e.chest, max_slot, t.chest_list_1, true)
        else
            t.chest_list_1 = {}
            t.chest_list_1 = getChestSlots(gameplay_world, e.chest, max_slot, t.chest_list_1)
        end
    end
    if e.fluidbox then
        local name = "无"
        local volume = 0
        local capacity = 0
        local flow = 0
        if e.fluidbox.fluid ~= 0 then
            local pt = iprototype.queryById(e.fluidbox.fluid)
            name = pt.name

            if e.fluidbox.id ~= 0 then
                local r = gameplay_core.fluidflow_query(e.fluidbox.fluid, e.fluidbox.id)
                if r then
                    volume = r.volume / r.multiple
                    capacity = math.floor(r.capacity / r.multiple)
                    flow = r.flow / r.multiple
                end
            end
        end
        t.values.fluid_name = name
        t.values.fluid_volume = volume
        t.values.fluid_capacity = capacity
        t.values.fluid_flow = flow
    end

    if e.fluidboxes then
        local function add_property(t, key, value)
            if value == 0 then
                return t
            end
            t.values[key] = value
            return t
        end

        for _, v in ipairs(FLUIDBOXES) do
            local fluid = e.fluidboxes[v.fluid]
            local id = e.fluidboxes[v.id]
            if fluid ~= 0 and id ~= 0 then
                local f = gameplay_core.fluidflow_query(fluid, id)
                if f then
                    if v.name == "out1" then
                        local pt = iprototype.queryById(fluid)
                        -- only show out1 detail
                        add_property(t, "fluid_name", pt.name)
                        add_property(t, "fluid_volume", f.volume / f.multiple)
                        add_property(t, "fluid_capacity", math.floor(f.capacity / f.multiple))
                    end
                    add_property(t, "fluidboxes_" .. v.name .. "_volume", f.volume / f.multiple)
                    add_property(t, "fluidboxes_" .. v.name .. "_capacity", math.floor(f.capacity / f.multiple))
                    add_property(t, "fluidboxes_" .. v.name .. "_flow", f.flow / f.multiple)

                    local cfg = typeobject.fluidboxes[v.classify][v.index]

                    add_property(t, "fluidboxes_" .. v.name .. "_base_level", cfg.base_level)
                    add_property(t, "fluidboxes_" .. v.name .. "_height", cfg.height)
                end
            end
        end
    end
    if e.airport then
        local typeobject = iprototype.queryById(e.building.prototype)
        t.values['drone_count'] = #typeobject.drone
    end
    return t
end

local function get_entity_property_list(object_id, recipe_inputs, recipe_ouputs)
    local object = assert(objects:get(object_id))
    local e = gameplay_core.get_entity(assert(object.gameplay_eid))
    if not e then
        return {}
    end

    local typeobject = iprototype.queryByName(object.prototype_name)

    local entity = get_property(e, typeobject)
    local prolist = get_property_list(entity)
    if e.assembling then
        local total_progress = 0
        local progress = 0
        if e.assembling.recipe ~= 0 then
            local recipe_typeobject = assert(iprototype.queryById(e.assembling.recipe))
            total_progress = recipe_typeobject.time * 100
            progress = e.assembling.progress
            prolist.recipe_name = recipe_typeobject.name
            if recipe_inputs and recipe_ouputs then
                prolist.recipe_inputs, prolist.recipe_ouputs = recipe_inputs, recipe_ouputs
            else
                prolist.recipe_inputs, prolist.recipe_ouputs = assembling_common.get(gameplay_core.get_world(), e)
            end
            if e.assembling.status == 0 then -- c status : idle
                prolist.progress = "0%"
            else
                prolist.progress = itypes.progress_str(progress, total_progress)
            end
            if e.mining then
                prolist.chest_style = "minner"
            else
                prolist.chest_style = "assemble"
            end
        end
    elseif e.laboratory then
        local current_inputs = ilaboratory:get_elements(typeobject.inputs)
        local items = {}
        for i, value in ipairs(current_inputs) do
            local slot = ichest.get(gameplay_core.get_world(), e.chest, i)
            assert(slot and slot.item ~= 0)
            items[#items+1] = {icon = value.icon, name = value.name, count = slot and slot.amount or 0, demand_count = slot and slot.limit or 0}
        end
        prolist.chest_list_1 = items
    end

    --modify status
    if prolist.status ~= STATUS_NO_POWER then
        if e.assembling then
            local status
            if e.assembling.recipe == 0 then
                status = STATUS_NO_RECIPE
            else
                if e.assembling.progress <= 0 then
                    if e.assembling.status == 0 then
                        status = STATUS_WAIT_INPUT
                    elseif e.assembling.status == 1 then
                        status = STATUS_WAIT_OUTPUT
                    end
                end
            end
            if status then
                prolist.status = status
            end
        elseif e.chest then
            local full = true
            for i = 1, ichest.get_max_slot(typeobject) do
                local slot = ichest.get(gameplay_core.get_world(), e.chest, i)
                if not slot then
                    break
                end
                if slot.item ~= 0 and slot.amount < slot.limit then
                    full = false
                    break
                end
            end

            if e.laboratory then
                if not full then
                    prolist.status = STATUS_WAIT_INPUT
                end
            else
                if full then
                    prolist.status = STATUS_STACK_FULL
                end
            end
        end
    end
    if e.chimney then
        if e.chimney.recipe == 0 then
            prolist.status = STATUS_NO_RECIPE
        else
            local r = gameplay_core.fluidflow_query(e.fluidbox.fluid, e.fluidbox.id)
            prolist.status = (r and r.volume > 0) and STATUS_WORK or STATUS_WAIT_INPUT
        end
    end
    return prolist
end

---------------
local M = {}
local update_interval = 3 --update per 25 frame
local counter = 1
local function update_property_list(datamodel, property_list)
    datamodel.chest_list_1 = property_list.chest_list_1 or {}
    datamodel.chest_list_2 = property_list.chest_list_2 or {}
    datamodel.chest_style = property_list.chest_style
    datamodel.progress = property_list.progress or "0%"
    datamodel.recipe_inputs = property_list.recipe_inputs or {}
    datamodel.recipe_ouputs = property_list.recipe_ouputs or {}
    datamodel.recipe_name = property_list.recipe_name
    local status = property_list.status or STATUS_WORK
    datamodel.detail_panel_status_icon = detail_panel_status[status].icon
    datamodel.detail_panel_status_desc = detail_panel_status[status].desc
    datamodel.property_list = property_list.prop_list
    return property_list.recipe_inputs, property_list.recipe_ouputs
end

local _update_model ; do
    local math3d = require "math3d"
    local ltask = require "ltask"
    local timepassed = 0.0
    local delta_radian = math.pi * 0.02
    local itimer = ecs.require "ant.timer|timer_system"
    function _update_model(name)
        timepassed = timepassed + itimer.delta()
        local cur_time = timepassed * 0.001
        local cur_radian = delta_radian * cur_time
        local rotation = math3d.quaternion {axis=math3d.vector{0, 1, 0}, r=math.pi * cur_radian}
        ltask.call(ltask.self(), "render_portrait_prefab", name, math3d.serialize(rotation))
    end
end

local last_inputs, last_ouputs
local preinput

function M.create(object_id)
    iui.register_leave("/pkg/vaststars.resources/ui/detail_panel.html")

    counter = update_interval
    local object = assert(objects:get(object_id))
    local e = gameplay_core.get_entity(assert(object.gameplay_eid))
    if not e then
        return {}
    end
    local typeobject = iprototype.queryByName(object.prototype_name)
    local datamodel = {
        object_id = object_id,
        icon = typeobject.icon,
        desc = typeobject.item_description,
        prototype_name = iprototype.display_name(typeobject),
        model = "mem:" .. typeobject.model .. " config:d,1,4,1.2",
        areaid = 0
    }
    last_inputs, last_ouputs = update_property_list(datamodel, get_entity_property_list(object_id))
    preinput = {}
    power_statistic = {
        tail = 1,
        head = 1,
        frames = {},
        drain = 0,
        power = 0,
        state = 0,
        no_power_count = 0,
        power_count = 0
    }

    timer = itimer.new()
    timer:interval(3, function ()
        _update_model(datamodel.model)
    end)
    return datamodel
end

local function get_delta(last, current, input)
    local delta = {}
    local autodirty = false
    local dirty = false
    for index, value in ipairs(current) do
        local d = (last and last[index]) and (value.count - last[index].count) or value.count
        if input then
            if d < 0 and not autodirty then
                autodirty = true
            end
        else
            if d > 0 and not autodirty then
                autodirty = true
            end
        end
        if d ~= 0 and not dirty then
            dirty = true
        end
        delta[index] = d
    end
    return autodirty, dirty, delta
end

local frame_period = 51
local function step_frame_head(st)
    if st.max_index then
        if st.frames[st.max_index].power < st.frames[st.head].power then
            st.max_index = st.head
        end
    end
    if st.head <= #st.frames and st.frames[st.head].power == 0 then
        st.no_power_count = st.no_power_count + 1
    end
    st.head = (st.head >= frame_period) and 1 or st.head + 1
    st.power_count = st.power_count + 1
    if st.head == st.tail then
        local fp = st.frames[st.tail]
        if fp then
            if st.tail <= #st.frames and st.frames[st.tail].power == 0 then
                st.no_power_count = st.no_power_count - 1
            end
            st.power = st.power - fp.power
            fp.power = 0
            if st.max_index and st.max_index == st.tail then
                st.max_index = 1
                for index, frame in ipairs(st.frames) do
                    if st.frames[st.max_index].power < frame.power then
                        st.max_index = index
                    end
                end
            end
            st.tail = (st.tail >= frame_period) and 1 or st.tail + 1
            st.power_count = st.power_count - 1
        end
    end
end
local function update_power(power)
    local st = power_statistic
    local frame_power = math.abs(power)
    st.power = st.power + frame_power
    if not st.frames[st.head] then
        st.frames[st.head] = {power = frame_power}
    else
        st.frames[st.head].power = st.frames[st.head].power + frame_power
    end
    step_frame_head(st)
end

function M.update(datamodel, object_id)
    timer:update()

    local object = assert(objects:get(object_id))
    local e = gameplay_core.get_entity(assert(object.gameplay_eid))
    if e.capacitance then
        update_power(e.capacitance.delta)
    end

    local current_inputs, current_ouputs
    if e.assembling and e.assembling.recipe ~= 0 then
        current_inputs, current_ouputs = assembling_common.get(gameplay_core.get_world(), e)
        local input_auto, input_dirty, input_delta = get_delta(last_inputs, current_inputs, true)
        local out_auto, output_dirty, _ = get_delta(last_ouputs, current_ouputs)
        -- if input_auto then
        --     preinput = copy_table(last_inputs)
        -- elseif out_auto then
        --     preinput = {}
        -- end
        if #preinput > 0 and not input_auto then
            for index, input in ipairs(preinput) do
                input.count = input.count + (input_delta[index] or 0)
            end
        end
        last_inputs, last_ouputs = current_inputs, current_ouputs
        if input_dirty or output_dirty then
            counter = 1
            update_property_list(datamodel, get_entity_property_list(object_id, (#preinput > 0) and preinput or current_inputs, current_ouputs))
            return
        end
    end
    counter = counter + 1
    if counter < update_interval then
        return
    end
    counter = 1
    update_property_list(datamodel, get_entity_property_list(object_id, (#preinput > 0) and preinput or current_inputs, current_ouputs))
end

return M