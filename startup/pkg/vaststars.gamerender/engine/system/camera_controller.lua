local ecs = ...
local world = ecs.world
local w = world.w

local iom = ecs.require "ant.objcontroller|obj_motion"
local math3d = require "math3d"
local mathpkg = import_package "ant.math"
local mu, mc = mathpkg.util, mathpkg.constant
local irq = ecs.require "ant.render|render_system.renderqueue"
local ic = ecs.require "ant.camera|camera"
local create_queue = require("utility.queue")
local hierarchy = require "hierarchy"
local animation = hierarchy.animation
local skeleton = hierarchy.skeleton
local math_max = math.max
local math_min = math.min

local MOVE_SPEED <const> = 8.0

local YAXIS_PLANE <const> = math3d.constant("v4", {0, 1, 0, 0})
local PLANES <const> = {YAXIS_PLANE}

local camera_controller = ecs.system "camera_controller"
local icamera_controller = {}

local ui_message_move_camera_mb = world:sub {"ui_message", "move_camera"}
local gesture_pinch = world:sub {"gesture", "pinch"}
local gesture_pan = world:sub {"gesture", "pan"}
local game_camera_lock_mb = world:sub {"game_camera", "lock"}
local game_camera_unlock_mb = world:sub {"game_camera", "unlock"}

local datalist = require "datalist"
local fs = require "filesystem"
local CAMERA_DEFAULT = datalist.parse(fs.open(fs.path("/pkg/vaststars.resources/camera_default.prefab")):read "a")[1].data.scene
local CAMERA_CONSTRUCT = datalist.parse(fs.open(fs.path("/pkg/vaststars.resources/camera_construct.prefab")):read "a")[1].data.scene

local CAMERA_DEFAULT_SCALE    = CAMERA_DEFAULT.s and math3d.constant("v4", CAMERA_DEFAULT.s)or mc.ONE
local CAMERA_DEFAULT_ROTATION = CAMERA_DEFAULT.r and math3d.constant("quat", CAMERA_DEFAULT.r) or mc.IDENTITY_QUAT
local CAMERA_DEFAULT_POSITION = CAMERA_DEFAULT.t and math3d.constant("v4", CAMERA_DEFAULT.t) or mc.ZERO_PT

local CAMERA_CONSTRUCT_SCALE    = CAMERA_CONSTRUCT.s and math3d.constant("v4", CAMERA_CONSTRUCT.s) or mc.ONE
local CAMERA_CONSTRUCT_ROTATION = CAMERA_CONSTRUCT.r and math3d.constant("quat", CAMERA_CONSTRUCT.r) or mc.IDENTITY_QUAT
local CAMERA_CONSTRUCT_POSITION = CAMERA_CONSTRUCT.t and math3d.constant("v4", CAMERA_CONSTRUCT.t) or mc.ZERO_PT

local CAMERA_DELTA_Z <const> = math3d.index(math3d.sub(CAMERA_CONSTRUCT_POSITION, CAMERA_DEFAULT_POSITION), 3)

local CAMERA_DEFAULT_YAIXS <const> = CAMERA_DEFAULT.t[2]
local CAMERA_YAIXS_MIN <const> = CAMERA_DEFAULT_YAIXS - 280
local CAMERA_YAIXS_MAX <const> = CAMERA_DEFAULT_YAIXS + 150

local CAMERA_XAIXS_MIN <const> = -1000
local CAMERA_XAIXS_MAX <const> = 1000
local CAMERA_ZAIXS_MIN <const> = -1450
local CAMERA_ZAIXS_MAX <const> = 800

local cam_cmd_queue = create_queue()
local cam_motion_matrix_queue = create_queue()

local function __clamp(v, min, max)
    return math_max(min, math_min(v, max))
end

local function zoom(factor, x, y)
    local ce <close> = world:entity(irq.main_camera())

    local pos = iom.get_position(ce)
    local target = icamera_controller.screen_to_world(x, y, PLANES)[1]
    local dir = math3d.normalize(math3d.sub(target, pos))
    local pos = math3d.muladd(dir, factor * MOVE_SPEED, pos)

    local y = math3d.index(pos, 2)
    if y >= CAMERA_YAIXS_MIN and y <= CAMERA_YAIXS_MAX then
        pos = math3d.set_index(pos, 1, __clamp(math3d.index(pos, 1), CAMERA_XAIXS_MIN, CAMERA_XAIXS_MAX))
        pos = math3d.set_index(pos, 3, __clamp(math3d.index(pos, 3), CAMERA_ZAIXS_MIN, CAMERA_ZAIXS_MAX))
        iom.set_position(ce, pos)
        world:pub {"camera_zoom"}
    end
end

local function focus_on_position(position)
    local ce <close> = world:entity(irq.main_camera())
    local p = icamera_controller.get_central_position()
    local delta = math3d.set_index(math3d.sub(position, p), 2, 0) -- the camera is always moving in the x/z axis and the y axis is always 0
    return iom.get_scale(ce), iom.get_rotation(ce), math3d.add(iom.get_position(ce), delta)
end

local function toggle_view(v)
    local ce <close> = world:entity(irq.main_camera())

    -- using the properties of similar triangles to calculate the position of the z-axis
    if v == "construct" then
        local position = iom.get_position(ce)
        local z = CAMERA_DELTA_Z * (math3d.index(position, 2) / math3d.index(CAMERA_DEFAULT_POSITION, 2))
        local position = math3d.add(iom.get_position(ce), math3d.vector(0, 0, z))
        return CAMERA_CONSTRUCT_SCALE, CAMERA_CONSTRUCT_ROTATION, position
    else
        local position = iom.get_position(ce)
        local z = -CAMERA_DELTA_Z * (math3d.index(position, 2) / math3d.index(CAMERA_DEFAULT_POSITION, 2))
        local position = math3d.add(iom.get_position(ce), math3d.vector(0, 0, z))
        return CAMERA_DEFAULT_SCALE, CAMERA_DEFAULT_ROTATION, position
    end
end

local function __set_camera_from_prefab(prefab)
    local data = datalist.parse(fs.open(fs.path("/pkg/vaststars.resources/" .. prefab)):read "a")
    if not data then
        return
    end
    assert(data[1] and data[1].data and data[1].data.camera)
    local c = data[1].data

    local ce <close> = world:entity(irq.main_camera())
    iom.set_srt(ce, c.scene.s or mc.ONE, c.scene.r, c.scene.t)
    ic.set_frustum(ce, c.camera.frustum)
end

local function __set_camera_srt(s, r, t)
    local ce <close> = world:entity(irq.main_camera())
    iom.set_srt(ce, s, r, t)
end

local function __check_camera_editable()
    return cam_cmd_queue:size() <= 0 and cam_motion_matrix_queue:size() <= 0
end

local function __add_camera_track(s, r, t)
    local raw_animation = animation.new_raw_animation()
    local skl = skeleton.build({{name = "root", s = mc.T_ONE, r = mc.T_IDENTITY_QUAT, t = mc.T_ZERO}})
    raw_animation:setup(skl, 2)

    local ce <close> = world:entity(irq.main_camera())

    raw_animation:push_prekey(
        "root",
        0,
        iom.get_scale(ce),
        iom.get_rotation(ce),
        iom.get_position(ce)
    )

    raw_animation:push_prekey(
        "root",
        1,
        s,
        r,
        t
    )

    local ani = raw_animation:build()
    local poseresult = animation.new_pose_result(#skl)
    poseresult:setup(skl)

    local ratio = 0
    local step = 2 / 30

    while ratio <= 1.0 do
        poseresult:do_sample(animation.new_sampling_context(1), ani, ratio, 0)
        poseresult:fetch_result()
        cam_motion_matrix_queue:push( math3d.ref(poseresult:joint(1)) )
        ratio = ratio + step
    end
end

local function __handle_camera_motion()
    if cam_motion_matrix_queue:size() == 0 then
        if cam_cmd_queue:size() == 0 then
            return
        end

        local cmd = assert(cam_cmd_queue:pop())
        local c = cmd[1]
        if c[1] == "focus_on_position" then
            __add_camera_track(focus_on_position(table.unpack(c, 2)))
        elseif c[1] == "toggle_view" then
            __add_camera_track(toggle_view(table.unpack(c, 2)))
        elseif c[1] == "callback" then
            c[2]()
        elseif c[1] == "set_camera_from_prefab" then
            __set_camera_from_prefab(c[2])
        elseif c[1] == "set_camera_srt" then
            __set_camera_srt(c[2], c[3], c[4])
        else
            assert(false)
        end
    end

    if cam_motion_matrix_queue:size() > 0 then
        local mat = cam_motion_matrix_queue:pop()
        if mat then
            local ce <close> = world:entity(irq.main_camera())
            iom.set_srt(ce, math3d.srt(mat))
            world:pub {"dragdrop_camera"}
        end
    end
end

local __handle_drop_camera; do
    local starting = math3d.ref()
    local lock

    function __handle_drop_camera(ce)
        for _, _, axis in game_camera_lock_mb:unpack() do
            lock = axis
        end

        for _ in game_camera_unlock_mb:unpack() do
            lock = nil
        end

        local ending_x, ending_y
        for _, _, e in gesture_pan:unpack() do
            if __check_camera_editable() then
                if e.state == "began" then
                    starting.v = icamera_controller.screen_to_world(e.x, e.y, PLANES)[1]
                else
                    ending_x, ending_y = e.x, e.y
                end
            end
        end

        if starting and ending_x and ending_y then
            w:extend(ce, "scene:in")
            local scene = ce.scene

            local ending = icamera_controller.screen_to_world(ending_x, ending_y, PLANES)[1]
            local delta_vec = math3d.sub(starting, ending)
            local pos = math3d.add(scene.t, delta_vec)

            if lock then
                if lock == "x-axis" then
                    pos = math3d.set_index(pos, 1, math3d.index(scene.t, 1))
                elseif lock == "z-axis" then
                    pos = math3d.set_index(pos, 3, math3d.index(scene.t, 3))
                else
                    assert(false)
                end
            end

            pos = math3d.set_index(pos, 1, __clamp(math3d.index(pos, 1), CAMERA_XAIXS_MIN, CAMERA_XAIXS_MAX))
            pos = math3d.set_index(pos, 3, __clamp(math3d.index(pos, 3), CAMERA_ZAIXS_MIN, CAMERA_ZAIXS_MAX))

            iom.set_position(ce, pos)
            world:pub {"dragdrop_camera", math3d.ref(delta_vec)}
        end
    end
end

function camera_controller:camera_usage()
    local ce <close> = world:entity(irq.main_camera())

    for _, _, e in gesture_pinch:unpack() do
        if __check_camera_editable() then
            zoom(e.velocity, e.x, e.y)
        end
    end

    __handle_drop_camera(ce)
    __handle_camera_motion()

    for _, _, left, top, position in ui_message_move_camera_mb:unpack() do
        local vr = irq.view_rect("main_queue")
        local vmin = math.min(vr.w / vr.ratio, vr.h / vr.ratio)
        local ui_position = icamera_controller.screen_to_world(left / 100 * vmin, top / 100 * vmin, PLANES)[1]

        local delta = math3d.set_index(math3d.sub(position, ui_position), 2, 0) -- the camera is always moving in the x/z axis and the y axis is always 0
        iom.move_delta(ce, delta)
    end
end

-- the following interfaces must be called during the `camera_usage` stage
function icamera_controller.screen_to_world(x, y, planes)
    local ce <close> = world:entity(irq.main_camera(), "camera:in")
    local vpmat = ce.camera.viewprojmat

    local vr = irq.view_rect("main_queue")
    local nx, ny = mu.remap_xy(x, y, vr.ratio)
    local ndcpt = mu.pt2D_to_NDC({nx, ny}, vr)
    ndcpt[3] = 0
    local p0 = mu.ndc_to_world(vpmat, ndcpt)
    ndcpt[3] = 1
    local p1 = mu.ndc_to_world(vpmat, ndcpt)

    local ray = {o = p0, d = math3d.sub(p0, p1)}

    local t = {}
    for _, plane in ipairs(planes) do
        t[#t + 1] = math3d.muladd(ray.d, math3d.plane_ray(ray.o, ray.d, plane), ray.o)
    end
    return t
end

function icamera_controller.world_to_screen(position)
    local ce <close> = world:entity(irq.main_camera(), "camera:in")
    local vp = ce.camera.viewprojmat
    local vr = irq.view_rect("main_queue")
    return mu.world_to_screen(vp, vr, position)
end

function icamera_controller.get_central_position()
    local ce <close> = world:entity(irq.main_camera())
    local ray = {o = iom.get_position(ce), d = math3d.mul(math.maxinteger, iom.get_direction(ce))}
    return math3d.muladd(ray.d, math3d.plane_ray(ray.o, ray.d, YAXIS_PLANE), ray.o)
end

function icamera_controller.get_interset_points()
    local ce <close> = world:entity(irq.main_camera(), "camera:in scene:in")
    local points = math3d.frustum_points(ce.camera.viewprojmat)
    local lb_raydir = math3d.sub(math3d.array_index(points, 5), math3d.array_index(points, 1))
    local lt_raydir = math3d.sub(math3d.array_index(points, 6), math3d.array_index(points, 2))
    local rb_raydir = math3d.sub(math3d.array_index(points, 7), math3d.array_index(points, 3))
    local rt_raydir = math3d.sub(math3d.array_index(points, 8), math3d.array_index(points, 4))

    local height = 0
    local xz_plane = math3d.vector(0, 1, 0, height)

    local eyepos = math3d.index(ce.scene.worldmat, 4)
    return {
        math3d.muladd(math3d.plane_ray(eyepos, lb_raydir, xz_plane), lb_raydir, eyepos),
        math3d.muladd(math3d.plane_ray(eyepos, lt_raydir, xz_plane), lt_raydir, eyepos),
        math3d.muladd(math3d.plane_ray(eyepos, rb_raydir, xz_plane), rb_raydir, eyepos),
        math3d.muladd(math3d.plane_ray(eyepos, rt_raydir, xz_plane), rt_raydir, eyepos),
    }
end

function icamera_controller.set_camera_from_prefab(prefab, callback)
    cam_cmd_queue:push {{"set_camera_from_prefab", prefab}}
    if callback then
        cam_cmd_queue:push {{"callback", callback}}
    end
end

function icamera_controller.focus_on_position(position, callback)
    cam_cmd_queue:push {{"focus_on_position", position}}
    if callback then
        cam_cmd_queue:push {{"callback", callback}}
    end
end

function icamera_controller.toggle_view(v, callback)
    cam_cmd_queue:push {{"toggle_view", v}}
    if callback then
        cam_cmd_queue:push {{"callback", callback}}
    end
end

-- for debug
function icamera_controller.set_camera_srt(s, r, t, callback)
    cam_cmd_queue:push {{"set_camera_srt", s, r, t}}
    if callback then
        cam_cmd_queue:push {{"callback", callback}}
    end
end

return icamera_controller
