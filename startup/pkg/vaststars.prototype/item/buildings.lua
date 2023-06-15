--物品在仓库显示大小为:4X4、4X2、4X1、2X1四种

local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

prototype "指挥中心" {
    type = {"item"},
    group = {"物流"},
    stack = 1,
    item_description = "存储材料和装配运输汽车的核心建筑",
}
prototype "组装机I" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用来打印工业产品或建筑框架的设备",
}

prototype "组装机II" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用来打印工业产品或建筑框架的设备",
}

prototype "熔炼炉I" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用来熔炼矿石和精炼金属的设备",
}

prototype "熔炼炉II" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用来熔炼矿石和精炼金属的设备",
}

prototype "小铁制箱子I" {
    type = {"item"},
    group = {"物流"},
    stack = 5,
    item_description = "贮藏物品的容器",
}

prototype "小铁制箱子II" {
    type = {"item"},
    group = {"物流"},
    stack = 5,
    item_description = "贮藏物品的容器",
}

prototype "大铁制箱子I" {
    type = {"item"},
    group = {"物流"},
    stack = 5,
    item_description = "贮藏物品的容器",
}

prototype "仓库" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "贮藏物品的容器",
}

prototype "物流需求站" {
    type = {"item"},
    group = {"物流"},
    stack = 1,
    item_description = "将货物从运输车卸载到货站",
}

prototype "无人机仓库I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "使用无人机运输并储存货物的仓库",
}

prototype "建造中心" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "用来建造建筑的场所",
}

prototype "修路站" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "用来建造道路的场所",
}

prototype "修管站" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "用来建造管道的场所",
}

prototype "采矿机I" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用来挖掘地面矿物资源的设备",
}

prototype "采矿机II" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用来挖掘地面矿物资源的设备",
}

prototype "蒸汽发电机I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "将蒸汽的热能转换成电能的设备",
}

prototype "化工厂I" {
    type = {"item"},
    group = {"化工"},
    stack = 10,
    item_description = "从事化学工业和处理化学原料的工厂",
}

prototype "铸造厂I" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "铸造金属的工厂",
}

prototype "蒸馏厂I" {
    type = {"item"},
    group = {"化工"},
    stack = 10,
    item_description = "使用蒸馏方式对液态原料精加工的工厂",
}

prototype "粉碎机I" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用于粉碎矿石或其他固体的设备",
}

prototype "浮选器I" {
    type = {"item"},
    group = {"加工"},
    stack = 10,
    item_description = "用于浮沉矿石进行分离的机器",
}

prototype "物流中心I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "派遣和停靠运输车辆的物流车站",
}

prototype "风力发电机I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "利用风能转换电能的装置",
}

prototype "铁制电线杆" {
    type = {"item"},
    group = {"物流"},
    stack = 25,
    item_description = "用于传输电力的铁制电杆",
}

prototype "科研中心I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "用于科学研究与试验设计的设施",
}

prototype "出货车站" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "给运输车提供货物的车站",
}

prototype "收货车站" {
    type = {"item"},
    group = {"物流"},
    stack = 8,
    item_description = "从运输车收取货物的车站",
}

prototype "电解厂I" {
    type = {"item"},
    group = {"化工"},
    stack = 10,
    item_description = "用电化学反应处理液体的工厂",
}

prototype "太阳能板I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "收集太阳能并利用光电效应发电的装置",
}

prototype "蓄电池I" {
    type = {"item"},
    group = {"物流"},
    stack = 25,
    item_description = "可充电和放电的蓄电装置",
}

prototype "水电站I" {
    type = {"item"},
    group = {"化工"},
    stack = 10,
    item_description = "处理气液的工厂",
}

prototype "砖石公路-X型" {
    type = {"item"},
    group = {"物流"},
    stack = 100,
    item_description = "供车辆行驶的砖石公路",
}

prototype "运输车辆I" {
    type = {"item"},
    group = {"物流"},
    stack = 50,
    item_description = "在道路上行驶并运输货物的交通工具",
    capacitance = "10MJ",
    speed = 63,
    icon = "textures/construct/truck.texture",
    model = "prefabs/lorry-1.prefab",
}

prototype "换热器I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "将水变成蒸汽的机器",
}

prototype "地热井I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "通过地下钻探获取地热资源的装置",
}

prototype "锅炉I" {
    type = {"item"},
    group = {"物流"},
    stack = 10,
    item_description = "通过加热将水变成蒸汽的装置",
}

prototype "热管1-X型" {
    type = {"item"},
    group = {"物流"},
    stack = 100,
    item_description = "传导热量的特殊管道",
}