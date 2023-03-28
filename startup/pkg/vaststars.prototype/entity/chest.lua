local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

prototype "小铁制箱子I" {
    model = "prefabs/small-chest.prefab",
    icon = "textures/building_pic/small_pic_chest.texture",
    background = "textures/build_background/pic_chest.texture",
    construct_detector = {"exclusive"},
    type = {"building"},
    area = "1x1",
    slots = 10,
}

prototype "小铁制箱子II" {
    model = "prefabs/small-chest.prefab",
    icon = "textures/building_pic/small_pic_chest.texture",
    background = "textures/build_background/pic_chest.texture",
    construct_detector = {"exclusive"},
    type = {"building"},
    area = "1x1",
    slots = 20,
}

prototype "大铁制箱子I" {
    model = "prefabs/small-chest.prefab",
    icon = "textures/building_pic/small_pic_chest.texture",
    background = "textures/build_background/pic_chest.texture",
    construct_detector = {"exclusive"},
    type = {"building"},
    area = "2x2",
    slots = 30,
}

prototype "仓库" {
    model = "prefabs/small-chest.prefab",
    icon = "textures/building_pic/small_pic_chest.texture",
    background = "textures/build_background/pic_chest.texture",
    construct_detector = {"exclusive"},
    type = {"building"},
    area = "5x5",
    slots = 60,
}

prototype "无人机仓库" {
    model = "prefabs/drone-depot.prefab",
    icon = "textures/building_pic/small_pic_drone_depot.texture",
    background = "textures/build_background/pic_chest.texture",
    construct_detector = {"exclusive"},
    type = {"building", "hub"},
    area = "2x2",
    supply_area = "6x6",
    slots = 1,
    drone_entity = "无人机",
    drone_count = 1,
    power_supply_area = "5x5",
    power_supply_distance = 9,
}
