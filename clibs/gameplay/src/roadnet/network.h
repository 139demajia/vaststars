#pragma once

#include <stdint.h>
#include "roadnet/road_cross.h"
#include "roadnet/road_straight.h"
#include "roadnet/endpoint.h"
#include "roadnet/lorry.h"
#include "util/dynarray.h"
#include "flatmap.h"

namespace roadnet {
    struct route_key {
        straightid S;
        straightid E;
        bool operator==(const route_key& rhs) const {
            return S == rhs.S && E == rhs.E;
        }
    };
    struct route_value {
        uint16_t dir : 2;
        uint16_t n : 14;
    };

    class network {
    public:
        network() = default;
        void cleanMap(world& w);
        flatmap<loction, ecs::endpoint> updateMap(world& w, flatmap<loction, uint8_t> const& map);
        lorryid          createLorry(world& w, uint16_t classid);
        void             destroyLorry(world& w, lorryid id);
        void             update(uint64_t ti);
        road::straight&  StraightRoad(straightid id);
        road::cross&     CrossRoad(crossid id);
        ecs::lorry&      Lorry(lorryid id);
        lorryid&         LorryInRoad(uint32_t index);
        map_coord        LorryInCoord(uint32_t index) const;

        dynarray<road::cross>           crossAry;
        dynarray<road::straight>        straightAry;
        dynarray<lorryid>               straightLorry;
        dynarray<map_coord>             straightCoord;
        std::vector<ecs::lorry>         lorryVec;
        std::vector<lorryid>            lorryFreeList;
        std::vector<lorryid>            lorryWaitList;
        flatmap<route_key, route_value> routeCached;
    };
}
