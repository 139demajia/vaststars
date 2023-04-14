local entities = {
    {
        prototype_name = "指挥中心",
        dir = "N",
        x = 126,
        y = 120,
    },
    {
        prototype_name = "组装机废墟",
        dir = "N",
        items = {
            {"电线杆框架",10},
            {"熔炼炉框架",2},
            {"组装机框架",2},
            {"空气过滤器框架",4},
            {"水电站框架",2},
            {"无人机仓库框架",5},
            {"修路站框架",2},
            {"修管站框架",2},
            {"送货车站框架",2},
            {"收货车站框架",2},
            {"熔炼炉框架",1},
        },
        x = 107,
        y = 134,
    },
    {
        prototype_name = "继电器废墟",
        dir = "S",
        items = {
            {"采矿机框架",1},
            {"组装机框架",2},
            {"科研中心框架",1},
        },
        x = 113,
        y = 120,
    },
    -- {
    --     prototype_name = "无人机仓库",
    --     dir = "N",
    --     x = 116,
    --     y = 121,
    -- },
    {
        prototype_name = "建造中心",
        dir = "N",
        x = 119,
        y = 120,
    },
    {
        prototype_name = "风力发电机I",
        dir = "N",
        x = 122,
        y = 114,
    },
    {
        prototype_name = "排水口废墟",
        dir = "S",
        items = {
            {"组装机框架",2},
            {"熔炼炉框架",1},
            {"运输车框架",4},
            {"电线杆框架",5},
            {"太阳能板框架",6},
        },
        x = 133,
        y = 122,
    },
    {
        prototype_name = "铁箱废墟",
        dir = "W",
        items = {
            {"蓄电池框架",15},
	        {"地下水挖掘机框架",4},
	        {"电解厂框架",1},
	        {"化工厂框架",3},
            {"无人机仓库框架",4},
        },
        x = 125,
        y = 108,
    },
    {
        prototype_name = "组装机I",
        dir = "N",
        x = 133,
        y = 117,
    },
    {
        prototype_name = "熔炼炉I",
        dir = "N",
        x = 140,
        y = 126,
    },
}

local road = {
}

return {
    entities = entities,
    road = road,
}