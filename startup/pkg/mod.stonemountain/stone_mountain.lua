local ecs = ...
local world = ecs.world
local w = world.w
local open_sm = false
local fastio    = require "fastio"
local datalist  = require "datalist"
local idrawindirect = ecs.import.interface "ant.render|idrawindirect"
local imaterial = ecs.import.interface "ant.asset|imaterial"
local math3d 	= require "math3d"
local iom = ecs.import.interface "ant.objcontroller|iobj_motion"
local mathpkg	= import_package "ant.math"
local mc		= mathpkg.constant
local renderpkg = import_package "ant.render"
local viewidmgr = renderpkg.viewidmgr
local declmgr   = import_package "ant.render".declmgr
local bgfx 			= require "bgfx"
local assetmgr  = import_package "ant.asset"
local icompute = ecs.import.interface "ant.render|icompute"
local terrain_module = require "terrain"
local ism = ecs.interface "istonemountain"
local sm_sys = ecs.system "stone_mountain"
local vb_num, vb_size, vb2_size, ib_num, ib_size = 0, 0, 0, 0, 0
local vb_handle, vb2_handle, ib_handle

local ratio, width, height = 0.77, 256, 256
local ratio_table = {
    [1] = 0.88, [2] = 0.90, [3] = 0.92, [4] = 0.94
}
local freq, depth, unit, offset = 4, 4, 10, 0
local main_viewid = viewidmgr.get "csm_fb"

local sm_table = {}
local sm_group = {
    [1] = 40001, [2] = 40002, [3] = 40003, [4] = 40004
}

local mesh_table = {
    [1] = {filename = "/pkg/mod.stonemountain/assets/mountain1.glb|meshes/Cylinder.002_P1.meshbin"},
    [2] = {filename = "/pkg/mod.stonemountain/assets/mountain2.glb|meshes/Cylinder.004_P1.meshbin"},
    [3] = {filename = "/pkg/mod.stonemountain/assets/mountain3.glb|meshes/Cylinder_P1.meshbin"},
    [4] = {filename = "/pkg/mod.stonemountain/assets/mountain4.glb|meshes/Cylinder.021_P1.meshbin"}
}

local sm_info_table = {
    {sidx = 1, scale = {lb = 0.064, rb = 0.064}, offset = 0.5}, 
    {sidx = 2, scale = {lb = 0.064, rb = 0.200}, offset = 0.1}, 
    {sidx = 3, scale = {lb = 0.125, rb = 0.250}, offset = 1.5},
    {sidx = 4, scale = {lb = 0.350, rb = 0.250}, offset = 2.0}
}


local function generate_sm_config()
    local function update_idx_table(x, z, m, n, idx_table)
        for oz = 0, n - 1 do
            for ox = 0, m - 1 do
                local xx, zz = ox + x, oz + z
                local idx = 1 + zz * width + xx
                if xx < width and zz < height then
                    idx_table[idx] = 1
                end
            end
        end        
    end
    local idx_table = {}
    for iz = 0, height - 1 do
        for ix = 0, width - 1 do
            for ri = 1, 4 do
                local seed, offset_y, offset_x = iz * ix + ri, iz + ri, ix + ri
                local noise = terrain_module.noise(ix, iz, freq, depth, seed, offset_y, offset_x)
                if ri == 1 then -- 1x1
                    local idx = 1 + iz * width + ix
                    if noise > ratio_table[ri] then
                        idx_table[idx] = 1
                    elseif not idx_table[idx] then
                        
                        idx_table[idx] = 0
                    end
                else
                    if noise > ratio_table[ri] then
                        update_idx_table(ix, iz, ri, ri, idx_table)
                    end   
                end
            end
        end
    end
    return string.pack(("B"):rep(width * height), table.unpack(idx_table))
end

function ism.create_random_sm(d, ww, hh, off, un)
    ratio = ratio + (1 - d) / 10
    width, height =  ww, hh
    if off then offset = off end
    if un then unit = un end
    return generate_sm_config()
end

function ism.create_sm_entity(idx_string)
    open_sm = true
    for iz = 0, height - 1 do
        for ix = 0, width - 1 do
            local idx = iz * width + ix + 1
            local is_sm = string.unpack(("B"), idx_string, idx)
            if is_sm == 1 then
                sm_table[(iz << 16) + ix] = {}
            end
        end
    end
end


local function get_srt()
    for _, sm_info in pairs(sm_info_table) do
        local sidx, lb, rb, off = sm_info.sidx, sm_info.scale.lb, sm_info.scale.rb, sm_info.offset
        for sm_idx, _ in pairs(sm_table) do
            if sm_table[sm_idx][sidx] then
                local ix, iz = sm_idx & 65535, sm_idx >> 16
                local seed, offset_y, offset_x = iz * ix + sidx, iz + sidx, ix + sidx
                local s_noise = terrain_module.noise(ix, iz, freq, depth, seed, offset_y, offset_x) * rb + lb
                local r_noise = math.floor(terrain_module.noise(ix, iz, freq, depth, seed, offset_y, offset_x) * 360) + math.random(-360, 360)
                local mesh_noise = (sm_idx + math.random(0, 4)) % 4 + 1
                local tx, tz = (ix + off - offset) * unit, (iz + off - offset) * unit
                sm_table[sm_idx][sidx] = {s = s_noise, r = r_noise, tx = tx, tz = tz, m = mesh_noise}
            end
        end
    end
end

local function set_sm_property()
    local function has_block(x, z, m, n)
        for oz = 0, n - 1 do
            for ox = 0, m - 1 do
                local ix, iz = x + ox, z + oz
                if ix >= width or iz >= height then return nil end
                local sm_idx = (iz << 16) + ix
                if (not sm_table[sm_idx])then
                    return nil
                end
            end
        end
        return true        
    end

    for sm_idx, _ in pairs(sm_table) do
        local ix, iz = sm_idx & 65535, sm_idx >> 16
        local near_table = {[1] = true}
        for _ , sm_info in pairs(sm_info_table) do
            local sidx = sm_info.sidx
            if sidx ~= 1 and has_block(ix, iz, sidx, sidx) then
                near_table[sidx] = true
            end
        end
        if math.random(0, 1) > 0 then
            near_table[1] = nil
        end
        for idx, _ in pairs(near_table) do
            sm_table[sm_idx][idx] = {}
        end
    end
end

local function make_sm_noise()
    set_sm_property()
    get_srt()
end

local function load_mem(m, filename)
    local function parent_path(v)
        return v:match("^(.+)/[^/]*$")
    end
    local binname = m[1]
    assert(type(binname) == "string" and (binname:match "%.[iv]bbin" or binname:match "%.[iv]b[2]bin"))

    local data, err = fastio.readall_s(assetmgr.compile(parent_path(filename) .. "/" .. binname))
    if not data then
        error(("read file failed:%s, error:%s"):format(binname, err))
    end
    m[1] = data
end

function sm_sys:init()
    local vb_memory, vb2_memory, ib_memory = '', '', ''
    local vb_decl, vb2_decl = declmgr.get('p30NIf|T40nii').handle, declmgr.get('c40niu|t20NIf').handle
    for idx = 1, 4 do
        local mesh = mesh_table[idx]
        local local_filename = assetmgr.compile(mesh.filename)
        local mm = datalist.parse(fastio.readall_s(local_filename))
        load_mem(mm.vb.memory,  mesh.filename)
        load_mem(mm.vb2.memory, mesh.filename)
        load_mem(mm.ib.memory,  mesh.filename)
        vb_num, vb_size, vb2_size = vb_num + mm.vb.num, vb_size + mm.vb.memory[3], vb2_size + mm.vb2.memory[3]
        ib_num, ib_size = ib_num + mm.ib.num, ib_size + mm.ib.memory[3]
        mesh.vb_num, mesh.vb_size, mesh.vb2_size = mm.vb.num, mm.vb.memory[3], mm.vb2.memory[3]
        mesh.ib_num, mesh.ib_size = mm.ib.num, mm.ib.memory[3]
        vb_memory  = vb_memory .. mm.vb.memory[1]
        vb2_memory = vb2_memory .. mm.vb2.memory[1]
        ib_memory  = ib_memory .. mm.ib.memory[1]
    end
    vb_handle  = bgfx.create_vertex_buffer(bgfx.memory_buffer(table.unpack{vb_memory, 1, vb_size}), vb_decl)
    vb2_handle = bgfx.create_vertex_buffer(bgfx.memory_buffer(table.unpack{vb2_memory, 1, vb2_size}), vb2_decl)
    ib_handle  = bgfx.create_index_buffer(bgfx.memory_buffer(table.unpack{ib_memory, 1, ib_size}), '')
end

local kb_mb = world:sub{"keyboard"}


local function create_sm_entity()
    local mesh_number_table = {}

    local stonemountain_info_table  = {}
    for mesh_idx = 1, 4 do
        local begin_num = #stonemountain_info_table
        for _, sms in pairs(sm_table) do
            if sms[mesh_idx] then
                local sm = sms[mesh_idx]
                stonemountain_info_table[#stonemountain_info_table+1] = {
                    {sm.s, sm.r, sm.tx, sm.tz}
                }               
            end
        end
        mesh_number_table[mesh_idx] = #stonemountain_info_table - begin_num
    end
    local gid = 40005
    local g = ecs.group(gid)
    ecs.group(gid):enable "view_visible"
    g:create_entity {
        policy = {
            "ant.render|render",
            "mod.stonemountain|stonemountain",
            "ant.render|indirect"
         },
        data = {
            scene         = {},
            mesh =  mesh_table[1].filename,
            material      ="/pkg/mod.stonemountain/assets/pbr_sm.material", 
            visible_state = "main_view|cast_shadow",
            stonemountain = {
                group = gid,
                stonemountain_info = stonemountain_info_table,
                mesh_number = mesh_number_table
            },
            render_layer = "foreground",
            indirect = "STONE_MOUNTAIN",
            on_ready = function(e)
                local draw_indirect_type = idrawindirect.get_draw_indirect_type("STONE_MOUNTAIN")
                imaterial.set_property(e, "u_draw_indirect_type", math3d.vector(draw_indirect_type))
            end
        }
    }
end

function sm_sys:stone_mountain()
    if open_sm then
        make_sm_noise()
        create_sm_entity()
        open_sm = false
    end
end

local function update_ro(ro)
    bgfx.destroy(ro.vb_handle)
    bgfx.destroy(ro.vb2_handle)
    bgfx.destroy(ro.ib_handle)
    ro.vb_handle, ro.vb2_handle, ro.ib_handle = vb_handle, vb2_handle, ib_handle
    ro.vb_num, ro.vb2_num, ro.ib_num = vb_num, vb_num, ib_num
end

function sm_sys:entity_init()
    for e in w:select "INIT stonemountain:update render_object?update indirect?update" do
        update_ro(e.render_object)
        local stonemountain = e.stonemountain
        local max_num = 20000
        local draw_indirect_eid = ecs.create_entity {
            policy = {
                "ant.render|compute_policy",
                "ant.render|draw_indirect"
            },
            data = {
                material    = "/pkg/ant.resources/materials/stone_mountain/stone_mountain.material",
                dispatch    = {
                    size    = {0, 0, 0},
                },
                compute = true,
                draw_indirect = {
                    itb_flag = "r",
                    max_num = max_num
                },
                on_ready = function()
                    stonemountain.ready = true
                end 
            }
        }
        stonemountain.draw_indirect_eid = draw_indirect_eid
        e.render_object.draw_num = 0
        e.render_object.idb_handle = 0xffffffff
        e.render_object.itb_handle = 0xffffffff
    end   
end

function sm_sys:entity_remove()
    for e in w:select "REMOVED stonemountain:in" do
        w:remove(e.stonemountain.draw_indirect_eid)
    end
end

local function get_instance_memory_buffer(stonemountain_info, max_num)
    local stonemountain_num = #stonemountain_info
    local fmt<const> = "ffff"
    local memory_buffer = bgfx.memory_buffer(3 * 16 * max_num)
    local memory_buffer_offset = 1
    for stonemountain_idx = 1, stonemountain_num do
        local instance_data = stonemountain_info[stonemountain_idx]
        for data_idx = 1, 3 do
            if data_idx == 1 then
                memory_buffer[memory_buffer_offset] = fmt:pack(table.unpack(instance_data[data_idx]))
            else
                memory_buffer[memory_buffer_offset] = fmt:pack(table.unpack({0, 0, 0, 0})) 
            end
            memory_buffer_offset = memory_buffer_offset + 16
        end
    end
    return memory_buffer
end

local function create_stonemountain_compute(dispatch, stonemountain_num, indirect_buffer, instance_params, indirect_params, mesh_offset)
    dispatch.size[1] = math.floor((stonemountain_num - 1) / 64) + 1
    local m = dispatch.material
    m.u_indirect_params			= indirect_params
    m.u_instance_params1        = instance_params[1]
    m.u_instance_params2        = instance_params[2]
    m.u_instance_params3        = instance_params[3]
    m.u_instance_params4        = instance_params[4]
    m.u_mesh_offset             = mesh_offset
    m.indirect_buffer           = indirect_buffer
    icompute.dispatch(main_viewid, dispatch)
end

function sm_sys:data_changed()
    
    for e in w:select "stonemountain:update render_object:update scene:in bounding:update" do
        if not e.stonemountain.ready then
            goto continue
        end
        e.bounding.scene_aabb = mc.NULL
        local stonemountain = e.stonemountain
        local stonemountain_info = stonemountain.stonemountain_info
        local mesh_number = stonemountain.mesh_number
        local mesh_offset = math3d.vector(mesh_number[1], mesh_number[2], mesh_number[3])
        local stonemountain_num = #stonemountain_info
        -- vertex offset / index offset / total index number
        local instance_params = {
            [1] = math3d.vector(0, 0, mesh_table[1].ib_num),
            [2] = math3d.vector(mesh_table[1].vb_num, mesh_table[1].ib_num, mesh_table[2].ib_num),
            [3] = math3d.vector(mesh_table[1].vb_num + mesh_table[2].vb_num, mesh_table[1].ib_num + mesh_table[2].ib_num, mesh_table[3].ib_num),
            [4] = math3d.vector(vb_num - mesh_table[4].vb_num, ib_num - mesh_table[4].ib_num, mesh_table[4].ib_num),
        }
        if stonemountain_num > 0 then
            local de <close> = w:entity(stonemountain.draw_indirect_eid, "draw_indirect:in dispatch:in")
            local idb_handle, itb_handle = de.draw_indirect.idb_handle, de.draw_indirect.itb_handle
            local instance_memory_buffer = get_instance_memory_buffer(stonemountain_info, 20000)
            bgfx.update(itb_handle, 0, instance_memory_buffer)
            local indirect_params = math3d.vector(stonemountain_num, 0, 0, 0)
            create_stonemountain_compute(de.dispatch, stonemountain_num, idb_handle, instance_params, indirect_params, mesh_offset)
            e.render_object.idb_handle = idb_handle
            e.render_object.itb_handle = itb_handle
            e.render_object.draw_num = stonemountain_num
        else
            e.render_object.idb_handle = 0xffffffff
            e.render_object.itb_handle = 0xffffffff
            e.render_object.draw_num = 0
        end

        e.stonemountain.ready = nil
        ::continue::
    end
end
