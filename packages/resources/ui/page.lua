local page_meta = {}
page_meta.__index = page_meta

function page_meta.create(document, e, item_renderer, detail_renderer)
    local row = tonumber(e.getAttribute("row"))
    local col = tonumber(e.getAttribute("col"))
    local page_count = 0
    local page = {
        current_page    = 1,
        pos             = 0,
        draging         = false,
        drag            = {mouse_pos = 0, anchor = 0, delta = 0},
        row             = row,
        col             = col,
        width           = e.getAttribute("width"),
        height          = e.getAttribute("height"),
        page_count      = page_count,
        item_renderer   = item_renderer,
        detail_renderer = detail_renderer,
        pages           = {},
        container       = {},
        document        = document,
    }
    setmetatable(page, page_meta)
    e.style.overflow = 'hidden'
    e.style.width = page.width
    local panel = document.createElement "div"
    e.appendChild(panel)
    panel.className = "pagestyle"
    panel.addEventListener('mousedown', function(event) page:on_mousedown(event) end)
    panel.addEventListener('mousemove', function(event) page:on_drag(event) end)
    panel.addEventListener('mouseup', function(event) page:on_mouseup(event) end)
    panel.style.height = page.height
    panel.style.flexDirection = 'row'
    panel.style.alignItems = 'center'
    panel.style.justifyContent = 'flex-start'
    page.panel = panel

    local footer = document.createElement "div"
    e.appendChild(footer)
    page.footer = footer
    footer.style.flexDirection = 'row'
    footer.style.justifyContent = 'center'
    footer.style.width = '100%'
    footer.style.height = e.getAttribute("footerheight")
    return page
end

function page_meta:update_footer_status()
    for index, e in ipairs(self.footer.childNodes) do
        e.style.backgroundImage = (index == self.current_page) and 'textures/common/page1.texture' or 'textures/common/page0.texture'
    end
end

function page_meta:update_footer()
    local footcount = #self.footer.childNodes
    if footcount > self.page_count then
        local removenode = {}
        for i = self.page_count + 1, footcount do
            removenode[#removenode + 1] = self.footer.childNodes[i]
        end
        for _, e in ipairs(removenode) do
            self.footer.removeChild(e)
        end
    elseif footcount < self.page_count then
        for i = footcount + 1, self.page_count do
            local footitem = self.document.createElement "div"
            footitem.style.width = '20px'
            footitem.style.height = '20px'
            footitem.style.backgroundSize = 'cover'
            self.footer.appendChild(footitem)
        end
    end
    self:update_footer_status()
end

function page_meta:update_contianer()
    for _, page in ipairs(self.pages) do
        self.panel.removeChild(page)
    end
    self.pages = {}
    self.container = {}
    for i = 1, self.page_count do
        local page_e = self.document.createElement "div"
        page_e.style.flexDirection = 'column'
        page_e.style.alignItems = 'center'
        page_e.style.justifyContent = 'space-evenly'
        page_e.style.width = self.width
        page_e.style.height = self.height
        local row = {}
        for r = 1, self.row do
            local row_e = self.document.createElement "div"
            row_e.style.width = self.width
            row_e.style.flexDirection = 'row'
            row_e.style.alignItems = 'center'
            row_e.style.justifyContent = 'space-evenly'
            page_e.appendChild(row_e)
            row[#row + 1] = row_e
        end
        self.panel.appendChild(page_e)
        self.pages[#self.pages + 1] = page_e
        self.container[#self.container + 1] = row
    end
    local count_per_page = self.row * self.col
    local ic = self.page_count * count_per_page
    for index = 1, ic do
        local pid = math.ceil(index / count_per_page)
        local remain = index % count_per_page
        local page = self.container[pid]
        local rid = math.ceil((remain == 0 and count_per_page or remain) / self.col)
        local row = page[rid]
        row.appendChild(self.item_renderer(index))
    end
end

function page_meta:on_dirty(item_count)
    if item_count <= 0 then
        return
    end
    self.item_count = item_count
    self.page_count = math.ceil(item_count / (self.row * self.col))
    self:update_contianer()
    self:update_footer()
end

function page_meta:get_current_page()
    return self.current_page
end

function page_meta:on_item_click(id, row, top)
    if not self.detail then
        return
    end
    if not self.draging then
        if self.source.selected_id ~= id then
            self:do_show_detail(true, id, row, top)
        else
            self:do_show_detail(not self.source.show_detail, id, row, top)
        end
    else
        self:do_show_detail(false, 0, 0, 0)
    end
end

function page_meta:do_show_detail(show, id, row, top)
    if not self.detail then
        return
    end
    local offset = 0
    if show then
        self.source.selected_id = id
        self.detail.style.top = (top + self.item_size) .. 'px'
        local dy = self.panel.childNodes[1].clientHeight - ((row + 1) * (self.item_size + self.gapy) + self.detail_height)
        offset = (dy >= 0) and 0 or dy
    else
        self.source.selected_id = 0
    end
    self.panel.style.top = offset .. 'px'
    self.source.show_detail = show
end

function page_meta:on_mousedown(event)
    self.drag.mouse_pos = event.x
    self.drag.anchor = self.pos
    self.draging = false
end

function page_meta:on_mouseup(event)
    local old_value = self.current_page
    if self.drag.delta < -100 then
        self.current_page = self.current_page + 1
        if self.current_page > self.page_count then
            self.current_page = self.page_count
        end
    elseif self.drag.delta > 100 then
        self.current_page = self.current_page - 1
        if self.current_page < 1 then
            self.current_page = 1
        end
    end
    if old_value ~= self.current_page then
        self:update_footer_status()
    end
    self.pos = (1 - self.current_page) * self.panel.childNodes[1].clientWidth
    self.panel.style.left = tostring(self.pos) .. 'px'
    return old_value ~= self.current_page
end

function page_meta:on_drag(event)
    if event.button then
        self.drag.delta = event.x - self.drag.mouse_pos
        self.pos = self.drag.anchor + self.drag.delta
        local e = self.panel
        local oldClassName = e.className
        e.className = e.className .. " notransition"
        e.style.left = tostring(math.floor(self.pos)) .. 'px'
        e.className = oldClassName
        self.draging = true
    else
        self.drag.delta = 0
    end
end

return page_meta