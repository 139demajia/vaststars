local guide2 = {
	{
        name = "",
		narrative = {
            {"哔哩..让我们正式进入{/color:4bd0ff 电网教学}", "/pkg/vaststars.resources/ui/textures/guide/guide-6.texture"},
        },
        narrative_end = {
            pop_chapter = {"教学","电网搭建"},
            task = {
                "电网教学",
            },
            guide_progress = 1,
        },
        prerequisites = {},
	},

	{
        name = "",
		narrative = {
            {"哔哩..检查地面上的{/color:4bd0ff 废墟堆},拾取残余{/g 物资}..哔哩..(期待)", "/pkg/vaststars.resources/ui/textures/guide/guide-6.texture"},
        },
        narrative_end = {
            task = {
                "检查废墟",
            },
            guide_progress = 2,
        },
        prerequisites = {
            "电网教学",
        },
	},

	{
        name = "",
		narrative = {
            {"哔哩..放置{/color:4bd0ff 采矿机}准备开采矿物..哔哩..(期待)", "/pkg/vaststars.resources/ui/textures/guide/guide-6.texture"},
        },
        narrative_end = {
            task = {
                "矿区搭建",
            },
            guide_progress = 10,
        },
        prerequisites = {
            "检查废墟",
        },
	},

    {
        name = "",
		narrative = {
            {"哔哩..所有的{/color:4bd0ff 采矿机}处于{/r 缺电状态},请放置{/g 风力发电机}供电..哔哩..(期待)", "/pkg/vaststars.resources/ui/textures/guide/guide-6.texture"},
        },
        narrative_end = {
            task = {
                "风力发电机放置",
            },
            guide_progress = 10,
        },
        prerequisites = {
            "矿区搭建",
        },
	},

    {
        name = "",
		narrative = {
            {"哔哩..{/color:4bd0ff 仓库}设置存储矿石类型..哔哩..(期待)", "/pkg/vaststars.resources/ui/textures/guide/guide-6.texture"},
        },
        narrative_end = {
            task = {
                "收集矿石",
            },
            guide_progress = 10,
        },
        prerequisites = {
            "风力发电机放置",
        },
	},

    {
        name = "",
		narrative = {
            {"哔哩..{/color:4bd0ff 仓库}设置存储矿石类型..哔哩..(期待)", "/pkg/vaststars.resources/ui/textures/guide/guide-6.texture"},
        },
        narrative_end = {
            task = {
                "电力铺设",
            },
            guide_progress = 10,
        },
        prerequisites = {
            "收集矿石",
        },
	},

}

return guide2