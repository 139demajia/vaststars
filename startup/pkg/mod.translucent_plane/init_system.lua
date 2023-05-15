local ecs       = ...
local world     = ecs.world
local w         = world.w
local renderpkg = import_package "ant.render"
local declmgr   = renderpkg.declmgr
local math3d    = require "math3d"
local mathpkg = import_package "ant.math"
local imaterial = ecs.import.interface "ant.asset|imaterial"
local timer 	= ecs.import.interface "ant.timer|itimer"
local layout_name<const>    = declmgr.correct_layout "p3"
local layout                = declmgr.get(layout_name)
local init_sys = ecs.system 'init_system'
local mc    = mathpkg.constant
local bgfx      = require "bgfx"
local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
local iplane_terrain  = ecs.import.interface "mod.terrain|iplane_terrain"
local itp = ecs.interface "itranslucent_plane"
local assetmgr  = import_package "ant.asset"
local translucent_plane_material
local rgba_table = {[1] = 0, [2] = 0, [3] = 0, [4] = 0}
local tp_table = {}
local NUM_QUAD_VERTICES<const> = 4
local RENDER_LAYER = "translucent"
local call_to_tp = {}
local tp_to_call = {}
local cur_call_id = 0
local tp_update

--build ib
local function build_ib(max_plane)
    do
        local planeib = {}
        planeib = {
            0, 1, 2,
            2, 3, 0,
        }
        local fmt<const> = ('I'):rep(#planeib)
        local offset<const> = NUM_QUAD_VERTICES
        local s = #fmt * 4


        local m = bgfx.memory_buffer(s * max_plane)
        for i=1, max_plane do
            local mo = s * (i - 1) + 1
            m[mo] = fmt:pack(table.unpack(planeib))
            for ii = 1, #planeib do
                planeib[ii]  = planeib[ii] + offset
            end
        end
        return bgfx.create_index_buffer(m, "d")
    end
end

local function to_mesh_buffer(vb, ib_handle, aabb)
    local vbbin = table.concat(vb, "")
    local numv = #vbbin // layout.stride
    local numi = (numv // NUM_QUAD_VERTICES) * 6 --6 for one quad 2 triangles and 1 triangle for 3 indices
    if numv < 1 then return end
    return {
        bounding = {aabb = aabb and math3d.ref(aabb) or nil},
        vb = {
            start = 0,
            num = numv,
            handle = bgfx.create_vertex_buffer(bgfx.memory_buffer(vbbin), layout.handle),
            --owned = true
        },
        ib = {
            start = 0,
            num = numi,
            handle = ib_handle,
            --owned = true
        }
    }
end

local function is_corner(cx, cz, rect)
    local xx, zz, ww, hh = rect.x, rect.z, rect.w, rect.h
    if cx == xx and cz == zz then return "N"
    elseif cx == xx + ww and cz == zz then return "E"
    elseif cx == xx and cz == zz - hh then return "S"
    elseif cx == xx + ww and cz == zz - hh then return "W"
    else return
    end
end

local function build_mesh(grids, unit, offset, aabb)
    local packfmt<const> = "fff"
    local vb = {}
    local grid_num = 0
    --local rect = grids.rect
    for grid, _ in pairs(grids) do
        if grid ~= "rect" then
            local cx, cz = grid >> 8, grid & 0xff
            --local is_corner = is_corner(cx - offset, cz - offset, rect)
            local ox, oz = cx * unit, cz * unit
            local nx, nz = ox + unit, oz + unit
            local v = {
                packfmt:pack(ox, 0, oz),
                packfmt:pack(ox, 0, nz),
                packfmt:pack(nx, 0, nz),
                packfmt:pack(nx, 0, oz),        
            }  
            vb[#vb+1] = table.concat(v, "")
            grid_num = grid_num + 1
        end
    end
    local ib_handle = build_ib(grid_num)
    return to_mesh_buffer(vb, ib_handle, aabb)
end

local function get_aabb(grids, width, height, unit, offset)
    local minx, minz = width + 1, height + 1
    local maxx, maxz = -1, -1
    local rect = grids.rect
    for grid,  _ in pairs(grids) do
        if grid ~= "rect" then
            local cx, cz = grid >> 8, grid & 0xff
            if cx > maxx then
                maxx = cx
            end
            if cx < minx then
                minx = cx
            end
            if cz > maxz then
                maxz = cz
            end
            if cz < minz then
                minz = cz
            end 
        end
    end
    local aabb_min = math3d.vector(minx * unit, 0, minz * unit)
    local aabb_max = math3d.vector(minx * unit + unit, 0, minz * unit + unit)
    return math3d.aabb(aabb_min, aabb_max)
end

function init_sys:init_world()
    translucent_plane_material = "/pkg/mod.translucent_plane/assets/translucent_plane.material"
end


local function create_translucent_plane_entity(grids_table, color, alpha)
    local grid_num = 0
    for k, v in pairs(grids_table) do
        grid_num  = grid_num + 1
    end
    if grid_num == 0 then
        return
    end
    local width, height, unit, offset = iplane_terrain.get_wh()
    local aabb = get_aabb(grids_table, width, height, unit, offset)
    local plane_mesh = build_mesh(grids_table, unit, offset, aabb)
    local eid
    local vb_handle, ib_handle
    if plane_mesh then
        vb_handle, ib_handle = plane_mesh.vb.handle, plane_mesh.ib.handle
        if alpha then
            eid = ecs.create_entity{
                policy = {
                    "ant.scene|scene_object",
                    "ant.render|simplerender",
                    "mod.translucent_plane|translucent_plane",
                },
                data = {
                    scene = {
                        t = math3d.vector(-offset * unit, 0, -offset * unit)
                    },
                    simplemesh  = plane_mesh,
                    material    = translucent_plane_material,
                    on_ready = function (e)
                        imaterial.set_property(e, "u_colorTable", math3d.vector(color[1], color[2], color[3], alpha.min))
                    end,
                    breath = {
                        min = alpha.min,
                        max = alpha.max,
                        cur = alpha.min,
                        freq = alpha.freq,
                        trend = 0,
                        color = {color[1], color[2], color[3]}
                    },
                    visible_state = "main_view",
                    --render_layer = "translucent",
                    render_layer = RENDER_LAYER
                },
            }
        else
            eid = ecs.create_entity{
                policy = {
                    "ant.scene|scene_object",
                    "ant.render|simplerender",
                    "mod.translucent_plane|translucent_plane",
                },
                data = {
                    scene = {
                        t = math3d.vector(-offset * unit, 0, -offset * unit)
                    },
                    simplemesh  = plane_mesh,
                    material    = translucent_plane_material,
                    on_ready = function (e)
                        imaterial.set_property(e, "u_colorTable", math3d.vector(color))
                    end,
                    visible_state = "main_view",
                    --render_layer = "translucent",
                    render_layer = RENDER_LAYER
                },
            }

        end
    end
    return eid, vb_handle, ib_handle
end 

local function create_grids_table(offset)
    local grids_table = {}
    -- create all rect' grids
    for idx = 1, #tp_table do
        local rect = tp_table[idx].rect
        local x, z, ww, hh = rect.x + offset, rect.z + offset, rect.w, rect.h
        local grids = {}
        for ih = 0, hh - 1 do
            for iw = 0, ww - 1 do
                local xx, zz = x + iw, z - ih
                local compress_coord = (xx << 8) + zz
                grids[compress_coord] = true
            end
        end
        --grids.rect = rect
        grids_table[idx] = grids
    end
    return grids_table
end

local function create_aabb_table(offset)
    local aabb_table = {}
    -- create all rect' aabb
    for idx = 1, #tp_table do
        local rect = tp_table[idx].rect
        local x, z, ww, hh = rect.x + offset, rect.z + offset, rect.w, rect.h
        local aabb = math3d.aabb(math3d.vector(x, 0, z - (hh - 1)), math3d.vector(x + ww - 1, 0, z))
        aabb_table[idx] = aabb
    end
    return aabb_table
end

local function update_grids_table(grids_table, aabb_table)
    if #grids_table <= 1 then
        return
    end
    for idx_offset = 0, #grids_table - 1 do
        local cur_idx = #grids_table-idx_offset
        local aabb = aabb_table[cur_idx]
        for prev_idx = 1, cur_idx - 1 do
            local prev_grids = grids_table[prev_idx]
            local prev_aabb = aabb_table[prev_idx]
            local inter_aabb = math3d.aabb_intersection(aabb, prev_aabb)
            if inter_aabb ~= mc.NULL then
                local inter_center, inter_extent = math3d.aabb_center_extents(inter_aabb)
                local inter_min, inter_max = math3d.sub(inter_center, inter_extent), math3d.add(inter_center, inter_extent)
                local inter_min_x, inter_min_z = math3d.index(inter_min, 1, 3)
                local inter_max_x, inter_max_z = math3d.index(inter_max, 1, 3)
                for zz = inter_min_z, inter_max_z do
                    for xx = inter_min_x, inter_max_x do
                        local compress_coord = (xx << 8) + zz
                        prev_grids[compress_coord] = nil
                    end
                end
            end
        end
    end
end

local remove_list = {}
local function remove_all_tp()
    for idx = 1, #tp_table do
        if tp_table[idx].eid and not remove_list[tp_table[idx].eid] then
            remove_list[tp_table[idx].eid] = {
                vb_handle = tp_table[idx].vb_handle,
                ib_handle = tp_table[idx].ib_handle
            }
            tp_table[idx].eid = nil
            tp_table[idx].vb_handle = nil
            tp_table[idx].ib_handle = nil
        end
    end
end

local function get_final_table(rect_table, color_table, alpha_table)
    for idx = 1, #rect_table do
        local tp_idx = #tp_table + 1
        tp_table[tp_idx] = {
            rect = rect_table[idx],
            color = color_table[idx]
        }
        if alpha_table and alpha_table[idx] then tp_table[tp_idx].alpha = alpha_table[idx] end
    end
end

local function generate_each_grids(offset, old_tp_num)
    local final_table = {}
    local id_table = {}
    local grids_table = create_grids_table(offset)
    local aabb_table = create_aabb_table(offset)
    update_grids_table(grids_table, aabb_table)
    -- tp_table contain old table + new table
    for idx = 1, #tp_table do
        local tp = {}
        tp.rect = tp_table[idx].rect
        tp.color = tp_table[idx].color
        tp.alpha = tp_table[idx].alpha
        tp.grids = grids_table[idx]
        if idx <= old_tp_num then
            -- old
            local old_call_id = tp_to_call[idx]
            local new_tp_id = #final_table + 1
            final_table[new_tp_id] = tp
            call_to_tp[old_call_id] = new_tp_id
            tp_to_call[new_tp_id] = old_call_id
        else
            -- new
            local new_tp_id = #final_table + 1
            final_table[new_tp_id] = tp
            local new_call_id = cur_call_id + 1
            cur_call_id = cur_call_id + 1
            call_to_tp[new_call_id] = new_tp_id
            tp_to_call[new_tp_id] = new_call_id
            id_table[#id_table+1] = new_call_id
        end
    end
    
    tp_table = final_table
    return id_table
end

function itp.create_translucent_plane(rect_table, color_table, render_layer, alpha_table)
    tp_update = true
    remove_all_tp()
    local width, height, unit, offset = iplane_terrain.get_wh()
    local old_tp_num = #tp_table
    get_final_table(rect_table, color_table, alpha_table)
    RENDER_LAYER = render_layer
    return generate_each_grids(offset, old_tp_num)
end

--删除完以后tp_table和tp_all中的idx没有保持一致
function itp.remove_translucent_plane(id_table)
    tp_update = true
    local index_table = {}
    for idx = 1, #id_table do
        local call_id = id_table[idx]
        local tp_id = call_to_tp[call_id]
        call_to_tp[call_id] = nil
        if tp_id then
            tp_to_call[tp_id] = nil
            index_table[tp_id] = true
            if tp_table[tp_id].eid and not remove_list[tp_table[tp_id].eid] then
                remove_list[tp_table[tp_id].eid] = {
                    vb_handle = tp_table[tp_id].vb_handle,
                    ib_handle = tp_table[tp_id].ib_handle
                }
                tp_table[tp_id].eid = nil
                tp_table[tp_id].vb_handle = nil
                tp_table[tp_id].ib_handle = nil
            end
        end
    end
    local final_table = {}
    for idx, tp in pairs(tp_table) do
        local new_tp_id = #final_table + 1
        if not index_table[idx] then
            final_table[new_tp_id] = tp
            local old_call_id = tp_to_call[idx]
            call_to_tp[old_call_id] = new_tp_id
            tp_to_call[idx] = nil
            tp_to_call[new_tp_id] = old_call_id
        end
    end
    remove_all_tp()
    tp_table = final_table
    local old_tp_num = #tp_table
    local width, height, unit, offset = iplane_terrain.get_wh()
    generate_each_grids(offset, old_tp_num)
end

function init_sys:data_changed()
    for e in w:select "breath:update" do
        local min, max, cur, freq, trend, color = e.breath.min, e.breath.max, e.breath.cur, e.breath.freq, e.breath.trend, e.breath.color
        local increment = (1 / 60) * freq
        if trend == 0 then
            cur = cur + increment
            if cur > max then
                cur, trend = max, 1
            end
        else
            cur = cur - increment
            if cur < min then
                cur, trend = min, 0
            end
        end
        e.breath.cur, e.breath.trend = cur, trend
        imaterial.set_property(e, "u_colorTable", math3d.vector(color[1], color[2], color[3], cur))
    end

    if tp_update then
        for eid, handles in pairs(remove_list) do
            local vb_handle, ib_handle = handles.vb_handle, handles.ib_handle
            w:remove(eid)
            bgfx.destroy(vb_handle)
            bgfx.destroy(ib_handle)
        end
        remove_list = {}
        for idx = 1, #tp_table do
            local eid, vb_handle, ib_handle = create_translucent_plane_entity(tp_table[idx].grids, tp_table[idx].color, tp_table[idx].alpha)
            if eid then
                tp_table[idx].eid = eid
                tp_table[idx].vb_handle = vb_handle 
                tp_table[idx].ib_handle = ib_handle 
            end
        end
        tp_update = nil
    end
end
