#include <lua.hpp>

#include "core/world.h"
#include "util/prototype.h"

void statistics::finish_recipe(world& w, uint16_t id) {
    const auto& ingredients = prototype::get<"ingredients", recipe_items>(w, id);
    const auto& results     = prototype::get<"results", recipe_items>(w, id);
    auto& frame             = current();
    stat_add(frame.consumption, ingredients);
    stat_add(frame.production, results);
}

void statistics::frame::reset() {
    production.clear();
    consumption.clear();
    generate_power.clear();
    consume_power.clear();
    power = 0;
}

void statistics::frame::add(const frame& f) {
    stat_add(production, f.production);
    stat_add(consumption, f.consumption);
    stat_add(generate_power, f.generate_power);
    stat_add(consume_power, f.consume_power);
    power += f.power;
}

void statistics::dataset::step() {
    pos = (pos + 1) % PRECISION;
    data[pos].reset();
}

const statistics::frame& statistics::dataset::back() const {
    return data[pos];
}

void statistics::dataset::sum(const dataset& d) {
    step();
    size_t n = tick / d.tick;
    for (size_t i = 0; i < n; ++i) {
        data[pos].add(d.data[(d.pos + PRECISION - i) % PRECISION]);
    }
}

bool statistics::dataset::update(uint64_t time) {
    if (time % tick != 0) {
        return false;
    }
    return true;
}

bool statistics::dataset::update(uint64_t time, const dataset& d) {
    if (time % tick != 0) {
        return false;
    }
    sum(d);
    return true;
}

statistics::statistics() {
    constexpr uint16_t UPS        = 30;
    constexpr uint64_t time_5s    = 5;
    constexpr uint64_t time_1m    = 1 * 60;
    constexpr uint64_t time_10m   = 10 * 60;
    constexpr uint64_t time_1h    = 1 * 60 * 60;
    constexpr uint64_t time_10h   = 10 * 60 * 60;
    constexpr uint64_t time_50h   = 50 * 60 * 60;
    constexpr uint64_t time_250h  = 250 * 60 * 60;
    constexpr uint64_t time_1000h = 1000 * 60 * 60;
    static_assert((time_5s * UPS) % PRECISION == 0);
    static_assert(PRECISION > (time_1m / time_5s));
    _dataset[0].tick = time_5s * UPS / PRECISION;
    _dataset[1].tick = time_1m * UPS / PRECISION;
    _dataset[2].tick = time_10m * UPS / PRECISION;
    _dataset[3].tick = time_1h * UPS / PRECISION;
    _dataset[4].tick = time_10h * UPS / PRECISION;
    _dataset[5].tick = time_50h * UPS / PRECISION;
    _dataset[6].tick = time_250h * UPS / PRECISION;
    _dataset[7].tick = time_1000h * UPS / PRECISION;
}

statistics::frame& statistics::current() {
    auto& _5s = _dataset[0];
    return _5s.data[_5s.pos];
}

void statistics::update(uint64_t time) {
    if (!_dataset[0].update(time)) {
        return;
    }
    _total.add(current());
    for (size_t i = 1; i < _dataset.size(); ++i) {
        if (!_dataset[i].update(time, _dataset[i - 1])) {
            break;
        }
    }
    _dataset[0].step();
}
