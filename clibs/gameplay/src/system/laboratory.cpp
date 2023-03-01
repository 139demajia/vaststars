#include <lua.hpp>
#include <optional>
#include <algorithm>

#include "luaecs.h"
#include "core/world.h"
#include "core/capacitance.h"
extern "C" {
#include "util/prototype.h"
}

#define STATUS_IDLE 0
#define STATUS_DONE 1
#define STATUS_INVALID 2

static void
laboratory_set_tech(lua_State* L, world& w, ecs::building& building, ecs::laboratory& l, ecs::chest& c2, uint16_t techid) {
    l.tech = techid;
    std::vector<uint16_t> limit(chest::size(w, container::index::from(c2.chest)));
    if (techid == 0 || l.status == STATUS_INVALID) {
        for (auto& v : limit) {
            v = 2;
        }
    }
    else {
        auto& r = w.techtree.get_ingredients(L, w, building.prototype, techid);
        assert(r);
        for (size_t i = 0; i < limit.size(); ++i) {
            limit[i] = 2 * (std::max)((uint16_t)1, (*r)[i+1].amount);
        }
    }
    chest::limit(w, container::index::from(c2.chest), limit.data(), (uint16_t)limit.size());
}

static void
laboratory_next_tech(lua_State* L, world& w, ecs::building& building, ecs::laboratory& l, ecs::chest& c2, uint16_t techid) {
    if (l.tech == techid) {
        return;
    }
    if (l.tech) {
        auto& oldr = w.techtree.get_ingredients(L, w, building.prototype, l.tech);
        if (oldr) {
            chest::recover(w, container::index::from(c2.chest), to_recipe(oldr));
        }
    }
    if (!techid) {
        laboratory_set_tech(L, w, building, l, c2, 0);
        l.progress = 0;
        l.status = STATUS_IDLE;
        return;
    }

    auto& newr = w.techtree.get_ingredients(L, w, building.prototype, techid);
    if (!newr) {
        l.tech = techid;
        l.progress = 0;
        l.status = STATUS_INVALID;
        return;
    }
    laboratory_set_tech(L, w, building, l, c2, techid);
    if (chest::pickup(w, container::index::from(c2.chest), to_recipe(newr))) {
        prototype_context tech = w.prototype(L, techid);
        int time = pt_time(&tech);
        l.progress = time * 100;
        l.status = STATUS_DONE;
    }
    else {
        l.progress = 0;
        l.status = STATUS_IDLE;
    }
}

static void
laboratory_update(lua_State* L, world& w, ecs_api::entity<ecs::laboratory, ecs::chest, ecs::capacitance, ecs::building>& v, bool& updated) {
    auto& building = v.get<ecs::building>();
    auto& l = v.get<ecs::laboratory>();
    auto& c2 = v.get<ecs::chest>();
    auto consumer = get_consumer(L, w, v);

    // step.1
    if (!consumer.cost_drain()) {
        return;
    }
    if (l.tech == 0 || l.status == STATUS_INVALID) {
        return;
    }

    // step.2
    while (l.progress <= 0) {
        prototype_context tech = w.prototype(L, l.tech);
        if (l.status == STATUS_DONE) {
            int count = pt_count(&tech);
            if (w.techtree.research_add(l.tech, count, 1)) {
                w.techtree.queue_pop();
                l.tech = 0;
                l.progress = 0;
                l.status = STATUS_IDLE;
                updated = true;
                return;
            }
            l.status = STATUS_IDLE;
        }
        if (l.status == STATUS_IDLE) {
            auto& r = w.techtree.get_ingredients(L, w, building.prototype, l.tech);
            if (!r || !chest::pickup(w, container::index::from(c2.chest), to_recipe(r))) {
                return;
            }
            int time = pt_time(&tech);
            l.progress += time * 100;
            l.status = STATUS_DONE;
        }
    }

    // step.3
    if (!consumer.cost_power()) {
        return;
    }

    // step.4
    l.progress -= l.speed;
}

static int
lbuild(lua_State *L) {
    world& w = *(world*)lua_touserdata(L, 1);
    for (auto& v : ecs_api::select<ecs::laboratory, ecs::chest, ecs::building>(w.ecs)) {
        auto& building = v.get<ecs::building>();
        auto& l = v.get<ecs::laboratory>();
        auto& c2 = v.get<ecs::chest>();
        laboratory_set_tech(L, w, building, l, c2, l.tech);
    }
    return 0;
}

static int
lupdate(lua_State *L) {
    world& w = *(world*)lua_touserdata(L, 1);
    bool updated = false;
    for (auto& v : ecs_api::select<ecs::laboratory, ecs::chest, ecs::capacitance, ecs::building>(w.ecs)) {
        auto& l = v.get<ecs::laboratory>();
        auto& c2 = v.get<ecs::chest>();
        uint16_t techid = w.techtree.queue_top();
        if (techid != l.tech) {
            ecs::building& building = v.get<ecs::building>();
            laboratory_next_tech(L, w, building, l, c2, techid);
        }
        laboratory_update(L, w, v, updated);
    }
    if (updated) {
        uint16_t techid = w.techtree.queue_top();
        for (auto& v : ecs_api::select<ecs::laboratory, ecs::chest, ecs::building>(w.ecs)) {
            auto& building = v.get<ecs::building>();
            auto& l = v.get<ecs::laboratory>();
            auto& c2 = v.get<ecs::chest>();
            laboratory_next_tech(L, w, building, l, c2, techid);
        }
    }
    return 0;
}

extern "C" int
luaopen_vaststars_laboratory_system(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "build", lbuild },
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
