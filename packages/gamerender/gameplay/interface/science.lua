local global = require "global"
local iprototype = require "gameplay.interface.prototype"

local M = {}

function M.update_tech_tree()
    if global.science.tech_tree then
        return
    end
    local tech_tree = {}
    for _, typeobject in pairs(iprototype.each_maintype "tech") do
        tech_tree[typeobject.name] = {name = typeobject.name, pretech = {}, posttech = {}, detail = typeobject, task = typeobject.task and true or false }
    end
    for _, tnode in pairs(tech_tree) do
        local prenames = tnode.detail.prerequisites
        if prenames then
            for _, name in ipairs(prenames) do
                local pre = tech_tree[name]
                if not pre then
                    print("Error Cann't found tech: ", name)
                else
                    tnode.pretech[#tnode.pretech + 1] = pre
                    pre.posttech[#pre.posttech + 1] = tnode
                end
            end
        end
    end
    global.science.tech_tree = tech_tree
end
function M.update_tech_list(gw)
    if not global.science.tech_tree then
        M.update_tech_tree()
    end
    local tech_tree = global.science.tech_tree
    local techlist = {}
    local finishlist = {}
    for _, tnode in pairs(tech_tree) do
        local prenames = tnode.detail.prerequisites
        local can_research = true
        if prenames then
            for _, name in ipairs(prenames) do
                local pre = tech_tree[name]
                if pre then
                    if can_research and not gw:is_researched(pre.name) then
                        can_research = false
                    end
                end
            end
        end
        if gw:is_researched(tnode.name) then
            finishlist[#finishlist + 1] = tnode
        else
            if can_research then
                techlist[#techlist + 1] = tnode
            end
        end
    end
    global.science.tech_list = techlist
    global.science.finish_list = finishlist
end
return M