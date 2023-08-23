#include <string>
#include "core/world.h"
#include "core/saveload.h"
#include "roadnet/network.h"
#include "util/queue.h"
#include <unordered_map>
#include <concepts>

extern "C" {
    #include "core/fluidflow.h"
}

namespace lua_world {
    template <typename T>
    T file_readv(FILE* f) {
        T v;
        file_read(f, v);
        return v;
    }

    template<typename T>
    concept QueueType = std::same_as<T, queue<typename T::value_type, T::chunk_size>>;

    template <QueueType T>
    void file_write(FILE* f, const T& t) {
        file_write(f, t.size());
        for (auto const& e : t) {
            file_write(f, e);
        }
    }
    template <QueueType T>
    void file_read(FILE* f, T& t) {
        //TODO: performance optimization
        t.clear();
        size_t n = file_readv<size_t>(f);
        for (size_t i = 0; i < n; ++i) {
            auto v = file_readv<typename T::value_type>(f);
            t.push(v);
        }
    }

    template<template<typename...> class Template, typename Class>
    struct is_instantiation : std::false_type {};
    template<template<typename...> class Template, typename... Args>
    struct is_instantiation<Template, Template<Args...>> : std::true_type {};
    template<typename Class, template<typename...> class Template>
    concept is_instantiation_of = is_instantiation<Template, Class>::value;

    template<typename T>
    concept map_type =
    is_instantiation_of<T, std::map> || is_instantiation_of<T, std::unordered_map>;

    template <typename First, typename Second>
    void file_write_pair(FILE* f, const std::pair<First, Second>& t) {
        file_write(f, t.first);
        file_write(f, t.second);
    }
    template <typename First, typename Second>
    void file_read_pair(FILE* f, std::pair<First, Second>& t) {
        file_read(f, const_cast<std::add_lvalue_reference_t<std::remove_const_t<First>>>(t.first));
        file_read(f, t.second);
    }
    template <typename T>
        requires (is_instantiation_of<T, std::map>)
    void file_write(FILE* f, const T& t) {
        file_write<size_t>(f, t.size());
        for (auto const& kv : t) {
            file_write_pair(f, kv);
        }
    }
    template <typename T>
        requires (is_instantiation_of<T, std::map>)
    void file_read(FILE* f, T& t) {
        t.clear();
        size_t n = file_readv<size_t>(f);
        for (size_t i = 1; i <= n; ++i) {
            typename T::value_type kv;
            file_read_pair(f, kv);
            t.emplace(std::move(kv));
        }
    }

    template <typename T>
        requires (is_instantiation_of<T, flatmap> || is_instantiation_of<T, flatset>)
    void file_write(FILE* f, const T& t) {
        auto const& data = t.toraw();
        file_write(f, data.h);
        if (data.h.mask != 0) {
            file_write(f, data.buckets, data.h.mask + 1);
        }
    }
    template <typename T>
        requires (is_instantiation_of<T, flatmap> || is_instantiation_of<T, flatset>)
    void file_read(FILE* f, T& t) {
        auto& data = t.toraw();
        if (data.h.mask != 0) {
            std::free(data.buckets);
        }
        file_read(f, data.h);
        if (data.h.mask == 0) {
            data.buckets = reinterpret_cast<decltype(data.buckets)>(&data.h.mask);
        }
        else {
            data.buckets = static_cast<decltype(data.buckets)>(std::malloc(sizeof(data.buckets[0]) * (data.h.mask + 1)));
            if (!data.buckets) {
                throw std::bad_alloc {};
            }
            file_read(f, data.buckets, data.h.mask + 1);
        }
    }

    template <typename T>
        requires (is_instantiation_of<T, roadnet::dynarray>)
    static void file_write(FILE* f, const T& t) {
        file_write(f, t.size());
        file_write(f, t.begin(), t.size());
    }
    template <typename T>
        requires (is_instantiation_of<T, roadnet::dynarray>)
    static void file_read(FILE* f, T& t) {
        size_t n = file_readv<size_t>(f);
        t.reset(n);
        file_read(f, t.begin(), t.size());
    }

    template <typename T>
        requires (is_instantiation_of<T, std::list>)
    static void file_write(FILE* f, const T& t) {
        file_write(f, t.size());
        for (auto const& v : t) {
            file_write(f, v);
        }
    }
    template <typename T>
        requires (is_instantiation_of<T, std::list>)
    static void file_read(FILE* f, T& t) {
        size_t n = file_readv<size_t>(f);
        t.resize(n);
        for (auto& v : t) {
            file_read(f, v);
        }
    }

    template <typename T>
        requires (is_instantiation_of<T, std::vector>)
    static void file_write(FILE* f, const T& t) {
        file_write(f, t.size());
        file_write(f, t.data(), t.size());
    }
    template <typename T>
        requires (is_instantiation_of<T, std::vector>)
    static void file_read(FILE* f, T& t) {
        size_t n = file_readv<size_t>(f);
        t.resize(n);
        file_read(f, t.data(), t.size());
    }

    void file_write(FILE* f, const statistics::frame& frame) {
        file_write(f, frame.production);
        file_write(f, frame.consumption);
        file_write(f, frame.generate_power);
        file_write(f, frame.consume_power);
    }

    void file_read(FILE* f, statistics::frame& frame) {
        file_read(f, frame.production);
        file_read(f, frame.consumption);
        file_read(f, frame.generate_power);
        file_read(f, frame.consume_power);
    }

    static void backup_scope(lua_State* L, FILE* f, const char* name, std::function<void()> func) {
        lua_Integer head = (lua_Integer)ftell(f);
        func();
        lua_Integer tail = (lua_Integer)ftell(f);
        lua_pushstring(L, name);
        lua_createtable(L, 2, 0);
        lua_pushinteger(L, head);
        lua_rawseti(L, -2, 1);
        lua_pushinteger(L, tail);
        lua_rawseti(L, -2, 2);
        lua_rawset(L, -3);
    }

    static bool restore_scope(lua_State* L, FILE* f, const char* name, std::function<void()> func, std::function<void()> errfunc) {
        lua_pushstring(L, name);
        if (lua_rawget(L, -2) != LUA_TTABLE) {
            lua_pop(L, 1);
            printf("restore `%s` failed", name);
            errfunc();
            return false;
        }
        lua_rawgeti(L, -1, 1);
        lua_Integer head = luaL_checkinteger(L, -1); lua_pop(L, 1);
        lua_rawgeti(L, -1, 2);
        lua_Integer tail = luaL_checkinteger(L, -1); lua_pop(L, 1);
        fseek(f, (long)head, SEEK_SET);
        func();
        if (ftell(f) != (long)tail) {
            lua_pop(L, 1);
            printf("restore `%s` failed", name);
            errfunc();
            return false;
        }
        lua_pop(L, 1);
        return true;
    }

    int backup_world(lua_State* L) {
        auto& w = getworld(L);
        FILE* f = createfile(L, 2, filemode::write);

        lua_newtable(L);

        backup_scope(L, f, "time", [&](){
            file_write(f, w.time);
        });

        backup_scope(L, f, "stat", [&](){
            file_write(f, w.stat._total);
            for (auto& dataset : w.stat._dataset) {
                file_write(f, dataset.pos);
                for (auto& frame : dataset.data) {
                    file_write(f, frame);
                }
            }
        });

        backup_scope(L, f, "techtree", [&](){
            file_write(f, w.techtree.queue);
            file_write(f, w.techtree.researched);
            file_write(f, w.techtree.progress);
        });

        backup_scope(L, f, "container", [&](){
            file_write(f, w.container.pages.size());
            for (auto const& page : w.container.pages) {
                file_write(f, page->slots);
            }
            file_write(f, w.container.freelist.size());
            for (auto const& lst : w.container.freelist) {
                file_write(f, lst.size());
                for (auto const& node : lst) {
                    file_write(f, node);
                }
            }
            file_write(f, w.container.top);
        });

        backup_scope(L, f, "roadnet", [&](){
            auto& rw = w.rw;
            file_write(f, rw.crossAry);
            file_write(f, rw.straightAry);
            file_write(f, rw.straightLorry);
            file_write(f, rw.straightCoord);
        });

        backup_scope(L, f, "fluidflow", [&](){
            file_write(f, w.fluidflows.size());
            fluid_state state;
            for (auto& [fluid, flow] : w.fluidflows) {
                file_write(f, fluid);
                file_write(f, flow.size());
                for (uint16_t idx = 0;; ++idx) {
                    if (!flow.index(idx, state)) {
                        break;
                    }
                    file_write(f, state);
                }
                file_write(f, flow.maxid);
                file_write(f, flow.freelist);
            }
        });

        fclose(f);
        return 1;
    }

    int restore_world(lua_State *L) {
        auto& w = getworld(L);
        FILE* f = createfile(L, 2, filemode::read);
        luaL_checktype(L, 3, LUA_TTABLE);
        lua_settop(L, 3);

        w.fluidflows.clear();
    
        restore_scope(L, f, "time", [&](){
            file_read(f, w.time);
        }, [&](){
            w.time = 0;
        });

        restore_scope(L, f, "stat", [&](){
            file_read(f, w.stat._total);
            for (auto& dataset : w.stat._dataset) {
                file_read(f, dataset.pos);
                for (auto& frame : dataset.data) {
                    file_read(f, frame);
                }
            }
        }, [&](){
            w.stat._total.reset();
        });

        restore_scope(L, f, "techtree", [&](){
            file_read(f, w.techtree.queue);
            file_read(f, w.techtree.researched);
            file_read(f, w.techtree.progress);
        }, [&](){
            w.techtree.queue.clear();
            w.techtree.researched.clear();
            w.techtree.progress.clear();
        });

        restore_scope(L, f, "container", [&](){
            w.container.clear();
            auto page_n = file_readv<size_t>(f);
            w.container.pages.reserve(page_n);
            for (size_t i = 0; i < page_n; ++i) {
                auto page = std::make_unique<container::page>();
                file_read(f, page->slots);
                w.container.pages.emplace_back(std::move(page));
            }
            auto freelist_n = file_readv<size_t>(f);
            w.container.freelist.reserve(freelist_n);
            for (size_t i = 0; i < freelist_n; ++i) {
                std::list<container::chunk> lst;
                auto lst_n = file_readv<size_t>(f);
                for (size_t j = 0; j < lst_n; ++j) {
                    lst.push_back(file_readv<container::chunk>(f));
                }
                w.container.freelist.emplace_back(std::move(lst));
            }
            file_read(f, w.container.top);
        }, [&](){
            w.container.clear();
            w.container.init();
        });

        restore_scope(L, f, "roadnet", [&](){
            auto& rw = w.rw;
            file_read(f, rw.crossAry);
            file_read(f, rw.straightAry);
            file_read(f, rw.straightLorry);
            file_read(f, rw.straightCoord);
            rw.routeCached.clear();
        }, [&](){
            //TODO
        });

        restore_scope(L, f, "fluidflow", [&](){
            w.fluidflows.clear();
            auto n = file_readv<size_t>(f);
            for (size_t i = 0; i < n; ++i) {
                auto fluid = file_readv<uint16_t>(f);
                auto size = file_readv<uint16_t>(f);
                auto& flow = w.fluidflows[fluid];
                for (auto j = 0; j < size; ++j) {
                    auto state = file_readv<fluid_state>(f);
                    flow.build(state.id, &state.box);
                    if (state.blocking) {
                        flow.block(state.id);
                    }
                }
                file_read(f, flow.maxid);
                file_read(f, flow.freelist);
            }
        }, [&](){
            w.fluidflows.clear();
        });

        fclose(f);
        return 0;
    }
}
