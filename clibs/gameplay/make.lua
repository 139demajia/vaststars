local lm = require "luamake"

lm:runlua "compile_gameplay_ecs" {
    script = "../../clibs/gameplay/compile_ecs.lua",
    input = "../../startup/pkg/vaststars.gameplay/init/component.lua",
    output = "../../clibs/gameplay/src/util/component.h",
}

local antdir = "../../" .. lm.antdir

lm:lua_source "gameplay" {
    cxx = "c++20",
    objdeps = "compile_gameplay_ecs",
    includes = {
        "src/",
        "src/roadnet",
        antdir .. "3rd/luaecs",
        antdir .. "3rd/bee.lua",
        antdir .. "clibs/ecs/",
    },
    sources = {
        "src/**/*.c",
        "src/**/*.cpp",
        "!src/core/road.c",
        "!src/core/mining.cpp",
    }
}
