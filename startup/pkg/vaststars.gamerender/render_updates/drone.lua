local ecs = ...
local world = ecs.world
local w = world.w
local math3d    = require "math3d"
local mc = import_package "ant.math".constant
local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
local objects = require "objects"
local ims = ecs.import.interface "ant.motion_sampler|imotion_sampler"
local ltween = require "motion.tween"
local entity_remove = world:sub {"gameplay", "remove_entity"}
local imotion = ecs.require "imotion"
local drone_sys = ecs.system "drone_system"
local gameplay_core = require "gameplay.core"
local global = require "global"
local terrain = ecs.require "terrain"

-- enum defined in c 
local STATUS_HAS_ERROR = 1
local BERTH_HUB = 0
local BERTH_RED = 1
local BERTH_BLUE = 2
local BERTH_HOME = 3
local drone_depot = {}
local lookup_drones = {}
local drone_offset = 6
local fly_height = 20
local item_height = 15
local function create_drone(homepos)
    local task = {
        running = false,
        duration = 0,
        elapsed_time = 0,
        to_home = false,
        process = 0,
        flyid = 0,
        gohome = function (self, flyid, from, to)
            if self.to_home then return end
            self:flyto(flyid, fly_height, from, to, true, 1.0)
            self.to_home = true
            -- print("----gohome----", math3d.index(to, 1, 2, 3))
        end,
        flyto = function (self, flyid, height, from, to, home, duration)
            self.flyid = flyid
            if self.to_home and not home then
                local exz <close> = w:entity(self.motion_xz)
                local xzpos = iom.get_position(exz)
                local ey <close> = w:entity(self.motion_y)
                local xpos = iom.get_position(ey)
                from = math3d.vector {math3d.index(xzpos, 1), math3d.index(xpos, 2), math3d.index(xzpos, 3)}
                self.to_home = false
                ims.set_duration(exz, -1)
                ims.set_duration(ey, -1)
            end
            -- print("----flyto----", home, from[1], from[2], from[3], to[1], to[2], to[3])
            local exz <close> = w:entity(self.motion_xz)
            ims.set_tween(exz, ltween.type("Sine"), ltween.type("Sine"))
            ims.set_keyframes(exz,
                {t = math3d.set_index(from, 2, 0), step = 0.0},
                {t = math3d.set_index(to, 2, 0),  step = 1.0}
            )
            local ey <close> = w:entity(self.motion_y)
            ims.set_tween(ey, ltween.type("Quartic"), ltween.type("Quartic"))
            -- print("----height----", home, from[2], height, to[2])
            ims.set_keyframes(ey,
                {t = math3d.vector({0, math3d.index(from, 2), 0}), step = 0.0},
                {t = math3d.vector({0, height, 0}), step = 0.1},
                {t = math3d.vector({0, height, 0}), step = 0.9},
                {t = math3d.vector({0, math3d.index(to, 2), 0}),  step = 1.0}
            )
            if home then
                self.duration = duration
                local ms = duration * 1000
                ims.set_duration(exz, ms)
                ims.set_duration(ey, ms)
            else
                ims.set_ratio(exz, 0)
                ims.set_ratio(ey, 0)
            end
            self.running = true
        end,
        update = function (self, step)
            if not self.running then
                return
            end
            local finished = false
            if self.to_home then
                --TODO: update framerate is 30
                local elapsed_time = 1.0 / 30
                self.elapsed_time = self.elapsed_time + elapsed_time
                if self.elapsed_time >= self.duration then
                    finished = true
                end
            else
                -- print("----update----", step)
                local exz <close> = w:entity(self.motion_xz)
                ims.set_ratio(exz, step)
                local ey <close> = w:entity(self.motion_y)
                ims.set_ratio(ey, step)
                if step >= 1.0 then
                    finished = true
                end
            end
            
            if finished then
                self.running = false
                self.elapsed_time = 0
                local exz <close> = w:entity(self.motion_xz)
                ims.set_duration(exz, -1)
                local ey <close> = w:entity(self.motion_y)
                ims.set_duration(ey, -1)
                if self.item then
                    for _, eid in ipairs(self.item.tag["*"]) do
                        w:remove(eid)
                    end
                    self.item = nil
                end
            end
        end,
        destroy = function (self)
            for _, eid in ipairs(self.prefab.tag["*"]) do
                w:remove(eid)
            end
            w:remove(self.motion_y)
            w:remove(self.motion_xz)
        end,
    }
    task.current_pos = homepos
    local motion_xz = imotion.create_motion_object(nil, nil, math3d.set_index(homepos, 2, 0))
    task.motion_xz = motion_xz
    local motion_y = imotion.create_motion_object(nil, nil, math3d.vector(0, math3d.index(homepos, 2), 0), motion_xz)
    task.motion_y = motion_y
    task.prefab = imotion.sampler_group:create_instance("/pkg/vaststars.resources/prefabs/drone.prefab", motion_y)
    return task
end

local function get_berth(lacation)
    return (lacation >> 5) & 0x03
end

local function create_item(item, parent)
    local prefab = imotion.sampler_group:create_instance("/pkg/vaststars.resources/prefabs/rock.prefab", parent)
    prefab.on_init = function(inst) end
    prefab.on_ready = function(inst)
        local e <close> = w:entity(inst.tag["*"][1])
        iom.set_position(e, math3d.vector{0, -2.0, 0})
    end
    prefab.on_message = function(inst, ...) end
    world:create_object(prefab)
    return prefab
end

local function get_home_pos(pos)
    return math3d.add(math3d.set_index(pos, 2, 0), {6, 8, -6})
end

local function remove_drone(eid)
    if lookup_drones[eid] then
        lookup_drones[eid]:destroy()
        lookup_drones[eid] = nil
    end
end

local function __get_position(location)
    local x, y = ((location >> 23) & 0x1FF) // 2, ((location >> 14) & 0x1FF) // 2
    local object = objects:coord(x, y)
    if not object then
        return math3d.vector(terrain:get_position_by_coord(x, y, 1, 1))
    end

    local idx = (location >> 7) & 0xF

    local building = global.buildings[object.id]
    if not building then
        return math3d.set_index(object.srt.t, 2, item_height)
    end
    local io_shelves = building.io_shelves
    if not io_shelves then
        return math3d.set_index(object.srt.t, 2, item_height)
    end
    return io_shelves:get_heap_position(idx+1)
end

function drone_sys:gameworld_update()
    local gameworld = gameplay_core.get_world()
    local same_dest_offset = {}
    local drone_task = {}
    for e in gameworld.ecs:select "drone:in eid:in" do
        local drone = e.drone
        assert(drone.prev ~= 0, "drone.prev == 0")
        -- if (drone.prev ~= 0) and (drone.next ~= 0) and (drone.maxprogress ~= 0) and (drone.progress ~= 0) then
        --     print(drone.status, drone.prev, drone.next, drone.maxprogress, drone.progress, drone.item)
        -- end
        if drone.status == STATUS_HAS_ERROR then
            if lookup_drones[e.eid] then
                remove_drone(e.eid)
            end
            goto continue
        end
        if not lookup_drones[e.eid] then
            lookup_drones[e.eid] = create_drone(get_home_pos(__get_position(drone.prev)))
        else
            local current = lookup_drones[e.eid]
            local flyid = drone.prev << 32 | drone.next
            if current.flyid ~= flyid or current.to_home then
                if drone.maxprogress > 0 then
                    if not same_dest_offset[flyid] then
                        same_dest_offset[flyid] = 0
                    else
                        same_dest_offset[flyid] = same_dest_offset[flyid] - (drone_offset / 2)
                    end

                    local from = __get_position(drone.prev)
                    local to = __get_position(drone.next)

                    -- status : go_home
                    --print("berth1:", e.eid, drone.maxprogress, drone.prev, drone.next, drone.progress)
                    if get_berth(drone.next) == BERTH_HOME then
                        current:gohome(flyid, from, get_home_pos(to))
                    else
                        drone_task[#drone_task + 1] = {flyid, current, from, to}
                    end
                elseif get_berth(drone.prev) == BERTH_HOME and not current.to_home then
                    -- status : to_home
                    local dst = __get_position(drone.prev)
                    -- print("berth2:", get_berth(drone.prev), get_berth(drone.next))
                    current:gohome(flyid, math3d.set_index(dst, 2, item_height), get_home_pos(dst))
                end
            else
                current:update(drone.maxprogress > 0 and (drone.maxprogress - drone.progress) / drone.maxprogress or 0)
            end
        end
        ::continue::
    end
    for _, task in ipairs(drone_task) do
        local flyid = task[1]
        local to = math3d.add(task[4], {same_dest_offset[flyid], 0, 0})
        task[2]:flyto(flyid, fly_height, task[3], to, false)
        same_dest_offset[flyid] = same_dest_offset[flyid] + drone_offset
    end
end

function drone_sys:gameworld_clean()
    for _, drone in pairs(lookup_drones) do
        drone:destroy()
    end
    lookup_drones = {}
end