#include <lua.hpp>
#include <stdlib.h>
#include <memory.h>
#include <assert.h>
#include "core/chest.h"
#include "core/world.h"
extern "C" {
#include "util/prototype.h"
}

static bool isFluidId(uint16_t id) {
    return (id & 0x0C00) == 0x0C00;
}

static void list_remove(world& w, container::index start, container::index i) {
    assert(start != i);
    for (auto index = start; index != container::kInvalidIndex;) {
        auto& slot = w.container.at(index);
        if (slot.next == i) {
            slot.next = w.container.at(index).next;
            w.container.free_slot(i);
            break;
        }
        index = slot.next;
    }
}

static void list_append(world& w, container::index start, container::index v) {
    for (auto index = start;;) {
        auto& s = w.container.at(index);
        if (s.next == container::kInvalidIndex) {
            s.next = v;
            break;
        }
        index = s.next;
    }
}

container::index chest::head(world& w, container::index start) {
    return w.container.at(start).next;
}

container::slot& chest::array_at(world& w, container::index start, uint8_t offset) {
    return w.container.at(chest::head(w, start) + offset);
}

std::span<container::slot> chest::array_slice(world& w, container::index start, uint8_t offset, uint16_t size) {
    return w.container.slice(chest::head(w, start) + offset, size);
}

container::index chest::create(world& w, uint16_t endpoint, container_slot* data, container::size_type asize, container::size_type lsize) {
    auto start = w.container.create_chest(asize, lsize);
    for (auto i = chest::head(w, start); i != container::kInvalidIndex;) {
        auto& s = w.container.at(i);
        (container_slot&)s = *data++;
        if (endpoint != 0xffff) {
            trading_flush(w, {endpoint}, s);
        }
        i = s.next;
    }
    return start;
}

void chest::add(world& w, container::index index, uint16_t endpoint, container_slot* data, container::size_type lsize) {
    if (lsize == 0) {
        return;
    }
    auto start = w.container.alloc_slot(lsize);
    list_append(w, index, start);
    for (auto i = start; i != container::kInvalidIndex;) {
        auto& s = w.container.at(i);
        (container_slot&)s = *data++;
        if (endpoint != 0xffff) {
            trading_flush(w, {endpoint}, s);
        }
        i = s.next;
    }
}

chest::chest_data& chest::query(ecs::chest& c) {
    static_assert(sizeof(chest::chest_data::index) == sizeof(ecs::chest::index));
    static_assert(sizeof(chest::chest_data::asize) == sizeof(ecs::chest::asize));
    return (chest_data&)c;
}

uint16_t chest::get_fluid(world& w, chest_data& c, uint8_t offset) {
    assert(offset < c.asize);
    auto& s = chest::array_at(w, c.index, offset);
    assert(isFluidId(s.item));
    return s.amount;
}

void chest::set_fluid(world& w, chest_data& c, uint8_t offset, uint16_t value) {
    assert(offset < c.asize);
    auto& s = chest::array_at(w, c.index, offset);
    assert(isFluidId(s.item));
    s.amount = value;
}

bool chest::pickup(world& w, chest_data& c, uint16_t endpoint, prototype_context& recipe) {
    recipe_items* ingredients = (recipe_items*)pt_ingredients(&recipe);
    return chest::pickup(w, c, endpoint, ingredients, 0);
}

bool chest::place(world& w, chest_data& c, uint16_t endpoint, prototype_context& recipe) {
    recipe_items* ingredients = (recipe_items*)pt_ingredients(&recipe);
    recipe_items* results = (recipe_items*)pt_results(&recipe);
    //TODO ingredients->n -> uint8_t
    return chest::place(w, c, endpoint, results, (uint8_t)ingredients->n);
}

bool chest::pickup(world& w, chest_data& c, uint16_t endpoint, const recipe_items* r, uint8_t offset) {
    assert(offset + r->n <= c.asize);
    size_t i = 0;
    for (auto& s: chest::array_slice(w, c.index, offset, r->n)) {
        auto& t = r->items[i++];
        assert(s.item == t.item);
        if (s.amount < t.amount) {
            return false;
        }
    }
    i = 0;
    for (auto& s: chest::array_slice(w, c.index, offset, r->n)) {
        auto& t = r->items[i++];
        s.amount -= t.amount;
    }
    chest::flush(w, c.index, endpoint);
    return true;
}

bool chest::place(world& w, chest_data& c, uint16_t endpoint, const recipe_items* r, uint8_t offset) {
    assert(offset + r->n <= c.asize);
    size_t i = 0;
    for (auto& s: chest::array_slice(w, c.index, offset, r->n)) {
        auto& t = r->items[i++];
        assert(s.item == t.item);
        if (s.amount + t.amount > s.limit) {
            return false;
        }
    }
    i = 0;
    for (auto& s: chest::array_slice(w, c.index, offset, r->n)) {
        auto& t = r->items[i++];
        s.amount += t.amount;
    }
    chest::flush(w, c.index, endpoint);
    return true;
}

bool chest::recover(world& w, chest_data& c, const recipe_items* r, uint8_t offset) {
    assert(offset + r->n <= c.asize);
    size_t i = 0;
    for (auto& s: chest::array_slice(w, c.index, offset, r->n)) {
        auto& t = r->items[i++];
        assert(s.item == t.item);
        s.amount += t.amount;
    }
    return true;
}

void chest::limit(world& w, chest_data& c, uint16_t endpoint, const uint16_t* r) {
    for (auto& s: chest::array_slice(w, c.index, 0, c.asize)) {
        s.limit = *r++;
    }
    chest::flush(w, c.index, endpoint);
}

size_t chest::size(chest_data& c) {
    return c.asize;
}

void chest::flush(world& w, container::index start, uint16_t endpoint) {
    if (endpoint == 0xffff) {
        return;
    }
    for (auto index = chest::head(w, start); index != container::kInvalidIndex;) {
        auto& s = w.container.at(index);
        trading_flush(w, {endpoint}, s);
        index = s.next;
    }
}

void chest::rollback(world& w, container::index start, uint16_t endpoint) {
    if (endpoint == 0xffff) {
        return;
    }
    for (auto index = chest::head(w, start); index != container::kInvalidIndex;) {
        auto& s = w.container.at(index);
        trading_rollback(w, {endpoint}, s);
        index = s.next;
    }
}

bool chest::pickup_force(world& w, container::index start, uint16_t item, uint16_t amount, bool unlock) {
    for (auto index = chest::head(w, start); index != container::kInvalidIndex;) {
        auto& s = w.container.at(index);
        if (s.item == item) {
            if (unlock) {
                if (amount > s.amount) {
                    return false;
                }
                if (amount <= s.lock_item) {
                    s.lock_item -= amount;
                }
                else {
                    s.lock_item = 0;
                }
            }
            else {
                if (amount + s.lock_item > s.amount) {
                    return false;
                }
            }
            s.amount -= amount;
            if (s.amount == 0 && s.lock_item == 0 && s.lock_space == 0) {
                if (s.unit == container_slot::slot_unit::list) {
                    list_remove(w, start, index);
                }
            }
            return true;
        }
        index = s.next;
    }
    return false;
}

void chest::place_force(world& w, container::index start, uint16_t item, uint16_t amount, bool unlock) {
    for (auto index = chest::head(w, start); index != container::kInvalidIndex;) {
        auto& s = w.container.at(index);
        if (s.item == item) {
            if (unlock) {
                if (amount <= s.lock_space) {
                    s.lock_space -= amount;
                }
                else {
                    s.lock_space = 0;
                }
            }
            s.amount += amount;
            return;
        }
        index = s.next;
    }

    auto idx = w.container.alloc_slot(1);
    auto& newslot = w.container.at(idx);
    newslot.init();
    newslot.item = item;
    newslot.amount = amount;
    list_append(w, start, idx);
}

const container_slot* chest::getslot(world& w, container::index start, uint8_t offset) {
    auto index = chest::head(w, start);
    for (uint8_t i = 0; i < offset; ++i) {
        if (index == container::kInvalidIndex) {
            return nullptr;
        }
        index = w.container.at(index).next;
    }
    if (index == container::kInvalidIndex) {
        return nullptr;
    }
    auto& s = w.container.at(index);
    return &s;
}

static int
lcreate(lua_State* L) {
    world& w = *(world *)lua_touserdata(L, 1);
    uint16_t endpoint = (uint16_t)luaL_checkinteger(L, 2);
    size_t sz = 0;
    container_slot* s = (container_slot*)luaL_checklstring(L, 3, &sz);
    size_t n = sz / sizeof(container_slot);
    if (n < 0 || n > (uint16_t) -1 || sz % sizeof(container_slot) != 0) {
        return luaL_error(L, "size out of range.");
    }
    uint16_t asize = (uint16_t)luaL_checkinteger(L, 4);
    if (asize > n) {
        return luaL_error(L, "asize out of range.");
    }
    auto index = chest::create(w, endpoint, s, asize, (uint16_t)n-asize);
    lua_pushinteger(L, index);
    return 1;
}

static int
ladd(lua_State* L) {
    world& w = *(world *)lua_touserdata(L, 1);
    uint16_t index = (uint16_t)luaL_checkinteger(L, 2);
    uint16_t endpoint = (uint16_t)luaL_checkinteger(L, 3);
    size_t sz = 0;
    container_slot* s = (container_slot*)luaL_checklstring(L, 4, &sz);
    size_t n = sz / sizeof(container_slot);
    if (n < 0 || n > (uint16_t) -1 || sz % sizeof(container_slot) != 0) {
        return luaL_error(L, "size out of range.");
    }
    chest::add(w, container::index::from(index), endpoint, s, (uint16_t)n);
    return 0;
}

static int
lget(lua_State* L) {
    world& w = *(world *)lua_touserdata(L, 1);
    uint16_t index = (uint16_t)luaL_checkinteger(L, 2);
    uint8_t offset = (uint8_t)(luaL_checkinteger(L, 3)-1);
    auto r = chest::getslot(w, container::index::from(index), offset);
    if (!r) {
        return 0;
    }
    lua_createtable(L, 0, 7);
    switch (r->type) {
    case container_slot::slot_type::red:
        lua_pushstring(L, "red");
        break;
    case container_slot::slot_type::blue:
        lua_pushstring(L, "blue");
        break;
    case container_slot::slot_type::green:
        lua_pushstring(L, "green");
        break;
    default:
        lua_pushstring(L, "unknown");
        break;
    }
    lua_setfield(L, -2, "type");
    lua_pushinteger(L, r->item);
    lua_setfield(L, -2, "item");
    lua_pushinteger(L, r->amount);
    lua_setfield(L, -2, "amount");
    lua_pushinteger(L, r->limit);
    lua_setfield(L, -2, "limit");
    lua_pushinteger(L, r->lock_item);
    lua_setfield(L, -2, "lock_item");
    lua_pushinteger(L, r->lock_space);
    lua_setfield(L, -2, "lock_space");
    return 1;
}

static int
lpickup(lua_State* L) {
    world& w = *(world *)lua_touserdata(L, 1);
    uint16_t index = (uint16_t)luaL_checkinteger(L, 2);
    uint16_t item = (uint16_t)luaL_checkinteger(L, 3);
    uint16_t amount = (uint16_t)luaL_checkinteger(L, 4);
    bool ok = chest::pickup_force(w, container::index::from(index), item, amount, false);
    lua_pushboolean(L, ok);
    return 1;
}

static int
lplace(lua_State* L) {
    world& w = *(world *)lua_touserdata(L, 1);
    uint16_t index = (uint16_t)luaL_checkinteger(L, 2);
    uint16_t item = (uint16_t)luaL_checkinteger(L, 3);
    uint16_t amount = (uint16_t)luaL_checkinteger(L, 4);
    chest::place_force(w, container::index::from(index), item, amount, false);
    return 0;
}

static int
lrollback(lua_State* L) {
    world& w = *(world *)lua_touserdata(L, 1);
    uint16_t index = (uint16_t)luaL_checkinteger(L, 2);
    uint16_t endpoint = (uint16_t)luaL_checkinteger(L, 3);
    chest::rollback(w, container::index::from(index), endpoint);
    return 0;
}

extern "C" int
luaopen_vaststars_chest_core(lua_State *L) {
    luaL_checkversion(L);
    luaL_Reg l[] = {
        { "create", lcreate },
        { "add", ladd },
        { "get", lget },
        { "pickup", lpickup },
        { "place", lplace },
        { "rollback", lrollback },
        { NULL, NULL },
    };
    luaL_newlib(L, l);
    return 1;
}
