local ecs   = ...
local world = ecs.world
local w     = world.w

local bgfx      = require "bgfx"
local math3d    = require "math3d"

local init_system   = ecs.system "init_system"

local imaterial     = ecs.require "ant.asset|material"
local icompute      = ecs.require "ant.render|compute.compute"
local idrawindirect = ecs.require "ant.render|draw_indirect_system"

local renderpkg     = import_package "ant.render"
local layoutmgr     = renderpkg.layoutmgr
local layout        = layoutmgr.get "p3|t20"

local hwi                   = import_package "ant.hwi"
local FIRST_viewid<const>   = hwi.viewid_get "csm_fb"

local iroad         = {}

local width, height = 20, 20
local TERRAIN_TYPES<const> = {
    road1 = "1",
    road2 = "2",
    road3 = "3",
    mark1 = "4",
    mark2 = "5",
    mark3 = "6"
}

local TERRAIN_DIRECTIONS<const> = {
    N = "1",
    E = "2",
    S = "3",
    W = "4",
}

local road_material_table = {
    [1] = "/pkg/mod.road/assets/road_u.material",
    [2] = "/pkg/mod.road/assets/road_i.material",
    [3] = "/pkg/mod.road/assets/road_l.material",
    [4] = "/pkg/mod.road/assets/road_t.material",
    [5] = "/pkg/mod.road/assets/road_x.material",
    [6] = "/pkg/mod.road/assets/road_o.material",
}

local mark_material_table = {
    [1] = "/pkg/mod.road/assets/mark_u.material",
    [2] = "/pkg/mod.road/assets/mark_i.material",
    [3] = "/pkg/mod.road/assets/mark_l.material",
    [4] = "/pkg/mod.road/assets/mark_t.material",
    [5] = "/pkg/mod.road/assets/mark_x.material",
    [6] = "/pkg/mod.road/assets/mark_o.material",
}

local function parse_terrain_type_dir(layers, tname)
    local type, shape, dir = tname..layers[tname].type, layers[tname].shape, layers[tname].dir
    local t<const> = assert(TERRAIN_TYPES[type])
    local s<const> = shape or "D"
    local d<const> = assert(TERRAIN_DIRECTIONS[dir])
    return ("%s%s%s"):format(t, s, d)
end

local function parse_layer(t, s, d)
    local pt, ps, pd
--[[     local u_table = {["1"] = 0, ["2"]= 90, ["3"] = 180, ["4"] = 270}
    local i_table = {["1"] = 270, ["2"]= 0, ["3"] = 90, ["4"] = 180}
    local l_table = {["1"] = 180, ["2"]= 270, ["3"] = 0, ["4"] = 90} ]]
    local u_table = {["1"] = 0, ["2"]= 270, ["3"] = 180, ["4"] = 90}
    local i_table = {["1"] = 270, ["2"]= 0, ["3"] = 90, ["4"] = 180}
    local l_table = {["1"] = 180, ["2"]= 90, ["3"] = 0, ["4"] = 270}
    if s == "U" then
        ps, pd = 0, u_table[d]
    elseif s == "I" then
        ps, pd = 1, i_table[d]
    elseif s == "L" then
        ps, pd = 2, l_table[d]
    elseif s == "T" then
        ps, pd = 3, u_table[d]
    elseif s == "X" then
        ps, pd = 4, 0
    elseif s == 'O' then    
        ps, pd = 5, 0
    else
        ps, pd = 6, 0
    end
    pt = t
    return pt, ps, pd                          
end

local NUM_QUAD_VERTICES<const> = 4

local function build_ib(max_plane)
    do
        local planeib = {}
        planeib = {
            0, 1, 2,
            2, 3, 0,
        }
        local fmt<const> = ('I'):rep(#planeib)
        local s = #fmt * 4


        local m = bgfx.memory_buffer(s * max_plane)
        for i=1, max_plane do
            local mo = s * (i - 1) + 1
            m[mo] = fmt:pack(table.unpack(planeib))
            for ii = 1, #planeib do
                planeib[ii]  = planeib[ii] + NUM_QUAD_VERTICES
            end
        end
        return bgfx.create_index_buffer(m, "d")
    end
end

local function get_road_info(road)
    local t = {road.x, 0.1, road.y, 0}
    local road_direction = road.road_direction or 0
    local road_info = {
        [1] = t,
        [2] = {road_direction, road.road_type, 0, 0},
        [3] = {0, 0, 0, 0},
    }
    return road_info
end

local function get_mark_info(road)
    local t = {road.x, 0.1, road.y, 0}
    local mark_direction = road.mark_direction or 0
    local mark_info = {
        [1] = t,
        [2] = {mark_direction, road.mark_type, 0, 0},
        [3] = {0, 0, 0, 0},
    }
    return mark_info
end

function init_system:init_world()
end

local function create_road_instance_info(create_list)
    local road_info_table = {[1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}}
    local mark_info_table = {[1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}}
    for ii = 1, #create_list do
        local cl = create_list[ii]
        local layers = cl.layers
        local road_layer, mark_layer
        if layers and layers.road then road_layer = parse_terrain_type_dir(layers, "road") end
        if layers and layers.mark then mark_layer = parse_terrain_type_dir(layers, "mark") end
        local road = {
            layers = {
                [1] = road_layer,
                [2] = mark_layer
            },
            x = cl.x,
            y = cl.y
        }
        layers = road.layers
        if not layers[1] then road.road_type, road.road_shape = 0, 0 end -- 0 not road 1 road 2 stop 3 building
        if not layers[2] then road.mark_type, road.mark_shape = 0, 0 end -- 0 not mark 1 red 2 white
        for i, layer in pairs(layers) do
            local t, s, d
            t = string.sub(layer, 1, 1)
            s = string.sub(layer, 2, 2)
            d = string.sub(layer, 3, 3)
            local pt, ps, pd = parse_layer(t, s, d)
            if i == 1 then
                road.road_type = pt - 0
                road.road_direction = pd
                road.road_shape = ps
            elseif i == 2 then
                road.mark_type = pt - 3
                road.mark_direction = pd
                road.mark_shape = ps
            end
        end
        if cl.layers.road then
            local road_info = get_road_info(road)
            local cur_road_info = road_info_table[road.road_shape + 1]
            cur_road_info[#cur_road_info+1] = road_info
        end
        if cl.layers.mark then
            local mark_info = get_mark_info(road)
            local cur_mark_info = mark_info_table[road.mark_shape + 1]
            cur_mark_info[#cur_mark_info+1] = mark_info
        end
    end
    return road_info_table, mark_info_table
end

local function to_mesh_buffer(vb, ib_handle)
    local vbbin = table.concat(vb, "")
    local numv = #vbbin // layout.stride
    local numi = (numv // NUM_QUAD_VERTICES) * 6 --6 for one quad 2 triangles and 1 triangle for 3 indices

    return {
        bounding = nil,
        vb = {
            start = 0,
            num = numv,
            handle = bgfx.create_vertex_buffer(bgfx.memory_buffer(vbbin), layout.handle),
        },
        ib = {
            start = 0,
            num = numi,
            handle = ib_handle,
        }
    }
end

local function build_mesh()
    local packfmt<const> = "fffff"
    local ox, oz = 0, 0
    local nx, nz = width, height
    local vb = {
        packfmt:pack(ox, 0, oz, 0, 1),
        packfmt:pack(ox, 0, nz, 0, 0),
        packfmt:pack(nx, 0, nz, 1, 0),
        packfmt:pack(nx, 0, oz, 1, 1),        
    }
    local ib_handle = build_ib(1)
    return to_mesh_buffer(vb, ib_handle)
end

function iroad.set_args(ww, hh)
    if ww then width = ww end
    if hh then height = hh end
end

local road_group = {}

local function get_srt_info_table(update_list)
    return create_road_instance_info(update_list)
end

local function create_road_group(gid, update_list, render_layer)
    if not render_layer then render_layer = "background" end
    local road_info_table, mark_info_table = get_srt_info_table(update_list)
    local road_mesh = build_mesh()
    local g = ecs.group(gid)
    for road_idx = 1, #road_info_table do
        local road_info = road_info_table[road_idx]
            g:create_entity{
                policy = {
                    "ant.scene|scene_object",
                    "ant.render|simplerender",
                    "mod.road|road",
                    "ant.render|indirect"
                },
                data = {
                    scene = {},
                    simplemesh  = road_mesh,
                    material    = road_material_table[road_idx],
                    visible_state = "main_view|selectable|pickup",
                    road = {srt_info = road_info, gid = gid, road_type = road_idx},
                    render_layer = render_layer,
                    indirect = "ROAD",
                    on_ready = function(e)
                        local draw_indirect_type = idrawindirect.get_draw_indirect_type("ROAD")
                        imaterial.set_property(e, "u_draw_indirect_type", math3d.vector(draw_indirect_type))
                    end
                },
            }       
    end

    for mark_idx = 1, #mark_info_table do
        local mark_info = mark_info_table[mark_idx]
            g:create_entity{
                policy = {
                    "ant.scene|scene_object",
                    "ant.render|simplerender",
                    "mod.road|road",
                    "ant.render|indirect"
                },
                data = {
                    scene = {},
                    simplemesh  = road_mesh,
                    material    = mark_material_table[mark_idx],
                    visible_state = "main_view|selectable|pickup",
                    road = {srt_info = mark_info, gid = gid, mark_type = mark_idx},
                    render_layer = render_layer,
                    indirect = "ROAD",
                    on_ready = function(e)
                        local draw_indirect_type = idrawindirect.get_draw_indirect_type("ROAD")
                        imaterial.set_property(e, "u_draw_indirect_type", math3d.vector(draw_indirect_type))
                    end
                },
            }       
    end
    g:enable "view_visible"
    ecs.group_flush "view_visible"
end

local function update_road_group(gid, update_list)
    local road_table, mark_table = get_srt_info_table(update_list)
    local select_tag = "view_visible road:update road_type:in"
    for e in w:select(select_tag) do
        if e.road.gid == gid then
            if e.road.road_type then
                local road_info = road_table[e.road.road_type]
                e.road.srt_info = road_info 
            end
            if e.road.mark_type then
                local mark_info = mark_table[e.road.mark_type]
                e.road.srt_info = mark_info 
            end
            e.road.ready = true
        end
    end
end

function init_system:entity_init()
    for e in w:select "INIT road:update render_object?update indirect?update" do
        local road = e.road
        local max_num = 500
        local draw_indirect_eid = ecs.create_entity {
            policy = {
                "ant.render|compute_policy",
                "ant.render|draw_indirect"
            },
            data = {
                material    = "/pkg/ant.resources/materials/indirect/indirect.material",
                dispatch    = {
                    size    = {0, 0, 0},
                },
                compute = true,
                draw_indirect = {
                    itb_flag = "r",
                    max_num = max_num
                },
                on_ready = function()
                    road.ready = true
                end 
            }
        }
        road.draw_indirect_eid = draw_indirect_eid
        e.render_object.draw_num = 0
        e.render_object.idb_handle = 0xffffffff
        e.render_object.itb_handle = 0xffffffff
    end   
end

function init_system:entity_remove()
    for e in w:select "REMOVED road:in" do
        w:remove(e.road.draw_indirect_eid)
    end
end

local function create_road_compute(dispatch, road_num, indirect_buffer, instance_buffer, instance_params, indirect_params)
    dispatch.size[1] = math.floor((road_num - 1) / 64) + 1
    local m = dispatch.material
    m.u_instance_params			= instance_params
    m.u_indirect_params         = indirect_params
    m.indirect_buffer           = indirect_buffer
    m.instance_buffer           = instance_buffer
    icompute.dispatch(FIRST_viewid, dispatch)
end

local function get_instance_memory_buffer(srt_info, max_num)
    local draw_num = #srt_info
    local fmt<const> = "ffff"
    local memory_buffer = bgfx.memory_buffer(3 * 16 * max_num)
    local memory_buffer_offset = 1
    for srt_idx = 1, draw_num do
        local instance_data = srt_info[srt_idx]
        for data_idx = 1, #instance_data do
            memory_buffer[memory_buffer_offset] = fmt:pack(table.unpack(instance_data[data_idx]))
            memory_buffer_offset = memory_buffer_offset + 16
        end
    end
    return memory_buffer
end

function init_system:data_changed()
    for e in w:select "road:update render_object:update scene:in" do
        if not e.road.ready then
            goto continue
        end
        local road = e.road
        local srt_info = road.srt_info
        local draw_num = 0
        if srt_info then draw_num = #srt_info end
        if draw_num > 0 then
            local de <close> = world:entity(road.draw_indirect_eid, "draw_indirect:in dispatch:in")
            local idb_handle, itb_handle = de.draw_indirect.idb_handle, de.draw_indirect.itb_handle
            local instance_memory_buffer = get_instance_memory_buffer(srt_info, 500)
            bgfx.update(itb_handle, 0, instance_memory_buffer)
            local instance_params = math3d.vector(0, e.render_object.vb_num, 0, e.render_object.ib_num)
            local indirect_params = math3d.vector(draw_num, 0, 0, 0)
            create_road_compute(de.dispatch, draw_num, idb_handle, itb_handle, instance_params, indirect_params)
            e.render_object.idb_handle = idb_handle
            e.render_object.itb_handle = itb_handle
            e.render_object.draw_num = draw_num
        else
            e.render_object.idb_handle = 0xffffffff
            e.render_object.itb_handle = 0xffffffff
            e.render_object.draw_num = 0
        end

        e.road.ready = nil
        ::continue::
    end
end

function iroad.update_roadnet_group(gid, update_list, render_layer)
    if not gid then
        gid = 30001
    end
    if road_group[gid] then
        update_road_group(gid, update_list)
    else
        create_road_group(gid, update_list, render_layer)
        road_group[gid] = true
    end

end

return iroad
