#include <lua.hpp>
#include <assert.h>
#include <string.h>

#include "luaecs.h"
#include "core/world.h"
#include "core/capacitance.h"
#include "util/prototype.h"

static constexpr uint64_t UPS        = 30;
static constexpr uint64_t DuskTick   = 100 * UPS;
static constexpr uint64_t NightTick  =  50 * UPS + DuskTick;
static constexpr uint64_t DawnTick   = 100 * UPS + NightTick;
static constexpr uint64_t DayTick    = 250 * UPS + DawnTick;

static constexpr uint64_t FixedPoint = 100 * UPS;

static uint64_t
solar_efficiency(uint64_t time) {
    if (time < DuskTick) {
        static_assert(FixedPoint == DuskTick);
        return DuskTick - time;
    }
    if (time < NightTick) {
        return 0;
    }
    if (time < DawnTick) {
        static_assert(FixedPoint == (DawnTick - NightTick));
        return time - NightTick;
    }
    return FixedPoint;
}

static int
lupdate(lua_State *L) {
    auto& w = getworld(L);
    w.time++;
    uint64_t eff = solar_efficiency(w.time / DayTick);
    if (eff != 0) {
        float efficiency = (float)eff / FixedPoint;
        for (auto& v : ecs_api::select<ecs::solar_panel, ecs::capacitance, ecs::building>(w.ecs)) {
            auto generator = get_generator(w, v);
            generator.force_produce(efficiency);
        }
    }
    
    for (auto& v : ecs_api::select<ecs::wind_turbine, ecs::capacitance, ecs::building>(w.ecs)) {
        auto generator = get_generator(w, v);
        generator.force_produce();
    }
    return 0;
}

extern "C" int
luaopen_vaststars_generator_system(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
