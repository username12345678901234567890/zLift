#pragma once
#include <level_zero/ze_api.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <atomic>
#include <new>
#include <string>
#include <vector>
#ifndef SLIFTER_ARG_BASE
#define SLIFTER_ARG_BASE 0x210
#endif
struct Dim3 {
    unsigned x = 1, y = 1, z = 1;
};
namespace zlift {
inline void die(const char *what, uint32_t code) {
    std::fprintf(stderr, "FAIL: %s -> 0x%x\n", what, code);
    std::exit(1);
}
#define ZLIFT_ZE(call)                                                         \
    do {                                                                       \
        ze_result_t _r = (call);                                               \
        if (_r != ZE_RESULT_SUCCESS)                                           \
            ::zlift::die(#call, (unsigned)_r);                                 \
    } while (0)
struct Runtime {
    ze_driver_handle_t driver = nullptr;
    ze_device_handle_t device = nullptr;
    ze_context_handle_t context = nullptr;
    ze_command_list_handle_t queue = nullptr;
    ze_module_handle_t module = nullptr;
    bool ready = false;
    pid_t pid = 0;
};
inline Runtime &runtime() {
    static Runtime rt;
    return rt;
}
inline std::atomic<int> in_allocator{0};
struct AllocatorGuard {
    AllocatorGuard() { in_allocator.fetch_add(1, std::memory_order_acquire); }
    ~AllocatorGuard() { in_allocator.fetch_sub(1, std::memory_order_release); }
};
inline void ensure_device() {
    Runtime &rt = runtime();
    if (rt.ready && rt.pid == getpid())
        return;
    if (rt.ready) {
        std::fprintf(stderr,
                     "FAIL: this process inherited an initialised GPU context "
                     "across fork(); Level Zero cannot be used in the child\n");
        std::fflush(stderr);
        std::_Exit(70);
    }
    AllocatorGuard guard;
    ZLIFT_ZE(zeInit(0));
    uint32_t ndrv = 0;
    ZLIFT_ZE(zeDriverGet(&ndrv, nullptr));
    std::vector<ze_driver_handle_t> drivers(ndrv);
    ZLIFT_ZE(zeDriverGet(&ndrv, drivers.data()));
    for (auto d : drivers) {
        uint32_t ndev = 0;
        if (zeDeviceGet(d, &ndev, nullptr) != ZE_RESULT_SUCCESS)
            continue;
        std::vector<ze_device_handle_t> devs(ndev);
        if (zeDeviceGet(d, &ndev, devs.data()) != ZE_RESULT_SUCCESS)
            continue;
        for (auto dev : devs) {
            ze_device_properties_t p = {ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES};
            if (zeDeviceGetProperties(dev, &p) == ZE_RESULT_SUCCESS &&
                p.type == ZE_DEVICE_TYPE_GPU) {
                rt.driver = d;
                rt.device = dev;
                break;
            }
        }
        if (rt.device)
            break;
    }
    if (!rt.device)
        die("no GPU device", 0);
    rt.pid = getpid();
    ze_context_desc_t cdesc = {ZE_STRUCTURE_TYPE_CONTEXT_DESC};
    ZLIFT_ZE(zeContextCreate(rt.driver, &cdesc, &rt.context));
    ze_command_queue_desc_t qdesc = {ZE_STRUCTURE_TYPE_COMMAND_QUEUE_DESC};
    qdesc.mode = ZE_COMMAND_QUEUE_MODE_SYNCHRONOUS;
    ZLIFT_ZE(zeCommandListCreateImmediate(rt.context, rt.device, &qdesc, &rt.queue));
    rt.ready = true;
}
inline bool usm_enabled = false;
inline bool shutting_down = false;
inline void **usm_slots = nullptr;
inline std::size_t usm_cap = 0;
inline std::size_t usm_count = 0;
inline std::size_t usm_tombstones = 0;
inline std::size_t usm_hash(void *p) {
    return (reinterpret_cast<std::uintptr_t>(p) >> 6) * 11400714819323198485ull;
}
inline void *const USM_TOMBSTONE = reinterpret_cast<void *>(1);
inline void usm_insert(void **slots, std::size_t cap, void *p) {
    std::size_t i = usm_hash(p) & (cap - 1);
    while (slots[i] && slots[i] != USM_TOMBSTONE)
        i = (i + 1) & (cap - 1);
    slots[i] = p;
}
inline void usm_track(void *p) {
    if ((usm_count + usm_tombstones + 1) * 2 >= usm_cap) {
        std::size_t cap = usm_cap ? usm_cap * 2 : 256;
        while (cap < (usm_count + 1) * 4)
            cap *= 2;
        void **slots = static_cast<void **>(std::calloc(cap, sizeof(void *)));
        for (std::size_t i = 0; i < usm_cap; i++)
            if (usm_slots[i] && usm_slots[i] != USM_TOMBSTONE)
                usm_insert(slots, cap, usm_slots[i]);
        std::free(usm_slots);
        usm_slots = slots;
        usm_cap = cap;
        usm_tombstones = 0;
    }
    usm_insert(usm_slots, usm_cap, p);
    usm_count++;
}
inline bool usm_untrack(void *p) {
    if (!usm_cap)
        return false;
    std::size_t i = usm_hash(p) & (usm_cap - 1);
    for (std::size_t probes = 0; probes < usm_cap; probes++) {
        void *slot = usm_slots[i];
        if (!slot)
            return false;
        if (slot == p) {
            usm_slots[i] = USM_TOMBSTONE;
            usm_count--;
            usm_tombstones++;
            return true;
        }
        i = (i + 1) & (usm_cap - 1);
    }
    return false;
}
inline void *usm_alloc(std::size_t bytes) {
    AllocatorGuard guard;
    ensure_device();
    ze_device_mem_alloc_desc_t ddesc = {ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
    ze_host_mem_alloc_desc_t hdesc = {ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
    void *p = nullptr;
    ZLIFT_ZE(zeMemAllocShared(runtime().context, &ddesc, &hdesc,
                              bytes ? bytes : 1, 64, runtime().device, &p));
    usm_track(p);
    return p;
}
inline void usm_free(void *p) {
    if (!p)
        return;
    if (shutting_down || !usm_untrack(p)) {
        if (!shutting_down)
            std::free(p);
        return;
    }
    AllocatorGuard guard;
    zeMemFree(runtime().context, p);
}
inline void load_module() {
    ensure_device();
    Runtime &rt = runtime();
    if (rt.module)
        return;
    AllocatorGuard guard;
    const char *path = std::getenv("ZLIFT_MODULE");
    if (!path)
        die("ZLIFT_MODULE unset", 0);
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        die(path, 0);
    std::fseek(f, 0, SEEK_END);
    long n = std::ftell(f);
    std::fseek(f, 0, SEEK_SET);
    std::vector<uint8_t> spv(n);
    if (std::fread(spv.data(), 1, n, f) != (size_t)n)
        die("short read", 0);
    std::fclose(f);
    ze_module_desc_t mdesc = {ZE_STRUCTURE_TYPE_MODULE_DESC};
    mdesc.format = ZE_MODULE_FORMAT_IL_SPIRV;
    mdesc.inputSize = spv.size();
    mdesc.pInputModule = spv.data();
    const char *flags = std::getenv("ZLIFT_BUILD_FLAGS");
    mdesc.pBuildFlags =
        flags ? flags : "-cl-fp32-correctly-rounded-divide-sqrt -ze-fp64-gen-emu";
    ze_module_build_log_handle_t log = nullptr;
    ze_result_t r =
        zeModuleCreate(rt.context, rt.device, &mdesc, &rt.module, &log);
    if (log) {
        size_t len = 0;
        zeModuleBuildLogGetString(log, &len, nullptr);
        if (len > 1) {
            std::vector<char> txt(len);
            zeModuleBuildLogGetString(log, &len, txt.data());
            std::fprintf(stderr, "%s\n", txt.data());
        }
        zeModuleBuildLogDestroy(log);
    }
    if (r != ZE_RESULT_SUCCESS)
        die("zeModuleCreate", r);
}
struct DeviceGlobal {
    unsigned slot;
    unsigned size;
    std::string name;
};
struct ArgSlot {
    unsigned offset;
    unsigned size;
    bool byval = false;
};
inline unsigned read_layout_field(const char *key, const char *field) {
    const char *path = std::getenv("ZLIFT_ARGS");
    if (!path)
        return 0;
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        return 0;
    std::string text;
    char buf[4096];
    size_t got;
    while ((got = std::fread(buf, 1, sizeof buf, f)) > 0)
        text.append(buf, got);
    std::fclose(f);
    size_t at = text.find(key);
    if (at == std::string::npos)
        return 0;
    size_t k = text.find(field, at);
    if (k == std::string::npos)
        return 0;
    return (unsigned)std::strtoul(text.c_str() + text.find(':', k) + 1,
                                  nullptr, 10);
}
inline void read_const_mem_layout(unsigned *banks, unsigned *stride) {
    *banks = *stride = 0;
    const char *path = std::getenv("ZLIFT_ARGS");
    if (!path)
        return;
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        return;
    std::string text;
    char buf[4096];
    size_t got;
    while ((got = std::fread(buf, 1, sizeof buf, f)) > 0)
        text.append(buf, got);
    std::fclose(f);
    size_t at = text.find("\"__const_mem__\"");
    if (at == std::string::npos)
        return;
    size_t b = text.find("\"banks\"", at), st = text.find("\"stride\"", at);
    if (b == std::string::npos || st == std::string::npos)
        return;
    *banks = (unsigned)std::strtoul(text.c_str() + text.find(':', b) + 1, nullptr, 10);
    *stride = (unsigned)std::strtoul(text.c_str() + text.find(':', st) + 1, nullptr, 10);
}
inline std::vector<ArgSlot> read_arg_layout(const std::string &kernel) {
    const char *path = std::getenv("ZLIFT_ARGS");
    std::vector<ArgSlot> slots;
    if (!path)
        return slots;
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        return slots;
    std::string text;
    char buf[4096];
    size_t got;
    while ((got = std::fread(buf, 1, sizeof buf, f)) > 0)
        text.append(buf, got);
    std::fclose(f);
    std::string key = "\"" + kernel + "\"";
    size_t at = text.find(key);
    if (at == std::string::npos)
        return slots;
    size_t end = text.find("]", at);
    std::string body = text.substr(at, end == std::string::npos ? end : end - at);
    size_t pos = 0;
    while (true) {
        size_t o = body.find("\"offset\"", pos);
        if (o == std::string::npos)
            break;
        size_t s = body.find("\"size\"", o);
        if (s == std::string::npos)
            break;
        size_t next = body.find("\"offset\"", s);
        size_t bv = body.find("\"byval\"", s);
        slots.push_back({(unsigned)std::strtoul(body.c_str() + body.find(':', o) + 1,
                                                nullptr, 10),
                         (unsigned)std::strtoul(body.c_str() + body.find(':', s) + 1,
                                                nullptr, 10),
                         bv != std::string::npos && (next == std::string::npos
                                                     || bv < next)});
        pos = s;
    }
    return slots;
}
inline std::vector<DeviceGlobal> read_device_globals() {
    std::vector<DeviceGlobal> out;
    const char *path = std::getenv("ZLIFT_ARGS");
    if (!path)
        return out;
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        return out;
    std::string text;
    char buf[4096];
    size_t got;
    while ((got = std::fread(buf, 1, sizeof buf, f)) > 0)
        text.append(buf, got);
    std::fclose(f);
    size_t at = text.find("\"__globals__\"");
    if (at == std::string::npos)
        return out;
    size_t pos = at;
    while (true) {
        size_t sl = text.find("\"slot\"", pos);
        if (sl == std::string::npos)
            break;
        size_t sz = text.find("\"size\"", sl);
        if (sz == std::string::npos)
            break;
        std::string name;
        size_t nm = text.rfind("\"name\"", sl);
        if (nm != std::string::npos && nm > at) {
            size_t q1 = text.find('"', text.find(':', nm) + 1);
            size_t q2 = q1 == std::string::npos ? q1 : text.find('"', q1 + 1);
            if (q2 != std::string::npos)
                name = text.substr(q1 + 1, q2 - q1 - 1);
        }
        out.push_back({(unsigned)std::strtoul(text.c_str() + text.find(':', sl) + 1,
                                              nullptr, 10),
                       (unsigned)std::strtoul(text.c_str() + text.find(':', sz) + 1,
                                              nullptr, 10),
                       name});
        pos = sz + 1;
    }
    return out;
}
} 
static inline float h2f_bits(uint16_t h)
{
    uint32_t sign = (uint32_t)(h & 0x8000) << 16;
    uint32_t exp  = (h >> 10) & 0x1f;
    uint32_t man  = h & 0x3ff;
    uint32_t out;
    if (exp == 0) {
        if (man == 0) {
            out = sign;
        } else {  
            int shift = 0;
            while (!(man & 0x400)) { man <<= 1; shift++; }
            out = sign | ((uint32_t)(113 - shift) << 23) | ((man & 0x3ff) << 13);
        }
    } else if (exp == 0x1f) {
        out = sign | 0x7f800000u | (man << 13);
    } else {
        out = sign | ((exp + 112) << 23) | (man << 13);
    }
    float f; std::memcpy(&f, &out, 4); return f;
}
static inline uint16_t f2h_bits(float f)
{
    uint32_t x; std::memcpy(&x, &f, 4);
    uint32_t sign = (x >> 16) & 0x8000;
    uint32_t e8   = (x >> 23) & 0xff;
    uint32_t man  = x & 0x7fffff;
    if (e8 == 0xff)  
        return (uint16_t)(sign | 0x7c00 | (man ? 0x200 | (man >> 13) : 0));
    int32_t exp = (int32_t)e8 - 127 + 15;
    if (exp >= 0x1f) return (uint16_t)(sign | 0x7c00);  
    if (exp <= 0) {                                     
        if (exp < -11) return (uint16_t)sign;
        man |= 0x800000;
        int shift = 14 - exp;  
        uint32_t sub  = man >> shift;
        uint32_t rem  = man & ((1u << shift) - 1);
        uint32_t halfu = 1u << (shift - 1);
        if (rem > halfu || (rem == halfu && (sub & 1))) sub++;
        return (uint16_t)(sign | sub);
    }
    uint16_t h = (uint16_t)(sign | ((uint32_t)exp << 10) | (man >> 13));
    uint32_t rem = man & 0x1fff;
    if (rem > 0x1000 || (rem == 0x1000 && (h & 1))) h++;  
    return h;
}
extern "C" {
alignas(8) inline thread_local uint8_t const_mem[5][4096] = {0};
}
namespace zlift {
inline uint32_t arg_off = SLIFTER_ARG_BASE;
constexpr uint32_t align_up(uint32_t x, uint32_t a) {
    return (x + (a - 1u)) & ~(a - 1u);
}
inline uint32_t ptr_slots[128];
inline unsigned ptr_slot_count = 0;
inline unsigned preset_slot_count = 0;
inline bool ptr_slot_scalar[128];
inline void note_ptr_slot(uint32_t at, bool scalar = false) {
    if (ptr_slot_count < 128) {
        ptr_slot_scalar[ptr_slot_count] = scalar;
        ptr_slots[ptr_slot_count++] = at;
    }
}
template <typename T> inline void writeArg(T v) {
    uint32_t at = align_up(arg_off, (uint32_t)sizeof(T));
    if constexpr (std::is_pointer_v<T>) {
        uint64_t raw = reinterpret_cast<uint64_t>(v);
        std::memcpy(&const_mem[0][at], &raw, sizeof raw);
        note_ptr_slot(at);
    } else {
        std::memcpy(&const_mem[0][at], &v, sizeof(T));
        if constexpr (sizeof(T) == 8)
            note_ptr_slot(at, true);
    }
    arg_off = at + sizeof(T);
}
} 
template <typename T> inline void writeStructField(int offset, T val) {
    std::memcpy(&const_mem[0][offset], &val, sizeof(T));
    if constexpr (sizeof(T) == 8) {
        zlift::note_ptr_slot((uint32_t)offset);
        zlift::preset_slot_count = zlift::ptr_slot_count;
    }
}
enum { ARG_BASE = SLIFTER_ARG_BASE };
inline uint32_t off = SLIFTER_ARG_BASE;
extern "C" {
alignas(16) inline int32_t shared_mem[8192] = {0};
}
struct SlifterTmaDesc {
    const void* global_base;   
    int32_t     rows;          
    int32_t     cols_k;        
    int32_t     elem_bytes;    
    int32_t     swizzle;       
    int32_t     ld;            
    int32_t     tile_base_off; 
    int32_t     max_rows;
    int32_t     stride_c2;     
    int32_t     stride_c3;     
    int32_t     vt_load;
    int32_t     store_dkv;
    int32_t     swiz_b;
};
struct ArgAt {
    uint32_t abs_off;
};
namespace zlift {
inline void writeArg(ArgAt a) { arg_off = a.abs_off; }
struct Staged {
    std::uintptr_t host_lo = 0;
    std::uintptr_t host_hi = 0;
    void *device = nullptr;
    void *pristine = nullptr;
    std::vector<std::pair<std::size_t, std::uintptr_t>> relocated;
};
inline Staged staged[8];
inline unsigned staged_count = 0;
inline void host_mapping(std::uintptr_t p, std::uintptr_t *lo,
                         std::uintptr_t *hi) {
    *lo = *hi = 0;
    std::FILE *maps = std::fopen("/proc/self/maps", "r");
    if (!maps)
        return;
    char line[512];
    std::uintptr_t run_lo = 0, run_hi = 0;
    bool found = false;
    while (std::fgets(line, sizeof line, maps)) {
        unsigned long a = 0, b = 0;
        char perms[8] = {0};
        if (std::sscanf(line, "%lx-%lx %7s", &a, &b, perms) != 3)
            continue;
        const bool writable = perms[0] == 'r' && perms[1] == 'w';
        if (!writable || a != run_hi) {
            if (found)
                break;              
            if (!writable) {
                run_lo = run_hi = 0;
                continue;
            }
            run_lo = a;             
        }
        run_hi = b;
        if (p >= run_lo && p < run_hi)
            found = true;
    }
    std::fclose(maps);
    if (found) {
        *lo = run_lo;
        *hi = run_hi;
    }
}
inline bool is_device_visible(void *p) {
    ze_memory_allocation_properties_t props = {
        ZE_STRUCTURE_TYPE_MEMORY_ALLOCATION_PROPERTIES};
    ze_device_handle_t owner = nullptr;
    return zeMemGetAllocProperties(runtime().context, p, &props, &owner) ==
               ZE_RESULT_SUCCESS &&
           props.type != ZE_MEMORY_TYPE_UNKNOWN;
}
inline bool tracing() {
    static const bool on = std::getenv("ZLIFT_TRACE") != nullptr;
    return on;
}
#define ZLIFT_TRACE_F(...)                                                     \
    do {                                                                       \
        if (::zlift::tracing())                                                \
            std::fprintf(stderr, "[zlift] " __VA_ARGS__);                      \
    } while (0)
inline Staged *stage_region(std::uintptr_t lo, std::uintptr_t hi,
                            std::uintptr_t follow = 0,
                            std::uintptr_t follow_end = 0) {
    for (unsigned j = 0; j < staged_count; j++)
        if (staged[j].host_lo == lo)
            return &staged[j];
    if (staged_count >= 8)
        return nullptr;
    Staged *entry = &staged[staged_count++];
    entry->host_lo = lo;
    entry->host_hi = hi;
    {
        AllocatorGuard guard;
        entry->device = nullptr;
        ze_device_mem_alloc_desc_t dd = {ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
        ze_host_mem_alloc_desc_t hd = {ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
        zeMemAllocShared(runtime().context, &dd, &hd, hi - lo, 4096,
                         runtime().device, &entry->device);
    }
    if (!entry->device) {
        staged_count--;
        return nullptr;
    }
    std::memcpy(entry->device, reinterpret_cast<void *>(lo), hi - lo);
    entry->pristine = std::malloc(hi - lo);
    if (entry->pristine)
        std::memcpy(entry->pristine, entry->device, hi - lo);
    auto *words = static_cast<std::uintptr_t *>(entry->device);
    std::size_t n = (hi - lo) / sizeof(std::uintptr_t);
    auto base = reinterpret_cast<std::uintptr_t>(entry->device);
    for (std::size_t j = 0; j < n; j++) {
        if (words[j] >= lo && words[j] < hi) {
            words[j] = base + (words[j] - lo);
            entry->relocated.emplace_back(j, words[j]);
            continue;
        }
        const std::uintptr_t at = lo + j * sizeof(std::uintptr_t);
        if (at < follow || at >= follow_end || words[j] < 0x10000u)
            continue;
        if (is_device_visible(reinterpret_cast<void *>(words[j])))
            continue;
        std::uintptr_t olo = 0, ohi = 0;
        host_mapping(words[j], &olo, &ohi);
        if (!olo)
            continue;
        Staged *other = stage_region(olo, ohi);
        if (!other)
            continue;
        ZLIFT_TRACE_F("stage +%zu inside a descriptor: %#lx -> %#lx\n",
                      j * sizeof(std::uintptr_t), (unsigned long)words[j],
                      (unsigned long)(reinterpret_cast<std::uintptr_t>(
                                          other->device) +
                                      (words[j] - olo)));
        words[j] = reinterpret_cast<std::uintptr_t>(other->device) +
                   (words[j] - olo);
        entry->relocated.emplace_back(j, words[j]);
    }
    return entry;
}
inline void stage_pointer_args() {
    staged_count = 0;
    for (unsigned i = 0; i < ptr_slot_count; i++) {
        std::uintptr_t p = 0;
        std::memcpy(&p, &const_mem[0][ptr_slots[i]], sizeof p);
        if (p < 0x10000u || is_device_visible(reinterpret_cast<void *>(p)))
            continue;
        std::uintptr_t lo = 0, hi = 0;
        host_mapping(p, &lo, &hi);
        if (!lo)
            continue;
        const std::uintptr_t win = ptr_slot_scalar[i] ? p : 0;
        Staged *entry = stage_region(lo, hi, win,
                                     win ? (p + 512 < hi ? p + 512 : hi) : 0);
        if (!entry)
            continue;
        std::uintptr_t moved =
            reinterpret_cast<std::uintptr_t>(entry->device) + (p - lo);
        std::memcpy(&const_mem[0][ptr_slots[i]], &moved, sizeof moved);
        ZLIFT_TRACE_F("stage +0x%03x %#lx -> %#lx (mapping %#lx..%#lx)\n",
                      ptr_slots[i], (unsigned long)p, (unsigned long)moved,
                      (unsigned long)lo, (unsigned long)hi);
    }
}
inline void unstage_pointer_args() {
    for (unsigned i = 0; i < staged_count; i++) {
        Staged &st = staged[i];
        std::size_t n = st.host_hi - st.host_lo;
        auto *host = reinterpret_cast<unsigned char *>(st.host_lo);
        auto *dev = static_cast<unsigned char *>(st.device);
        auto *was = static_cast<unsigned char *>(st.pristine);
        if (was) {
            {
                auto *w = reinterpret_cast<std::uintptr_t *>(dev);
                auto *o = reinterpret_cast<const std::uintptr_t *>(was);
                for (auto &[j, placed] : st.relocated)
                    if (w[j] == placed)
                        w[j] = o[j];
            }
            for (std::size_t j = 0; j < n; j++)
                if (dev[j] != was[j])
                    host[j] = dev[j];
            std::free(was);
        }
        AllocatorGuard guard;
        zeMemFree(runtime().context, st.device);
        st = Staged{};
    }
    staged_count = 0;
}
inline void note_bank_candidates(const char *kname) {
    auto add = [](uint32_t off) {
        for (unsigned i = 0; i < ptr_slot_count; i++)
            if (ptr_slots[i] == off)
                return;
        note_ptr_slot(off, true);
    };
    auto layout = read_arg_layout(kname);
    if (!layout.empty()) {
        for (auto slot : layout)
            if (slot.size == 8)
                add(slot.offset);
        return;
    }
    for (uint32_t off = 0x210; off + 8 <= 0x400; off += 8)
        add(off);
}
inline const char *shm_guard_symbol() { return "shared_mem"; }
inline constexpr unsigned SHM_GUARD_BYTES = 64;
inline void *shm_guard_region() {
    if (std::getenv("ZLIFT_NO_SHM_GUARD"))
        return nullptr;
    unsigned bytes = read_layout_field("\"__shared__\"", "\"bytes\"");
    if (!bytes)
        return nullptr;
    void *at = nullptr;
    if (zeModuleGetGlobalPointer(runtime().module, shm_guard_symbol(),
                                 nullptr, &at) != ZE_RESULT_SUCCESS ||
        !at)
        return nullptr;
    return static_cast<unsigned char *>(at) + bytes;
}
inline void shm_overflow_check() {
    void *at = shm_guard_region();
    if (!at)
        return;
    unsigned char seen[SHM_GUARD_BYTES];
    Runtime &rt = runtime();
    ZLIFT_ZE(zeCommandListAppendMemoryCopy(rt.queue, seen, at, sizeof seen,
                                           nullptr, 0, nullptr));
    ZLIFT_ZE(zeCommandListHostSynchronize(rt.queue, UINT64_MAX));
    bool touched = false;
    for (unsigned char b : seen)
        touched = touched || b != 0;
    if (!touched)
        return;
    unsigned bytes = read_layout_field("\"__shared__\"", "\"bytes\"");
    std::fprintf(stderr,
                 "SKIP_SHMEM: the kernel indexed past the %u bytes of "
                 "workgroup memory this module was built with\n", bytes);
    std::fflush(stdout);
    std::fflush(stderr);
    std::_Exit(4);
}
inline void launch(const char *kname, Dim3 grid, Dim3 block) {
    load_module();
    note_bank_candidates(kname);
    stage_pointer_args();
    AllocatorGuard guard;
    Runtime &rt = runtime();
    ze_kernel_desc_t kdesc = {ZE_STRUCTURE_TYPE_KERNEL_DESC};
    kdesc.pKernelName = kname;
    ze_kernel_handle_t kernel = nullptr;
    ZLIFT_ZE(zeKernelCreate(rt.module, &kdesc, &kernel));
    unsigned index = 0;
    std::vector<void *> byval_bufs;
    for (auto [offset, size, byval] : read_arg_layout(kname)) {
        if (offset == 65535 || offset == 65534) {
            unsigned v = offset == 65535 ? 0u : grid.x;
            ZLIFT_TRACE_F("arg %u <- %s = %u\n", index,
                          offset == 65535 ? "block offset" : "grid width", v);
            ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++, sizeof(v), &v));
            continue;
        }
        if (byval) {
            void *buf = nullptr;
            {
                AllocatorGuard guard;
                ze_device_mem_alloc_desc_t dd = {
                    ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
                ze_host_mem_alloc_desc_t hd = {
                    ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
                zeMemAllocShared(rt.context, &dd, &hd, size, 64, rt.device,
                                 &buf);
            }
            if (!buf)
                die("zeMemAllocShared for a by-value argument", 0);
            std::memcpy(buf, &const_mem[0][offset], size);
            byval_bufs.push_back(buf);
            ZLIFT_TRACE_F("arg %u <- +0x%03x %u bytes by value -> %p\n", index,
                          offset, size, buf);
            ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++, sizeof(void *),
                                              &buf));
            continue;
        }
        uint64_t shown = 0;
        std::memcpy(&shown, &const_mem[0][offset], size < 8 ? size : 8);
        ZLIFT_TRACE_F("arg %u <- +0x%03x size %u = %#lx\n", index, offset, size,
                      (unsigned long)shown);
        ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++, size,
                                          &const_mem[0][offset]));
    }
    unsigned banks = 0, stride = 0;
    read_const_mem_layout(&banks, &stride);
    void *const_mem_arg = nullptr;
    if (banks && stride) {
        {
            AllocatorGuard guard;
            ze_device_mem_alloc_desc_t dd = {
                ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
            ze_host_mem_alloc_desc_t hd = {
                ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
            zeMemAllocShared(rt.context, &dd, &hd, (std::size_t)banks * stride,
                             64, rt.device, &const_mem_arg);
        }
        if (const_mem_arg) {
            for (unsigned b = 0; b < banks && b < 5; b++)
                std::memcpy(static_cast<unsigned char *>(const_mem_arg) +
                                (std::size_t)b * stride,
                            const_mem[b], stride < 4096 ? stride : 4096);
            ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++,
                                              sizeof(void *), &const_mem_arg));
        }
    }
    unsigned nv_size = read_layout_field("\"__nv_global__\"", "\"size\"");
    void *nv_global_arg = nullptr;
    if (nv_size) {
        {
            AllocatorGuard guard;
            ze_device_mem_alloc_desc_t dd = {
                ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
            ze_host_mem_alloc_desc_t hd = {
                ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
            zeMemAllocShared(rt.context, &dd, &hd, nv_size, 64, rt.device,
                             &nv_global_arg);
        }
        if (nv_global_arg) {
            std::memset(nv_global_arg, 0, nv_size);
            void *host = nullptr;
            std::memcpy(&host, &const_mem[4][0], sizeof host);
            if (host)
                std::memcpy(nv_global_arg, host, nv_size);
            ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++, sizeof(void *),
                                              &nv_global_arg));
        }
    }
    unsigned nvi_size = read_layout_field("\"__nv_global_init__\"", "\"size\"");
    void *nv_init_arg = nullptr;
    if (nvi_size) {
        {
            AllocatorGuard guard;
            ze_device_mem_alloc_desc_t dd = {
                ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
            ze_host_mem_alloc_desc_t hd = {
                ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
            zeMemAllocShared(rt.context, &dd, &hd, nvi_size, 64, rt.device,
                             &nv_init_arg);
        }
        if (nv_init_arg) {
            std::memset(nv_init_arg, 0, nvi_size);
            const char *args_path = std::getenv("ZLIFT_ARGS");
            if (args_path) {
                std::string blob(args_path);
                const std::string suffix = ".args.json";
                if (blob.size() > suffix.size() &&
                    blob.compare(blob.size() - suffix.size(), suffix.size(),
                                 suffix) == 0)
                    blob.resize(blob.size() - suffix.size());
                blob += ".nvglobal.bin";
                if (std::FILE *bf = std::fopen(blob.c_str(), "rb")) {
                    std::fread(nv_init_arg, 1, nvi_size, bf);
                    std::fclose(bf);
                } else {
                    die("no .nvglobal.bin beside the argument layout", 0);
                }
            }
            ZLIFT_TRACE_F(".nv.global.init %u bytes -> %p\n", nvi_size,
                          nv_init_arg);
            ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++, sizeof(void *),
                                              &nv_init_arg));
        }
    }
    std::vector<std::pair<void *, DeviceGlobal>> dev_globals;
    std::vector<std::pair<void *, DeviceGlobal>> module_globals;
    for (DeviceGlobal g : read_device_globals()) {
        if (!g.name.empty()) {
            void *at = nullptr;
            if (zeModuleGetGlobalPointer(rt.module, g.name.c_str(), nullptr,
                                         &at) == ZE_RESULT_SUCCESS &&
                at) {
                void *host = nullptr;
                std::memcpy(&host, &const_mem[4][8 * g.slot], sizeof host);
                if (host)
                    ZLIFT_ZE(zeCommandListAppendMemoryCopy(
                        rt.queue, at, host, g.size, nullptr, 0, nullptr));
                else
                    ZLIFT_ZE(zeCommandListAppendMemoryFill(
                        rt.queue, at, "\0", 1, g.size, nullptr, 0, nullptr));
                ZLIFT_ZE(zeCommandListHostSynchronize(rt.queue, UINT64_MAX));
                ZLIFT_TRACE_F("__device__ %s (%u bytes) <- %p, in the module\n",
                              g.name.c_str(), g.size, host);
                module_globals.push_back({at, g});
                continue;
            }
        }
        void *buf = nullptr;
        {
            AllocatorGuard guard;
            ze_device_mem_alloc_desc_t dd = {
                ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
            ze_host_mem_alloc_desc_t hd = {
                ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
            zeMemAllocShared(rt.context, &dd, &hd, g.size, 64, rt.device, &buf);
        }
        if (!buf)
            die("zeMemAllocShared for a __device__ variable", 0);
        std::memset(buf, 0, g.size);
        void *host = nullptr;
        std::memcpy(&host, &const_mem[4][8 * g.slot], sizeof host);
        if (host)
            std::memcpy(buf, host, g.size);
        ZLIFT_TRACE_F("__device__ slot %u (%u bytes) <- %p -> %p\n", g.slot,
                      g.size, host, buf);
        ZLIFT_ZE(zeKernelSetArgumentValue(kernel, index++, sizeof(void *), &buf));
        dev_globals.push_back({buf, g});
    }
    ZLIFT_ZE(zeKernelSetIndirectAccess(kernel,
                                       ZE_KERNEL_INDIRECT_ACCESS_FLAG_HOST |
                                           ZE_KERNEL_INDIRECT_ACCESS_FLAG_DEVICE |
                                           ZE_KERNEL_INDIRECT_ACCESS_FLAG_SHARED));
    ZLIFT_ZE(zeKernelSetGroupSize(kernel, block.x, block.y, block.z));
    ze_group_count_t groups = {grid.x, grid.y, grid.z};
    ZLIFT_ZE(zeCommandListAppendLaunchKernel(rt.queue, kernel, &groups, nullptr,
                                             0, nullptr));
    ZLIFT_ZE(zeCommandListHostSynchronize(rt.queue, UINT64_MAX));
    zeKernelDestroy(kernel);
    shm_overflow_check();
    if (nv_init_arg) {
        AllocatorGuard guard;
        zeMemFree(rt.context, nv_init_arg);
    }
    if (nv_global_arg) {
        void *host = nullptr;
        std::memcpy(&host, &const_mem[4][0], sizeof host);
        if (host)
            std::memcpy(host, nv_global_arg, nv_size);
        AllocatorGuard guard;
        zeMemFree(rt.context, nv_global_arg);
    }
    if (const_mem_arg) {
        AllocatorGuard guard;
        zeMemFree(rt.context, const_mem_arg);
    }
    for (auto &[at, g] : module_globals) {
        void *host = nullptr;
        std::memcpy(&host, &const_mem[4][8 * g.slot], sizeof host);
        if (host) {
            ZLIFT_ZE(zeCommandListAppendMemoryCopy(rt.queue, host, at, g.size,
                                                   nullptr, 0, nullptr));
            ZLIFT_ZE(zeCommandListHostSynchronize(rt.queue, UINT64_MAX));
        }
    }
    for (auto &[buf, g] : dev_globals) {
        void *host = nullptr;
        std::memcpy(&host, &const_mem[4][8 * g.slot], sizeof host);
        if (host)
            std::memcpy(host, buf, g.size);
        AllocatorGuard guard;
        zeMemFree(rt.context, buf);
    }
    for (void *b : byval_bufs) {
        AllocatorGuard guard;
        zeMemFree(rt.context, b);
    }
    unstage_pointer_args();
}
} 
namespace zlift {
template <typename... Args>
void launch_named(const char *name, Dim3 grid, Dim3 block, Args... args) {
    arg_off = SLIFTER_ARG_BASE;
    ptr_slot_count = preset_slot_count;
    (writeArg(args), ...);
    launch(name, grid, block);
    ptr_slot_count = preset_slot_count = 0;
}
template <typename... Args>
void launch_named(const char *name, int grid, int block, Args... args) {
    launch_named(name, Dim3{(unsigned)grid, 1, 1}, Dim3{(unsigned)block, 1, 1},
                 args...);
}
} 
#define launchKernel(k, ...) ::zlift::launch_named(#k, __VA_ARGS__)
#define launchKernel2D(k, ...) ::zlift::launch_named(#k, __VA_ARGS__)
#define launchKernel3D(k, ...) ::zlift::launch_named(#k, __VA_ARGS__)
namespace zlift {
__attribute__((constructor)) inline void enable_usm() {
    ensure_device();
    usm_enabled = true;
}
__attribute__((destructor)) inline void disable_usm() {
    usm_enabled = false;
    shutting_down = true;
}
} 
void *operator new(std::size_t n) {
    if (!zlift::usm_enabled || zlift::in_allocator.load(std::memory_order_acquire))
        return std::malloc(n ? n : 1);
    return zlift::usm_alloc(n);
}
void *operator new[](std::size_t n) {
    if (!zlift::usm_enabled || zlift::in_allocator.load(std::memory_order_acquire))
        return std::malloc(n ? n : 1);
    return zlift::usm_alloc(n);
}
void operator delete(void *p) noexcept { zlift::usm_free(p); }
void operator delete[](void *p) noexcept { zlift::usm_free(p); }
void operator delete(void *p, std::size_t) noexcept { zlift::usm_free(p); }
void operator delete[](void *p, std::size_t) noexcept { zlift::usm_free(p); }
void operator delete(void *p, std::align_val_t) noexcept { zlift::usm_free(p); }
void operator delete[](void *p, std::align_val_t) noexcept { zlift::usm_free(p); }
