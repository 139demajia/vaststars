#include <lua.hpp>

#include "luaecs.h"
#include "core/world.h"
#include "core/capacitance.h"

static void
block(world& w, component::fluidbox const& fb) {
    w.fluidflows[fb.fluid].block(fb.id);
}

static int
lupdate(lua_State *L) {
    auto& w = getworld(L);
    for (auto& v : ecs::select<component::pump, component::building, component::capacitance, component::fluidbox>(w.ecs)) {
        auto consumer = get_consumer(w, v);
        if (!consumer.cost_drain() || !consumer.cost_power()) {
            block(w, v.get<component::fluidbox>());
            continue;
        }
    }
    return 0;
}

extern "C" int
luaopen_vaststars_pump_system(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
