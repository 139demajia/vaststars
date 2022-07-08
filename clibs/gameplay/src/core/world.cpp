#include <lua.hpp>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include "core/world.h"
#include "core/container.h"
#include "system/fluid.h"
extern "C" {
    #include "core/fluidflow.h"
}

#if defined(_WIN32)
    #include <windows.h>
#else
#endif

#define CONTAINER_TYPE(id)  ((id) & 0x8000)
#define CONTAINER_INDEX(id) ((id) & 0x3FFF)
#define CONTAINER_TYPE_CHEST  0x0000
#define CONTAINER_TYPE_RECIPE 0x8000

template <>
container& world::query_container<container>(uint16_t id) {
    uint16_t idx = CONTAINER_INDEX(id);
    if (CONTAINER_TYPE(id) == CONTAINER_TYPE_CHEST) {
        assert(containers.chest.size() > idx);
        return containers.chest[idx];
    }
    assert(containers.recipe.size() > idx);
    return containers.recipe[idx];
}

template <>
chest_container& world::query_container<chest_container>(uint16_t id) {
    uint16_t idx = CONTAINER_INDEX(id);
    assert(CONTAINER_TYPE(id) == CONTAINER_TYPE_CHEST);
    assert(containers.chest.size() > idx);
    return containers.chest[idx];
}

template <>
recipe_container& world::query_container<recipe_container>(uint16_t id) {
    uint16_t idx = CONTAINER_INDEX(id);
    assert(CONTAINER_TYPE(id) != CONTAINER_TYPE_CHEST);
    assert(containers.recipe.size() > idx);
    return containers.recipe[idx];
}

template <>
uint16_t world::container_id<chest_container>() {
    return CONTAINER_TYPE_CHEST | (uint16_t)(containers.chest.size()-1);
}

template <>
uint16_t world::container_id<recipe_container>() {
    return CONTAINER_TYPE_RECIPE | (uint16_t)(containers.recipe.size()-1);
}

namespace lua_world {
    template <typename T, typename R>
    T checklimit(lua_State* L, int idx, R const& r) {
        if (r < std::numeric_limits<T>::lowest() || r >(std::numeric_limits<T>::max)()) {
            luaL_argerror(L, idx, "limit exceeded");
        }
        return (T)r;
    }
    template <typename T>
    T checkinteger(lua_State* L, int idx) {
        return checklimit<T>(L, idx, luaL_checkinteger(L, idx));
    }
    template <typename T>
    T optinteger(lua_State* L, int idx, lua_Integer def) {
        return checklimit<T>(L, idx, luaL_optinteger(L, idx, def));
    }
    struct world& getworld(lua_State* L, int idx) {
        return *(struct world*)lua_touserdata(L, idx);
    }

    static int
    is_researched(lua_State* L) {
        struct world& w = getworld(L, 1);
        uint16_t techid = checkinteger<uint16_t>(L, 2);
        lua_pushboolean(L, w.techtree.is_researched(techid));
        return 1;
    }
    
    static int
    research_queue(lua_State* L) {
        struct world& w = getworld(L, 1);
        if (lua_gettop(L) == 1) {
            auto& q = w.techtree.queue_get();
            size_t N = q.size();
            lua_createtable(L, (int)N, 0);
            for (size_t i = 0; i < N; ++i) {
                lua_pushinteger(L, q[i]);
                lua_rawseti(L, -2, i+1);
            }
            return 1;
        }
        luaL_checktype(L, 2, LUA_TTABLE);
        std::vector<uint16_t> q;
        for (lua_Integer i = 1;; ++i) {
            if (lua_rawgeti(L, 2, i) == LUA_TNIL) {
                break;
            }
            q.push_back(checkinteger<uint16_t>(L, -1));
        }
        w.techtree.queue_set(q);
        return 0;
    }

    static int
    research_progress(lua_State* L) {
        struct world& w = getworld(L, 1);
        uint16_t techid = checkinteger<uint16_t>(L, 2);
        if (lua_gettop(L) == 2) {
            uint16_t progress = w.techtree.get_progress(techid);
            if (progress == 0) {
                return 0;
            }
            lua_pushinteger(L, progress);
            return 1;
        }
        uint16_t value = checkinteger<uint16_t>(L, 3);
        bool ok = w.techtree.research_set(w, L, techid, value);
        lua_pushboolean(L, ok);
        return 1;
    }

    static int
    reset(lua_State* L) {
        struct world& w = getworld(L, 1);
        w.fluidflows.clear();
        w.containers.chest.clear();
        w.containers.recipe.clear();
        return 0;
    }

    static int
    destroy(lua_State* L) {
        struct world& w = getworld(L, 1);
        w.~world();
        return 0;
    }
    
    static int
    fluidflow_build(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);
        int capacity = checkinteger<int>(L, 3);
        int height =  checkinteger<int>(L, 4);
        int base_level = checkinteger<int>(L, 5);
        int pumping_speed = optinteger<int>(L, 6, 0);
        fluid_box box {
            .capacity = capacity,
            .height = height,
            .base_level = base_level,
            .pumping_speed = pumping_speed,
        };
        uint16_t id = w.fluidflows[fluid].build(&box);
        if (id == 0) {
            return luaL_error(L, "fluidflow build failed.");
        }
        lua_pushinteger(L, id);
        return 1;
    }

    static int
    fluidflow_rebuild(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);
        uint16_t id = checkinteger<uint16_t>(L, 3);
        w.fluidflows[fluid].rebuild(id);
        return 0;
    }

    static int
    fluidflow_restore(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);
        uint16_t id = checkinteger<uint16_t>(L, 3);
        int capacity =  checkinteger<int>(L, 4);
        int height =  checkinteger<int>(L, 5);
        int base_level =  checkinteger<int>(L, 6);
        int pumping_speed = optinteger<int>(L, 7, 0);
        fluid_box box {
            .capacity = capacity,
            .height = height,
            .base_level = base_level,
            .pumping_speed = pumping_speed,
        };
        bool ok = w.fluidflows[fluid].restore(id, &box);
        if (!ok) {
            return luaL_error(L, "fluidflow restore failed.");
        }
        return 0;
    }

    static int
    fluidflow_teardown(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);
        uint16_t id = checkinteger<uint16_t>(L, 3);
        bool ok = w.fluidflows[fluid].teardown(id);
        if (!ok) {
            return luaL_error(L, "fluidflow teardown failed.");
        }
        return 0;
    }

    static int
    fluidflow_connect(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);
        fluidflow& flow = w.fluidflows[fluid];
        luaL_checktype(L, 3, LUA_TTABLE);
        lua_Integer n = luaL_len(L, 3);
        for (lua_Integer i = 1; i+2 <= n; i += 3) {
            lua_rawgeti(L, 3, i);
            lua_rawgeti(L, 3, i+1);
            lua_rawgeti(L, 3, i+2);
            uint16_t from = checkinteger<uint16_t>(L, -3);
            uint16_t to = checkinteger<uint16_t>(L, -2);
            bool oneway = !!lua_toboolean(L, -1);
            bool ok =  flow.connect(from, to, oneway);
            if (!ok) {
                return luaL_error(L, "fluidflow connect failed.");
            }
            lua_pop(L, 3);
        }
        return 0;
    }

    static int
    fluidflow_query(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);

        auto& f = w.fluidflows[fluid];
        uint16_t id = checkinteger<uint16_t>(L, 3);
        fluid_state state;
        if (!f.query(id, state)) {
            return luaL_error(L, "fluidflow query failed.");
        }
        lua_createtable(L, 0, 7);
        lua_pushinteger(L, f.multiple);
        lua_setfield(L, -2, "multiple");
        lua_pushinteger(L, state.volume);
        lua_setfield(L, -2, "volume");
        lua_pushinteger(L, state.flow);
        lua_setfield(L, -2, "flow");
        lua_pushinteger(L, state.box.capacity);
        lua_setfield(L, -2, "capacity");
        lua_pushinteger(L, state.box.height);
        lua_setfield(L, -2, "height");
        lua_pushinteger(L, state.box.base_level);
        lua_setfield(L, -2, "base_level");
        lua_pushinteger(L, state.box.pumping_speed);
        lua_setfield(L, -2, "pumping_speed");
        return 1;
    }

    static int
    fluidflow_set(lua_State *L) {
        struct world& w = getworld(L, 1);
        uint16_t fluid = checkinteger<uint16_t>(L, 2);

        auto& f = w.fluidflows[fluid];
        uint16_t id = checkinteger<uint16_t>(L, 3);
        int value = checkinteger<int>(L, 4);
        int multiple = optinteger<int>(L, 5, f.multiple);
        f.set(id, value, multiple);
        return 0;
    }

    static int
    manual(lua_State *L) {
        struct world& w = getworld(L, 1);
        if (lua_gettop(L) == 1) {
            auto& q = w.manual.todos;
            size_t N = q.size();
            lua_createtable(L, (int)N, 0);
            for (size_t i = 0; i < N; ++i) {
                lua_createtable(L, 2, 0);
                switch (q[i].type) {
                case manual_crafting::type::crafting:
                    lua_pushstring(L, "crafting");
                    break;
                case manual_crafting::type::finish:
                    lua_pushstring(L, "finish");
                    break;
                case manual_crafting::type::separator:
                    lua_pushstring(L, "separator");
                    break;
                default:
                    return 0;
                }
                lua_rawseti(L, -2, 1);
                lua_pushinteger(L, q[i].id);
                lua_rawseti(L, -2, 2);

                lua_rawseti(L, -2, i+1);
            }
            return 1;
        }

        luaL_checktype(L, 2, LUA_TTABLE);
        std::vector<manual_crafting::todo> todos;
        lua_Integer n = luaL_len(L, 2);
        for (lua_Integer i = 1; i <= n; ++i) {
            if (LUA_TTABLE != lua_rawgeti(L, 2, i)) {
                lua_pushstring(L, "failed");
                return 1;
            }
            manual_crafting::todo todo;
            {
                lua_rawgeti(L, -1, 1);
                static const char *const opts[] = {"crafting", "finish", "separator", NULL};
                static const manual_crafting::type optsnum[] = {manual_crafting::type::crafting, manual_crafting::type::finish, manual_crafting::type::separator};
                todo.type = optsnum[luaL_checkoption(L, -1, NULL, opts)];
                lua_pop(L, 1);
            }
            {
                lua_rawgeti(L, -1, 2);
                todo.id = checkinteger<uint16_t>(L, -1);
                lua_pop(L, 1);
            }
            todos.emplace_back(todo);
            lua_pop(L, 1);
        }

        while (todos.size() > 0 && todos.back().type == manual_crafting::type::separator) {
            todos.pop_back();
        }

        bool reset = true;
        if (w.manual.todos.size() > 0 && todos.size() > 0) {
            if (w.manual.todos[1].id == todos[1].id) {
                if (w.manual.todos[1].type == todos[1].type && todos[1].type == manual_crafting::type::crafting) {
                    reset = false;
                }
            }
        }
        std::swap(w.manual.todos, todos);
        lua_pushstring(L, reset? "reset": "ok");
        return 1;
    }

    static int
    manual_container(lua_State *L) {
        struct world& w = getworld(L, 1);
        lua_createtable(L, 0, (int)w.manual.container.size());
        for (auto [item, amount] : w.manual.container) {
            lua_pushinteger(L, item);
            lua_pushinteger(L, amount);
            lua_rawset(L, -3);
        }
        return 1;
    }

    int backup_world(lua_State* L);
    int restore_world(lua_State* L);
    int backup_container(lua_State* L);
    int restore_container(lua_State* L);


    constexpr static intptr_t LuaFunction = 0x7000000000000000;

    static int system_call(lua_State* L) {
        intptr_t* list = (intptr_t*)lua_touserdata(L, lua_upvalueindex(4));
        size_t n = lua_rawlen(L, lua_upvalueindex(4)) / sizeof(intptr_t);
        lua_settop(L, 0);
        lua_pushvalue(L, lua_upvalueindex(1));
        for (size_t i = 0; i < n; ++i) {
            intptr_t f = list[i];
            if (f != LuaFunction) {
                ((lua_CFunction)f)(L);
            }
            else {
                lua_rawgeti(L, lua_upvalueindex(3), i+1);
                lua_pushvalue(L, lua_upvalueindex(2));
                lua_call(L, 1, 0);
            }
        }
        return 0;
    }

    static int system(lua_State* L) {
        luaL_checktype(L, 3, LUA_TTABLE);
        lua_settop(L, 3);

        lua_Integer n = luaL_len(L, 3);
        intptr_t* list = (intptr_t*)lua_newuserdatauv(L, sizeof(intptr_t) * n, 3);
        for (lua_Integer i = 1; i <= n; ++i) {
            lua_rawgeti(L, 3, i);
            luaL_checktype(L, -1, LUA_TFUNCTION);
            if (lua_iscfunction(L, -1)) {
                intptr_t f = (intptr_t)lua_tocfunction(L, -1);
                assert(f != LuaFunction);
                list[i-1] = f;
            }
            else {
                list[i-1] = LuaFunction;
            }
            lua_pop(L, 1);
        }
        lua_pushcclosure(L, system_call, 4);
        return 1;
    }

    static uint64_t time_monotonic() {
        uint64_t t;
#if defined(_WIN32)
        t = GetTickCount64();
#else
        struct timespec ti;
        clock_gettime(CLOCK_MONOTONIC, &ti);
        t = (uint64_t)ti.tv_sec * 1000 + ti.tv_nsec / 1000000;
#endif
        return t;
    }

    static int system_perf_call(lua_State* L) {
        intptr_t* list = (intptr_t*)lua_touserdata(L, lua_upvalueindex(4));
        size_t n = lua_rawlen(L, lua_upvalueindex(4)) / sizeof(intptr_t);
        lua_settop(L, 0);
        lua_pushvalue(L, lua_upvalueindex(1));
        for (size_t i = 0; i < n; ++i) {
            uint64_t time = time_monotonic();
            intptr_t f = list[i];
            if (f != LuaFunction) {
                ((lua_CFunction)f)(L);
            }
            else {
                lua_rawgeti(L, lua_upvalueindex(3), i+1);
                lua_pushvalue(L, lua_upvalueindex(2));
                lua_call(L, 1, 0);
            }
            time = time_monotonic() - time;
            lua_rawgeti(L, lua_upvalueindex(5), i+1);
            lua_pushinteger(L, time + lua_tointeger(L, -1));
            lua_rawseti(L, lua_upvalueindex(5), i+1);
            lua_pop(L, 1);
        }
        return 0;
    }

    static int system_perf(lua_State* L) {
        luaL_checktype(L, 3, LUA_TTABLE);
        lua_settop(L, 3);

        lua_Integer n = luaL_len(L, 3);
        intptr_t* list = (intptr_t*)lua_newuserdatauv(L, sizeof(intptr_t) * n, 3);
        lua_createtable(L, (int)n, 0);
        for (lua_Integer i = 1; i <= n; ++i) {
            lua_rawgeti(L, 3, i);
            luaL_checktype(L, -1, LUA_TFUNCTION);
            if (lua_iscfunction(L, -1)) {
                intptr_t f = (intptr_t)lua_tocfunction(L, -1);
                assert(f != LuaFunction);
                list[i-1] = f;
            }
            else {
                list[i-1] = LuaFunction;
            }
            lua_pop(L, 1);
            lua_pushinteger(L, 0);
            lua_rawseti(L, -2, i);
        }
        lua_pushcclosure(L, system_perf_call, 5);
        lua_getupvalue(L, -1, 5);
        return 2;
    }

    static int
    create(lua_State* L) {
        struct world* w = (struct world*)lua_newuserdatauv(L, sizeof(struct world), 0);
        new (w) world;
        w->ecs = (struct ecs_context *)lua_touserdata(L, 1);
        w->P = (struct prototype_cache *)lua_touserdata(L, 2);
        if (luaL_newmetatable(L, "gameplay::world")) {
            lua_pushvalue(L, -1);
            lua_setfield(L, -2, "__index");
            luaL_Reg l[] = {
                // techtree
                {"is_researched", is_researched},
                {"research_queue", research_queue},
                {"research_progress", research_progress},
                // fluidflow
                { "fluidflow_build", fluidflow_build },
                { "fluidflow_restore", fluidflow_restore },
                { "fluidflow_teardown", fluidflow_teardown },
                { "fluidflow_connect", fluidflow_connect },
                { "fluidflow_query", fluidflow_query },
                { "fluidflow_set", fluidflow_set },
                { "fluidflow_rebuild", fluidflow_rebuild },
                // manual
                { "manual", manual },
                { "manual_container", manual_container },
                // saveload
                { "backup_world", backup_world },
                { "restore_world", restore_world },
                { "backup_container", backup_container },
                { "restore_container", restore_container },
                // misc
                {"reset", reset},
                {"system", system},
                {"system_perf", system_perf},
                {"__gc", destroy},
                {nullptr, nullptr},
            };
            luaL_setfuncs(L, l, 0);
        }
        lua_setmetatable(L, -2);
        return 1;
    }
}

static FILE* tofile(lua_State* L, int idx) {
    struct luaL_Stream* p = (struct luaL_Stream*)luaL_checkudata(L, 2, LUA_FILEHANDLE);
    if (!p->closef)
        luaL_error(L, "attempt to use a closed file");
    lua_assert(p->f);
    return p->f;
}

#if defined(_MSC_VER)
#define MSVC_NONSTDC() _Pragma("warning(suppress: 4996)")
#else
#define MSVC_NONSTDC() 
#endif

static int
lfileno(lua_State* L) {
    struct world* w = (struct world*)lua_touserdata(L, 1);
    FILE* f = tofile(L, 2);
    MSVC_NONSTDC();
    lua_pushinteger(L, fileno(f));
    return 1;
}

extern "C" int
luaopen_vaststars_world_core(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "create_world", lua_world::create },
		{ "fileno", lfileno },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
