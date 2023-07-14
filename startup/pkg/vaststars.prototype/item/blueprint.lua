local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

-- prototype "破损水电站" {
--     type = {"item"},
--     stack = 10,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-hydroplant.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损空气过滤器" {
--     type = {"item"},
--     stack = 10,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-air-filter1.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损地下水挖掘机" {
--     type = {"item"},
--     stack = 50,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-pump.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损电解厂" {
--     type = {"item"},
--     stack = 10,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-electrolysis1.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损化工厂" {
--     type = {"item"},
--     stack = 10,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-chemistry2.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损组装机" {
--     type = {"item"},
--     stack = 10,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-assembler.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损铁制电线杆" {
--     type = {"item"},
--     stack = 50,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-electric-pole1.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损太阳能板" {
--     type = {"item"},
--     stack = 50,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-solar-panel.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

-- prototype "破损蓄电池" {
--     type = {"item"},
--     stack = 50,
--     pile = "4x1x4",
--     pile_model = "prefabs/stackeditems/iron-ore.prefab",
--     icon = "textures/construct/broken-grid-battery.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

prototype "破损运输车辆" {
    type = {"item"},
    stack = 50,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-truck.texture",
    item_category = "加工",
    item_description = "需要维修的运输车辆",
}

-- prototype "破损物流需求站" {
--     type = {"item"},
--     stack = 50,
--     icon = "textures/construct/broken-goodsstation-input.texture",
--     item_category = "加工",
--     item_description = "用来抓取货物的机械装置",
-- }

----

prototype "初级建筑框架" {
    type = {"item"},
    stack = 8,
    pile = "2x2x2",
    backpack_stack = 8,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-hydroplant.texture",
    item_category = "加工",
    item_description = "用于修建初级建筑的框架",
}

prototype "中级建筑框架" {
    type = {"item"},
    stack = 8,
    pile = "2x2x2",
    backpack_stack = 8,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-hydroplant.texture",
    item_category = "加工",
    item_description = "用于修建中级建筑的框架",
}

prototype "高级建筑框架" {
    type = {"item"},
    stack = 8,
    pile = "2x2x2",
    backpack_stack = 8,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-hydroplant.texture",
    item_category = "加工",
    item_description = "用于修建高级建筑的框架",
}

prototype "水电站框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-hydroplant.texture",
    item_category = "加工",
    item_description = "用于建造水电站的框架",
}

prototype "空气过滤器框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-air-filter1.texture",
    item_category = "加工",
    item_description = "用于建造空气过滤器的框架",
}

prototype "地下水挖掘机框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-pump.texture",
    item_category = "加工",
    item_description = "用于建造地下水挖掘机的框架",
}

prototype "电解厂框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-electrolysis1.texture",
    item_category = "加工",
    item_description = "用于建造电解厂的框架",
}

prototype "化工厂框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-chemistry2.texture",
    item_category = "加工",
    item_description = "用于建造化工厂的框架",
}

prototype "采矿机框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-miner.texture",
    item_category = "加工",
    item_description = "用于建造采矿机的框架",
}

prototype "组装机框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-assembler.texture",
    item_category = "加工",
    item_description = "用于建造组装机的框架",
}

prototype "电线杆框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-electric-pole1.texture",
    item_category = "加工",
    item_description = "用于建造铁制电线杆的框架",
}

prototype "无人机仓库框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-drone-depot.texture",
    item_category = "加工",
    item_description = "用于建造无人机仓库I的框架",
}

prototype "压力泵框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-drone-depot.texture",
    item_category = "加工",
    item_description = "用于抽水的框架",
}

prototype "液罐框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-drone-depot.texture",
    item_category = "加工",
    item_description = "用于液罐的框架",
}

prototype "车站框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-logisitic.texture",
    item_category = "加工",
    item_description = "用于建造车站的框架",
}

prototype "出货车站框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-goodsstation-output.texture",
    item_category = "加工",
    item_description = "用于建造出货车站的框架",
}

prototype "收货车站框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-goodsstation-input.texture",
    item_category = "加工",
    item_description = "用于建造收货车站的框架",
}

prototype "熔炼炉框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-furnace.texture",
    item_category = "加工",
    item_description = "用于建造熔炼炉的框架",
}

prototype "太阳能板框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-solar-panel.texture",
    item_category = "加工",
    item_description = "用于建造太阳能板的框架",
}

prototype "蓄电池框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-grid-battery.texture",
    item_category = "加工",
    item_description = "用于建造蓄电池的框架",
}

prototype "车辆厂框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-goodsstation-output.texture",
    item_category = "加工",
    item_description = "用于建造车辆厂的框架",
}

prototype "科研中心框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-lab.texture",
    item_category = "加工",
    item_description = "用于建造科研中心的框架",
}

prototype "排水口框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-assembler.texture",
    item_category = "加工",
    item_description = "用于排水设施的框架",
}

prototype "粉碎机框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-assembler.texture",
    item_category = "加工",
    item_description = "用于粉碎物品的框架",
}

prototype "蒸馏厂框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-assembler.texture",
    item_category = "加工",
    item_description = "用于蒸馏气体设施的框架",
}

prototype "烟囱框架" {
    type = {"item"},
    stack = 4,
    pile = "4x1x4",
    backpack_stack = 16,
    pile_model = "prefabs/stackeditems/iron-ore.prefab",
    icon = "textures/construct/broken-assembler.texture",
    item_category = "加工",
    item_description = "用于排气设施的框架",
}