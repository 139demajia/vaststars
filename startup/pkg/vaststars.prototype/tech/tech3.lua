local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype


  prototype "物流教学" {
    desc = "物流教学",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = { "task" },
    task = {"unknown", 0, 4},
    effects = {
      -- unlock_recipe = {"采矿机打印"},
    },
    prerequisites = {},
    count = 1,
    tips_pic = {
      "",
    },
    sign_desc = {
      { desc = "初次进入火星", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "废墟搜索" {
    desc = "从废墟中搜索物资",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = {"task" },
    task = {"unknown", 0, 6},
    task_params = {ui = "pickup_item", building = "机身残骸"},
    prerequisites = {"物流教学"},
    count = 1,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    guide_focus = {
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 111,
        y = 140,
        w = 4.0,
        h = 4.0,
        show_arrow = true,
      },
      {
        camera_x = 111,
        camera_y = 138,
      },
    },
    sign_desc = {
      { desc = "搜索机身残骸获取有用物资", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "道路维修" {
    desc = "维修砖石公路",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = {"task" },
    task = {"unknown", 0, 1},
    task_params = {
        path = {
                {{112, 134}, {145, 134}},
                {{162, 132}, {162, 122}},
              }
    },
    prerequisites = {"废墟搜索"},
    count = 1,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    -- effects = {
    --   unlock_recipe = {"石砖","砖石公路打印"},
    --   unlock_item = {"石砖","砖石公路-X型"},
    -- },
    guide_focus = {
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 138.5,
        y = 134.5,
        w = 6.4,
        h = 2,
        show_arrow = true,
      },
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 162.5,
        y = 126.5,
        w = 2,
        h = 6.4,
        show_arrow = true,
      },
      {
        camera_x = 150,
        camera_y = 132,
      },
    },
    sign_desc = {
      { desc = "修补2处断开的砖石公路", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }
  
  prototype "停车站放置" {
    desc = "放置1座停车站",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = {"task" },
    task = {"select_entity", 0, "停车站"},
    prerequisites = {"道路维修"},
    count = 1,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    guide_focus = {
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 165.5,
        y = 122.5,
        w = 4.2,
        h = 2.1,
        show_arrow = true,
      },
      {
        camera_x = 164,
        camera_y = 122,
      },
    },
    effects = {
      unlock_item = {"碎石","铁矿石"},
    },
    sign_desc = {
      { desc = "在放置1座停车站", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "物流站发货设置" {
    desc = "物流站发货设置",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = {"task" },
    task = {"unknown", 0, 8},
    task_params = {items = {"supply|碎石", "supply|铁矿石"}},
    prerequisites = {"停车站放置"},
    count = 1,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    guide_focus = {
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 115.5,
        y = 132.5,
        w = 4.2,
        h = 2.1,
        show_arrow = true,
      },
      {
        camera_x = 114,
        camera_y = 132,
      },
    },
    sign_desc = {
      { desc = "物流站设置发货碎石和铁矿石", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "物流站收货设置" {
    desc = "物流站收货设置",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = {"task" },
    task = {"unknown", 0, 8},
    task_params = {items = {"demand|碎石", "demand|铁矿石"}},
    prerequisites = {"物流站发货设置"},
    count = 1,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    guide_focus = {
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 148.5,
        y = 127.5,
        w = 2.1,
        h = 4.2,
        show_arrow = true,
      },
      {
        camera_x = 148,
        camera_y = 126,
      },
    },
    sign_desc = {
      { desc = "物流站设置收货碎石和铁矿石", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "派遣运输车" {
    desc = "派遣2辆运输车",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = { "task" },
    task = {"unknown", 0, 2},                          
    prerequisites = {"物流站收货设置"},
    count = 2,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate1.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate2.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate3.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate4.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate5.texture",
    },
    effects = {
      unlock_recipe = {"石砖","砖石公路打印"},
      unlock_item = {"石砖","砖石公路-X型"},
    },
    sign_desc = {
      { desc = "指挥中心派遣2辆运输车", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "石砖大生产" {
    desc = "规模生产石砖",
    type = { "task" },
    icon = "/pkg/vaststars.resources/ui/textures/science/book.texture",
    task = {"stat_production", 0, "石砖"},
    count = 3,
    prerequisites = {"派遣运输车"},
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "使用组装机生产3个石砖", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "铁板大生产" {
    desc = "规模生产石砖",
    type = { "task" },
    icon = "/pkg/vaststars.resources/ui/textures/science/book.texture",
    task = {"stat_production", 0, "铁板"},
    count = 3,
    prerequisites = {"石砖大生产"},
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    effects = {
      unlock_recipe = {"轻型采矿机"},
      unlock_item = {"轻型采矿机"},
    },
    sign_desc = {
      { desc = "使用组装机生产3个石砖", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "制造采矿机" {
    desc = "制造轻型采矿机",
    type = { "task" },
    icon = "/pkg/vaststars.resources/ui/textures/science/book.texture",
    task = {"stat_production", 0, "轻型采矿机"},
    count = 1,
    prerequisites = {"铁板大生产"},
    effects = {
      unlock_recipe = {"轻型运输车"},
      unlock_item = {"轻型运输车"},
    },
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "使用组装机生产1个轻型采矿机", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "铝矿石开采" {
    desc = "放置3台采矿机",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = {"task" },
    task = {"select_entity", 0, "采矿机I"},
    prerequisites = {"制造采矿机"},
    count = 3,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    guide_focus = {
      {
        prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
        x = 106,
        y = 128,
        w = 3.2,
        h = 3.2,
        show_arrow = true,
      },
      {
        camera_x = 113,
        camera_y = 134,
      },
    },
    effects = {
      unlock_item = {"铝矿石"},
    },
    sign_desc = {
      { desc = "在石矿、铁矿、铝矿上各放置1台采矿机", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "更多运输车" {
    desc = "派遣6辆运输车",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = { "task" },
    task = {"unknown", 0, 2},                          
    prerequisites = {"物流站收货设置"},
    count = 6,
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate1.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate2.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate3.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate4.texture",
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_produce_ironplate5.texture",
    },
    sign_desc = {
      { desc = "指挥中心总共派遣6辆运输车", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  -- prototype "铝矿石运输" {
  --   desc = "车辆运输铝矿石",
  --   icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
  --   type = {"task" },
  --   task = {"select_entity", 0, "采矿机I"},
  --   prerequisites = {"制造采矿机"},
  --   count = 3,
  --   tips_pic = {
  --     "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   guide_focus = {
  --     {
  --       prefab = "glbs/selected-box-no-animation.glb|mesh.prefab",
  --       x = 106,
  --       y = 128,
  --       w = 3.2,
  --       h = 3.2,
  --       show_arrow = true,
  --     },
  --     {
  --       camera_x = 113,
  --       camera_y = 134,
  --     },
  --   },
  --   sign_desc = {
  --     { desc = "在石矿、铁矿、铝矿上各放置1台采矿机", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
  --   },
  -- }

  prototype "科技包大生产" {
    desc = "规模生产地质科技包",
    type = { "task" },
    icon = "/pkg/vaststars.resources/ui/textures/science/book.texture",
    task = {"stat_production", 0, "地质科技包"},
    count = 3,
    prerequisites = {"更多运输车"},
    tips_pic = {
      "/pkg/vaststars.resources/ui/textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "使用组装机生产3个地质科技包", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }

  prototype "开启科技研究" {
    desc = "获得火星岩石加工成石砖的工艺",
    type = { "tech" },
    icon = "/pkg/vaststars.resources/ui/textures/science/book.texture",
    prerequisites = {"科技包大生产"},
    ingredients = {
        {"地质科技包", 1},
    },
    count = 8,
    time = "1s"
  }

  prototype "物流教学结束" {
    desc = "教学结束",
    icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture",
    type = { "task" },
    task = {"unknown", 0, 4},
    effects = {
    },
    prerequisites = {"开启科技研究"},
    count = 1,
    tips_pic = {
      "",
    },
    sign_desc = {
      { desc = "完成所有的物流教学", icon = "/pkg/vaststars.resources/ui/textures/construct/industry.texture"},
    },
  }