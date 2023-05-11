local entities = { {
    dir = "N",
    items = {},
    prototype_name = "指挥中心",
    recipe = "车辆装配",
    x = 126,
    y = 120
  }, {
    dir = "N",
    items = { { "收货车站", 2 }, { "送货车站", 2 }, { "铁制电线杆", 10 }, { "熔炼炉I", 2 }, { "水电站I", 2 }, { "无人机仓库", 5 } },
    prototype_name = "机身残骸",
    x = 107,
    y = 134
  }, {
    dir = "S",
    items = { { "无人机仓库", 4 }, { "采矿机I", 2 }, { "科研中心I", 1 }, { "组装机I", 4 } },
    prototype_name = "机尾残骸",
    x = 110,
    y = 120
  }, {
    dir = "S",
    items = { { "风力发电机I", 1 }, { "蓄电池I", 10 }, { "太阳能板I", 6 }, { "蒸汽发电机I", 8 }, { "锅炉I", 4 } },
    prototype_name = "机翼残骸",
    x = 133,
    y = 122
  }, {
    dir = "W",
    items = { { "电解厂I", 1 }, { "空气过滤器I", 4 }, { "化工厂I", 3 }, { "地下水挖掘机", 4 } },
    prototype_name = "机头残骸",
    x = 125,
    y = 108
  }, {
    dir = "N",
    prototype_name = "采矿机I",
    recipe = "碎石挖掘",
    x = 143,
    y = 147
  }, {
    dir = "N",
    prototype_name = "风力发电机I",
    x = 146,
    y = 147
  }, {
    dir = "N",
    prototype_name = "无人机仓库",
    x = 141,
    y = 145
  }, {
    dir = "E",
    prototype_name = "送货车站",
    x = 141,
    y = 144
  }, {
    dir = "N",
    prototype_name = "采矿机I",
    recipe = "铁矿石挖掘",
    x = 162,
    y = 127
  }, {
    dir = "N",
    prototype_name = "风力发电机I",
    x = 162,
    y = 130
  }, {
    dir = "N",
    prototype_name = "无人机仓库",
    x = 159,
    y = 126
  }, {
    dir = "N",
    prototype_name = "送货车站",
    x = 157,
    y = 124
  }, {
    dir = "N",
    prototype_name = "采矿机I",
    recipe = "碎石挖掘",
    x = 113,
    y = 127
  }, {
    dir = "N",
    prototype_name = "风力发电机I",
    x = 113,
    y = 123
  }, {
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 120,
    y = 119
  }, {
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 128,
    y = 119
  }, {
    dir = "N",
    item = "碎石",
    prototype_name = "无人机仓库",
    x = 117,
    y = 126
  }, {
    dir = "N",
    item = "碎石",
    prototype_name = "送货车站",
    x = 119,
    y = 124
  }, {
    dir = "W",
    item = "碎石",
    prototype_name = "收货车站",
    x = 139,
    y = 113
  }, {
    dir = "W",
    prototype_name = "收货车站",
    x = 139,
    y = 117
  }, {
    dir = "N",
    item = "碎石",
    prototype_name = "无人机仓库",
    x = 136,
    y = 112
  }, {
    dir = "N",
    prototype_name = "无人机仓库",
    x = 136,
    y = 116
  }, {
    dir = "N",
    fluid_name = "",
    prototype_name = "熔炼炉I",
    x = 133,
    y = 116
  }, {
    dir = "N",
    fluid_name = "",
    prototype_name = "组装机I",
    x = 133,
    y = 111
  }, {
    dir = "N",
    prototype_name = "无人机仓库",
    x = 131,
    y = 112
  }, {
    dir = "N",
    prototype_name = "无人机仓库",
    x = 131,
    y = 116
  }, {
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 134,
    y = 119
  }, {
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 134,
    y = 114
  }, {
    dir = "N",
    item = "运输车框架",
    prototype_name = "无人机仓库",
    x = 131,
    y = 123
  } }
local road = {
  [28044] = 8,
  [28300] = 10,
  [28556] = 10,
  [28811] = 44,
  [28812] = 11,
  [29067] = 58,
  [29068] = 10,
  [29323] = 38,
  [29324] = 11,
  [29580] = 10,
  [29835] = 44,
  [29836] = 11,
  [30091] = 58,
  [30092] = 10,
  [30347] = 38,
  [30348] = 11,
  [30604] = 10,
  [30860] = 10,
  [31116] = 10,
  [31372] = 10,
  [31628] = 10,
  [31862] = 44,
  [31863] = 53,
  [31864] = 41,
  [31871] = 44,
  [31872] = 53,
  [31873] = 41,
  [31884] = 10,
  [31900] = 44,
  [31901] = 53,
  [31902] = 41,
  [32116] = 4,
  [32117] = 5,
  [32118] = 7,
  [32119] = 5,
  [32120] = 7,
  [32121] = 5,
  [32122] = 5,
  [32123] = 5,
  [32124] = 5,
  [32125] = 5,
  [32126] = 5,
  [32127] = 7,
  [32128] = 5,
  [32129] = 7,
  [32130] = 5,
  [32131] = 5,
  [32132] = 5,
  [32133] = 5,
  [32134] = 5,
  [32135] = 5,
  [32136] = 5,
  [32137] = 5,
  [32138] = 5,
  [32139] = 5,
  [32140] = 15,
  [32141] = 5,
  [32142] = 5,
  [32143] = 5,
  [32144] = 5,
  [32145] = 5,
  [32146] = 5,
  [32147] = 5,
  [32148] = 5,
  [32149] = 5,
  [32150] = 5,
  [32151] = 5,
  [32152] = 5,
  [32153] = 5,
  [32154] = 5,
  [32155] = 5,
  [32156] = 7,
  [32157] = 5,
  [32158] = 7,
  [32159] = 1,
  [32396] = 10,
  [32652] = 10,
  [32908] = 10,
  [33164] = 10,
  [33420] = 10,
  [33676] = 10,
  [33932] = 10,
  [34188] = 10,
  [34444] = 10,
  [34700] = 10,
  [34956] = 10,
  [35212] = 10,
  [35468] = 10,
  [35724] = 10,
  [35980] = 10,
  [36236] = 10,
  [36492] = 10,
  [36748] = 14,
  [36749] = 41,
  [37004] = 10,
  [37005] = 58,
  [37260] = 14,
  [37261] = 35,
  [37516] = 10,
  [37772] = 10,
  [38028] = 2
}

local function prepare(world)
  local prototype = import_package "vaststars.gameplay".prototype
  local e = assert(world.ecs:first("base eid:in"))
  e = world.entity[e.eid]
  local pt = prototype.queryByName("运输车辆I")
  local slot, idx
  for i = 1, 256 do
      local s = world:container_get(e.chest, i)
      if not s then
          break
      end
      if s.item == pt.id then
          slot, idx = s, i
          break
      end
  end
  assert(slot)
  world:container_set(e.chest, idx, {amount = 25, limit = 25})
end

return {
    name = "路网测试",
    entities = entities,
    road = road,
    prepare = prepare,
}