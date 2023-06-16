#include <lua.hpp>
#include <string>
#include "roadnet/type.h"
#include "roadnet/network.h"
#include "core/world.h"
#include <bee/nonstd/bit.h>

namespace roadnet::lua {
    static world& get_world(lua_State* L, int idx = 1) {
        return *(world*)lua_touserdata(L, idx);
    }

    static loction get_loction(lua_State* L, int idx) {
        auto v = luaL_checkinteger(L, idx);
        uint8_t x = (uint8_t)((v >>  0) & 0xFF);
        uint8_t y = (uint8_t)((v >>  8) & 0xFF);
        return {x,y};
    }

    static int reset(lua_State* L) {
        auto& w = get_world(L);
        luaL_checktype(L, 2, LUA_TTABLE);
        flatmap<loction, uint8_t> map;
        lua_pushnil(L);
        while (lua_next(L, 2)) {
            auto l = get_loction(L, -2);
            uint8_t m = (uint8_t)luaL_checkinteger(L, -1);
            map.insert_or_assign(l, m);
            lua_pop(L, 1);
        }
        auto endpointMap = w.rw.updateMap(w, map);
        lua_createtable(L, 0, (int)endpointMap.size());
        for (const auto& [loc, ep] : endpointMap) {
            lua_pushinteger(L, loc.id);
            lua_pushinteger(L, std::bit_cast<uint32_t>(ep));
            lua_rawset(L, -3);
        }
        return 1;
    }
    static int remove_lorry(lua_State* L) {
        return 0;
    }
}

extern "C" int
luaopen_vaststars_roadnet_core(lua_State* L) {
    luaL_Reg lib[] = {
        { "reset", roadnet::lua::reset },
        { "remove_lorry", roadnet::lua::remove_lorry },
        { NULL, NULL },
    };
    luaL_newlib(L, lib);
    return 1;
}
