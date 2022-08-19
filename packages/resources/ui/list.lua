local list_meta = {}
list_meta.__index = list_meta

function list_meta.create(document, e, item_count, item_renderer, detail_renderer)
    local list = {
        direction   = tonumber(e.getAttribute("direction")),
        width       = e.getAttribute("width"),
        height      = e.getAttribute("height"),
        item_count  = item_count,
        pos         = 0,
        drag        = {mouse_pos = 0, anchor = 0, delta = 0},
        item_renderer = item_renderer,
        detail_renderer = detail_renderer,
        item_map       = {},
        index_map      = {},
        document    = document,
        data_for_item   = false
    }
    setmetatable(list, list_meta)
    e.style.overflow = 'hidden'
    e.style.width = list.width
    e.style.height = list.height
    local panel = document.createElement "div"
    e.appendChild(panel)
    panel.className = "liststyle"
    if list.direction == 0 then
        panel.style.height = list.height
        panel.style.flexDirection = 'row'
    else
        panel.style.width = list.width
        panel.style.flexDirection = 'column'
    end
    panel.style.alignItems = 'center'
    panel.style.justifyContent = 'flex-start'
    panel.addEventListener('mousedown', function(event) list:on_mousedown(event) end)
    panel.addEventListener('mousemove', function(event) list:on_drag(event) end)
    panel.addEventListener('mouseup', function(event) list:on_mouseup(event) end)
    panel.addEventListener('touchstart', function(event) list:on_mousedown(event) end)
    panel.addEventListener('touchmove', function(event) list:on_drag(event) end)
    panel.addEventListener('touchend', function(event) list:on_mouseup(event) end)
    list.view = e
    list.panel = panel
    list:on_dirty_all(item_count)
    return list
end

function list_meta:set_selected(item)
    if self.selected == item then
        return false
    end
    self.selected = item
    return true
end

function list_meta:get_selected()
    return self.selected
end

function list_meta:get_item(index)
    return self.index_map[index].item
end

function list_meta:on_dirty(index)
    if self.data_for_item then
        return
    end
    local iteminfo = self.index_map[index]
    self:show_detail(iteminfo.item, false)
    if self.selected == iteminfo.item then
        self.selected = nil
    end
    self.item_map[iteminfo.item] = nil
    self.panel.removeChild(iteminfo.item)
    local new_item = self.item_renderer(index)
    self.item_map[new_item] = iteminfo
    iteminfo.item = new_item
    self.panel.appendChild(new_item, index - 1)
end

function list_meta:on_dirty_all(item_count)
    self.panel.removeAllChild()
    self.item_count = item_count or self.item_count
    self.item_width = nil
    self.item_height = nil
    self.item_map = {}
    self.index_map = {}
    if self.data_for_item then
        self.item_renderer(self.panel)
    else
        for index = 1, self.item_count do
            local item = self.item_renderer(index)
            self.panel.appendChild(item)
            local item_info = {index = index, detail = false, item = item}
            self.item_map[item] = item_info
            self.index_map[#self.index_map + 1] = item_info
        end
    end
end

function list_meta:set_list_size(width, height)
    self.width = width
    self.height = height
    self:on_dirty()
end

function list_meta:set_item_count(count)
    self.item_count = count
    self:on_dirty()
end
function list_meta:show_detail(it, show)
    local iteminfo
    if type(it) == "number" then
        iteminfo = self.index_map[it]
    else
        iteminfo = self.item_map[it]
    end
     
    if not iteminfo then
        return
    end
    if show then
        if not iteminfo.detail then
            self.detail = self.detail_renderer(iteminfo.index)
            iteminfo.item.parentNode.appendChild(self.detail, iteminfo.index)
            iteminfo.detail = true
        end
    else
        if iteminfo.detail and self.detail then
            local parent = self.detail.parentNode
            parent.removeChild(self.detail)
            self.detail = nil
            iteminfo.detail = false
        end
    end
end
function list_meta:on_mousedown(event)
    if #self.index_map < 1 or not self.item_width then
        local childNodes = self.data_for_item and self.panel.childNodes[1].childNodes or self.panel.childNodes
        for index, it in ipairs(childNodes) do
            if not self.item_width then
                self.item_width = it.clientWidth
                self.item_height = it.clientHeight
            end
            local item_info = {index = index, detail = false, item = it}
            self.item_map[it] = item_info
            self.index_map[#self.index_map + 1] = item_info
        end
    end
    local pos = ((self.direction == 0) and event.x or event.y)
    if not pos and event.targetTouches and #event.targetTouches > 0 then
        pos = (self.direction == 0) and event.targetTouches[1].x or event.targetTouches[1].y
    end
    self.drag.mouse_pos = pos
    self.drag.anchor = self.pos
end

function list_meta:on_mouseup(event)
    local min = (self.direction == 0) and (self.view.clientWidth - self.item_count * self.item_width) or (self.view.clientHeight - self.item_count * self.item_height)
    if min > 0 then
        min = 0
    end
    local adjust = false
    if self.pos > 0 then
        self.pos = 0
        adjust = true  
    elseif self.pos < min then
        self.pos = min
        adjust = true
    end
    if adjust then
        if self.direction == 0 then
            self.panel.style.left = tostring(self.pos) .. 'px'
        else
            self.panel.style.top = tostring(self.pos) .. 'px'
        end
    end
end

function list_meta:on_drag(event)
    local pos = (self.direction == 0) and event.x or event.y
    if not pos and event.targetTouches and #event.targetTouches > 0 then
        pos = (self.direction == 0) and event.targetTouches[1].x or event.targetTouches[1].y
    end
    if event.button or event.targetTouches then
        self.drag.delta = pos - self.drag.mouse_pos
        self.pos = self.drag.anchor + self.drag.delta
        local e = self.panel
        local oldClassName = e.className
        e.className = e.className .. " notransition"
        if self.direction == 0 then
            e.style.left = tostring(math.floor(self.pos)) .. 'px'
        else
            e.style.top = tostring(math.floor(self.pos)) .. 'px'
        end
        e.className = oldClassName
    end
end

return list_meta