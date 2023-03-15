#pragma once

#include <stdint.h>
#include <optional>
#include "roadnet/road_crossroad.h"
#include "roadnet/road_straight.h"
#include "roadnet/road_endpoint.h"
#include "util/dynarray.h"

namespace roadnet {
    class network {
    public:
        network() = default;

        std::map<loction, uint8_t> getMap() const;
        void loadMap(const std::map<loction, uint8_t>& mapData);
        lorryid    createLorry(world& w, uint16_t classid);
        void       destroyLorry(world& w, lorryid id);

        void        update(uint64_t ti);
        road::straight& StraightRoad(roadid id);
        road::crossroad& CrossRoad(roadid id);
        lorry&      Lorry(lorryid id);
        lorryid&    LorryInRoad(uint32_t index);
        road::endpoint& Endpoint(endpointid id);

        road_coord coordConvert(map_coord  mc);
        road_coord coordConvert(loction l, direction dir);
        map_coord  coordConvert(road_coord rc);

        dynarray<road::crossroad>   crossAry;
        dynarray<road::straight>    straightAry;
        std::vector<road::endpoint> endpointVec;
        dynarray<lorryid>           lorryAry;
        std::vector<lorry>          lorryVec;
        std::vector<lorryid>        lorryFreeList;
        std::map<std::pair<roadid,roadid>, direction> routeMap;

        struct straightData {
            uint16_t  id;
            uint16_t  len;
            loction   loc;
            direction start_dir;
            direction finish_dir;
            roadid neighbor; // the next crossroad along this straight road
            straightData() {}
            straightData(uint16_t id, uint16_t len, loction loc, direction start_dir, direction finish_dir, roadid neighbor)
                : id(id)
                , len(len)
                , loc(loc)
                , start_dir(start_dir)
                , finish_dir(finish_dir)
                , neighbor(neighbor)
            {}
        };

        struct endpointData {
            roadid id;
            uint16_t offset;
            uint8_t x;
            uint8_t y;
            direction dir;
            endpointData() {}
            endpointData(roadid id, uint16_t offset, uint8_t x, uint8_t y, direction dir)
                : id(id)
                , offset(offset)
                , x(x)
                , y(y)
                , dir(dir)
            {}
        };

        std::map<loction, uint8_t> map;
        std::vector<straightData> straightVec;
        std::map<loction, roadid> crossMap;
        std::map<roadid, loction> crossMapR;

    private:
        roadid   findCrossRoad(loction l);
        std::optional<loction> whereCrossRoad(roadid id);
    };
}
