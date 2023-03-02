#pragma once

#include <list>
#include <memory>
#include <optional>
#include <span>
#include <vector>
#include <assert.h>
#include <stdint.h>
#include <util/component.h>
extern "C" {
#include "util/prototype.h"
}

struct world;
struct lua_State;

struct recipe_items {
    uint16_t n;
    uint16_t unused = 0;
    struct {
        uint16_t item;
        uint16_t amount;
    } items[1];
};

class container {
public:
    using size_type = uint16_t;
    static constexpr size_type kPageSize = 256;
    struct index {
        uint8_t page;
        uint8_t slot;
        index operator+(uint8_t v) const {
            assert((size_t)slot + v < kPageSize);
            return {page, (uint8_t)(slot + v)};
        }
        index& operator++() {
            assert((size_t)slot + 1 < kPageSize);
            slot++;
            return *this;
        }
        bool operator==(const index& rhs) const {
            return page == rhs.page && slot == rhs.slot;
        }
        operator const uint16_t&() const {
            return *(uint16_t*)this;
        }
        static index from(uint16_t v) {
            return *(index*)&v;
        }
    };
    struct slot {
        enum class slot_type: uint8_t {
            red = 0,
            blue,
            green,
            none,
        };
        slot_type type = slot_type::red;
        uint8_t   eof;
        uint16_t  item = 0;
        uint16_t  amount = 0;
        uint16_t  limit = 0;
        uint16_t  lock_item = 0;
        uint16_t  lock_space = 0;
    };
    struct page {
        slot slots[kPageSize];
    };
    struct chunk {
    public:
        chunk() {} // for saveload
        chunk(uint8_t slot, size_type length)
            : slot(slot)
        {
            assert(1 <= length && length <= 256);
            this->length = (uint8_t)(length-1);
        }
        bool operator<(const chunk& rhs) const {
            return slot < rhs.slot;
        }
        size_type size() const {
            return length + 1;
        }
        void add_size(const chunk& rhs) {
            assert(length + rhs.size() < kPageSize);
            length += rhs.size();
        }
        void sub_size(size_type size) {
            assert(size < length);
            length -= size;
        }
        uint8_t slot;
    private:
        uint8_t length;
    };
    static constexpr index kInvalidIndex = {0,0};
public:
    container() {
        init();
    }
    index create_chest(size_type size) {
        assert(size <= kPageSize);
        if (size == 0) {
            return kInvalidIndex;
        }
        return alloc_array(size);
    }
    void free_array(index idx, size_type size) {
        free_chunk(idx.page, {idx.slot, size});
    }
    slot& at(index idx) {
        assert(idx.page < pages.size());
        return pages[idx.page]->slots[idx.slot];
    }
    std::span<slot> slice(index idx, size_type size) {
        assert(idx.page < pages.size());
        return {pages[idx.page]->slots + idx.slot, size};
    }
    void init() {
        pages.emplace_back(new page);
        top = 0;
        alloc_array_(1);
    }
    void clear() {
        pages.clear();
        freelist.clear();
    }
private:
    void init_array(index start, size_type size) {
        uint8_t last = (uint8_t)(size-1);
        for (size_t i = 0; i < size; ++i) {
            pages[start.page]->slots[start.slot+i].eof = last;

        }
    }
    index alloc_array_(size_type size) {
        assert(size <= kPageSize);
        uint8_t page;
        uint8_t slot;
        if (size + top <= kPageSize) {
            page = (uint8_t)(pages.size()-1);
            slot = top;
            top += size;
        }
        else if (size == kPageSize) {
            free_page();
            alloc_page();
            page = (uint8_t)(pages.size()-1);
            slot = 0;
            alloc_page();
        }
        else {
            free_page();
            alloc_page();
            page = (uint8_t)(pages.size()-1);
            slot = 0;
            top = (uint8_t)size;
        }
        index start {page, slot};
        init_array(start, size);
        return start;
    }
    index alloc_array(size_type size) {
        for (size_t i = 0; i < freelist.size(); ++i) {
            auto& lst = freelist[i];
            for (auto it = lst.begin(); it != lst.end(); ++it) {
                if (it->size() >= size) {
                    index start {(uint8_t)i, it->slot};
                    if (it->size() == size) {
                        lst.erase(it);
                    }
                    else {
                        it->slot += size;
                        it->sub_size(size);
                    }
                    init_array(start, size);
                    return start;
                }
            }
        }
        return alloc_array_(size);
    }
    void free_page() {
        free_chunk((uint8_t)(pages.size()-1), {top, size_type(kPageSize - top)});
    }
    void alloc_page() {
        assert(pages.size() <= 255);
        pages.emplace_back(new page);
        top = 0;
    }
    void free_chunk(uint8_t page, chunk c) {
        if (page+1 > freelist.size()) {
            freelist.resize(page+1);
        }
        auto& lst = freelist[page];
        for (auto it = lst.begin(); it != lst.end(); ++it) {
            if (c < *it) {
                auto p = lst.insert(it, c);
                while (true) {
                    auto next = ++p;
                    if (p->slot + p->size() != next->slot) {
                        assert(p->slot + p->size() < next->slot);
                        break;
                    }
                    p->add_size(*next);
                    lst.erase(next);
                }
                while (true) {
                    auto prev = --p;
                    if (prev->slot + prev->size() != p->slot) {
                        assert(prev->slot + prev->size() < p->slot);
                        break;
                    }
                    p->slot = prev->slot;
                    p->add_size(*prev);
                    lst.erase(prev);
                }
                break;
            }
        }
    }
public: //TODO for saveload
    std::vector<std::unique_ptr<page>> pages;
    std::vector<std::list<chunk>> freelist;
    uint8_t top;
};

namespace chest {

    container::index create(world& w, container::slot* data, container::size_type size);
    void destroy(world& w, container::index c);
    
    container::slot& array_at(world& w, container::index c, uint8_t offset);
    std::span<container::slot> array_slice(world& w, container::index c, uint8_t offset, uint16_t size);
    std::span<container::slot> array_slice(world& w, container::index c);

    // for fluidflow
    uint16_t get_fluid(world& w, container::index c, uint8_t offset);
    void     set_fluid(world& w, container::index c, uint8_t offset, uint16_t value);

    // for chest
    bool     pickup(world& w, container::index c, prototype_context& recipe);
    bool     place(world& w, container::index c, prototype_context& recipe);

    // for laboratory
    bool     pickup(world& w, container::index c, const recipe_items* r, uint8_t offset = 0);
    bool     place(world& w, container::index c, const recipe_items* r, uint8_t offset = 0);
    bool     recover(world& w, container::index c, const recipe_items* r);
    void     limit(world& w, container::index c, const uint16_t* r, uint16_t n);
    uint16_t size(world& w, container::index c);

    // for lua api
    container::slot& getslot(world& w, container::index c, uint8_t offset);

    // for trading
    bool pickup_force(world& w, container::index c, uint16_t item, uint16_t amount, bool unlock);
    bool place_force(world& w, container::index c, uint16_t item, uint16_t amount, bool unlock);
}
