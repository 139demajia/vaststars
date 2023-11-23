local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

prototype "指挥中心" {
    model = "glbs/headquater-1.glb|mesh.prefab",
    model_status = {work = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_headquarter.texture",
    construct_detector = {"exclusive"},
    type = {"building", "base", "chest"},
    chest_type = "supply",
    maxslot = 16,
    speed = "50%",
    area = "6x6",
    sound = "building/headquarter",
    camera_distance = 100,
    teardown = false,
    move = false,
    copy = false,
}

prototype "物流中心" {
    model = "glbs/headquater-1.glb|mesh.prefab",
    model_status = {work = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_headquarter.texture",
    construct_detector = {"exclusive"},
    craft_category = {"基地制造"},
    item = "运输车辆I",
    type = {"building", "factory"},
    speed = "50%",
    maxslot = 8,
    area = "6x6",
    sound = "building/logistics-center",
    camera_distance = 100,
    crossing = {
        connections = {
            {type="factory", position={2,4,"S"}},
        },
    },
    starting = "2,2",
    road = {
        "2,2,║",
        "2,4,║",
        "2,6,╨",
    },
}

prototype "科研中心I" {
    type = {"building", "consumer","laboratory"},
    chest_style = "chest",
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "100kW",
    speed = "100%",
    sound = "building/lab",
    camera_distance = 75,
    drone_height = 42,
    priority = "secondary",
    inputs = {
        "地质科技包",
        "气候科技包",
        "机械科技包",
        "电子科技包",
        "化学科技包",
        "物理科技包",
    },
}

prototype "地质科研中心" {
    type = {"building", "consumer","laboratory"},
    chest_style = "chest",
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "1MW",
    speed = "100%",
    sound = "building/lab",
    camera_distance = 75,
    drone_height = 42,
    priority = "secondary",
    inputs = {
        "地质科技包",
    },
}

prototype "科研中心II" {
    type = {"building", "consumer","laboratory"},
    chest_style = "chest",
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "250kW",
    speed = "200%",
    sound = "building/lab",
    camera_distance = 75,
    priority = "secondary",
    inputs = {
        "地质科技包",
        "气候科技包",
        "机械科技包",
    },
}

prototype "科研中心III" {
    type = {"building", "consumer","laboratory"},
    chest_style = "chest",
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "500kW",
    speed = "400%",
    sound = "building/lab",
    camera_distance = 75,
    priority = "secondary",
    inputs = {
        "地质科技包",
        "气候科技包",
        "机械科技包",
    },
}


prototype "砖石公路-I型" {
    building_category = 4,
    display_name = "砖石公路",
    item_name = "砖石公路-X型",
    model = "glbs/road/I.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_road.texture",
    construct_detector = {"exclusive"},
    building_direction = {"N", "E"},
    track = "I",
    type = {"building", "road"},
    area = "2x2",
    camera_distance = 50,
    move = false,
    crossing = {
        connections = {
            {type="none", position={0,0,"N"}},
            {type="none", position={0,0,"S"}},
        },
    },
    road = {
        "0,0,║",
    },
}

prototype "砖石公路-L型" {
    building_category = 4,
    display_name = "砖石公路",
    item_name = "砖石公路-X型",
    model = "glbs/road/L.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_road.texture",
    construct_detector = {"exclusive"},
    building_direction = {"N", "E", "S", "W"},
    track = "L",
    type = {"building", "road"},
    area = "2x2",
    camera_distance = 50,
    move = false,
    crossing = {
        connections = {
            {type="none", position={0,0,"N"}},
            {type="none", position={0,0,"E"}},
        },
    },
    road = {
        "0,0,╚",
    },
}

prototype "砖石公路-T型" {
    building_category = 4,
    display_name = "砖石公路",
    item_name = "砖石公路-X型",
    model = "glbs/road/T.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_road.texture",
    construct_detector = {"exclusive"},
    building_direction = {"N", "E", "S", "W"},
    track = "T",
    type = {"building", "road"},
    area = "2x2",
    camera_distance = 50,
    move = false,
    crossing = {
        connections = {
            {type="none", position={0,0,"E"}},
            {type="none", position={0,0,"S"}},
            {type="none", position={0,0,"W"}},
        },
    },
    road = {
        "0,0,╦",
    },
}

prototype "砖石公路-O型" {
    building_category = 4,
    display_name = "砖石公路",
    item_name = "砖石公路-X型",
    model = "glbs/road/I.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_road.texture",
    construct_detector = {"exclusive"},
    building_direction = {"N"},
    track = "O",
    type = {"building", "road"},
    area = "2x2",
    camera_distance = 50,
    move = false,
    crossing = {
        connections = {
        }
    },
    road = {
    },
}

prototype "砖石公路-U型" {
    building_category = 4,
    display_name = "砖石公路",
    item_name = "砖石公路-X型",
    model = "glbs/road/I.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_road.texture",
    construct_detector = {"exclusive"},
    building_direction = {"N", "E", "S", "W"},
    track = "U",
    type = {"building", "road"},
    area = "2x2",
    camera_distance = 50,
    move = false,
    crossing = {
        connections = {
            {type="none", position={0,0,"N"}},
        },
    },
    road = {
        "0,0,v",
    },
}

prototype "砖石公路-X型" {
    building_category = 4,
    display_name = "砖石公路",
    item_name = "砖石公路-X型",
    model = "glbs/road/X.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_road.texture",
    construct_detector = {"exclusive"},
    building_direction = {"N"},
    track = "X",
    type = {"building", "road"},
    area = "2x2",
    camera_distance = 50,
    move = false,
    crossing = {
        connections = {
            {type="none", position={0,0,"N"}},
            {type="none", position={0,0,"E"}},
            {type="none", position={0,0,"S"}},
            {type="none", position={0,0,"W"}},
        },
    },
    road = {
        "0,0,╬",
    },
}

prototype "物流站" {
    model = "glbs/goods-station-1.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_goods_station1.texture",
    construct_detector = {"exclusive"},
    type = {"building", "station"},
    chest_style = "station",
    rotate_on_build = true,
    area = "4x2",
    drone_height = 24,
    sound = "building/logistics-center",
    crossing = {
        connections = {
            {type="station", position={1,1,"S"}},
            {type="station", position={1,2,"S"}},
        },
    },
    endpoint = "2,0",
    road = {
        "0,0,╔╗",
        "0,2,╨╨",
    },
    maxslot = 8,
    camera_distance = 90,
}

prototype "停车站" {
    model = "glbs/goods-station-1.glb|mesh.prefab",
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_goods_station1.texture",
    construct_detector = {"exclusive"},
    type = {"building","park"},
    rotate_on_build = true,
    area = "4x2",
    drone_height = 24,
    sound = "building/logistics-center",
    crossing = {
        connections = {
            {type="station", position={1,1,"S"}},
            {type="station", position={1,2,"S"}},
        },
    },
    endpoint = "2,0",
    road = {
        "0,0,╔╗",
        "0,2,╨╨",
    },
    camera_distance = 90,
}

prototype "广播塔I" {
    type = {"building", "consumer"},
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "1MW",
    speed = "100%",
    module_slot = 1,
    module_supply_area = "9x9",
    camera_distance = 75,
    priority = "secondary",
}

prototype "广播塔II" {
    type = {"building", "consumer"},
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "2MW",
    speed = "100%",
    module_slot = 2,
    module_supply_area = "13x13",
    camera_distance = 75,
    priority = "secondary",
}

prototype "广播塔III" {
    type = {"building", "consumer"},
    model = "glbs/lab-1.glb|mesh.prefab",
    model_status = {work = true, low_power = true},
    icon = "/pkg/vaststars.resources/ui/textures/building-pic/small_pic_lab.texture",
    construct_detector = {"exclusive"},
    area = "3x3",
    power = "4MW",
    speed = "125%",
    module_slot = 3,
    module_supply_area = "13x13",
    camera_distance = 75,
    priority = "secondary",
}