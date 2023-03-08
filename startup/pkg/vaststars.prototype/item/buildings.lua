--物品在仓库显示大小为:4X4、4X2、4X1、2X1四种

local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

prototype "指挥中心" {
    type = {"item"},
    stack = 1,
    item_description = "基地建造的核心建筑",
}
prototype "组装机I" {
    type = {"item"},
    stack = 1,
    item_description = "用来组装或制造工业产品的工厂",
}

prototype "组装机II" {
    type = {"item"},
    stack = 1,
    item_description = "用来组装或制造工业产品的工厂",
}
prototype "车辆厂I" {
    type = {"item"},
    stack = 1,
    item_description = "用来组装运输车的工厂",
}

prototype "熔炼炉I" {
    type = {"item"},
    stack = 1,
    item_description = "用来熔炼矿石的炉子",
}

prototype "熔炼炉II" {
    type = {"item"},
    stack = 1,
    item_description = "用来熔炼矿石的炉子",
}

prototype "小铁制箱子I" {
    type = {"item"},
    stack = 5,
    item_description = "贮藏物品的容器",
}

prototype "小铁制箱子II" {
    type = {"item"},
    stack = 5,
    item_description = "贮藏物品的容器",
}

prototype "大铁制箱子I" {
    type = {"item"},
    stack = 5,
    item_description = "贮藏物品的容器",
}

prototype "仓库" {
    type = {"item"},
    stack = 1,
    item_description = "贮藏物品的容器",
}

prototype "基建站" {
    type = {"item"},
    stack = 1,
    item_description = "修建道路的专用设备",
}

prototype "物流需求站" {
    type = {"item"},
    stack = 1,
    item_description = "将货物从运输车卸载到货站",
}

prototype "无人机仓库" {
    type = {"item"},
    stack = 1,
    item_description = "储存货物的放置点",
}

prototype "建造中心" {
    type = {"item"},
    stack = 1,
    item_description = "用来建造建筑的场所",
}

prototype "道路建造站" {
    type = {"item"},
    stack = 1,
    item_description = "用来建造道路的场所",
}

prototype "管道建造站" {
    type = {"item"},
    stack = 1,
    item_description = "用来建造管道的场所",
}

prototype "车站" {
    type = {"item"},
    stack = 1,
    item_description = "运输汽车装卸货物的停靠站点",
}

prototype "采矿机I" {
    type = {"item"},
    stack = 1,
    item_description = "用来挖掘矿物资源的机器",
}

prototype "采矿机II" {
    type = {"item"},
    stack = 1,
    item_description = "用来挖掘矿物资源的机器",
}

prototype "机器爪I" {
    type = {"item"},
    stack = 50,
    item_description = "用来抓取货物的机械装置",
}

prototype "蒸汽发电机I" {
    type = {"item"},
    stack = 1,
    item_description = "将热能转换成电能的机器",
}

prototype "化工厂I" {
    type = {"item"},
    stack = 1,
    item_description = "加工化工原料的工厂",
}

prototype "铸造厂I" {
    type = {"item"},
    stack = 1,
    item_description = "铸造金属的工厂",
}

prototype "蒸馏厂I" {
    type = {"item"},
    stack = 1,
    item_description = "用来蒸馏液体的工厂",
}

prototype "粉碎机I" {
    type = {"item"},
    stack = 1,
    item_description = "用于粉碎物体的装置",
}

prototype "浮选器I" {
    type = {"item"},
    stack = 1,
    item_description = "用于浮沉矿石的机器",
}

prototype "物流中心I" {
    type = {"item"},
    stack = 1,
    item_description = "派遣和停靠运输车辆的物流车站",
}

prototype "风力发电机I" {
    type = {"item"},
    stack = 1,
    item_description = "利用风能转换电能的机器",
}

prototype "铁制电线杆" {
    type = {"item"},
    stack = 5,
    item_description = "用于传输电力的铁制电杆",
}

prototype "科研中心I" {
    type = {"item"},
    stack = 1,
    item_description = "研究科技技术的中心",
}

prototype "电解厂I" {
    type = {"item"},
    stack = 1,
    item_description = "使用电能电离液体的工厂",
}

prototype "太阳能板I" {
    type = {"item"},
    stack = 1,
    item_description = "用来收集太阳能发电的装置",
}

prototype "蓄电池I" {
    type = {"item"},
    stack = 5,
    item_description = "可充电和放电的蓄能装置",
}

prototype "水电站I" {
    type = {"item"},
    stack = 1,
    item_description = "处理水的工厂",
}

prototype "砖石公路-X型-01" {
    type = {"item"},
    stack = 100,
    item_description = "供车辆行驶的砖石公路",
}

prototype "运输车辆I" {
    type = {"item"},
    stack = 1,
    item_description = "运输货物的交通工具",
}

prototype "换热器I" {
    type = {"item"},
    stack = 1,
    item_description = "将水变成蒸汽的机器",
}

prototype "锅炉I" {
    type = {"item"},
    stack = 1,
    item_description = "将水变成蒸汽的机器",
}

prototype "热管1-X型" {
    type = {"item"},
    stack = 100,
    item_description = "传导热量的特殊管道",
}