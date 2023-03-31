#include <lua.hpp>
#include <string>
#include <map>
#include "roadnet/coord.h"
#include "roadnet/network.h"
#include "core/world.h"
#include <bee/nonstd/bit.h>

namespace roadnet::lua {
    static roadnet::network& get_network(lua_State* L, int idx = 1) {
        auto& w = *(world*)lua_touserdata(L, idx);
        return w.rw;
    }

    static std::string_view get_strview(lua_State* L, int idx) {
        size_t len = 0;
        const char* buf = luaL_checklstring(L, idx, &len);
        return std::string_view(buf, len);
    }

    static map_coord get_map_coord(lua_State* L, int idx) {
        auto v = luaL_checkinteger(L, idx);
        uint8_t x = (uint8_t)((v >>  0) & 0xFF);
        uint8_t y = (uint8_t)((v >>  8) & 0xFF);
        uint8_t z = (uint8_t)((v >> 16) & 0xFF);
        return {x,y,z};
    }

    static road_coord get_road_coord(lua_State* L, int idx) {
        auto v = luaL_checkinteger(L, idx);
        uint16_t id     = (uint16_t)(v & 0xFFFF);
        uint16_t type   = (uint16_t)((v >> 0) & 0x1);
        if (type) {
            cross_type offset = (cross_type)((v >> 18) & 0x00FF);
            return road_coord(std::bit_cast<roadid>(id), offset);
        }
        else {
            uint8_t  stype  = (uint8_t)(((v >> 16) >> 14) & 0x3);
            uint16_t offset = (uint16_t)((v >> 18) & 0x3FFF);
            return road_coord(std::bit_cast<roadid>(id), (straight_type)stype, offset);
        }
    }

    static loction get_loction(lua_State* L, int idx) {
        auto v = luaL_checkinteger(L, idx);
        uint8_t x = (uint8_t)((v >>  0) & 0xFF);
        uint8_t y = (uint8_t)((v >>  8) & 0xFF);
        return {x,y};
    }

    static std::map<loction, uint8_t> get_map_data(lua_State* L, int idx) {
        std::map<loction, uint8_t> map;
        luaL_checktype(L, idx, LUA_TTABLE);
        for(lua_pushnil(L); lua_next(L, idx); lua_pop(L, 1)) {
            auto l = get_loction(L, -2);
            uint8_t m = (uint8_t)luaL_checkinteger(L, -1);
            map.emplace(l, m);
        }
        return map;
    }

    static void push_map_coord(lua_State* L, map_coord& c) {
        uint32_t v = 0;
        v |= (uint32_t)c.x <<  0;
        v |= (uint32_t)c.y <<  8;
        v |= (uint32_t)c.z << 16;
        lua_pushinteger(L, v);
    }

    static void push_road_coord(lua_State* L, road_coord& c) {
        uint32_t v = 0;
        v |= (uint32_t)std::bit_cast<uint16_t>(c.id);
        v |= (uint32_t)c.type << 16;
        v |= (uint32_t)c.offset << 18;
        lua_pushinteger(L, v);
    }

    static void push_route_map(lua_State* L, int from, int to, int cost) {
        lua_createtable(L, 4, 0);

        lua_pushinteger(L, 1);
        lua_pushinteger(L, from);
        lua_settable(L, -3);

        lua_pushinteger(L, 2);
        lua_pushinteger(L, to);
        lua_settable(L, -3);
        
        lua_pushinteger(L, 3);
        lua_pushinteger(L, cost);
        lua_settable(L, -3);
    }

    static int load_map(lua_State* L) {
        auto& w = get_network(L);
        w.loadMap(get_map_data(L, 2));
        return 0;
    }
    static int get_map(lua_State* L) {
        auto& w = get_network(L);
        lua_createtable(L, 0, 0);
        for(auto& [l, m] : w.getMap()) {
            lua_pushinteger(L, l.id);
            lua_pushinteger(L, m);
            lua_settable(L, -3);
        }
        return 1;
    }
    static int lmap_coord(lua_State* L) {
        auto& w = get_network(L);
        auto r = w.coordConvert(get_road_coord(L, 2));
        push_map_coord(L, r);
        return 1;
    }
    struct eachlorry {
        enum class status {
            cross,
            straight,
            finish,
        };
        status status = status::cross;
        uint32_t index = 0;
        uint16_t straight = 0;
        lorryid next_cross(roadnet::network& w, road_coord& coord) {
            static constexpr int N = 2;
            for (;;) {
                if (index >= N * w.crossAry.size()) {
                    status = status::straight;
                    index = 0;
                    return next_straight(w, coord);
                }
                uint16_t road_idx = (uint16_t)(index / N);
                uint8_t  entry_idx = index % N;
                index++;
                auto& road = w.crossAry[road_idx];
                auto id = road.cross_lorry[entry_idx];
                if (id) {
                    coord = {roadid {roadtype::cross, road_idx}, road.cross_status[entry_idx]};
                    return id;
                }
            }
        }
        lorryid next_straight(roadnet::network& w, road_coord& coord) {
            for (;;) {
                if (index >= w.lorryAry.size()) {
                    status = status::finish;
                    return lorryid::invalid();
                }
                auto& id = w.lorryAry[index];
                if (id) {
                    while (index >= w.straightAry[straight].lorryOffset + w.straightAry[straight].len) {
                        straight++;
                    }
                    coord = {roadid {roadtype::straight, straight}, straight_type::straight, (uint16_t)(index - w.straightAry[straight].lorryOffset)};
                    index++;
                    return id;
                }
                index++;
            }
        }
        lorryid next(roadnet::network& w, road_coord& coord) {
            switch (status) {
            case status::cross:
                return next_cross(w, coord);
            case status::straight:
                return next_straight(w, coord);
            default:
            case status::finish:
                return lorryid::invalid();
            }
        }
        static eachlorry& get(lua_State* L, int idx) {
            return *static_cast<eachlorry*>(lua_touserdata(L, idx));
        }
        static int next(lua_State* L) {
            auto& w = get_network(L, lua_upvalueindex(2));
            eachlorry& self = get(L, lua_upvalueindex(1));
            road_coord coord;
            auto id = self.next(w, coord);
            if (id == lorryid::invalid()) {
                return 0;
            }
            lua_pushinteger(L, id.id);
            push_road_coord(L, coord);
            lua_pushinteger(L, w.Lorry(id).tick);
            return 3;
        }
        static int gc(lua_State* L) {
            get(L, 1).~eachlorry();
            return 0;
        }
    };
    static int each_lorry(lua_State* L) {
        void* storage = lua_newuserdatauv(L, sizeof(eachlorry), 0);
        new (storage) eachlorry;
        if (luaL_newmetatable(L, "roadnet::each_lorry")) {
            static luaL_Reg mt[] = {
                {"__gc", eachlorry::gc},
                {NULL, NULL},
            };
            luaL_setfuncs(L, mt, 0);
        }
        lua_setmetatable(L, -2);
        lua_pushvalue(L, -1);
        lua_pushvalue(L, 1);
        lua_pushcclosure(L, eachlorry::next, 2);
        return 1;
    }
    static int endpoint_id(lua_State* L) {
        auto& w = get_network(L);
        auto x = luaL_checkinteger(L, 2);
        auto y = luaL_checkinteger(L, 3);
        auto dir = direction(luaL_checkinteger(L, 4));
        auto id = w.EndpointId({(uint8_t)x, (uint8_t)y}, dir);
        lua_pushinteger(L, id.id);
        return 1;
    }
    static int constants(lua_State* L) {
        auto& w = get_network(L);
        static constexpr std::pair<const char*, uint8_t> constants[] = {
            { "kTime", roadnet::kTime },
            { "kWaitTime", roadnet::kWaitTime },
            { "kCrossTime", roadnet::kCrossTime },
        };

        lua_createtable(L, 0, std::size(constants));
        for (const auto& [name, value] : constants) {
            lua_pushstring(L, name);
            lua_pushinteger(L, value);
            lua_settable(L, -3);
        }

        return 1;
    }
}

extern "C" int
luaopen_vaststars_roadnet_core(lua_State* L) {
    luaL_Reg l[] = {
        { "load_map", roadnet::lua::load_map },
        { "get_map", roadnet::lua::get_map },
        { "map_coord", roadnet::lua::lmap_coord },
        { "each_lorry", roadnet::lua::each_lorry },
        { "endpoint_id", roadnet::lua::endpoint_id },
        { "constants", roadnet::lua::constants},
        { NULL, NULL },
    };
    luaL_newlib(L, l);
    return 1;
}
