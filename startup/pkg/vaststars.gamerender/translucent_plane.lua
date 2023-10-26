local ecs = ...
local world = ecs.world
local w = world.w

local itp = ecs.require "ant.landform|translucent_plane_system"
local CONSTANT <const> = require "gameplay.interface.constant"
local RENDER_LAYER <const> = ecs.require "engine.render_layer".RENDER_LAYER

local tp = {}
local WIDTH <const> = CONSTANT.MAP_WIDTH
local HEIGHT <const> = CONSTANT.MAP_HEIGHT
local TILE_SIZE <const> = CONSTANT.TILE_SIZE
local OFFSET <const> = {-(WIDTH * TILE_SIZE)/2, -(HEIGHT * TILE_SIZE)/2}

-- render axis
-- z
-- ▲
-- │
-- │
-- └──►x

local function get_sub_rects(rects)

    local function remove_corner_sub_rects(rects)
        local rnum = #rects
        for i = 1, rnum do
            for j = i + 1, rnum do
                local srect, drect = rects[i], rects[j]
                local sx, sy, sw, sh = srect.x, srect.y, srect.w, srect.h
                local dx, dy, dw, dh = drect.x, drect.y, drect.w, drect.h
                local intersect = not((sx + sw <= dx) or (dx + dw <= sx) or (sy + sh <= dy) or (dy + dh <= sy))
                if intersect then
                    local xx, yy, ww, hh = sx, sy, sw, sh
                    if sw > dw then
                        ww = sw - dw
                        if sx == dx then xx = sx + dw end
                    end
    
                    if sh > dh then
                        hh = sh - dh
                        if sy == dy then yy = sy + dh end
                    end
                    rects[i] = {x = xx, y = yy, w = ww, h = hh, gid = rects[i].gid, color = rects[i].color} 
                end
            end
        end
        return rects    
    end

    local function is_intersect(srect, drect)
        local gid, color = srect.gid, srect.color
        local sx, sy, sw, sh = srect.x, srect.y, srect.w, srect.h
        local dx, dy, dw, dh = drect.x, drect.y, drect.w, drect.h
    
        local not_intersect = (sx + sw <= dx) or (dx + dw <= sx) or (sy + sh <= dy) or (dy + dh <= sy)
        if not_intersect then return -1, {} end
    
        local inside = (sx >= dx) and (sx + sw <= dx + dw) and (sy >= dy) and (sy + sh <= dy + dh)
        if inside then return 0, {} end
    
        local w1, w2, h1, h2 = dx - sx, sx + sw - dx - dw, dy - sy, sy + sh - dy - dh
        local valid_masks = {w1 > 0, w2 > 0, h1 > 0, h2 > 0}
        local all_rects = {
            {x = sx,      y = sy,      w = w1, h = sh, gid = gid, color = color},
            {x = dx + dw, y = sy,      w = w2, h = sh, gid = gid, color = color},
            {x = sx,      y = sy,      w = sw, h = h1, gid = gid, color = color},
            {x = sx,      y = dy + dh, w = sw, h = h2, gid = gid, color = color}
        }
        local valid_rects = {}
        for i = 1, 4 do
            if valid_masks[i] then valid_rects[#valid_rects+1] = all_rects[i] end
        end
        return 1, remove_corner_sub_rects(valid_rects)
    end

    local i = 1
    local rnum = #rects
    while i <= rnum do
        local j = i + 1
        while j <= rnum do
            local srect, drect = rects[i], rects[j]
            local flag, new_rects = is_intersect(srect,drect)
            if flag >= 0 then -- srect intersect with drect
                if flag == 1 then -- srect not inside in drect
                    for _, v in ipairs(new_rects) do
                        table.insert(rects, i + 1, v)
                    end
                end
                table.remove(rects, i)
                rnum = #rects
                goto continue
            end
            j = j + 1
        end
        i = i + 1
        ::continue::
    end
    return rects
end

local function set_offsets(rects)
    for _, rect in ipairs(rects) do
        rect.x, rect.y = rect.x + OFFSET[1], rect.y + OFFSET[2]
    end
end

function tp.update(rects)
    set_offsets(rects)
    local sub_rects = get_sub_rects(rects)
    itp.update_tp(sub_rects, RENDER_LAYER.TRANSLUCENT_PLANE, TILE_SIZE)
end

function tp.clear()
    itp.clear_tp()
end

return tp