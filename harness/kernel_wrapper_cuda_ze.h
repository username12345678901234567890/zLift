#pragma once
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <atomic>
#include <new>
#include <algorithm>
#include <string>
#include <vector>
#ifndef SLIFTER_ARG_BASE
#define SLIFTER_ARG_BASE 0x210
#endif
struct Dim3 {
    unsigned x = 1, y = 1, z = 1;
};
extern "C" {
typedef unsigned CUresult;
typedef int CUdevice;
typedef unsigned long long CUdeviceptr;
typedef void *CUcontext;
typedef void *CUmodule;
typedef void *CUfunction;
typedef void *CUstream;
CUresult cuInit(unsigned);
CUresult cuDeviceGet(CUdevice *, int);
CUresult cuCtxCreate_v2(CUcontext *, unsigned, CUdevice);
CUresult cuModuleLoadData(CUmodule *, const void *);
CUresult cuModuleGetFunction(CUfunction *, CUmodule, const char *);
CUresult cuModuleGetGlobal_v2(CUdeviceptr *, size_t *, CUmodule, const char *);
CUresult cuMemcpyHtoD_v2(CUdeviceptr, const void *, size_t);
CUresult cuMemcpyDtoH_v2(void *, CUdeviceptr, size_t);
CUresult cuMemAlloc_v2(CUdeviceptr *, size_t);
CUresult cuMemsetD8_v2(CUdeviceptr, unsigned char, size_t);
CUresult cuMemFree_v2(CUdeviceptr);
CUresult cuLaunchKernel(CUfunction, unsigned, unsigned, unsigned, unsigned,
                        unsigned, unsigned, unsigned, CUstream, void **, void **);
CUresult cuCtxSynchronize(void);
}
namespace zlift {
inline void die(const char *what, unsigned code) {
    std::fprintf(stderr, "FAIL: %s -> %u\n", what, code);
    std::exit(1);
}
#define ZLIFT_CU(call)                                                         \
    do {                                                                       \
        CUresult _r = (call);                                                  \
        if (_r != 0)                                                           \
            ::zlift::die(#call, _r);                                           \
    } while (0)
struct Runtime {
    CUcontext ctx = nullptr;
    CUmodule module = nullptr;
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
inline bool usm_enabled = false;
inline bool shutting_down = false;
inline void ensure_device() {
    Runtime &rt = runtime();
    if (rt.ready && rt.pid == getpid())
        return;
    if (rt.ready) {
        std::fprintf(stderr,
                     "FAIL: this process inherited an initialised GPU context "
                     "across fork(); the driver cannot be used in the child\n");
        std::fflush(stderr);
        std::_Exit(70);
    }
    AllocatorGuard guard;
    ZLIFT_CU(cuInit(0));
    CUdevice dev = 0;
    ZLIFT_CU(cuDeviceGet(&dev, 0));
    ZLIFT_CU(cuCtxCreate_v2(&rt.ctx, 0, dev));
    rt.pid = getpid();
    rt.ready = true;
}
inline void load_module() {
    Runtime &rt = runtime();
    ensure_device();
    if (rt.module)
        return;
    const char *path = std::getenv("ZLIFT_CUBIN");
    bool cubin = path != nullptr;
    if (!path)
        path = std::getenv("ZLIFT_PTX");
    if (!path)
        die("neither ZLIFT_CUBIN nor ZLIFT_PTX is set", 0);
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        die(path, 0);
    std::string image;
    char buf[4096];
    size_t got;
    while ((got = std::fread(buf, 1, sizeof buf, f)) > 0)
        image.append(buf, got);
    std::fclose(f);
    AllocatorGuard guard;
    ZLIFT_CU(cuModuleLoadData(&rt.module,
                              cubin ? (const void *)image.data()
                                    : (const void *)image.c_str()));
}
inline void **usm_slots = nullptr;
inline std::size_t usm_cap = 0;
inline std::size_t usm_count = 0;
inline std::size_t usm_tombstones = 0;
inline void *const USM_TOMBSTONE = reinterpret_cast<void *>(1);
inline std::size_t usm_hash(void *p) {
    return (reinterpret_cast<std::uintptr_t>(p) >> 6) * 11400714819323198485ull;
}
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
inline bool usm_forget(void *p) {
    if (!usm_cap)
        return false;
    std::size_t i = usm_hash(p) & (usm_cap - 1);
    for (std::size_t probe = 0; probe < usm_cap; probe++) {
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
inline void *usm_alloc(std::size_t n) {
    AllocatorGuard guard;
    CUdeviceptr p = 0;
    if (cuMemAlloc_v2(&p, n ? n : 1) != 0 || !p)
        return std::malloc(n ? n : 1);
    void *ptr = reinterpret_cast<void *>(p);
    usm_track(ptr);
    return ptr;
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
enum { ARG_BASE = SLIFTER_ARG_BASE };
inline uint32_t off = SLIFTER_ARG_BASE;
extern "C" {
alignas(16) inline int32_t shared_mem[8192] = {0};
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
struct Staged {
    std::uintptr_t host_lo = 0;
    std::uintptr_t host_hi = 0;
    void *device = nullptr;
    void *pristine = nullptr;
    std::vector<std::pair<std::size_t, std::uintptr_t>> relocated;
};
inline Staged staged[8];
inline unsigned staged_count = 0;
inline bool is_ours(void *p) {
    if (!usm_cap)
        return false;
    std::size_t i = usm_hash(p) & (usm_cap - 1);
    for (std::size_t probe = 0; probe < usm_cap; probe++) {
        if (!usm_slots[i])
            return false;
        if (usm_slots[i] == p)
            return true;
        i = (i + 1) & (usm_cap - 1);
    }
    return false;
}
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
    CUdeviceptr d = 0;
    {
        AllocatorGuard guard;
        if (cuMemAlloc_v2(&d, hi - lo) != 0)
            d = 0;
    }
    if (!d) {
        staged_count--;
        return nullptr;
    }
    entry->device = reinterpret_cast<void *>(d);
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
        if (is_ours(reinterpret_cast<void *>(words[j])))
            continue;
        std::uintptr_t olo = 0, ohi = 0;
        host_mapping(words[j], &olo, &ohi);
        if (!olo)
            continue;
        Staged *other = stage_region(olo, ohi);
        if (!other)
            continue;
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
        if (p < 0x10000u || is_ours(reinterpret_cast<void *>(p)))
            continue;
        std::uintptr_t lo = 0, hi = 0;
        host_mapping(p, &lo, &hi);
        if (!lo)
            continue;
        const std::uintptr_t win = ptr_slot_scalar[i] ? p : 0;
        Staged *entry = stage_region(lo, hi, win,
                                     win ? (p + 512 < hi ? p + 512 : hi) : 0);
        if (std::getenv("ZLIFT_STAGE_TRACE"))
            std::fprintf(stderr,
                         "[stage] +0x%03x p=%#lx map=%#lx..%#lx dev=%p\n",
                         ptr_slots[i], (unsigned long)p, (unsigned long)lo,
                         (unsigned long)hi, entry ? entry->device : nullptr);
        if (!entry)
            continue;
        std::uintptr_t moved =
            reinterpret_cast<std::uintptr_t>(entry->device) + (p - lo);
        std::memcpy(&const_mem[0][ptr_slots[i]], &moved, sizeof moved);
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
            std::size_t moved = 0, raced = 0;
            for (std::size_t j = 0; j < n; j++) {
                if (dev[j] != was[j]) {
                    host[j] = dev[j];
                    moved++;
                } else if (host[j] != was[j]) {
                    raced++;
                }
            }
            if (std::getenv("ZLIFT_STAGE_TRACE"))
                std::fprintf(stderr,
                             "[unstage] %#lx..%#lx moved=%zu host-moved=%zu\n",
                             (unsigned long)st.host_lo,
                             (unsigned long)st.host_hi, moved, raced);
            std::free(was);
        }
        AllocatorGuard guard;
        cuMemFree_v2(reinterpret_cast<CUdeviceptr>(st.device));
        st = Staged{};
    }
    staged_count = 0;
}
} 
template <typename T> inline void writeStructField(int offset, T val) {
    std::memcpy(&const_mem[0][offset], &val, sizeof(T));
    if constexpr (sizeof(T) == 8) {
        zlift::note_ptr_slot((uint32_t)offset);
        zlift::preset_slot_count = zlift::ptr_slot_count;
    }
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
struct DeviceGlobal {
    std::string name;
    unsigned slot;
    unsigned size;
};
struct ArgSlot {
    unsigned offset;
    unsigned size;
    bool byval = false;
};
inline std::vector<ArgSlot> read_arg_layout(const std::string &kernel) {
    std::vector<ArgSlot> slots;
    const char *path = std::getenv("ZLIFT_ARGS");
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
inline std::vector<ArgSlot> read_cuda_params(const std::string &kernel) {
    std::vector<ArgSlot> slots;
    const char *path = std::getenv("ZLIFT_ARGS");
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
    size_t sect = text.find("\"__cuda_params__\"");
    if (sect == std::string::npos)
        return slots;
    size_t at = text.find("\"" + kernel + "\"", sect);
    if (at == std::string::npos)
        return slots;
    size_t end = text.find("]", at);
    std::string body = text.substr(at, end == std::string::npos ? end : end - at);
    size_t pos = 0;
    while (true) {
        size_t o = body.find("\"offset\"", pos);
        if (o == std::string::npos)
            break;
        size_t sz = body.find("\"size\"", o);
        if (sz == std::string::npos)
            break;
        slots.push_back({(unsigned)std::strtoul(body.c_str() + body.find(':', o) + 1,
                                                nullptr, 10),
                         (unsigned)std::strtoul(body.c_str() + body.find(':', sz) + 1,
                                                nullptr, 10),
                         false});
        pos = sz;
    }
    return slots;
}
inline std::vector<DeviceGlobal> read_nv_global_symbols() {
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
    size_t at = text.find("\"__nv_global_symbols__\"");
    if (at == std::string::npos)
        return out;
    size_t pos = text.find('{', at);
    if (pos == std::string::npos)
        return out;
    pos++;
    std::vector<std::pair<unsigned, DeviceGlobal>> found;
    while (true) {
        size_t q1 = text.find('"', pos);
        if (q1 == std::string::npos)
            break;
        size_t q2 = text.find('"', q1 + 1);
        if (q2 == std::string::npos)
            break;
        std::string name = text.substr(q1 + 1, q2 - q1 - 1);
        size_t brace = text.find('{', q2);
        size_t close = brace == std::string::npos ? std::string::npos
                                                 : text.find('}', brace);
        if (close == std::string::npos)
            break;
        std::string entry = text.substr(brace, close - brace);
        size_t o = entry.find("\"offset\"");
        size_t z = entry.find("\"size\"");
        if (o == std::string::npos || z == std::string::npos)
            break;
        unsigned offset = (unsigned)std::strtoul(
            entry.c_str() + entry.find(':', o) + 1, nullptr, 10);
        unsigned width = (unsigned)std::strtoul(
            entry.c_str() + entry.find(':', z) + 1, nullptr, 10);
        found.push_back({offset, {name, 0, width}});
        pos = close + 1;
        size_t next = text.find_first_not_of(" \t\r\n", pos);
        if (next == std::string::npos || text[next] != ',')
            break;
        pos = next + 1;
    }
    std::sort(found.begin(), found.end(),
              [](const auto &a, const auto &b) { return a.first < b.first; });
    for (unsigned i = 0; i < found.size(); i++) {
        found[i].second.slot = i;
        out.push_back(found[i].second);
    }
    return out;
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
        size_t nm = text.find("\"name\"", pos);
        if (nm == std::string::npos)
            break;
        size_t q1 = text.find('"', text.find(':', nm) + 1);
        size_t q2 = text.find('"', q1 + 1);
        size_t sl = text.find("\"slot\"", q2);
        size_t sz = text.find("\"size\"", sl);
        if (q1 == std::string::npos || sl == std::string::npos ||
            sz == std::string::npos)
            break;
        out.push_back({text.substr(q1 + 1, q2 - q1 - 1),
                       (unsigned)std::strtoul(text.c_str() + text.find(':', sl) + 1,
                                              nullptr, 10),
                       (unsigned)std::strtoul(text.c_str() + text.find(':', sz) + 1,
                                              nullptr, 10)});
        pos = sz + 1;
    }
    return out;
}
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
inline void note_bank_candidates(const char *kname) {
    auto add = [](uint32_t off) {
        for (unsigned i = 0; i < ptr_slot_count; i++)
            if (ptr_slots[i] == off)
                return;
        note_ptr_slot(off, true);
    };
    auto layout = read_arg_layout(kname);
    if (layout.empty()) {
        for (auto slot : read_cuda_params(kname))
            for (unsigned off = slot.offset; off + 8 <= slot.offset + slot.size;
                 off += 8)
                layout.push_back({off, 8, false});
    }
    if (!layout.empty()) {
        for (auto slot : layout)
            if (slot.size == 8)
                add(slot.offset);
        return;
    }
    for (uint32_t off = 0x210; off + 8 <= 0x400; off += 8)
        add(off);
}
inline std::string sole_kernel_name() {
    const char *path = std::getenv("ZLIFT_ARGS");
    if (!path)
        return {};
    std::FILE *f = std::fopen(path, "rb");
    if (!f)
        return {};
    std::string text;
    char buf[4096];
    size_t got;
    while ((got = std::fread(buf, 1, sizeof buf, f)) > 0)
        text.append(buf, got);
    std::fclose(f);
    std::string only;
    int depth = 0;
    for (size_t i = 0; i < text.size(); i++) {
        char c = text[i];
        if (c == '{' || c == '[') {
            depth++;
            continue;
        }
        if (c == '}' || c == ']') {
            depth--;
            continue;
        }
        if (c != '"' || depth != 1)
            continue;
        size_t end = text.find('"', i + 1);
        if (end == std::string::npos)
            break;
        std::string key = text.substr(i + 1, end - i - 1);
        i = end;
        if (key.rfind("__", 0) == 0)
            continue;
        if (!only.empty())
            return {};  
        only = key;
    }
    return only;
}
inline const char *shm_guard_symbol() { return "shared_mem"; }
inline constexpr unsigned SHM_GUARD_BYTES = 64;
inline bool shm_guard_region(CUdeviceptr *out) {
    unsigned bytes = read_layout_field("\"__shared__\"", "\"bytes\"");
    if (!bytes)
        return false;
    size_t n = 0;
    if (cuModuleGetGlobal_v2(out, &n, runtime().module, shm_guard_symbol()) != 0
        || !*out)
        return false;
    *out += bytes;
    return true;
}
inline void shm_overflow_check() {
    CUdeviceptr d = 0;
    if (!shm_guard_region(&d))
        return;
    unsigned char seen[SHM_GUARD_BYTES];
    if (cuMemcpyDtoH_v2(seen, d, sizeof seen) != 0)
        return;
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
    Runtime &rt = runtime();
    CUfunction fn = nullptr;
    AllocatorGuard lookup_guard;
    if (cuModuleGetFunction(&fn, rt.module, kname) != 0 || !fn) {
        std::string only = sole_kernel_name();
        if (only.empty() || only == kname)
            die("cuModuleGetFunction(&fn, rt.module, kname)", 500);
        ZLIFT_CU(cuModuleGetFunction(&fn, rt.module, only.c_str()));
        std::fprintf(stderr,
                     "[harness] '%s' is not in this module; it holds one "
                     "kernel, '%s', so that is what runs\n",
                     kname, only.c_str());
        static std::string held;
        held = only;
        kname = held.c_str();
    }
    note_bank_candidates(kname);
    stage_pointer_args();
    AllocatorGuard guard;
    std::vector<void *> params;
    auto cuda = read_cuda_params(kname);
    for (auto slot : (cuda.empty() ? read_arg_layout(kname) : cuda))
        params.push_back(&const_mem[0][slot.offset]);
    void *bank_blob = &const_mem[0][0];
    if (read_layout_field("\"__const_mem__\"", "\"banks\""))
        params.push_back(&bank_blob);
    auto globals = read_device_globals();
    if (globals.empty())
        globals = read_nv_global_symbols();
    std::vector<std::pair<CUdeviceptr, DeviceGlobal>> written;
    for (auto &g : globals) {
        CUdeviceptr d = 0;
        size_t n = 0;
        if (cuModuleGetGlobal_v2(&d, &n, rt.module, g.name.c_str()) != 0 || !d)
            continue;
        void *host = nullptr;
        std::memcpy(&host, &const_mem[4][8 * g.slot], sizeof host);
        if (host)
            ZLIFT_CU(cuMemcpyHtoD_v2(d, host, g.size));
        written.push_back({d, g});
    }
    unsigned shared = 32768;
    if (const char *s = std::getenv("ZLIFT_SHARED"))
        shared = (unsigned)std::strtoul(s, nullptr, 10);
    ZLIFT_CU(cuLaunchKernel(fn, grid.x, grid.y, grid.z, block.x, block.y,
                            block.z, shared, nullptr, params.data(), nullptr));
    ZLIFT_CU(cuCtxSynchronize());
    shm_overflow_check();
    for (auto &[d, g] : written) {
        void *host = nullptr;
        std::memcpy(&host, &const_mem[4][8 * g.slot], sizeof host);
        if (host)
            ZLIFT_CU(cuMemcpyDtoH_v2(host, d, g.size));
    }
    unstage_pointer_args();
}
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
__attribute__((constructor)) inline void enable_usm() {
    ensure_device();
    usm_enabled = true;
}
__attribute__((destructor)) inline void disable_usm() {
    usm_enabled = false;
    shutting_down = true;
}
} 
#define launchKernel(k, ...) ::zlift::launch_named(#k, __VA_ARGS__)
#define launchKernel2D(k, ...) ::zlift::launch_named(#k, __VA_ARGS__)
#define launchKernel3D(k, ...) ::zlift::launch_named(#k, __VA_ARGS__)
void *operator new(std::size_t n) {
    if (!zlift::usm_enabled || zlift::in_allocator.load(std::memory_order_acquire))
        return std::malloc(n ? n : 1);
    return zlift::usm_alloc(n);
}
void *operator new[](std::size_t n) { return operator new(n); }
void *operator new(std::size_t n, const std::nothrow_t &) noexcept {
    return operator new(n);
}
void *operator new[](std::size_t n, const std::nothrow_t &) noexcept {
    return operator new(n);
}
void operator delete(void *p) noexcept {
    if (!p)
        return;
    if (zlift::shutting_down)
        return;
    if (zlift::usm_forget(p)) {
        zlift::AllocatorGuard guard;
        cuMemFree_v2(reinterpret_cast<CUdeviceptr>(p));
        return;
    }
    std::free(p);
}
void operator delete[](void *p) noexcept { operator delete(p); }
void operator delete(void *p, std::size_t) noexcept { operator delete(p); }
void operator delete[](void *p, std::size_t) noexcept { operator delete(p); }
void operator delete(void *p, const std::nothrow_t &) noexcept { operator delete(p); }
void operator delete[](void *p, const std::nothrow_t &) noexcept { operator delete(p); }
