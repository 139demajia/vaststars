#include "core/backpack.h"
#include "core/world.h"
#include <algorithm>
#include <limits>
#include <lua.hpp>
#include <binding/binding.h>

constexpr uint32_t kMaxItemAmount = std::numeric_limits<uint16_t>::max();

template <typename T>
void safe_assgin(uint16_t& v, T a, uint16_t limit) {
    if (a >= limit) {
        v = limit;
        return;
    }
    v = (uint16_t)a;
}

template <typename T>
void safe_add_assgin(uint16_t& v, T a, uint16_t limit) {
    if (a >= limit) {
        v = limit;
        return;
    }
    auto s = (uint32_t)v + a;
    if (s >= limit) {
        v = limit;
        return;
    }
    v = (uint16_t)s;
}

static void array_erase(ecs::backpack* it, ecs::backpack* end) {
    ecs::backpack* back = end - 1;
    for (; it != back; ++it) {
        if (it->item == 0) {
            return;
        }
        *it = *(it + 1);
    }
    back->item = 0;
    back->amount = 0;
}

bool backpack_pickup(world& w, uint16_t item, uint16_t amount) {
    assert(item != 0);
    auto [begin, end] = ecs_api::array<ecs::backpack>(w.ecs);
    for (auto it = begin; it != end; ++it) {
        auto& bp = *it;
        if (bp.item == item) {
            if (amount > bp.amount) {
                return false;
            }
            bp.amount -= (uint16_t)amount;
            if (bp.amount == 0) {
                array_erase(it, end);
            }
            return true;
        }
        else if (bp.item == 0) {
            break;
        }
    }
    return false;
}

void backpack_place(world& w, uint16_t item, uint16_t amount) {
    assert(item != 0);
    for (auto& bp : ecs_api::array<ecs::backpack>(w.ecs)) {
        if (bp.item == item) {
            safe_add_assgin(bp.amount, amount, kMaxItemAmount);
            return;
        }
        else if (bp.item == 0) {
            bp.item = item;
            safe_assgin(bp.amount, amount, kMaxItemAmount);
            return;
        }
    }
    auto e = ecs_api::create_entity<ecs::backpack>(w.ecs);
    auto& bp = e.get<ecs::backpack>();
    bp.item = item;
    safe_assgin(bp.amount, amount, kMaxItemAmount);
}

uint16_t backpack_query(world& w, uint16_t item) {
    for (auto& bp : ecs_api::array<ecs::backpack>(w.ecs)) {
        if (bp.item == item) {
            return bp.amount;
        }
        else if (bp.item == 0) {
            break;
        }
    }
    return 0;
}

static int lpickup(lua_State *L) {
    auto& w = getworld(L);
    uint16_t item = bee::lua::checkinteger<uint16_t>(L, 2);
    uint16_t amount = bee::lua::checkinteger<uint16_t>(L, 3);
    bool ok = backpack_pickup(w, item, amount);
    lua_pushboolean(L, ok);
    return 1;
}

static int lplace(lua_State *L) {
    auto& w = getworld(L);
    uint16_t item = bee::lua::checkinteger<uint16_t>(L, 2);
    uint16_t amount = bee::lua::checkinteger<uint16_t>(L, 3);
    backpack_place(w, item, amount);
    return 0;
}

static int lquery(lua_State *L) {
    auto& w = getworld(L);
    uint16_t item = bee::lua::checkinteger<uint16_t>(L, 2);
    uint16_t amount = backpack_query(w, item);
    lua_pushinteger(L, amount);
    return 1;
}

extern "C" int
luaopen_vaststars_backpack_core(lua_State *L) {
    luaL_checkversion(L);
    luaL_Reg l[] = {
        { "pickup", lpickup },
        { "place", lplace },
        { "query", lquery },
        { NULL, NULL },
    };
    luaL_newlib(L, l);
    return 1;
}
