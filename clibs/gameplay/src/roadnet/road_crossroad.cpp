﻿#include "roadnet/road_crossroad.h"
#include "roadnet/network.h"
#include <assert.h>

namespace roadnet::road {
    static constexpr bool constIsCross(cross_type a, cross_type b) {
        if (((uint8_t)a & 0x03) == ((uint8_t)b & 0x03)) {
            return true;
        }
        if (((uint8_t)a & 0x0C) == ((uint8_t)b & 0x0C)) {
            return true;
        }
        if (((a == cross_type::lr) || (a == cross_type::rl)) && ((b == cross_type::tb) || (b == cross_type::bt))) {
            return true;
        }
        if (a == cross_type::lr && (b == cross_type::bl || b == cross_type::rb)) {
            return true;
        }
        if (a == cross_type::rl && (b == cross_type::tr || b == cross_type::lt)) {
            return true;
        }
        if (a == cross_type::tb && (b == cross_type::lt || b == cross_type::bl)) {
            return true;
        }
        if (a == cross_type::bt && (b == cross_type::rb || b == cross_type::tr)) {
            return true;
        }
        return false;
    }
    static constexpr uint16_t constGetCrossMask(cross_type a) {
        uint16_t m = 0;
        for (uint8_t i = 0; i < 16; ++i) {
            if (constIsCross(a, cross_type(i)) || constIsCross(cross_type(i), a)) {
                m |= 1 << i;
            }
        }
        return m;
    }
    static constexpr uint16_t CrossMap[16] = {
        constGetCrossMask(cross_type(0)),  constGetCrossMask(cross_type(1)),
        constGetCrossMask(cross_type(2)),  constGetCrossMask(cross_type(3)),
        constGetCrossMask(cross_type(4)),  constGetCrossMask(cross_type(5)),
        constGetCrossMask(cross_type(6)),  constGetCrossMask(cross_type(7)),
        constGetCrossMask(cross_type(8)),  constGetCrossMask(cross_type(9)),
        constGetCrossMask(cross_type(10)), constGetCrossMask(cross_type(11)),
        constGetCrossMask(cross_type(12)), constGetCrossMask(cross_type(13)),
        constGetCrossMask(cross_type(14)), constGetCrossMask(cross_type(15)),
    };
    static bool isCross(cross_type a, cross_type b) {
        return (CrossMap[(uint8_t)a] & (1 << (uint16_t)b)) != 0;
    }

    static constexpr direction reverse(direction dir) {
        switch (dir) {
        case direction::l: return direction::r;
        case direction::t: return direction::b;
        case direction::r: return direction::l;
        case direction::b: return direction::t;
        case direction::n: default: return direction::n;
        }
    }

    bool crossroad::hasNeighbor(direction dir) const {
        return neighbor[(uint8_t)dir] != roadid::invalid();
    }

    void crossroad::setNeighbor(direction dir, roadid id) {
        assert(!hasNeighbor(dir));
        neighbor[(uint8_t)dir] = id;
    }

    void crossroad::setRevNeighbor(direction dir, roadid id) {
        assert(rev_neighbor[(uint8_t)dir] == roadid::invalid());
        rev_neighbor[(uint8_t)dir] = id;
    }

    void crossroad::addLorry(network& w, lorryid id, uint16_t offset) {
        cross_type type = cross_type(offset);
        for (size_t i = 0; i < 2; ++i) {
            if (!cross_lorry[i]) {
                auto& l = w.Lorry(id);
                cross_lorry[i] = id;
                cross_status[i] = type;
                l.initTick(kCrossTime);
                return;
            }
        }
    }

    bool crossroad::hasLorry(network& w, uint16_t offset) {
        cross_type type = cross_type(offset);
        if (cross_lorry[0] && cross_lorry[1]) {
            return false;
        }
        if (!cross_lorry[0] && !cross_lorry[1]) {
            return true;
        }
        if (!cross_lorry[0]) {
            return !isCross(cross_type(offset), cross_status[0]);
        }
        return !isCross(cross_type(offset), cross_status[1]);
    }

    void crossroad::delLorry(network& w, uint16_t offset) {
        cross_type type = cross_type(offset);
        for (size_t i = 0; i < 2; ++i) {
            if (cross_lorry[i] && cross_status[i] == type) {
                cross_lorry[i] = lorryid::invalid();
                return;
            }
        }
    }

    lorryid& crossroad::waitingLorry(network& w, direction dir) {
        return w.StraightRoad(rev_neighbor[(size_t)dir]).waitingLorry(w);
    }

    void crossroad::update(network& w, uint64_t ti) {
        for (size_t i = 0; i < 2; ++i) {
            lorryid id = cross_lorry[i];
            if (!id) {
                continue;
            }
            auto& l = w.Lorry(id);
            if (!l.ready()) {
                continue;
            }
            cross_type t = cross_status[i];
            auto& road = w.StraightRoad(neighbor[(uint8_t)t & 0x03u]);
            direction out = direction((uint8_t)t & 0x03u);
            if (road.tryEntry(w, id)) {
                cross_lorry[i] = lorryid::invalid();
            }
        }
        for (uint8_t ii = 0; ii < 4; ++ii) {
            uint8_t i = (ii + (ti>>4)) % 4; // swap the order of the lorries every 16 ticks
            if (!hasNeighbor(direction(i))) {
                continue;
            }
            lorryid id = waitingLorry(w, direction(i));
            if (!id) {
                continue;
            }
            auto& l = w.Lorry(id);
            if (!l.ready()) {
                continue;
            }
            if (cross_lorry[0] && cross_lorry[1]) {
                continue;
            }
            direction out;
            if (!l.nextDirection(w, rev_neighbor[i], out)) {
                continue;
            }
            if (!w.StraightRoad(neighbor[(uint8_t)out]).canEntry(w, id)) {
                continue;
            }
            cross_type type = (cross_type)(((uint8_t)i << 2) | (uint8_t)out);
            size_t idx;
            if (!cross_lorry[0] && !cross_lorry[1]) {
                idx = 0;
            }
            else if (cross_lorry[0]) {
                if (isCross(type, cross_status[0])) {
                    continue;
                }
                idx = 1;
            }
            else {
                if (isCross(type, cross_status[1])) {
                    continue;
                }
                idx = 0;
            }
            waitingLorry(w, direction(i)) = lorryid::invalid();
            cross_lorry[idx] = id;
            cross_status[idx] = type;
            l.initTick(kCrossTime);
        }
    }
}
