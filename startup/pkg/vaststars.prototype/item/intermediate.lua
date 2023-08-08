local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

prototype "铁板" {
    type = {"item"},
    station_limit = 12,
    --pile = "4x4",   --物品需要填写： 长 X 高
    --capacity = 32,  --物品需要填写容纳总量值
    pile = "4x4x4",
    backpack_limit = 50,
    drone_depot_gap3 = "0.2x0.05x0.2",
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/iron-plate.texture",
    item_description = "铁制材料锻造加工成的板状材料",
    item_category = "金属",
}

prototype "铁丝" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-wire.glb|mesh.prefab",
    item_icon = "textures/icons/item/iron-wire.texture",
    item_description = "铁制材料锻造加工成的丝状材料",
    item_category = "金属",
}

prototype "铁棒" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/iron-plate.texture",
    item_description = "铁制材料锻造加工成的棒状材料",
    item_category = "金属",
}

prototype "钢板" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-steel-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/steel-plate.texture",
    item_description = "钢制材料锻造加工成的板状材料",
    item_category = "金属",
}

prototype "钢齿轮" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-steel-gear.glb|mesh.prefab",
    item_icon = "textures/icons/item/steel-gear.texture",
    item_description = "由钢制成在旋转轴之间传递动力的机械部件",
    item_category = "金属",
}

prototype "铁矿石" {
    display_name = "铁矿",
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    backpack_limit = 100,
    drone_depot_gap3 = "0.2x0.05x0.2",
    pile_model = "glb/stackeditems/stack-iron-ore.glb|mesh.prefab",
    item_icon = "textures/icons/item/iron-ore.texture",
    item_description = "可以提取铁的矿物",
    item_category = "金属",
    mineral_model = "prefabs/mineral/ground-iron-ore.prefab",
    mineral_area = "3x3",
}

prototype "碎石" {
    display_name = "石矿",
    type = {"item"},
    station_limit = 12,
    pile = "2x3x2",
    drone_depot_gap3 = "1x0.2x1",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-gravel.glb|mesh.prefab",
    item_icon = "textures/icons/item/gravel.texture",
    item_description = "伴生在矿物里的小块石头",
    item_category = "金属",
    mineral_model = "prefabs/mineral/ground-gravel.prefab",
    mineral_area = "3x3",
}

prototype "石砖" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-stone-brick.glb|mesh.prefab",
    item_icon = "textures/icons/item/stone-brick.texture",
    item_description = "由天然石材制成的建筑材料",
    item_category = "物流",
}

prototype "铝矿石" {
    display_name = "铝矿",
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-aluminium-ore.glb|mesh.prefab",
    item_icon = "textures/icons/item/aluminium-ore.texture",
    item_description = "可以提取铝的矿物",
    item_category = "金属",
    mineral_model = "prefabs/mineral/ground-aluminum.prefab",
    mineral_area = "3x3",
}

prototype "碾碎铁矿石" {
    type = {"item"},
    station_limit = 24,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-crush-iron-ore.glb|mesh.prefab",
    item_icon = "textures/icons/item/crush-iron-ore.texture",
    item_description = "被粉碎的铁矿石",
    item_category = "金属",
}

prototype "碾碎铝矿石" {
    type = {"item"},
    station_limit = 24,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-crush-aluminium-ore.glb|mesh.prefab",
    item_icon = "textures/icons/item/crush-aluminium-ore.texture",
    item_description = "被粉碎的铝矿石",
    item_category = "金属",
}

prototype "氢氧化铝" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-aluminium-hydroxide.glb|mesh.prefab",
    item_icon = "textures/icons/item/aluminium-hydroxide.texture",
    item_description = "一种白色结晶粉末,分子式Al(OH)3",
    item_category = "化工",
}

prototype "氧化铝" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-aluminium-oxide.glb|mesh.prefab",
    item_icon = "textures/icons/item/aluminium-oxide.texture",
    item_description = "一种白色固体,分子式Al2O3",
    item_category = "金属",
}

prototype "碳化铝" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/iron-ore.glb|mesh.prefab",
    item_icon = "textures/icons/item/aluminium-oxide.texture",
    item_description = "一种淡黄棕色固体,分子式Al4C3",
    item_category = "金属",
}

prototype "铝板" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-aluminium-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/aluminium-plate.texture",
    item_description = "铝制材料锻造加工成的板状材料",
    item_category = "金属",
}

prototype "铝棒" {
    type = {"item"},
    station_limit = 12,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-aluminium-rod.glb|mesh.prefab",
    item_icon = "textures/icons/item/aluminium-plate.texture",
    item_description = "铝制材料锻造加工成的棒状材料",
    item_category = "金属",
}

prototype "铝丝" {
    type = {"item"},
    station_limit = 16,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-wire.glb|mesh.prefab",
    item_icon = "textures/icons/item/copper-wire.texture",
    item_description = "铝制材料锻造加工成的丝状材料",
    item_category = "金属",
}

prototype "石墨" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-graphite.glb|mesh.prefab",
    item_icon = "textures/icons/item/graphite.texture",
    item_description = "一种高热导率、高电导率、低摩擦的碳材料",
    item_category = "化工",
}

prototype "硅" {
    type = {"item"},
    station_limit = 20,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-silitem_icon.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon.texture",
    item_description = "一种坚硬脆性的结晶固体,分子式Si",
    item_category = "化工",
}

prototype "硅板" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-silitem_icon-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon-plate.texture",
    item_description = "硅制材料锻造加工成的板状材料",
    item_category = "器件",
}

prototype "沙石矿" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-limestone.glb|mesh.prefab",
    item_icon = "textures/icons/item/limestone.texture",
    item_description = "含沙石的矿石",
    item_category = "金属",
}

prototype "氢氧化钠" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-sodium-hydroxide.glb|mesh.prefab",
    item_icon = "textures/icons/item/sodium-hydroxide.texture",
    item_description = "一种白色固体,化学式为NaOH",
    item_category = "化工",
}

prototype "钠" {
    type = {"item"},
    station_limit = 13,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-gravel.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon.texture",
    item_description = "一种银白色固体,化学式为Na",
    item_category = "化工",
}

prototype "金红石" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-gravel.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon.texture",
    item_description = "一种褐红的针状晶形,化学式为TiO2",
    item_category = "金属",
}

prototype "钛板" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 50,
    pile_model = "glb/stackeditems/stack-copper-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon-plate.texture",
    item_description = "钛制材料锻造加工成的板状材料",
    item_category = "金属",
}

-- prototype "石头" {
--     type = {"item"},
--     station_limit = 10,
--     pile = "4x4x4",
--     pile_model = "glb/stackeditems/stack-gravel.glb|mesh.prefab",
--     item_icon = "textures/icons/item/gravel.texture",
--     item_description = "一种矿石",
--     item_category = "金属",
-- }

prototype "沙子" {
    type = {"item"},
    station_limit = 12,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-sand.glb|mesh.prefab",
    item_icon = "textures/icons/item/sand.texture",
    item_description = "由细碎的岩石和矿物颗粒组成的颗粒状材料",
    item_category = "金属",
}

prototype "塑料" {
    type = {"item"},
    station_limit = 12,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-plastic.glb|mesh.prefab",
    item_icon = "textures/icons/item/plastic.texture",
    item_description = "一种由聚合物制成的合成材料",
    item_category = "器件",
}

prototype "电动机I" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    backpack_limit = 25,
    drone_depot_gap3 = "0.65x0.2x0.65",
    pile_model = "glb/stackeditems/stack-motor.glb|mesh.prefab",
    item_icon = "textures/icons/item/motor.texture",
    item_description = "一种将电能转化为机械能的设备",
    item_category = "器件",
}

prototype "电动机II" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-motor.glb|mesh.prefab",
    item_icon = "textures/icons/item/motor.texture",
    item_description = "一种将电能转化为机械能的设备",
    item_category = "器件",
}

prototype "电动机III" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    backpack_limit = 25,
    drone_depot_gap3 = "0.65x0.2x0.65",
    pile_model = "glb/stackeditems/stack-motor.glb|mesh.prefab",
    item_icon = "textures/icons/item/motor.texture",
    item_description = "一种将电能转化为机械能的设备",
    item_category = "器件",
}

prototype "铁齿轮" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-gear.glb|mesh.prefab",
    item_icon = "textures/icons/item/iron-gear.texture",
    item_description = "由铁制成在旋转轴之间传递动力的机械部件",
    item_category = "金属",
}

prototype "玻璃" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-glass.glb|mesh.prefab",
    item_icon = "textures/icons/item/glass.texture",
    item_description = "一种坚硬、透明或半透明的物质",
    item_category = "金属",
}

prototype "坩埚" {
    type = {"item"},
    station_limit = 4,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-crucible.glb|mesh.prefab",
    item_icon = "textures/icons/item/crucible.texture",
    item_description = "一种由石墨制成耐高温的加工容器",
    item_category = "器件",
}

prototype "橡胶" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-rubber.glb|mesh.prefab",
    item_icon = "textures/icons/item/rubber.texture",
    item_description = "一种高弹性聚合物材料",
    item_category = "器件",
}

prototype "电容I" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-capacitor.glb|mesh.prefab",
    item_icon = "textures/icons/item/capacitor.texture",
    item_description = "一种用于存储和释放电能的电子元件",
    item_category = "器件",
}

prototype "电容II" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-capacitor.glb|mesh.prefab",
    item_icon = "textures/icons/item/capacitor.texture",
    item_description = "一种用于存储和释放电能的电子元件",
    item_category = "器件",
}

prototype "绝缘线" {
    type = {"item"},
    station_limit = 12,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-insulated-wire.glb|mesh.prefab",
    item_icon = "textures/icons/item/insulated-wire.texture",
    item_description = "由保护性绝缘材料包裹的电导体",
    item_category = "器件",
}

prototype "逻辑电路" {
    type = {"item"},
    station_limit = 8,
    pile = "2x4x2",
    drone_depot_gap3 = "0.65x0.2x0.65",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-logic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "用于执行逻辑操作和处理数字信息的电路",
    item_category = "器件",
}

prototype "数据线" {
    type = {"item"},
    station_limit = 12,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/insulated-wire.texture",
    item_description = "用于在电子设备之间传输数字数据的电缆",
    item_category = "器件",
}

prototype "运算电路" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "一种用于对输入数据进行数学运算的电路",
    item_category = "器件",
}

prototype "效能插件I" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-green-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/green-electronic-circuit.texture",
    item_description = "降低机器电能消耗的模块",
    item_category = "器件",
}

prototype "效能插件II" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-green-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/green-electronic-circuit.texture",
    item_description = "降低机器电能消耗的模块",
    item_category = "器件",
}

prototype "效能插件III" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-green-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/green-electronic-circuit.texture",
    item_description = "降低机器电能消耗的模块",
    item_category = "器件",
}


prototype "产能插件I" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-red-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/red-electronic-circuit.texture",
    item_description = "提高机器生产能力的模块",
    item_category = "器件",
}

prototype "产能插件II" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-red-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/red-electronic-circuit.texture",
    item_description = "提高机器生产能力的模块",
    item_category = "器件",
}

prototype "产能插件III" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-red-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/red-electronic-circuit.texture",
    item_description = "提高机器生产能力的模块",
    item_category = "器件",
}

prototype "速度插件I" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-blue-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/blue-electronic-circuit.texture",
    item_description = "提高机器生产速度的模块",
    item_category = "器件",
}

prototype "速度插件II" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-blue-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/blue-electronic-circuit.texture",
    item_description = "提高机器生产速度的模块",
    item_category = "器件",
}

prototype "速度插件III" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-blue-electronic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/blue-electronic-circuit.texture",
    item_description = "提高机器生产速度的模块",
    item_category = "器件",
}

prototype "混凝土" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/stone-brick.texture",
    item_description = "由多种材料组成具有高强度、耐久度的建筑材料",
    item_category = "物流",
}

prototype "处理器I" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-logic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "负责执行指令和进行计算的核心组件",
    item_category = "器件",
}

prototype "处理器II" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-logic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "负责执行指令和进行计算的核心组件",
    item_category = "器件",
}

prototype "电池I" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/capacitor.texture",
    item_description = "将化学能转化为电能并储存起来的器件",
    item_category = "器件",
}

prototype "电池II" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/capacitor.texture",
    item_description = "将化学能转化为电能并储存起来的器件",
    item_category = "器件",
}

prototype "玻璃纤维" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/glass.texture",
    item_description = "由细小的玻璃纤维编织而成的高强度材料",
    item_category = "器件",
}

prototype "石墨烯" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon.texture",
    item_description = "具有高电导率、高热导率、高强度和柔韧性的碳原子组成的二维材料",
    item_category = "器件",
}

prototype "隔热板" {
    type = {"item"},
    station_limit = 8,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/silicon-plate.texture",
    item_description = "用于保护火箭在发射和再入大气层过程中遭受极端温度的材料",
    item_category = "器件",
}

prototype "火箭控制器" {
    type = {"item"},
    station_limit = 12,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "负责控制和调节火箭在发射、飞行和着陆过程中各种功能和参数的设备",
    item_category = "器件",
}

prototype "火箭区段" {
    type = {"item"},
    station_limit = 12,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "火箭在发射和飞行过程中执行特定功能的一个部分",
    item_category = "器件",
}

prototype "火箭整流罩" {
    type = {"item"},
    station_limit = 4,
    pile = "4x1x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 25,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "火箭在穿越大气层过程中围绕有效载荷部分的一种保护结构",
    item_category = "器件",
}
------------------------------------------------
prototype "地质科技包" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-geology-pack.glb|mesh.prefab",
    item_icon = "textures/icons/item/geology-pack.texture",
    tech_icon = "textures/icons/item/geology-pack.texture",
    item_description = "用于收集、分析和解释地质调查数据",
    item_category = "器件",
}

prototype "气候科技包" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-climatology-pack.glb|mesh.prefab",
    item_icon = "textures/icons/item/climatology-pack.texture",
    tech_icon = "textures/icons/item/climatology-pack.texture",
    item_description = "用于收集、分析和解释气候变化数据",
    item_category = "器件",
}

prototype "机械科技包" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-mechanical-pack.glb|mesh.prefab",
    item_icon = "textures/icons/item/mechanical-pack.texture",
    tech_icon = "textures/icons/item/mechanical-pack.texture",
    item_description = "用于收集、分析和解释机械过程数据",
    item_category = "器件",
}

prototype "电子科技包" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-electrical-pack.glb|mesh.prefab",
    item_icon = "textures/icons/item/electrical-pack.texture",
    tech_icon = "textures/icons/item/electrical-pack.texture",
    item_description = "用于收集、分析和解释电器工作数据",
    item_category = "器件",
}

prototype "化学科技包" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-chemical-pack.glb|mesh.prefab",
    item_icon = "textures/icons/item/chemical-pack.texture",
    tech_icon = "textures/icons/item/chemical-pack.texture",
    item_description = "用于收集、分析和解释化学反应数据",
    item_category = "器件",
}

prototype "物理科技包" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/chemical-pack.texture",
    tech_icon = "textures/icons/item/chemical-pack.texture",
    item_description = "用于收集、分析和解释物理实验数据",
    item_category = "器件",
}

prototype "废料" {
    type = {"item"},
    station_limit = 16,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-scrap.glb|mesh.prefab",
    item_icon = "textures/icons/item/scrap.texture",
    item_description = "指各种工业产生的任何废弃的固体材料",
    item_category = "器件",
}

prototype "铜板" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-copper-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/copper-plate.texture",
    item_category = "金属",
    item_description = "铜制材料锻造加工成的板状材料",
}
prototype "铜丝" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x2",
    drone_depot_gap3 = "0.5x0.2x1",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-copper-wire.glb|mesh.prefab",
    item_icon = "textures/icons/item/copper-wire.texture",
    item_category = "金属",
    item_description = "铜制材料锻造加工成的丝状材料",
}

prototype "电路板" {
    type = {"item"},
    station_limit = 8,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-logic-circuit.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_category = "器件",
    item_description = "由绝缘材料制成并且安装电子元件的板",
}

prototype "核铀燃料" {
	type = { "item" },
	station_limit = 50,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_category = "器件",
    item_description = "用于核反应堆产生核能的铀-235",
}

prototype "用尽的核铀燃料" {
	type = { "item" },
	station_limit = 50,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_category = "器件",
    item_description = "核能发电生产的副产品",
}
--------------------------
prototype "海藻" {
	type = { "item" },
	station_limit = 50,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "一种植物",
    item_category = "器件",
}

prototype "纤维燃料" {
	type = { "item" },
	station_limit = 50,
    pile = "4x4x4",
    drone_depot_gap3 = "0.2x0.05x0.2",
    backpack_limit = 100,
    pile_model = "glb/stackeditems/stack-iron-plate.glb|mesh.prefab",
    item_icon = "textures/icons/item/logic-circuit.texture",
    item_description = "一种燃料",
    item_category = "器件",
}