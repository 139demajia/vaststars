#include <lua.hpp>

#include "luaecs.h"
#include "core/world.h"
#include "core/entity.h"
#include "core/select.h"
extern "C" {
#include "util/prototype.h"
}


struct task {
    enum class type: uint16_t {
        stat_production = 0,
        stat_consumption,
        select_entity,
        select_chect,
        power_generator,
    };
    type     type;
    uint16_t e;
    uint16_t p1;
    uint16_t p2;

    uint64_t stat_production(world& w);
    uint64_t stat_consumption(world& w);
    uint64_t select_entity(world& w);
    uint64_t select_chect(world& w);
    uint64_t power_generator(world& w);
    uint64_t eval(world& w);
    uint16_t progress(world& w, uint16_t max);
};

uint64_t task::stat_production(world& w) {
    auto iter = w.stat.production.find(p1);
    if (iter) {
        return *iter;
    }
    return 0;
}

uint64_t task::stat_consumption(world& w) {
    auto iter = w.stat.consumption.find(p1);
    if (iter) {
        return *iter;
    }
    return 0;
}

uint64_t task::select_entity(world& w) {
    uint64_t n = 0;
    for (auto& v : w.select<entity>()) {
        entity& e = v.get<entity>();
        if (e.prototype == p1) {
            ++n;
        }
    }
    return n;
}

uint64_t task::select_chect(world& w) {
    uint64_t n = 0;
    for (auto& v : w.select<chest, entity>()) {
        entity& e = v.get<entity>();
        if (e.prototype == p1) {
            chest& c = v.get<chest>();
            auto& container = w.query_container<chest_container>(c.container);
            for (auto& slot : container.slots) {
                if (slot.item == p2) {
                    n += slot.amount;
                    break;
                }
            }
        }
    }
    return n;
}

uint64_t task::power_generator(world& w) {
    return w.powergrid.generate_power;
}

uint64_t task::eval(world& w) {
    switch (type) {
    case task::type::stat_production:  return stat_production(w);
    case task::type::stat_consumption: return stat_consumption(w);
    case task::type::select_entity:    return select_entity(w);
    case task::type::select_chect:     return select_chect(w);
    case task::type::power_generator:  return power_generator(w);
    }
    return 0;
}

uint16_t task::progress(world& w, uint16_t max) {
    uint64_t v = eval(w);
    for (uint16_t i = 0; i < e; ++i) {
        v /= 10;
    }
    if (v >= max) {
        return max;
    }
    return (uint16_t)v;
}

static int
lupdate(lua_State *L) {
    world& w = *(world*)lua_touserdata(L, 1);
    for (;;) {
        uint16_t taskid = w.techtree.queue_top();
        if (taskid == 0) {
            break;
        }
        prototype_context task_prototype = w.prototype(taskid);
        if (0 != pt_time(&task_prototype)) {
            break;
        }
        struct task& task = *(struct task*)pt_task(&task_prototype);
        uint16_t count = (uint16_t)pt_count(&task_prototype);
        uint16_t value = task.progress(w, count);
        if (!w.techtree.research_set(taskid, count, value)) {
            break;
        }
        w.techtree.queue_pop();
    }
    return 0;
}

extern "C" int
luaopen_vaststars_task_system(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
