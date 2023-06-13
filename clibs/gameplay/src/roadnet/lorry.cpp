#include "roadnet/lorry.h"
#include "roadnet/network.h"
#include "roadnet/route.h"
#include "core/world.h"
#include "util/prototype.h"
#include <bee/nonstd/unreachable.h>

namespace roadnet {
    void lorry::init(world& w, uint16_t classid) {
        auto speed = prototype::get<"speed">(w, classid);
        this->classid = classid;
        this->item_classid = 0;
        this->item_amount = 0;
        this->status = status::normal;
        this->time = 1000 / speed;
    }
    void lorry::entry(roadtype type) {
        switch (type) {
        case roadtype::cross:
            maxprogress = progress = time;
            break;
        case roadtype::straight:
            maxprogress = progress = time;
            break;
        default:
            std::unreachable();
        }
    }
    void lorry::go(straightid ending, uint16_t item_classid, uint16_t item_amount) {
        this->status = status::normal;
        this->ending = ending;
        this->item_classid = item_classid;
        this->item_amount = item_amount;
    }
    void lorry::reset(world& w) {
        classid = 0;
    }
    bool lorry::invaild() const noexcept {
        return classid == 0;
    }
    void lorry::update(network& w, uint64_t ti) {
        if (progress != 0) {
            --progress;
        }
    }
    bool lorry::next_direction(network& w, straightid C, direction& dir) {
        if (status != status::normal) {
            return false;
        }
        route_value val;
        if (route(w, C, ending, val)) {
            dir = (direction)val.dir;
            return true;
        }
        status = status::error;
        return false;
    }
    bool lorry::ready() const noexcept {
        if (status != status::normal) {
            return false;
        }
        return progress == 0;
    }
}
