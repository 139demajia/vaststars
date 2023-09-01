﻿#include <lua.hpp>
#include "system/drone.h"
#include "luaecs.h"
#include "core/world.h"
#include "core/capacitance.h"
#include "core/backpack.h"
#include <bee/nonstd/unreachable.h>
#include <math.h>
#include <algorithm>

using DroneEntity = ecs_api::entity<ecs::drone>;

static uint8_t safe_add(uint8_t a, uint8_t b) {
    if (b > UINT8_C(255) - a)
        return UINT8_C(255);
    return a + b;
}

static uint8_t safe_sub(uint8_t a, uint8_t b) {
    if (a > b)
        return a - b;
    return UINT8_C(0);
}

struct building_rect {
    uint8_t x1, x2, y1, y2;
    building_rect(uint8_t x, uint8_t y, uint8_t direction, uint16_t area, uint16_t scale_area) {
        uint8_t w = area >> 8;
        uint8_t h = area & 0xFF;
        uint8_t sw = scale_area >> 8;
        uint8_t sh = scale_area & 0xFF;
        assert(w > 0 && h > 0);
        assert(sw > 0 && sh > 0);
        if (sw < w) {
            std::swap(sw, w);
        }
        if (sh < h) {
            std::swap(sh, h);
        }
        w--; sw--;
        h--; sh--;
        uint8_t wl = (sw - w) / 2;
        uint8_t wr = sw - wl;
        uint8_t hl = (sh - h) / 2;
        uint8_t hr = sh - hl;
        switch (direction) {
        case 0: // N
        case 2: // S
            x1 = safe_sub(x, wl); x2 = safe_add(x, wr);
            y1 = safe_sub(y, hl); y2 = safe_add(y, hr);
            break;
        case 1: // E
        case 3: // W
            x1 = safe_sub(x, hl); x2 = safe_add(x, hr);
            y1 = safe_sub(y, wl); y2 = safe_add(y, wr);
            break;
        default:
            std::unreachable();
        }
    }
    building_rect(ecs::building const& b, uint16_t area)
        : building_rect(b.x, b.y, b.direction, area, area)
    {}
    building_rect(ecs::building const& b, uint16_t area, uint16_t scale_area)
        : building_rect(b.x, b.y, b.direction, area, scale_area)
    {}
    void each(std::function<void(uint8_t,uint8_t)> f) {
        for (uint8_t i = x1; i <= x2; ++i)
            for (uint8_t j = y1; j <= y2; ++j)
                f(i, j);
    }
};

enum class drone_status : uint8_t {
    init,
    has_error,
    empty_task,
    idle,
    at_home,
    go_mov1,
    go_mov2,
    go_home,
};

static uint16_t getxy(uint8_t x, uint8_t y) {
    return ((uint16_t)x << 8) | (uint16_t)y;
}

static container::slot* ChestGetSlot(world& w, airport_berth const& berth) {
    if (auto building = w.buildings.find(getxy(berth.x, berth.y))) {
        return &chest::array_at(w, container::index::from(building->chest), berth.slot);
    }
    return nullptr;
}

static std::optional<uint8_t> ChestFindSlot(world& w, airport_berth const& berth, uint16_t item) {
    if (auto building = w.buildings.find(getxy(berth.x, berth.y))) {
        auto c = container::index::from(building->chest);
        container::slot* index = chest::find_item(w, c, item);
        if (index) {
            auto& start = chest::array_at(w, c, 0);
            return (uint8_t)(index-&start);
        }
    }
    return std::nullopt;
}

static void SetStatus(ecs::drone& drone, drone_status status) {
    drone.status = (uint8_t)status;
}

static void AssertStatus(ecs::drone& drone, drone_status status) {
    assert(drone.status == (uint8_t)status);
}

static void CheckHasHome(world& w, DroneEntity& e, ecs::drone& drone, std::function<void(world&, DroneEntity&, ecs::drone&, airport&)> f) {
    auto it = w.airports.find(drone.home);
    if (it == w.airports.end()) {
        if (drone.item != 0) {
            backpack_place(w, drone.item, 1);
            drone.item = 0;
        }
        SetStatus(drone, drone_status::has_error);
        e.enable_tag<ecs::drone_changed>();
        return;
    }
    f(w, e, drone, it->second);
}

static void GoHome(world& w, DroneEntity& e, ecs::drone& drone, const airport& info);

struct HubSearcher {
    struct Node {
        airport_berth berth;
        building* building;
    };
    std::vector<Node> hub_pickup;
    std::vector<Node> hub_place;
    std::vector<Node> chest_pickup;
    std::vector<Node> chest_place;
    static bool PickupSort(const HubSearcher::Node& a, const HubSearcher::Node& b) {
        return a.building->pickup_time < b.building->pickup_time;
    }
    static bool PlaceSort(const HubSearcher::Node& a, const HubSearcher::Node& b) {
        return a.building->place_time < b.building->place_time;
    }
};

static HubSearcher createHubSearcher(world& w, airport& info) {
    w.hub_time++;
    HubSearcher searcher;
    searcher.hub_pickup.reserve(info.hub.size());
    searcher.hub_place.reserve(info.hub.size());
    searcher.chest_pickup.reserve(info.chest_red.size());
    searcher.chest_place.reserve(info.chest_blue.size());
    for (auto& berth : info.hub) {
        if (auto building = w.buildings.find(getxy(berth.x, berth.y))) {
            searcher.hub_pickup.push_back({berth, building});
            searcher.hub_place.push_back({berth, building});
        }
    }
    for (auto& berth : info.chest_red) {
        if (auto building = w.buildings.find(getxy(berth.x, berth.y))) {
            searcher.chest_pickup.push_back({berth, building});
        }
    }
    for (auto& berth : info.chest_blue) {
        if (auto building = w.buildings.find(getxy(berth.x, berth.y))) {
            searcher.chest_place.push_back({berth, building});
        }
    }
    std::sort(std::begin(searcher.hub_pickup), std::end(searcher.hub_pickup), HubSearcher::PickupSort);
    std::sort(std::begin(searcher.hub_place), std::end(searcher.hub_place), HubSearcher::PlaceSort);
    std::sort(std::begin(searcher.chest_pickup), std::end(searcher.chest_pickup), HubSearcher::PickupSort);
    std::sort(std::begin(searcher.chest_place), std::end(searcher.chest_place), HubSearcher::PlaceSort);
    return searcher;
}

static void rebuild(world& w) {
    w.hub_time = 0;
    struct mapinfo {
        airport_berth berth;
        container::slot::slot_type type;
        bool operator==(const mapinfo& rhs) const {
            return berth == rhs.berth && type == rhs.type;
        }
    };
    std::map<uint16_t, flatmap<uint16_t, mapinfo>> globalmap;
    flatset<uint16_t> used_id;
    for (auto& v : ecs_api::select<ecs::airport>(w.ecs)) {
        auto& airport = v.get<ecs::airport>();
        used_id.insert(airport.id);
    }

    for (auto& v : ecs_api::select<ecs::chest, ecs::building>(w.ecs)) {
        auto& chest = v.get<ecs::chest>();
        auto& building = v.get<ecs::building>();
        uint16_t area = prototype::get<"area">(w, building.prototype);
        building_rect r(building, area);
        auto c = container::index::from(chest.chest);
        if (c == container::kInvalidIndex) {
            continue;
        }
        auto slice = chest::array_slice(w, c);
        for (uint8_t i = 0; i < slice.size(); ++i) {
            auto& chestslot = slice[i];
            auto item = chestslot.item;
            auto berth = airport_berth { building.x, building.y, i };
            auto& map = globalmap[item];
            r.each([&](uint8_t x, uint8_t y) {
                map.insert_or_assign(getxy(x, y), mapinfo {berth, chestslot.type});
            });
        }
    }

    flatmap<uint16_t, uint16_t> created_airport;
    std::map<uint16_t, airport> airports;
    uint16_t maxid = 1;
    auto create_hubid = [&]()->uint16_t {
        for (; maxid <= (std::numeric_limits<uint16_t>::max)(); ++maxid) {
            if (!airports.contains(maxid) && !used_id.contains(maxid)) {
                return maxid;
            }
        }
        return 0;
    };
    for (auto& v : ecs_api::select<ecs::airport, ecs::building, ecs::capacitance>(w.ecs)) {
        auto& airport = v.get<ecs::airport>();
        auto& building = v.get<ecs::building>();
        if (airport.id == 0) {
            airport.id = create_hubid();
            created_airport.insert_or_assign(getxy(building.x, building.y), airport.id);
        }
        auto homeBuilding = createBuildingCache(w, building, 0);
        struct airport info;
        info.prototype = building.prototype;
        info.width = homeBuilding.w;
        info.height = homeBuilding.h;
        info.homeBerth = airport_berth { building.x, building.y, 0 };
        info.capacitance = &v.get<ecs::capacitance>();
        if (airport.item == 0) {
            info.item = 0;
            airports.emplace(airport.id, info);
            continue;
        }
        auto& map = globalmap[airport.item];
        flatset<mapinfo> set;
        uint16_t area = prototype::get<"area">(w, building.prototype);
        uint16_t supply_area = prototype::get<"supply_area">(w, building.prototype);
        building_rect(building, area, supply_area).each([&](uint8_t x, uint8_t y) {
            if (auto pm = map.find(getxy(x, y))) {
                set.insert(*pm);
            }
        });
        for (auto h: set) {
            switch (h.type) {
            case container::slot::slot_type::transit:
                info.hub.emplace_back(h.berth);
                break;
            case container::slot::slot_type::supply:
                info.chest_red.emplace_back(h.berth);
                break;
            case container::slot::slot_type::demand:
                info.chest_blue.emplace_back(h.berth);
                break;
            default:
                assert(false);
                break;
            }
        }
        info.item = info.idle()? 0 : airport.item;
        airports.emplace(airport.id, std::move(info));
    }
    w.airports = std::move(airports);

    for (auto& e : ecs_api::select<ecs::drone>(w.ecs)) {
        auto& drone = e.get<ecs::drone>();
        auto status = (drone_status)drone.status;
        switch (status) {
        case drone_status::has_error:
            break;
        case drone_status::init:
            if (auto p = created_airport.find(drone.home)) {
                drone.home = *p;
                CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport const& info) {
                    drone.prev = std::bit_cast<airport_berth>(info.homeBerth);
                    if (info.item == 0) {
                        SetStatus(drone, drone_status::idle);
                        return;
                    }
                    SetStatus(drone, drone_status::at_home);
                });
            }
            else {
                SetStatus(drone, drone_status::has_error);
            }
            e.enable_tag<ecs::drone_changed>();
            break;
        case drone_status::idle:
            CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport const& info) {
                if (drone.prev != info.homeBerth) {
                    GoHome(w, e, drone, info);
                    return;
                }
                if (info.item != 0) {
                    SetStatus(drone, drone_status::at_home);
                }
            });
            break;
        case drone_status::at_home:
            CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport const& info) {
                if (drone.prev != info.homeBerth) {
                    SetStatus(drone, drone_status::idle);
                    GoHome(w, e, drone, info);
                    return;
                }
                if (info.item == 0) {
                    SetStatus(drone, drone_status::idle);
                }
            });
            break;
        case drone_status::go_home:
        case drone_status::go_mov2:
        case drone_status::empty_task:
            CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport const& info) {
                // nothing to do, just check home
            });
            break;
        case drone_status::go_mov1:
            CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport const& info) {
                auto mov1 = drone.next;
                auto mov2 = drone.mov2;
                if (auto slot = ChestGetSlot(w, mov1)) {
                    if (slot->item != info.item || slot->type == container::slot::slot_type::demand) {
                        if (auto findshot = ChestFindSlot(w, mov1, info.item)) {
                            mov1.slot = *findshot;
                            drone.next = std::bit_cast<airport_berth>(mov1);
                        }
                        else {
                            // undo mov2
                            if (auto mov2slot = ChestGetSlot(w, mov2)) {
                                if (slot->item == info.item && slot->type != container::slot::slot_type::supply) {
                                    assert(mov2slot->lock_space > 0);
                                    mov2slot->lock_space--;
                                }
                            }
                            SetStatus(drone, drone_status::empty_task);
                            return;
                        }
                    }
                }
                if (auto slot = ChestGetSlot(w, drone.mov2)) {
                    if (slot->item != info.item || slot->type == container::slot::slot_type::supply) {
                        if (auto findshot = ChestFindSlot(w, mov2, info.item)) {
                            mov2.slot = *findshot;
                            drone.mov2 = std::bit_cast<airport_berth>(mov2);
                        }
                        else {
                            // undo mov1
                            if (auto mov1slot = ChestGetSlot(w, mov1)) {
                                assert(mov1slot->lock_item > 0);
                                mov1slot->lock_item--;
                            }
                            SetStatus(drone, drone_status::empty_task);
                            return;
                        }
                    }
                }
            });
            break;
        default:
            std::unreachable();
        }
    }
}

static int lbuild(lua_State* L) {
    auto& w = getworld(L);
    if (!(w.dirty & kDirtyHub)) {
        return 0;
    }
    rebuild(w);
    return 0;
}

static void Arrival(world& w, DroneEntity& e, ecs::drone& drone);

static void Move(world& w, DroneEntity& e, ecs::drone& drone, const HubSearcher::Node& target) {
    drone.next = std::bit_cast<airport_berth>(target.berth);
    if (drone.prev == drone.next) {
        drone.maxprogress = drone.progress = 0;
        Arrival(w, e, drone);
        return;
    }
    auto source = drone.prev;
    auto sourceBuilding = w.buildings.find(getxy(source.x, source.y));
    if (!sourceBuilding) {
        static building dummy {0,0,0};
        sourceBuilding = &dummy;
    }
    float x1 = source.x + sourceBuilding->w / 2.f;
    float y1 = source.y + sourceBuilding->h / 2.f;
    float x2 = target.berth.x + target.building->w / 2.f;
    float y2 = target.berth.y + target.building->h / 2.f;
    float dx = x1-x2;
    float dy = y1-y2;
    float z = sqrt(dx*dx+dy*dy);
    auto speed = prototype::get<"speed">(w, drone.prototype);
    drone.maxprogress = drone.progress = uint16_t(z*1000/speed);
    e.enable_tag<ecs::drone_changed>();
}

static void DoTask(world& w, DroneEntity& e, ecs::drone& drone, const airport& info, const HubSearcher::Node& mov1, const HubSearcher::Node& mov2) {
    {
        //lock mov1
        auto chestslot = ChestGetSlot(w, mov1.berth);
        assert(chestslot);
        assert(chestslot->amount > chestslot->lock_item);
        chestslot->lock_item += 1;
    }
    {
        //lock mov2
        auto chestslot = ChestGetSlot(w, mov2.berth);
        assert(chestslot);
        assert(chestslot->limit > chestslot->amount + chestslot->lock_space);
        chestslot->lock_space += 1;
    }
    //update drone
    mov1.building->pickup_time = w.hub_time;
    mov2.building->place_time = w.hub_time;
    SetStatus(drone, drone_status::go_mov1);
    drone.mov2 = std::bit_cast<airport_berth>(mov2.berth);
    Move(w, e, drone, mov1);
}

static void DoTaskOnlyMov1(world& w, DroneEntity& e, ecs::drone& drone, const airport& info, const HubSearcher::Node& mov1) {
    {
        //lock mov1
        auto chestslot = ChestGetSlot(w, mov1.berth);
        assert(chestslot);
        assert(chestslot->amount > chestslot->lock_item);
        chestslot->lock_item += 1;
    }
    //update drone
    mov1.building->pickup_time = w.hub_time;
    AssertStatus(drone, drone_status::go_mov1);
    Move(w, e, drone, mov1);
}

static void DoTaskOnlyMov2(world& w, DroneEntity& e, ecs::drone& drone, const airport& info, const HubSearcher::Node& mov2) {
    {
        //lock mov2
        auto chestslot = ChestGetSlot(w, mov2.berth);
        assert(chestslot);
        assert(chestslot->limit > chestslot->amount + chestslot->lock_space);
        chestslot->lock_space += 1;
    }
    //update drone
    mov2.building->place_time = w.hub_time;
    AssertStatus(drone, drone_status::go_mov2);
    Move(w, e, drone, mov2);
}

static std::optional<HubSearcher::Node> FindChestRed(world& w, const HubSearcher& searcher) {
    for (auto const& v : searcher.chest_pickup) {
        auto& chestslot = chest::array_at(w, container::index::from(v.building->chest), v.berth.slot);
        if (chestslot.amount > chestslot.lock_item) {
            return v;
        }
    }
    return std::nullopt;
}

static std::optional<HubSearcher::Node> FindChestBlue(world& w, const HubSearcher& searcher) {
    for (auto const& v : searcher.chest_place) {
        auto& chestslot = chest::array_at(w, container::index::from(v.building->chest), v.berth.slot);
        if (chestslot.limit > chestslot.amount + chestslot.lock_space) {
            return v;
        }
    }
    return std::nullopt;
}

static std::optional<HubSearcher::Node> FindChestBlueForce(world& w, const HubSearcher& searcher) {
    for (auto const& v : searcher.chest_place) {
        return v;
    }
    return std::nullopt;
}

static std::tuple<std::optional<HubSearcher::Node>, std::optional<HubSearcher::Node>, bool> FindHub(world& w, const HubSearcher& searcher) {
    std::optional<HubSearcher::Node> max;
    uint16_t maxAmount = 0;
    for (auto const& v : searcher.hub_pickup) {
        auto& chestslot = chest::array_at(w, container::index::from(v.building->chest), v.berth.slot);
        auto amount = chestslot.amount - chestslot.lock_item;
        if ((!max || (amount > maxAmount)) && (amount > 0)) {
            max = v;
            maxAmount = amount;
        }
    }
    std::optional<HubSearcher::Node> min;
    uint16_t minAmount = 0;
    for (auto const& v : searcher.hub_place) {
        auto& chestslot = chest::array_at(w, container::index::from(v.building->chest), v.berth.slot);
        auto amount = chestslot.amount + chestslot.lock_space;
        if ((!min || (amount < minAmount)) && (chestslot.limit > amount)) {
            min = v;
            minAmount = amount;
        }
    }
    bool moveable = false;
    if (min) { 
        moveable = minAmount + 2 <= maxAmount;
    }
    return {min, max, moveable};
}

static std::optional<HubSearcher::Node> FindHubForce(world& w, const HubSearcher& searcher) {
    std::optional<HubSearcher::Node> min;
    uint16_t minAmount = 0;
    for (auto const& v : searcher.hub_place) {
        auto& chestslot = chest::array_at(w, container::index::from(v.building->chest), v.berth.slot);
        auto amount = chestslot.amount + chestslot.lock_space;
        if ((!min || (amount < minAmount))) {
            min = v;
            minAmount = amount;
        }
    }
    return min;
}

static void GoHome(world& w, DroneEntity& e, ecs::drone& drone, const airport& info) {
    assert((drone_status)drone.status != drone_status::at_home);
    SetStatus(drone, drone_status::go_home);
    building homeBuilding {0, 0, info.width, info.height};
    HubSearcher::Node node {
        info.homeBerth,
        &homeBuilding,
    };
    Move(w, e, drone, node);
}

static bool FindTask(world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
    auto consumer = consumer_context {
        *info.capacitance,
        prototype::get<"cost">(w, drone.prototype),
        0,
        prototype::get<"capacitance">(w, info.prototype),
    };
    if (!consumer.has_power()) {
        return false;
    }
    auto searcher = createHubSearcher(w, info);
    auto red = FindChestRed(w, searcher);
    auto blue = FindChestBlue(w, searcher);
    // red -> blue
    if (red && blue) {
        DoTask(w, e, drone, info, *red, *blue);
        consumer.cost_power();
        return true;
    }
    auto [min, max, moveable] = FindHub(w, searcher);
    // red -> hub
    if (red && min) {
        DoTask(w, e, drone, info, *red, *min);
        consumer.cost_power();
        return true;
    }
    // hub -> blue
    if (blue && max) {
        DoTask(w, e, drone, info, *max, *blue);
        consumer.cost_power();
        return true;
    }
    // hub -> hub
    if (moveable) {
        DoTask(w, e, drone, info, *max, *min);
        consumer.cost_power();
        return true;
    }
    return false;
}

static void FindTaskNotAtHome(world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
    if (info.item == 0) {
        GoHome(w, e, drone, info);
        return;
    }
    if (FindTask(w, e, drone, info)) {
        return;
    }
    GoHome(w, e, drone, info);
}

static bool FindTaskOnlyMov1(world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
    auto searcher = createHubSearcher(w, info);
    auto red = FindChestRed(w, searcher);
    if (red) {
        DoTaskOnlyMov1(w, e, drone, info, *red);
        return true;
    }
    auto [_1, max, _2] = FindHub(w, searcher);
    if (max) {
        if (drone.mov2 != max->berth) {
            DoTaskOnlyMov1(w, e, drone, info, *max);
            return true;
        }
    }
    return false;
}

static bool FindTaskOnlyMov2(world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
    auto searcher = createHubSearcher(w, info);
    {
        auto blue = FindChestBlue(w, searcher);
        if (blue) {
            DoTaskOnlyMov2(w, e, drone, info, *blue);
            return true;
        }
    }
    {
        auto [min, _1, _2] = FindHub(w, searcher);
        if (min) {
            DoTaskOnlyMov2(w, e, drone, info, *min);
            return true;
        }
    }
    {
        auto blue = FindChestBlueForce(w, searcher);
        if (blue) {
            DoTaskOnlyMov2(w, e, drone, info, *blue);
            return true;
        }
    }
    {
        auto min = FindHubForce(w, searcher);
        if (min) {
            DoTaskOnlyMov2(w, e, drone, info, *min);
            return true;
        }
    }
    return false;
}

static bool FindTaskOnlyMov2(world& w, DroneEntity& e, ecs::drone& drone, airport& info, airport_berth mov1) {
    auto searcher = createHubSearcher(w, info);
    {
        auto blue = FindChestBlue(w, searcher);
        if (blue) {
            DoTaskOnlyMov2(w, e, drone, info, *blue);
            return true;
        }
    }
    {
        auto [min, _1, _2] = FindHub(w, searcher);
        if (min) {
            if (mov1 != min->berth) {
                DoTaskOnlyMov2(w, e, drone, info, *min);
                return true;
            }
        }
    }
    {
        auto blue = FindChestBlueForce(w, searcher);
        if (blue) {
            DoTaskOnlyMov2(w, e, drone, info, *blue);
            return true;
        }
    }
    {
        auto min = FindHubForce(w, searcher);
        if (min) {
            if (mov1 != min->berth) {
                DoTaskOnlyMov2(w, e, drone, info, *min);
                return true;
            }
        }
    }
    return false;
}

static void UnlockMov2(world& w, ecs::drone& drone, airport const& info) {
    auto slot = ChestGetSlot(w, drone.mov2);
    drone.mov2 = airport_berth {0,0,0};
    if (slot && slot->item == drone.item) {
        if (slot->lock_space > 0) {
            slot->lock_space--;
        }
    }
}

static void Arrival(world& w, DroneEntity& e, ecs::drone& drone) {
    drone.prev = drone.next;
    switch ((drone_status)drone.status) {
    case drone_status::go_mov1: {
        CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
            assert(info.item != 0);
            auto slot = ChestGetSlot(w, drone.next);
            if (!slot || slot->item != info.item || slot->amount == 0) {
                if (slot && slot->item == info.item && slot->amount == 0 && slot->lock_item > 0) {
                    slot->lock_item--;
                }
                if (FindTaskOnlyMov1(w, e, drone, info)) {
                    return;
                }
                UnlockMov2(w, drone, info);
                GoHome(w, e, drone, info);
                return;
            }
            if (slot->lock_item > 0) {
                slot->lock_item--;
            }
            auto mov2Berth = drone.mov2;
            if (auto movBuilding = w.buildings.find(getxy(mov2Berth.x, mov2Berth.y))) {
                slot->amount--;
                drone.item = info.item;
                SetStatus(drone, drone_status::go_mov2);
                HubSearcher::Node node {
                    mov2Berth,
                    movBuilding,
                };
                Move(w, e, drone, node);
                drone.mov2 = airport_berth {0,0,0};
            }
            else {
                if (FindTaskOnlyMov2(w, e, drone, info, drone.next)) {
                    slot->amount--;
                    drone.item = info.item;
                    return;
                }
                UnlockMov2(w, drone, info);
                GoHome(w, e, drone, info);
            }
        });
        break;
    }
    case drone_status::go_mov2: {
        CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
            auto slot = ChestGetSlot(w, drone.next);
            if (!slot || slot->item != drone.item) {
                if (info.item != drone.item) {
                    backpack_place(w, drone.item, 1);
                    drone.item = 0;
                    GoHome(w, e, drone, info);
                    return;
                }
                if (FindTaskOnlyMov2(w, e, drone, info)) {
                    return;
                }
                backpack_place(w, drone.item, 1);
                drone.item = 0;
                GoHome(w, e, drone, info);
                return;
            }
            if (slot->lock_space > 0) {
                slot->lock_space--;
            }
            slot->amount++;
            drone.item = 0;
            FindTaskNotAtHome(w, e, drone, info);
        });
        break;
    }
    case drone_status::go_home:
        drone.next = airport_berth {0,0,0};
        drone.maxprogress = 0;
        CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
            if (drone.prev != info.homeBerth) {
                GoHome(w, e, drone, info);
                return;
            }
            if (info.item == 0) {
                SetStatus(drone, drone_status::idle);
                return;
            }
            if (FindTask(w, e, drone, info)) {
                return;
            }
            SetStatus(drone, drone_status::at_home);
        });
        break;
    case drone_status::empty_task:
        CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
            FindTaskNotAtHome(w, e, drone, info);
        });
        break;
    default:
        std::unreachable();
    }
}

static void Update(world& w, DroneEntity& e, ecs::drone& drone) {
    if (drone.progress > 0) {
        drone.progress--;
    }
    if (drone.progress == 0) {
        Arrival(w, e, drone);
    }
}

static int
lupdate(lua_State *L) {
    auto& w = getworld(L);
    for (auto& e : ecs_api::select<ecs::drone>(w.ecs)) {
        auto& drone = e.get<ecs::drone>();
        switch ((drone_status)drone.status) {
        case drone_status::at_home:
            CheckHasHome(w, e, drone, +[](world& w, DroneEntity& e, ecs::drone& drone, airport& info) {
                if (info.item == 0) {
                    SetStatus(drone, drone_status::idle);
                    return;
                }
                FindTask(w, e, drone, info);
            });
            break;
        case drone_status::go_mov1:
        case drone_status::go_mov2:
        case drone_status::go_home:
        case drone_status::empty_task:
            Update(w, e, drone);
            break;
        case drone_status::init:
        case drone_status::idle:
        case drone_status::has_error:
            break;
        default:
            std::unreachable();
        }
    }
    return 0;
}

extern "C" int
luaopen_vaststars_drone_system(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "build", lbuild },
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
