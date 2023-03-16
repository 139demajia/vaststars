local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.register.prototype

  --task = {"stat_production", 0, "铁矿石"},            生产XX个物品
  --task = {"stat_manual_production", 0, "铁矿石"},     手动生产XX个物品
  --task = {"stat_consumption", 0, "铁矿石"},           消耗XX个物品
  --task = {"select_entity", 0, "组装机"},              拥有XX台机器
  --task = {"select_chest", 0, "指挥中心", "铁丝"},     向指挥中心转移X个物品
  --task = {"power_generator", 0},                      电力发电到达X瓦
  --task = {"unknown", 0},                              自定义任务
  --task = {"unknown", 0, 3},                           自定义任务，指定选择配方
  --task_params = {recipe = "地质科技包1"},
  --count = 1,
  --time是指1个count所需的时间


  -- prototype "清除废墟" {
  --   desc = "清除指挥中心附近的3处废墟",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"unknown", 0},
  --   prerequisites = {},
  --   count = 3,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_click_build.texture",
  --     "textures/task_tips_pic/task_demolish2.texture",
  --     "textures/task_tips_pic/task_demolish3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "清除指挥中心附近的3处废墟", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "仓库选择" {
  --   desc = "选择采矿机蓝图",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"unknown", 0, 3},
  --   task_params = {recipe = "采矿机设计图"},
  --   prerequisites = {""},
  --   count = 1,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "选择采矿机设计图", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "建造采矿机" {
  --   desc = "选择采矿机设计图",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_consumption", 0, "采矿机设计图"},
  --   prerequisites = {"仓库选择"},
  --   count = 1,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "在“建造中心”建造1个采矿机", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "建造电线杆" {
  --   desc = "建造4个电线杆",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_consumption", 0, "电线杆设计图"},
  --   prerequisites = {"放置采矿机"},
  --   count = 4,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "在“建造中心”建造4个电线杆", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "放置电线杆" {
  --   desc = "放置4个铁制电线杆",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "铁制电线杆"},
  --   prerequisites = {"建造电线杆"},
  --   count = 4,
  --   effects = {
  --      unlock_recipe = {"无人机仓库打印"},
  --   },
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_pole1.texture",
  --     "textures/task_tips_pic/task_place_pole2.texture",
  --   },
  --   sign_desc = {
  --     { desc = "放置4个铁制电线杆构成电网", icon = "textures/construct/industry.texture"},
  --   },
  -- }

    -- prototype "建造无人机仓库" {
  --   desc = "建造2个无人机仓库",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_consumption", 0, "无人机仓库设计图"},
  --   prerequisites = {"放置电线杆"},
  --   count = 2,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "在“建造中心”建造2个无人机仓库", icon = "textures/construct/industry.texture"},
  --   },
  -- }

    -- prototype "放置无人机仓库" {
  --   desc = "放置2个无人机仓库",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "无人机仓库"},
  --   prerequisites = {"建造无人机仓库"},
  --   count = 2,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_pole1.texture",
  --     "textures/task_tips_pic/task_place_pole2.texture",
  --   },
  --   sign_desc = {
  --     { desc = "放置2个无人机仓库", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "生产碎石矿" {
  --   desc = "挖掘足够的碎石可以开始进行锻造",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "碎石"},
  --   prerequisites = {"放置无人机仓库"},
  --   count = 6,
  --   effects = {
  --      unlock_recipe = {"科研中心打印"},
  --   },
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ore3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "在碎石矿上放置挖矿机并挖掘6个碎石矿", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "放置科研中心" {
  --   desc = "放置可以研究火星科技的建筑",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "科研中心I"},
  --   prerequisites = {"生产碎石矿"},
  --   count = 1,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_click_build.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用“建造”放置1座科研中心", icon = "textures/construct/industry.texture"},
  --   },
  -- }

--   prototype "地质研究" {
--     desc = "对火星地质结构进行标本采集和研究",
--     type = { "tech" },
--     icon = "textures/science/tech-research.texture",
--     effects = {
--       unlock_recipe = {"地质科技包1","组装机打印"},
--     },
--     ingredients = {
--     },
--     count = 5,
--     time = "1.2s",
--     prerequisites = {"放置科研中心"},
--     sign_desc = {
--       { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
--     },
--     sign_icon = "textures/science/tech-important.texture",
-- }

    -- prototype "建造组装机" {
  --   desc = "建造组装机",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_consumption", 0, "组装机设计图"},
  --   prerequisites = {"地质研究"},
  --   count = 2,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "在“建造中心”建造2个组装机", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "自动化生产" {
  --   desc = "自动化生产科技包用于科技研究",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "地质科技包"},
  --   prerequisites = {"建造组装机"},
  --   count = 4,
  --   effects = {
  --      unlock_recipe = {"地质科技包1"},
  --   },
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_geopack3.texture",
  --     "textures/task_tips_pic/task_produce_geopack4.texture",
  --     "textures/task_tips_pic/task_produce_geopack5.texture",
  --     "textures/task_tips_pic/task_produce_geopack6.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用组装机生产至4个地质科技包", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "石头处理1" {
  --   desc = "获得火星岩石加工成石砖的工艺",
  --   type = { "tech" },
  --   icon = "textures/science/tech-research.texture",
  --   effects = {
  --     unlock_recipe = {"石砖"},
  --   },
  --   prerequisites = {"自动化生产"},
  --   ingredients = {
  --       {"地质科技包", 2},
  --   },
  --   count = 4,
  --   time = "1s"
  -- }

  -- prototype "生产石砖" {
  --   desc = "挖掘足够的碎石可以开始进行锻造",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "石砖"},
  --   prerequisites = {"石头处理1"},
  --   count = 4,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ore3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用组装机生产4个石砖", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "物流学I" {
  --   desc = "获得火星岩石加工成石砖的工艺",
  --   type = { "tech" },
  --   icon = "textures/science/tech-research.texture",
  --   effects = {
  --     unlock_recipe = {"道路建造站"},
  --   },
  --   prerequisites = {"生产石砖"},
  --   ingredients = {
  --       {"地质科技包", 4},
  --   },
  --   count = 4,
  --   time = "1s"
  -- }

    -- prototype "放置道路建造站" {
  --   desc = "放置1座道路建造站",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "道路建造站"},
  --   prerequisites = {"物流学I"},
  --   count = 1,
  --   effects = {
  --     unlock_recipe = {"车站打印"},
  --   },
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "放置1个道路建造站", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "修建公路" {
  --   desc = "修建20节公路",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "砖石公路-X型-01"},
  --   task_params = {starting = {117, 125}, ending = {135, 125}},
  --   prerequisites = {"放置道路建造站"},
  --   count = 20,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_road1.texture",
  --     "textures/task_tips_pic/task_place_road2.texture",
  --     "textures/task_tips_pic/task_place_road3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "至少修建20段道路", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "放置车站" {
  --   desc = "放置1座道路建造站",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "车站"},
  --   prerequisites = {"放置道路建造站"},
  --   count = 1,
  --   effects = {
  --     unlock_recipe = {"运输汽车生产"},
  --   },
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "放置1个车站", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "生产运输车辆" {
  --   desc = "挖掘足够的铁矿石可以开始进行锻造",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "运输车辆I"},
  --   prerequisites = {"放置车站"},
  --   count = 4,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ore3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "组装机维修4辆运输车辆", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "生产铁矿石" {
  --   desc = "挖掘足够的铁矿石可以开始进行锻造",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "铁矿石"},
  --   prerequisites = {"生产运输车辆"},
  --   count = 10,
  --   effects = {
  --     unlock_recipe = {"熔炼炉打印"},
  --   },
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ore3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "在铁矿上放置挖矿机并挖掘10个铁矿石", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "铁矿熔炼" {
  --   desc = "掌握熔炼铁矿石冶炼成铁板的工艺",
  --   type = { "tech" },
  --   icon = "textures/science/tech-research.texture",
  --   effects = {
  --     unlock_recipe = {"铁板1"},
  --   },
  --   prerequisites = {"生产铁矿石"},
  --   ingredients = {
  --       {"地质科技包", 1},
  --   },
  --   count = 4,
  --   time = "3s"
  -- }
  
  -- prototype "放置熔炼炉" {
  --   desc = "放置熔炼炉",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "熔炼炉I"},
  --   prerequisites = {"生产铁矿石"},
  --   count = 2,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_click_build.texture",
  --     "textures/task_tips_pic/task_produce_geopack1.texture",
  --     "textures/task_tips_pic/task_produce_geopack2.texture",
  --     "textures/task_tips_pic/start_construct.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用“建造”放置2台熔炼炉", icon = "textures/construct/industry.texture"},
  --   },
  -- }
  
  -- prototype "生产铁板" {
  --   desc = "铁板可以打造坚固器材，对于基地建设多多益善",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "铁板"},
  --   prerequisites = {"放置熔炼炉","铁矿熔炼"},
  --   count = 4,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ironplate1.texture",
  --     "textures/task_tips_pic/task_produce_ironplate2.texture",
  --     "textures/task_tips_pic/task_produce_ironplate3.texture",
  --     "textures/task_tips_pic/task_produce_ironplate4.texture",
  --     "textures/task_tips_pic/task_produce_ironplate5.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用熔炼炉生产4个铁板", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "铁加工1" {
  --   desc = "获得铁板加工铁齿轮的工艺",
  --   type = { "tech" },
  --   icon = "textures/science/tech-research.texture",
  --   effects = {
  --     unlock_recipe = {"铁齿轮"},
  --   },
  --   prerequisites = {"生产铁板"},
  --   ingredients = {
  --       {"地质科技包", 1},
  --   },
  --   count = 6,
  --   time = "2s"
  -- }

  -- prototype "生产铁齿轮" {
  --   desc = "铁板可以打造坚固器材，对于基地建设多多益善",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "铁齿轮"},
  --   prerequisites = {"铁加工1"},
  --   count = 2,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ironplate1.texture",
  --     "textures/task_tips_pic/task_produce_ironplate2.texture",
  --     "textures/task_tips_pic/task_produce_ironplate3.texture",
  --     "textures/task_tips_pic/task_produce_ironplate4.texture",
  --     "textures/task_tips_pic/task_produce_ironplate5.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用组装机生产2个铁齿轮", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  -- prototype "机械运输" {
  --   desc = "研究生产运输车辆工艺",
  --   type = { "tech" },
  --   icon = "textures/science/tech-research.texture",
  --   effects = {
  --     unlock_recipe = {"运输车辆1"},
  --   },
  --   prerequisites = {"生产铁齿轮"},
  --   ingredients = {
  --       {"地质科技包", 1},
  --   },
  --   count = 6,
  --   time = "2s"
  -- }

  -- prototype "生产运输车辆" {
  --   desc = "生产8辆运输车",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"stat_production", 0, "运输车辆I"},
  --   prerequisites = {"机械运输"},
  --   count = 8,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_produce_ironplate1.texture",
  --     "textures/task_tips_pic/task_produce_ironplate2.texture",
  --     "textures/task_tips_pic/task_produce_ironplate3.texture",
  --     "textures/task_tips_pic/task_produce_ironplate4.texture",
  --     "textures/task_tips_pic/task_produce_ironplate5.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用组装机生产8辆运输车", icon = "textures/construct/industry.texture"},
  --   },
  -- }

-- prototype "电磁学1" {
--   desc = "研究电能转换成机械能的基础供能装置",
--   type = { "tech" },
--   icon = "textures/science/tech-research.texture",
--   effects = {
--     unlock_recipe = {"电动机1"},
--   },
--   prerequisites = {"生产运输车辆"},
--   ingredients = {
--     {"地质科技包", 1},
--   },
--   count = 10,
--   time = "6s"
-- }

-- prototype "物流学II" {
--   desc = "研究电能转换成机械能的基础供能装置",
--   type = { "tech" },
--   icon = "textures/science/tech-research.texture",
--   effects = {
--     unlock_recipe = {"车站"},
--   },
--   prerequisites = {"生产运输车辆"},
--   ingredients = {
--     {"地质科技包", 1},
--   },
--   count = 10,
--   time = "6s"
-- }

-- prototype "气候研究" {
--   desc = "对火星大气成分进行标本采集和研究",
--   type = { "tech" },
--   icon = "textures/science/tech-research.texture",
--   effects = {
--     unlock_recipe = {"气候科技包1"},
--     unlock_building = {"空气过滤器I","地下水挖掘机"},
--   },
--   prerequisites = {"物流学II"},
--   ingredients = {
--       {"地质科技包", 1},
--   },
--   sign_desc = {
--     { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
--   },
--   sign_icon = "textures/science/tech-important.texture",
--   count = 6,
--   time = "1.5s"
-- }

-- prototype "管道系统1" {
--   desc = "研究装载和运输液体或气体的管道",
--   type = { "tech" },
--   icon = "textures/science/tech-research.texture",
--   effects = {
--     unlock_recipe = {"管道1","管道2","液罐1"},
--     unlock_building = {"液罐I","管道1-X型"},
--   },
--   prerequisites = {"气候研究"},
--   ingredients = {
--       {"地质科技包", 1},
--   },
--   count = 6,
--   time = "1s"
-- }

-- prototype "生产管道" {
--   desc = "管道用于液体传输",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_production", 0, "管道1-X型"},
--   prerequisites = {"管道系统1"},
--   count = 10,
--   tips_pic = {
--     "textures/task_tips_pic/task_produce_pipe1.texture",
--   },
--   sign_desc = {
--     { desc = "使用组装机生产10个管道", icon = "textures/construct/industry.texture"},
--   },
-- }

-- prototype "采水研究" {
--   desc = "对火星大气成分进行标本采集和研究",
--   type = { "tech" },
--   icon = "textures/science/tech-research.texture",
--   effects = {
--     unlock_recipe = {"地下水挖掘机","水电站打印"},
--   },
--   prerequisites = {"生产管道"},
--   ingredients = {
--       {"地质科技包", 1},
--   },
--   sign_desc = {
--     { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
--   },
--   sign_icon = "textures/science/tech-important.texture",
--   count = 6,
--   time = "1.5s"
-- }

-- prototype "建造地下水挖掘机" {
--   desc = "生产科技包用于科技研究",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_production", 0, "地下水挖掘机"},
--   prerequisites = {"采水研究"},
--   count = 1,
--   tips_pic = {
--     "textures/task_tips_pic/task_produce_climatepack2.texture",
--     "textures/task_tips_pic/task_produce_climatepack3.texture",
--     "textures/task_tips_pic/task_produce_climatepack4.texture",
--     "textures/task_tips_pic/task_produce_climatepack5.texture",
--   },
--   sign_desc = {
--     { desc = "生产1个地下水挖掘机", icon = "textures/construct/industry.texture"},
--   },
-- }

-- prototype "建造水电站" {
--   desc = "建造水电站用于处理液体",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_production", 0, "水电站I"},
--   prerequisites = {"采水研究"},
--   count = 1,
--   tips_pic = {
--     "textures/task_tips_pic/task_produce_climatepack2.texture",
--     "textures/task_tips_pic/task_produce_climatepack3.texture",
--     "textures/task_tips_pic/task_produce_climatepack4.texture",
--     "textures/task_tips_pic/task_produce_climatepack5.texture",
--   },
--   sign_desc = {
--     { desc = "建造1个水电站", icon = "textures/construct/industry.texture"},
--   },
-- }

-- prototype "生产气候科技包" {
--   desc = "生产科技包用于科技研究",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_production", 0, "气候科技包"},
--   prerequisites = {"建造地下水挖掘机","建造水电站"},
--   count = 1,
--   tips_pic = {
--     "textures/task_tips_pic/task_produce_climatepack2.texture",
--     "textures/task_tips_pic/task_produce_climatepack3.texture",
--     "textures/task_tips_pic/task_produce_climatepack4.texture",
--     "textures/task_tips_pic/task_produce_climatepack5.texture",
--   },
--   sign_desc = {
--     { desc = "使用水电站生产1个气候科技包", icon = "textures/construct/industry.texture"},
--   },
-- }

  -- prototype "修复阻断公路" {
  --   desc = "放置1座科研中心",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"unknown", 0, 1},
  --   task_params = {starting = {117, 125}, ending = {135, 125}},
  --   prerequisites = {"放置道路建造站"},
  --   count = 1,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_road1.texture",
  --     "textures/task_tips_pic/task_place_road2.texture",
  --     "textures/task_tips_pic/task_place_road3.texture",
  --   },
  --   sign_desc = {
  --     { desc = "使用“建造”放置8段道路使得道路联通", icon = "textures/construct/industry.texture"},
  --   },
  -- }

  prototype "迫降火星" {
    desc = "迫降火星",
    icon = "textures/construct/industry.texture",
    type = { "task" },
    task = {"unknown", 0, 4},
    effects = {
      unlock_recipe = {"采矿机设计图","采矿机打印"},
      unlock_item = {"铁板","采矿机设计图"},
    },
    prerequisites = {""},
    count = 1,
    tips_pic = {
      "",
    },
    sign_desc = {
      { desc = "初次进入火星", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "操作仓库" {
    desc = "选择采矿机蓝图",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"unknown", 0, 3},
    task_params = {recipe = "采矿机设计图"},
    prerequisites = {"迫降火星"},
    count = 1,
    tips_pic = {
      "textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "选择采矿机设计图", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "建造采矿机" {
    desc = "",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"stat_consumption", 0, "采矿机设计图"},
    prerequisites = {"操作仓库"},
    count = 2,
    tips_pic = {
      "textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "使用建造中心建造2个采矿机", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "放置采矿机" {
    desc = "放置2台采矿机",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"select_entity", 0, "采矿机I"},
    prerequisites = {"建造采矿机"},
    effects = {
       unlock_recipe = {"电线杆打印"},
    },
    count = 2,
    tips_pic = {
      "textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "在石矿上放置2个采矿机", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "放置道路建造站" {
    desc = "放置1座道路建造站",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"select_entity", 0, "道路建造站"},
    prerequisites = {"操作仓库"},
    count = 1,
    tips_pic = {
      "textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "放置1个道路建造站", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "放置物流中心" {
    desc = "放置1座物流中心",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"select_entity", 0, "物流中心I"},
    prerequisites = {"放置道路建造站"},
    count = 1,
    tips_pic = {
      "textures/task_tips_pic/task_place_logistics.texture",
    },
    sign_desc = {
      { desc = "使用“建造”放置1个物流中心", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "放置科研中心" {
    desc = "放置1座科研中心",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"select_entity", 0, "科研中心I"},
    prerequisites = {"放置物流中心"},
    count = 1,
    tips_pic = {
      "textures/task_tips_pic/task_click_build.texture",
    },
    sign_desc = {
      { desc = "使用“建造”放置1座科研中心", icon = "textures/construct/industry.texture"},
    },
  }

  prototype "放置电线杆" {
    desc = "放置2个铁制电线杆",
    icon = "textures/construct/industry.texture",
    type = { "tech", "task" },
    task = {"select_entity", 0, "铁制电线杆"},
    prerequisites = {"放置科研中心"},
    count = 2,
    tips_pic = {
      "textures/task_tips_pic/task_place_pole1.texture",
      "textures/task_tips_pic/task_place_pole2.texture",
    },
    sign_desc = {
      { desc = "使用“建造”放置2个铁制电线杆", icon = "textures/construct/industry.texture"},
    },
  }
  
prototype "地质研究" {
    desc = "对火星地质结构进行标本采集和研究",
    type = { "tech" },
    icon = "textures/science/tech-research.texture",
    ingredients = {
    },
    count = 5,
    time = "1.2s",
    prerequisites = {"放置电线杆"},
    sign_desc = {
      { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
    },
    sign_icon = "textures/science/tech-important.texture",
}

  -- prototype "放置太阳能板" {
  --   desc = "放置4座太阳能板",
  --   icon = "textures/construct/industry.texture",
  --   type = { "tech", "task" },
  --   task = {"select_entity", 0, "太阳能板I"},
  --   prerequisites = {"地质研究"},
  --   count = 4,
  --   tips_pic = {
  --     "textures/task_tips_pic/task_place_logistics.texture",
  --   },
  --   sign_desc = {
  --     { desc = "放置4个太阳能板", icon = "textures/construct/industry.texture"},
  --   },
  -- }

-- prototype "放置车辆厂" {
--   desc = "放置1座车辆厂",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"select_entity", 0, "车辆厂I"},
--   prerequisites = {"放置太阳能板"},
--   count = 1,
--   tips_pic = {
--     "textures/task_tips_pic/task_place_logistics.texture",
--   },
--   sign_desc = {
--     { desc = "放置1个车辆厂", icon = "textures/construct/industry.texture"},
--   },
-- }

-- prototype "生产运输车辆" {
--   desc = "生产运输车辆2辆",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_consumption", 0, 运输车辆设计图},
--   prerequisites = {"放置车辆厂"},
--   task_params = {},
--   count = 2,
--   tips_pic = {
--     "textures/task_tips_pic/task_click_build.texture",
--     "textures/task_tips_pic/task_demolish2.texture",
--     "textures/task_tips_pic/task_demolish3.texture",
--   },
--   sign_desc = {
--     { desc = "在车辆厂生产2辆运输车辆", icon = "textures/construct/industry.texture"},
--   },
-- }

-- prototype "增添运输车辆" {
--   desc = "增加运输车辆至5辆",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"unknown", 0, 2},
--   prerequisites = {"地质研究"},
--   task_params = {},
--   count = 5,
--   tips_pic = {
--     "textures/task_tips_pic/task_click_build.texture",
--     "textures/task_tips_pic/task_demolish2.texture",
--     "textures/task_tips_pic/task_demolish3.texture",
--   },
--   sign_desc = {
--     { desc = "在物流中心需求运输车辆至5辆", icon = "textures/construct/industry.texture"},
--   },
-- }

prototype "生产铁矿石" {
  desc = "挖掘足够的铁矿石可以开始进行锻造",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "铁矿石"},
  prerequisites = {"放置采矿机"},
  count = 2,
  tips_pic = {
    "textures/task_tips_pic/task_produce_ore3.texture",
  },
  sign_desc = {
    { desc = "在铁矿上放置挖矿机并挖掘2个铁矿石", icon = "textures/construct/industry.texture"},
  },
}

prototype "生产碎石矿" {
  desc = "挖掘足够的碎石可以开始进行锻造",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "碎石"},
  prerequisites = {"放置采矿机"},
  count = 2,
  tips_pic = {
    "textures/task_tips_pic/task_produce_ore3.texture",
  },
  sign_desc = {
    { desc = "在碎石矿上放置挖矿机并挖掘2个碎石矿", icon = "textures/construct/industry.texture"},
  },
}

prototype "放置组装机" {
  desc = "放置组装机",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"select_entity", 0, "组装机I"},
  prerequisites = {"生产铁矿石","生产碎石矿"},
  count = 2,
  tips_pic = {
    "textures/task_tips_pic/task_click_build.texture",
    "textures/task_tips_pic/task_produce_geopack1.texture",
    "textures/task_tips_pic/task_produce_geopack2.texture",
    "textures/task_tips_pic/start_construct.texture",
  },
  sign_desc = {
    { desc = "使用“建造”放置2台组装机", icon = "textures/construct/industry.texture"},
  },
}

prototype "自动化生产" {
  desc = "自动化生产科技包用于科技研究",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "地质科技包"},
  prerequisites = {"放置组装机"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_produce_geopack3.texture",
    "textures/task_tips_pic/task_produce_geopack4.texture",
    "textures/task_tips_pic/task_produce_geopack5.texture",
    "textures/task_tips_pic/task_produce_geopack6.texture",
  },
  sign_desc = {
    { desc = "使用组装机生产至1个地质科技包", icon = "textures/construct/industry.texture"},
  },
}


prototype "物流研究" {
  desc = "对火星地质结构进行标本采集和研究",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"破损运输车"},
  },
  ingredients = {
    {"地质科技包", 1},
  },
  count = 1,
  time = "1.2s",
  prerequisites = {"自动化生产"},
  sign_desc = {
    { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
  },
  sign_icon = "textures/science/tech-important.texture",
}

prototype "放置车辆厂" {
  desc = "放置车辆厂",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"select_entity", 0, "车辆厂I"},
  prerequisites = {"物流研究"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_click_build.texture",
    "textures/task_tips_pic/task_produce_geopack1.texture",
    "textures/task_tips_pic/task_produce_geopack2.texture",
    "textures/task_tips_pic/start_construct.texture",
  },
  sign_desc = {
    { desc = "使用“建造”放置1个车辆厂", icon = "textures/construct/industry.texture"},
  },
}

prototype "增添运输车辆" {
  desc = "增加运输车辆至5辆",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "运输车辆I"},
  prerequisites = {"放置车辆厂"},
  task_params = {},
  count = 5,
  tips_pic = {
    "textures/task_tips_pic/task_click_build.texture",
    "textures/task_tips_pic/task_demolish2.texture",
    "textures/task_tips_pic/task_demolish3.texture",
  },
  sign_desc = {
    { desc = "在车辆厂生产运输车辆至5辆", icon = "textures/construct/industry.texture"},
  },
}

prototype "基地生产1" {
  desc = "维修物流中心引入公路运输",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"运输汽车生产","砖石公路"},
    unlock_building = {"砖石公路-X型-01"},
  },
  prerequisites = {"增添运输车辆"},
  ingredients = {
      {"地质科技包", 1},
  },
  count = 2,
  time = "2s",
  sign_icon = "textures/science/tech-cycle.texture",
}

-- prototype "维修运输汽车" {
--   desc = "维修运输车参与物流",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_consumption", 0, "破损运输车辆"},
--   prerequisites = {"基地生产1"},
--   count = 2,
--   tips_pic = {
--     "textures/task_tips_pic/task_repair_truck.texture",
--   },
--   sign_desc = {
--     { desc = "使用组装机维修2辆破损运输车辆", icon = "textures/construct/industry.texture"},
--   },
-- }

-- prototype "维修物流中心" {
--   desc = "维修运输车参与物流",
--   icon = "textures/construct/industry.texture",
--   type = { "tech", "task" },
--   task = {"stat_consumption", 0, "破损物流中心"},
--   prerequisites = {"基地生产1"},
--   count = 1,
--   tips_pic = {
--     "textures/task_tips_pic/task_repair_logistics.texture",
--   },
--   sign_desc = {
--     { desc = "使用组装机维修1个破损物流中心", icon = "textures/construct/industry.texture"},
--   },
-- }


prototype "铁矿熔炼" {
  desc = "掌握熔炼铁矿石冶炼成铁板的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"铁板1"},
  },
  prerequisites = {"基地生产1"},
  ingredients = {
      {"地质科技包", 1},
  },
  count = 4,
  time = "3s"
}

prototype "放置熔炼炉" {
  desc = "放置熔炼炉",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"select_entity", 0, "熔炼炉I"},
  prerequisites = {"铁矿熔炼"},
  count = 2,
  tips_pic = {
    "textures/task_tips_pic/task_click_build.texture",
    "textures/task_tips_pic/task_produce_geopack1.texture",
    "textures/task_tips_pic/task_produce_geopack2.texture",
    "textures/task_tips_pic/start_construct.texture",
  },
  sign_desc = {
    { desc = "使用“建造”放置2台熔炼炉", icon = "textures/construct/industry.texture"},
  },
}

prototype "生产铁板" {
  desc = "铁板可以打造坚固器材，对于基地建设多多益善",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "铁板"},
  prerequisites = {"放置熔炼炉"},
  count = 4,
  tips_pic = {
    "textures/task_tips_pic/task_produce_ironplate1.texture",
    "textures/task_tips_pic/task_produce_ironplate2.texture",
    "textures/task_tips_pic/task_produce_ironplate3.texture",
    "textures/task_tips_pic/task_produce_ironplate4.texture",
    "textures/task_tips_pic/task_produce_ironplate5.texture",
  },
  sign_desc = {
    { desc = "使用熔炼炉生产4个铁板", icon = "textures/construct/industry.texture"},
  },
}

prototype "石头处理1" {
  desc = "获得火星岩石加工成石砖的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"石砖"},
  },
  prerequisites = {"生产铁板"},
  ingredients = {
      {"地质科技包", 1},
  },
  count = 4,
  time = "1s"
}

prototype "生产石砖" {
  desc = "石砖可以打造基础建筑，对于基地建设多多益善",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "石砖"},
  prerequisites = {"石头处理1"},
  count = 4,
  tips_pic = {
    "textures/task_tips_pic/task_produce_stonebrick.texture",
  },
  sign_desc = {
    { desc = "使用组装机生产4个石砖", icon = "textures/construct/industry.texture"},
  },
}

prototype "气候研究" {
  desc = "对火星大气成分进行标本采集和研究",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"气候科技包1"},
    unlock_building = {"空气过滤器I","地下水挖掘机"},
  },
  prerequisites = {"生产石砖"},
  ingredients = {
      {"地质科技包", 1},
  },
  sign_desc = {
    { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
  },
  sign_icon = "textures/science/tech-important.texture",
  count = 6,
  time = "1.5s"
}

prototype "维修破损空气过滤器" {
  desc = "将破损的机器修复会大大节省建设时间和资源",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_consumption", 0, "空气过滤器设计图"},
  prerequisites = {"气候研究"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_repair_airfilter.texture",
  },
  sign_desc = {
    { desc = "使用组装机维修1个破损空气过滤器", icon = "textures/construct/industry.texture"},
  },
}

prototype "维修破损地下水挖掘机" {
  desc = "将破损的机器修复会大大节省建设时间和资源",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_consumption", 0, "地下水挖掘机设计图"},
  prerequisites = {"气候研究"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_repair_digger.texture",
  },
  sign_desc = {
    { desc = "使用组装机维修1个破损地下水挖掘机", icon = "textures/construct/industry.texture"},
  },
}

prototype "修建水电站" {
  desc = "修建水电站收集气体和液体",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"select_entity", 0, "水电站I"},
  prerequisites = {"维修破损空气过滤器","维修破损地下水挖掘机"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_click_build.texture",
    "textures/task_tips_pic/task_place_hydro.texture",
  },
  sign_desc = {
    { desc = "修建1座水电站", icon = "textures/construct/industry.texture"},
  },
}

prototype "生产气候科技包" {
  desc = "生产科技包用于科技研究",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "气候科技包"},
  prerequisites = {"修建水电站"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_produce_climatepack2.texture",
    "textures/task_tips_pic/task_produce_climatepack3.texture",
    "textures/task_tips_pic/task_produce_climatepack4.texture",
    "textures/task_tips_pic/task_produce_climatepack5.texture",
  },
  sign_desc = {
    { desc = "使用水电站生产1个气候科技包", icon = "textures/construct/industry.texture"},
  },
}

prototype "管道系统1" {
  desc = "研究装载和运输液体或气体的管道",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"管道1","管道2","液罐1"},
    unlock_building = {"液罐I","管道1-X型"},
  },
  prerequisites = {"生产气候科技包"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
  },
  count = 2,
  time = "1s"
}

prototype "生产管道" {
  desc = "管道可以承载液体和气体，将需要相同气液的机器彼此联通起来",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "管道1-X型"},
  prerequisites = {"管道系统1"},
  count = 10,
  tips_pic = {
    "textures/task_tips_pic/task_produce_pipe1.texture",
  },
  sign_desc = {
    { desc = "使用组装机生产10个管道", icon = "textures/construct/industry.texture"},
  },
}

prototype "水利研究" {
  desc = "对火星地层下的水源进行开采",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"水电站设计"},
    unlock_building = {"水电站I"},
  },
  prerequisites = {"生产管道"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
  },
  count = 4,
  time = "1s"
}


prototype "电解" {
  desc = "科技的描述",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"地下卤水电解","隔膜电解","电解厂设计"},
    unlock_building = {"电解厂I"},
  },
  prerequisites = {"水利研究"},
  ingredients = {
      {"气候科技包", 1},
  },
  count = 5,
  time = "2s"
}

prototype "空气分离" {
  desc = "获得火星大气分离出纯净气体的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"空气分离1"},
  },
  prerequisites = {"维修破损组装机","电解"},
  ingredients = {
      {"气候科技包", 1},
  },
  count = 4,
  time = "1.5s"
}

prototype "收集空气" {
  desc = "采集火星上的空气",
  type = { "tech", "task" },
  icon = "textures/construct/industry.texture",
  task = {"stat_production", 1, "空气"},
  prerequisites = {"空气分离"},
  count = 4000,
  tips_pic = {
    "textures/task_tips_pic/task_produce_air1.texture",
    "textures/task_tips_pic/task_produce_air2.texture",
  },
  sign_desc = {
    { desc = "用空气过滤器生产40000单位空气", icon = "textures/construct/industry.texture",},
  },
}

prototype "铁加工1" {
  desc = "获得铁板加工铁齿轮的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"铁齿轮","维修组装机"},
    unlock_building = {"组装机I"},
  },
  prerequisites = {"生产管道"},
  ingredients = {
      {"地质科技包", 1},
  },
  count = 6,
  time = "2s"
}

prototype "维修破损组装机" {
  desc = "将破损的机器修复会大大节省建设时间和资源",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_consumption", 0, "组装机设计图"},
  prerequisites = {"铁加工1"},
  count = 3,
  tips_pic = {
    "textures/task_tips_pic/task_repair_assembler.texture",
  },
  sign_desc = {
    { desc = "使用组装机维修3个破损组装机", icon = "textures/construct/industry.texture"},
  },
}

prototype "石头处理2" {
  desc = "对火星岩石成分的研究",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"维修太阳能板","维修蓄电池"},
    unlock_building = {"太阳能板I","蓄电池I"},
  },
  prerequisites = {"空气分离"},
  ingredients = {
      {"地质科技包", 1},
  },
  count = 8,
  time = "2s"
}

prototype "修理太阳能板" {
  desc = "维修太阳能板并利用太阳能板技术发电",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_consumption", 0, "太阳能板设计图"},
  prerequisites = {"石头处理2"},
  count = 2,
  tips_pic = {
    "textures/task_tips_pic/task_repair_solarpanel.texture",
  },
  sign_desc = {
    { desc = "使用组装机维修2个破损太阳能板", icon = "textures/construct/industry.texture"},
  },
}

prototype "放置太阳能板" {
  desc = "放置太阳能板将光热转换成电能",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"select_entity", 0, "太阳能板I"},
  prerequisites = {"修理太阳能板"},
  count = 8,
  tips_pic = {
    "textures/task_tips_pic/task_place_solarpanel.texture",
  },
  sign_desc = {
    { desc = "放置8个太阳能板", icon = "textures/construct/industry.texture"},
  },
}

prototype "基地生产2" {
  desc = "提高指挥中心的生产效率",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    modifier = {["headquarter-mining-speed"] = 0.1},
    unlock_recipe = {"维修铁制电线杆","建造中心"},
    unlock_building = {"铁制电线杆"},
  },
  prerequisites = {"空气分离"},
  ingredients = {
      {"地质科技包", 1},
  },
  count = 8,
  time = "1s",
  sign_desc = {
    { desc = "该科技可以持续地提高某项能力", icon = "textures/science/recycle.texture"},
  },
  sign_icon = "textures/science/tech-cycle.texture",
}

prototype "储存1" {
  desc = "研究更便捷的存储方式",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"小铁制箱子1"},
    unlock_building = {"小铁制箱子I"},
  },
  prerequisites = {"维修破损组装机","基地生产2"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
  },
  count = 6,
  time = "2s"
}

prototype "生产铁制箱子" {
  desc = "生产小铁制箱子用于存储基地的资源",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "小铁制箱子I"},
  prerequisites = {"储存1"},
  count = 3,
  tips_pic = {
    "textures/task_tips_pic/task_produce_chest.texture",
  },
  sign_desc = {
    { desc = "使用组装机生产3个小铁制箱子", icon = "textures/construct/industry.texture"},
  },
}

prototype "碳处理1" {
  desc = "含碳气体化合成其他物质的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"二氧化碳转甲烷","化工厂打印"},
    unlock_building = {"化工厂I"},
  },
  prerequisites = {"电解","空气分离","放置太阳能板"},
  ingredients = {
      {"气候科技包", 1},
  },
  count = 4,
  time = "2s"
}

prototype "生产氢气" {
  desc = "生产工业气体氢气",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "氢气"},
  prerequisites = {"碳处理1"},
  count = 500,
  tips_pic = {
    "textures/task_tips_pic/task_produce_h21.texture",
    "textures/task_tips_pic/task_produce_h22.texture",
  },
  sign_desc = {
    { desc = "电解厂电解卤水生产500个单位氢气", icon = "textures/construct/industry.texture"},
  },
}

prototype "生产二氧化碳" {
  desc = "生产工业气体二氧化碳",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "二氧化碳"},
  prerequisites = {"碳处理1"},
  count = 500,
  tips_pic = {
    "textures/task_tips_pic/task_produce_co21.texture",
    "textures/task_tips_pic/task_produce_co22.texture",
  },
  sign_desc = {
    { desc = "蒸馏厂分离空气生产500个单位二氧化碳", icon = "textures/construct/industry.texture"},
  },
}

prototype "碳处理2" {
  desc = "含碳气体化合成其他物质的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"甲烷转乙烯","二氧化碳转一氧化碳","一氧化碳转石墨"},
  },
  prerequisites = {"生产氢气","生产二氧化碳"},
  ingredients = {
      {"气候科技包", 1},
  },
  count = 8,
  time = "2s"
}

prototype "地质研究2" {
  desc = "对火星地质结构进行标本采集和研究",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"地质科技包2"},
  },
  ingredients = {
      {"地质科技包", 20},
  },
  count = 5,
  time = "1.2s",
  prerequisites = {"碳处理2"},
  sign_desc = {
    { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
  },
  sign_icon = "textures/science/tech-important.texture",
}

prototype "管道系统2" {
  desc = "研究装载和运输液体或气体的管道",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"地下管1"},
    unlock_building = {"地下管1-JI型"},
  },
  prerequisites = {"收集空气","放置太阳能板"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
  },
  count = 5,
  time = "2s"
}

prototype "排放" {
  desc = "研究气体和液体的排放工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"烟囱1","排水口1"},
    unlock_building = {"烟囱I","排水口I"},
  },
  prerequisites = {"管道系统2"},
  ingredients = {
    {"气候科技包", 1},
  },
  count = 8,
  time = "2s"
}

prototype "冶金学1" {
  desc = "研究工业高温熔炼的装置",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"熔炼炉1"},
    unlock_building = {"熔炼炉I"},
  },
  prerequisites = {"放置太阳能板","生产铁制箱子"},
  ingredients = {
    {"地质科技包", 1},
  },
  count = 5,
  time = "4s"
}

prototype "维修化工厂" {
  desc = "维修化工厂生成化工原料",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_consumption", 0, "化工厂设计图"},
  prerequisites = {"碳处理2"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_repair_chemicalplant1.texture",
  },
  sign_desc = {
    { desc = "使用组装机维修1个破损化工厂", icon = "textures/construct/industry.texture"},
  },
}

prototype "放置化工厂" {
  desc = "放置化工厂生产化工产品",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"select_entity", 0, "化工厂I"},
  prerequisites = {"维修化工厂"},
  count = 1,
  tips_pic = {
    "textures/task_tips_pic/task_click_build.texture",
    "textures/task_tips_pic/task_place_chemicalplant.texture",
  },
  sign_desc = {
    { desc = "放置1座化工厂", icon = "textures/construct/industry.texture"},
  },
}

prototype "生产甲烷" {
  desc = "生产工业气体甲烷",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "甲烷"},
  prerequisites = {"放置化工厂"},
  count = 1000,
  tips_pic = {
    "textures/task_tips_pic/task_produce_ch4.texture",
  },
  sign_desc = {
    { desc = "用化工厂生产1000个单位甲烷", icon = "textures/construct/industry.texture"},
  },
}

prototype "有机化学" {
  desc = "研究碳化合物组成、结构和制备方法",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"塑料1"},
  },
  prerequisites = {"生产甲烷"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
  },
  count = 6,
  time = "10s"
}

prototype "生产乙烯" {
  desc = "生产工业气体乙烯",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "乙烯"},
  prerequisites = {"有机化学"},
  count = 1000,
  tips_pic = {
    "textures/task_tips_pic/task_produce_ch4.texture",
  },
  sign_desc = {
    { desc = "用化工厂生产1000个单位乙烯", icon = "textures/construct/industry.texture"},
  },
}

prototype "生产塑料" {
  desc = "使用有机化学的科学成果生产质量轻、耐腐蚀的工业材料塑料",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "塑料"},
  prerequisites = {"生产乙烯"},
  count = 30,
  tips_pic = {
    "textures/task_tips_pic/task_produce_plastic.texture",
  },
  sign_desc = {
    { desc = "用化工厂生产30个塑料", icon = "textures/construct/industry.texture"},
  },
}

prototype "电磁学1" {
  desc = "研究电能转换成机械能的基础供能装置",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"电动机1"},
  },
  prerequisites = {"生产塑料","排放"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
  },
  count = 10,
  time = "6s"
}

--研究机械科技瓶
prototype "机械研究" {
  desc = "对适合在火星表面作业的机械装置进行改进和开发",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"机械科技包1"},
  },
  prerequisites = {"电磁学1"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
  },
  count = 6,
  time = "2s",
  sign_desc = {
    { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
  },
  sign_icon = "textures/science/tech-important.texture",
}

prototype "生产机械科技包" {
  desc = "生产科技包用于科技研究",
  icon = "textures/construct/industry.texture",
  type = { "tech", "task" },
  task = {"stat_production", 0, "机械科技包"},
  prerequisites = {"机械研究"},
  count = 3,
  tips_pic = {
    "textures/task_tips_pic/task_produce_plastic.texture",
  },
  sign_desc = {
    { desc = "用组装机生产3个机械科技包", icon = "textures/construct/industry.texture"},
  },
}

prototype "挖掘1" {
  desc = "研究对火星岩石的开采技术",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"采矿机1"},
    unlock_building = {"采矿机I"},
  },
  prerequisites = {"生产机械科技包"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
  },
  count = 4,
  time = "7s"
}

-- prototype "驱动1" {
--   desc = "使用机械手臂快速转移物品",
--   type = { "tech" },
--   icon = "textures/science/tech-research.texture",
--   effects = {
--     unlock_recipe = {"机器爪1"},
--   },
--   prerequisites = {"生产机械科技包"},
--   ingredients = {
--     {"机械科技包", 1},
--   },
--   count = 3,
--   time = "8s"
-- }

prototype "蒸馏1" {
  desc = "将液体混合物汽化进行成分分离的技术",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"蒸馏厂1"},
    unlock_building = {"蒸馏厂I"},
  },
  prerequisites = {"挖掘1"},
  ingredients = {
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 4,
  time = "7s"
}

prototype "电力传输1" {
  desc = "将电能远距离传输的技术",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"铁制电线杆"},
    unlock_building = {"铁制电线杆"},
  },
  prerequisites = {"生产机械科技包"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 2,
  time = "12s"
}

prototype "泵系统1" {
  desc = "使用机械方式加快液体流动",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"压力泵1"},
    unlock_building = {"压力泵I"},
  },
  prerequisites = {"电力传输1"},
  ingredients = {
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 4,
  time = "6s"
}

prototype "自动化1" {
  desc = "使用3D打印技术快速复制物品",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"组装机1"},
    unlock_building = {"组装机I"},
  },
  prerequisites = {"挖掘1","电力传输1"},
  ingredients = {
    {"机械科技包", 1},
  },
  count = 4,
  time = "9s"
}

prototype "地下水净化" {
  desc = "火星地下开采卤水进行过滤净化工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"地下卤水净化","地下水挖掘机","水电站1"},
    unlock_building = {"地下水挖掘机","水电站I"},
  },
  prerequisites = {"蒸馏1"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 4,
  time = "10s"
}

prototype "炼钢" {
  desc = "将铁再锻造成更坚硬金属的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"钢板1"},
  },
  prerequisites = {"挖掘1"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 5,
  time = "9s"
}

prototype "发电机1" {
  desc = "使用蒸汽作为工质将热能转为机械能的发电装置",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"蒸汽发电机1"},
    unlock_building = {"蒸汽发电机I"},
  },
  prerequisites = {"电力传输1"},
  ingredients = {
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 4,
  time = "15s"
}

prototype "物流1" {
  desc = "使用交通工具进行远程运输",
  type = { "tech" },
  icon = "textures/science/tech-logistics.texture",
  effects = {
    unlock_recipe ={"物流中心1","运输车辆1"},
    unlock_building = {"物流中心I"},
  },
  prerequisites = {"发电机1"},
  ingredients = {
    {"机械科技包", 1},
  },
  count = 5,
  time = "10s"
}

prototype "空气过滤技术" {
  desc = "研究将火星混合气体分离的装置",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"空气过滤器1"},
    unlock_building = {"空气过滤器I"},
  },
  prerequisites = {"泵系统1","发电机1"},
  ingredients = {
    {"气候科技包", 1},
  },
  count = 5,
  time = "10s"
}

prototype "矿物处理1" {
  desc = "将矿物进行碾碎并收集的机械工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"粉碎机1","沙子1"},
    unlock_building = {"粉碎机I"},
  },
  prerequisites = {"挖掘1","自动化1"},
  ingredients = {
    {"地质科技包", 1},
    {"机械科技包", 1},
  },
  count = 5,
  time = "10s"
}

prototype "钢加工" {
  desc = "钢制产品更多的铸造技术",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"钢齿轮"},
  },
  prerequisites = {"炼钢"},
  ingredients = {
    {"地质科技包", 1},
    {"机械科技包", 1},
  },
  count = 8,
  time = "8s"
}

prototype "浮选" {
  desc = "使用浮选对矿石实行筛选",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"浮选器1"},
    unlock_building = {"浮选器I"},
  },
  prerequisites = {"矿物处理1","地下水净化"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 8,
  time = "8s"
}

prototype "硅处理" {
  desc = "从沙子中提炼硅的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"硅1","玻璃"},
  },
  prerequisites = {"浮选"},
  ingredients = {
    {"地质科技包", 1},
    {"机械科技包", 1},
  },
  count = 8,
  time = "8s"
}

prototype "铁矿熔炼2" {
  desc = "熔炼铁矿石冶炼成铁板的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"铁板2"},
  },
  prerequisites = {"钢加工","空气过滤技术"},
  ingredients = {
      {"地质科技包", 1},
      {"机械科技包", 1},
  },
  count = 6,
  time = "8s"
}

prototype "能量存储" {
  desc = "更多的有机化学制取工业气体工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"电解厂1"},
    unlock_building = {"电解厂I"},
  },
  prerequisites = {"空气过滤技术"},
  ingredients = {
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 4,
  time = "12s"
}

prototype "有机化学2" {
  desc = "更多的有机化学制取工业气体工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"乙烯转丁二烯","纯水转蒸汽"},
  },
  prerequisites = {"硅处理","能量存储"},
  ingredients = {
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 8,
  time = "8s"
}

prototype "化学工程" {
  desc = "使用大型设施生产化工产品",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"化工厂1","纯水电解"},
    unlock_building = {"化工厂I"},
  },
  prerequisites = {"有机化学2"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 5,
  time = "10s"
}

prototype "管道系统3" {
  desc = "研究装载和运输液体或气体的管道",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"地下管2"},
    unlock_building = {"地下管2-JI型"},
  },
  prerequisites = {"空气过滤技术","浮选"},
  ingredients = {
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 6,
  time = "10s"
}

prototype "无机化学" {
  desc = "使用无机化合物合成物质的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"酸碱中和","碱性溶液","盐酸"},
  },
  prerequisites = {"化学工程","管道系统3"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 10,
  time = "5s"
}

prototype "废料回收1" {
  desc = "回收工业废料",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"铁矿石回收","碎石回收","沙子回收","废料中和"},
  },
  prerequisites = {"无机化学"},
  ingredients = {
      {"地质科技包", 1},
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 12,
  time = "6s"
}

prototype "石头处理3" {
  desc = "获得将硅加工成坩埚的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"坩埚"},
  },
  prerequisites = {"硅处理"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 12,
  time = "8s"
}

prototype "有机化学3" {
  desc = "更多的有机化学制取工业气体工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"橡胶"},
  },
  prerequisites = {"化学工程"},
  ingredients = {
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 12,
  time = "8s"
}

prototype "储存2" {
  desc = "研究更便捷的存储方式",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"大铁制箱子1","小铁制箱子2"},
    unlock_building = {"大铁制箱子I","小铁制箱子II"},
  },
  prerequisites = {"有机化学3","炼钢"},
  ingredients = {
      {"气候科技包", 1},
      {"机械科技包", 1},
  },
  count = 15,
  time = "8s"
}

prototype "冶金学2" {
  desc = "研究工业高温熔炼的装置",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"熔炼炉2"},
    unlock_building = {"熔炼炉II"},
  },
  prerequisites = {"石头处理3","铁矿熔炼2"},
  ingredients = {
    {"地质科技包", 1},
    {"机械科技包", 1},
  },
  count = 20,
  time = "6s"
}

prototype "铝生产" {
  desc = "加工铝矿的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"碾碎铝矿石","铝矿石浮选","氧化铝","铝板1"},
  },
  prerequisites = {"无机化学"},
  ingredients = {
    {"地质科技包", 1},
    {"机械科技包", 1},
  },
  count = 20,
  time = "6s"
}

prototype "硅生产" {
  desc = "将硅加工硅板的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"硅板1"},
  },
  prerequisites = {"无机化学","冶金学2"},
  ingredients = {
    {"地质科技包", 1},
    {"机械科技包", 1},
  },
  count = 30,
  time = "6s"
}

prototype "润滑" {
  desc = "研究工业润滑油制作工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"润滑油"},
  },
  prerequisites = {"硅生产"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 30,
  time = "5s"
}

prototype "铝加工" {
  desc = "使用铝加工其他零器件的工艺",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"铝丝1","铝棒1"},
  },
  prerequisites = {"铝生产","冶金学2"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 25,
  time = "8s"
}

prototype "沸腾实验" {
  desc = "生产精密的电子元器件",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"换热器1","热管1","纯水沸腾","卤水沸腾"},
    unlock_building = {"换热器I","热管1-X型"},
  },
  prerequisites = {"铝生产"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 15,
  time = "5s"
}

prototype "电子器件" {
  desc = "生产精密的电子元器件",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"电容1","绝缘线1","逻辑电路1"},
  },
  prerequisites = {"铝加工","硅生产"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 40,
  time = "5s"
}

prototype "批量生产1" {
  desc = "研究大规模生产的技术",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"组装机2","采矿机2"},
  },
  prerequisites = {"废料回收1"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  count = 30,
  time = "6s"
}

prototype "电子研究" {
  desc = "对电子设备进行深度研究",
  type = { "tech" },
  icon = "textures/science/tech-research.texture",
  effects = {
    unlock_recipe = {"电子科技包1"},
  },
  prerequisites = {"批量生产1","电子器件"},
  ingredients = {
    {"地质科技包", 1},
    {"气候科技包", 1},
    {"机械科技包", 1},
  },
  sign_desc = {
    { desc = "该科技是火星探索的前沿科技，它可以引导更多的科技研究", icon = "textures/science/important.texture"},
  },
  sign_icon = "textures/science/tech-important.texture",
  count = 50,
  time = "5s"
}