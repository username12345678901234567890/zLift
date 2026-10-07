#include <map>
#include <tuple>
#include <sycl/sycl.hpp>
#include <sycl/ext/oneapi/backend/level_zero.hpp>
#include <sycl/ext/intel/experimental/grf_size_properties.hpp>
#include <oneapi/mkl.hpp>
#include <dlfcn.h>
#include <cstdio>
#include <cstddef>
#include <filesystem>
#include <cstdlib>
#include <mutex>
#include <optional>
#include <string>
#include <vector>
namespace ze = sycl::ext::oneapi::level_zero;
namespace blas = oneapi::mkl::blas::column_major;
static constexpr int CUBLAS_OP_N_ = 0;
namespace {
oneapi::mkl::transpose op_of(int op) {
    switch (op) {
        case 1: return oneapi::mkl::transpose::trans;
        case 2: return oneapi::mkl::transpose::conjtrans;
        default: return oneapi::mkl::transpose::nontrans;
    }
}
struct Gpu {
    bool ok = false;
    std::optional<sycl::context> ctx;
    std::optional<sycl::device> dev;
    std::optional<sycl::queue> q;
};
bool tracing() {
    static const bool on = std::getenv("ZBLAS_TRACE") != nullptr;
    return on;
}
struct Prof {
    std::map<std::string, std::pair<double, long long>> t;   
    std::mutex m;
    bool on = std::getenv("ZBLAS_PROF") != nullptr;
    void add(const std::string &what, double sec) {
        if (!on) return;
        std::lock_guard<std::mutex> g(m);
        auto &e = t[what];
        e.first += sec;
        e.second++;
    }
    ~Prof() {
        if (!on || t.empty()) return;
        double tot = 0;
        for (auto &kv : t) tot += kv.second.first;
        std::fprintf(stderr, "\n[zblas] --- device time in this shim ---\n");
        for (auto &kv : t)
            std::fprintf(stderr, "[zblas] %-28s %8.2f s  %8lld calls  %5.1f%%\n",
                         kv.first.c_str(), kv.second.first, kv.second.second,
                         100.0 * kv.second.first / tot);
        std::fprintf(stderr, "[zblas] %-28s %8.2f s\n", "total", tot);
    }
};
static Prof &prof() {
    static Prof p;
    return p;
}
struct Timed {
    const char *what;
    std::chrono::steady_clock::time_point t0;
    explicit Timed(const char *w)
        : what(w), t0(std::chrono::steady_clock::now()) {}
    ~Timed() {
        if (prof().on)
            prof().add(what, std::chrono::duration<double>(
                                 std::chrono::steady_clock::now() - t0).count());
    }
};
bool gpu_disabled() {
    static const bool off = std::getenv("ZBLAS_NO_GPU") != nullptr;
    return off;
}
bool driver_handles(void **drv, void **ctx, void **dev) {
    using Fn = int (*)(void **, void **, void **);
    static Fn fn = [] {
        if (void *p = dlsym(RTLD_DEFAULT, "zlift_ze_handles")) {
            return reinterpret_cast<Fn>(p);
        }
        for (const char *name : {"libcuda.so.1", "libcuda.so"}) {
            if (void *lib = dlopen(name, RTLD_NOW | RTLD_GLOBAL)) {
                if (void *p = dlsym(lib, "zlift_ze_handles")) {
                    return reinterpret_cast<Fn>(p);
                }
            }
        }
        return static_cast<Fn>(nullptr);
    }();
    if (!fn) {
        return false;
    }
    return fn(drv, ctx, dev) == 0;
}
void preload_runtime() {
#ifdef ZBLAS_ONEAPI_LIBS
    static const char *const dirs[] = {ZBLAS_ONEAPI_LIBS};
    static const char *const libs[] = {
        "libtbb.so.12", "libtbbmalloc.so.2", "libumf.so.0", "libhwloc.so.15",
        "libur_loader.so.0", "libur_adapter_level_zero.so.0",
    };
    for (const char *lib : libs) {
        for (const char *dir : dirs) {
            std::string path = std::string(dir) + "/" + lib;
            if (dlopen(path.c_str(), RTLD_NOW | RTLD_GLOBAL)) {
                break;
            }
        }
    }
#endif
}
const Gpu &gpu() {
    static Gpu g;
    static std::once_flag once;
    std::call_once(once, [] {
        if (gpu_disabled()) {
            if (tracing()) {
                std::fprintf(stderr, "[zblas] ZBLAS_NO_GPU set; CPU path\n");
            }
            return;
        }
        preload_runtime();
        void *drv = nullptr, *zctx = nullptr, *zdev = nullptr;
        if (!driver_handles(&drv, &zctx, &zdev)) {
            if (tracing()) {
                std::fprintf(stderr, "[zblas] no driver handles; CPU path\n");
            }
            return;
        }
        try {
            bool found = false;
            for (const auto &d : sycl::device::get_devices(sycl::info::device_type::gpu)) {
                if (d.get_backend() != sycl::backend::ext_oneapi_level_zero) {
                    continue;
                }
                auto native = sycl::get_native<sycl::backend::ext_oneapi_level_zero>(d);
                if (reinterpret_cast<void *>(native) == zdev) {
                    g.dev = d;
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw std::runtime_error("the driver's device is not one SYCL enumerates");
            }
            sycl::backend_input_t<sycl::backend::ext_oneapi_level_zero, sycl::context> ci{
                reinterpret_cast<ze_context_handle_t>(zctx),
                std::vector<sycl::device>{*g.dev},
                ze::ownership::keep};
            g.ctx = sycl::make_context<sycl::backend::ext_oneapi_level_zero>(ci);
            g.q = sycl::queue(*g.ctx, *g.dev);
            g.ok = true;
            if (tracing()) {
                std::fprintf(stderr, "[zblas] GPU path on %s\n",
                             g.dev->get_info<sycl::info::device::name>().c_str());
            }
        } catch (const std::exception &e) {
            if (tracing()) {
                std::fprintf(stderr, "[zblas] no GPU queue (%s); CPU path\n", e.what());
            }
            g.ok = false;
        } catch (...) {
            g.ok = false;
        }
    });
    return g;
}
bool usm_here(const Gpu &g, std::initializer_list<const void *> ptrs) {
    for (const void *p : ptrs) {
        if (!p) {
            return false;
        }
        auto kind = sycl::get_pointer_type(p, *g.ctx);
        if (kind == sycl::usm::alloc::unknown || kind == sycl::usm::alloc::host) {
            return false;
        }
    }
    return true;
}
template <typename Body>
int run(Body body) {
    const Gpu &g = gpu();
    if (!g.ok) {
        return 1;
    }
    try {
        body(const_cast<Gpu &>(g));
        return 0;
    } catch (const std::exception &e) {
        if (tracing()) {
            std::fprintf(stderr, "[zblas] GEMM threw (%s); CPU path\n", e.what());
        }
        return 2;
    } catch (...) {
        return 2;
    }
}
namespace xmx {
namespace matrix = sycl::ext::oneapi::experimental::matrix;
using bf16 = sycl::ext::oneapi::bfloat16;
constexpr int TM = 8, TN = 16, TK = 16, SG = 16;
struct Scratch {
    void *p = nullptr;
    size_t bytes = 0;
    bf16 *get(sycl::queue &q, size_t need_bytes) {
        if (need_bytes > bytes) {
            if (p) sycl::free(p, q);
            p = sycl::malloc_device(need_bytes, q);
            bytes = p ? need_bytes : 0;
            if (!p) throw std::runtime_error("no device scratch for XMX");
        }
        return static_cast<bf16 *>(p);
    }
};
static void split_to_bf16(sycl::queue &q, const float *src, int ld,
                          bool src_row_major, int rows, int cols,
                          bf16 *hi, bf16 *lo, bool want_lo) {
    static const bool vec_split = [] {
        const char *v = std::getenv("ZBLAS_SPLIT");
        return !(v && std::string(v) == "scalar");
    }();
    if (vec_split && src_row_major && (cols % 4) == 0 && (ld % 4) == 0) {
        q.parallel_for(sycl::range<2>(rows, cols / 4), [=](sycl::id<2> id) {
            size_t r = id[0], c4 = id[1];
            sycl::vec<float, 4> x;
            x.load(c4, sycl::multi_ptr<const float,
                       sycl::access::address_space::global_space>(
                           src + r * (size_t)ld));
            sycl::vec<float, 4> hf;
            bf16 h[4];
            for (int j = 0; j < 4; j++) {
                h[j] = bf16(x[j]);
                hf[j] = float(h[j]);
            }
            sycl::vec<unsigned short, 4> hv, lv;
            for (int j = 0; j < 4; j++)
                hv[j] = sycl::bit_cast<unsigned short>(h[j]);
            hv.store(c4, sycl::multi_ptr<unsigned short,
                         sycl::access::address_space::global_space>(
                             reinterpret_cast<unsigned short *>(
                                 hi + r * (size_t)cols)));
            if (want_lo) {
                for (int j = 0; j < 4; j++)
                    lv[j] = sycl::bit_cast<unsigned short>(bf16(x[j] - hf[j]));
                lv.store(c4, sycl::multi_ptr<unsigned short,
                             sycl::access::address_space::global_space>(
                                 reinterpret_cast<unsigned short *>(
                                     lo + r * (size_t)cols)));
            }
        }).wait();
        return;
    }
    q.parallel_for(sycl::range<2>(rows, cols), [=](sycl::id<2> id) {
        int r = (int)id[0], c = (int)id[1];
        float x = src_row_major ? src[(size_t)r * ld + c]
                                : src[(size_t)c * ld + r];
        bf16 h = bf16(x);
        hi[(size_t)r * cols + c] = h;
        if (want_lo) lo[(size_t)r * cols + c] = bf16(x - float(h));
    }).wait();
}
template <typename T, int RM, int RN, int PASSES, int GRF>
static void mad(sycl::queue &q, int M, int N, int K,
                const T *Ah, const T *Al, const T *Bh, const T *Bl,
                float *C, int ldc) {
    sycl::range<2> global((size_t)M / (TM * RM) * SG, (size_t)N / (TN * RN));
    sycl::range<2> local(SG, 1);
    auto body = [=](sycl::nd_item<2> it) {
        auto sg = it.get_sub_group();
        size_t m0 = it.get_group(0) * (TM * RM), n0 = it.get_group(1) * (TN * RN);
        matrix::joint_matrix<sycl::sub_group, float, matrix::use::accumulator,
                             TM, TN> acc[RM][RN];
        for (int i = 0; i < RM; i++)
            for (int j = 0; j < RN; j++) matrix::joint_matrix_fill(sg, acc[i][j], 0.0f);
        for (int k = 0; k < K; k += TK) {
            matrix::joint_matrix<sycl::sub_group, T, matrix::use::a,
                                 TM, TK, matrix::layout::row_major> ah[RM], al[RM];
            matrix::joint_matrix<sycl::sub_group, T, matrix::use::b,
                                 TK, TN, matrix::layout::row_major> bh[RN], bl[RN];
            auto ldA = [&](auto &dst, const T *Ap, int i) {
                matrix::joint_matrix_load(sg, dst,
                    sycl::multi_ptr<const T, sycl::access::address_space::global_space>(
                        Ap + (m0 + i * TM) * (size_t)K + k), K);
            };
            auto ldB = [&](auto &dst, const T *Bp, int j) {
                matrix::joint_matrix_load(sg, dst,
                    sycl::multi_ptr<const T, sycl::access::address_space::global_space>(
                        Bp + (size_t)k * N + n0 + j * TN), N);
            };
            for (int i = 0; i < RM; i++) ldA(ah[i], Ah, i);
            for (int j = 0; j < RN; j++) ldB(bh[j], Bh, j);
            if (PASSES == 3) {
                for (int i = 0; i < RM; i++) ldA(al[i], Al, i);
                for (int j = 0; j < RN; j++) ldB(bl[j], Bl, j);
            }
            for (int i = 0; i < RM; i++)
                for (int j = 0; j < RN; j++)
                    matrix::joint_matrix_mad(sg, acc[i][j], ah[i], bh[j], acc[i][j]);
            if (PASSES == 3) {
                for (int i = 0; i < RM; i++)
                    for (int j = 0; j < RN; j++)
                        matrix::joint_matrix_mad(sg, acc[i][j], ah[i], bl[j], acc[i][j]);
                for (int i = 0; i < RM; i++)
                    for (int j = 0; j < RN; j++)
                        matrix::joint_matrix_mad(sg, acc[i][j], al[i], bh[j], acc[i][j]);
            }
        }
        for (int i = 0; i < RM; i++)
            for (int j = 0; j < RN; j++)
                matrix::joint_matrix_store(sg, acc[i][j],
                    sycl::multi_ptr<float, sycl::access::address_space::global_space>(
                        C + (m0 + i * TM) * (size_t)ldc + n0 + j * TN),
                    ldc, matrix::layout::row_major);
    };
    if constexpr (GRF == 256) {
        _Pragma("GCC diagnostic push")
        _Pragma("GCC diagnostic ignored \"-Wdeprecated-declarations\"")
        sycl::ext::oneapi::experimental::properties props{
            sycl::ext::oneapi::experimental::sub_group_size<SG>,
            sycl::ext::intel::experimental::grf_size<256>};
        q.parallel_for(sycl::nd_range<2>(global, local), props,
            [=](sycl::nd_item<2> it) { body(it); }).wait();
        _Pragma("GCC diagnostic pop")
    } else {
        q.parallel_for(sycl::nd_range<2>(global, local),
            [=](sycl::nd_item<2> it) [[sycl::reqd_sub_group_size(SG)]] { body(it); }).wait();
    }
}
struct MadShape {
    int m, n, k, passes, elem;
    bool operator<(const MadShape &o) const {
        return std::tie(m, n, k, passes, elem)
             < std::tie(o.m, o.n, o.k, o.passes, o.elem);
    }
};
constexpr int MAD_CANDIDATES = 12;
template <typename T, int PASSES>
static void mad_by_index(int idx, sycl::queue &q, int M, int N, int K,
                         const T *Ah, const T *Al, const T *Bh,
                         const T *Bl, float *C, int ldc) {
    switch (idx) {
    case 0:  mad<T, 8, 2, PASSES, 128>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 1:  mad<T, 2, 4, PASSES, 128>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 2:  mad<T, 4, 2, PASSES, 128>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 3:  mad<T, 4, 4, PASSES, 128>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 4:  mad<T, 2, 2, PASSES, 128>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 5:  mad<T, 8, 2, PASSES, 256>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 6:  mad<T, 2, 4, PASSES, 256>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 7:  mad<T, 4, 2, PASSES, 256>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 8:  mad<T, 4, 4, PASSES, 256>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 9:  mad<T, 2, 2, PASSES, 256>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    case 10:  mad<T, 1, 1, PASSES, 256>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    default: mad<T, 1, 1, PASSES, 128>(q, M, N, K, Ah, Al, Bh, Bl, C, ldc); break;
    }
}
static bool mad_fits(int idx, int M, int N) {
    static const int rm[] = {8, 2, 4, 4, 2, 8, 2, 4, 4, 2, 1, 1};
    static const int rn[] = {2, 4, 2, 4, 2, 2, 4, 2, 4, 2, 1, 1};
    return M % (TM * rm[idx]) == 0 && N % (TN * rn[idx]) == 0;
}
template <typename T, int PASSES>
static void mad_dispatch(sycl::queue &q, int M, int N, int K,
                         const T *Ah, const T *Al, const T *Bh,
                         const T *Bl, float *C, int ldc) {
    Timed _t("gemm f32 3-pass");
    static std::map<MadShape, int> best;
    static const bool autotune = std::getenv("ZBLAS_NO_AUTOTUNE") == nullptr;
    MadShape key{M, N, K, PASSES, (int)sizeof(T) + (std::is_same_v<T, sycl::half> ? 100 : 0)};
    auto it = best.find(key);
    if (it == best.end()) {
        int pick = MAD_CANDIDATES - 1;
        if (autotune) {
            double best_t = 1e30;
            for (int i = 0; i < MAD_CANDIDATES; i++) {
                if (!mad_fits(i, M, N)) continue;
                double t_i = 1e30;
                for (int rep = 0; rep < 3; rep++) {
                    auto t0 = std::chrono::steady_clock::now();
                    mad_by_index<T, PASSES>(i, q, M, N, K, Ah, Al, Bh, Bl, C, ldc);
                    double dt = std::chrono::duration<double>(
                        std::chrono::steady_clock::now() - t0).count();
                    if (dt < t_i) t_i = dt;
                }
                if (t_i < best_t) { best_t = t_i; pick = i; }
            }
        } else {
            for (int i = 0; i < MAD_CANDIDATES; i++)
                if (mad_fits(i, M, N)) { pick = i; break; }
        }
        it = best.emplace(key, pick).first;
        if (tracing()) {
            static const char *name[] = {"8x2","2x4","4x2","4x4","2x2",
                "8x2/grf256","2x4/grf256","4x2/grf256","4x4/grf256","2x2/grf256",
                "1x1/grf256","1x1"};
            std::fprintf(stderr, "[zblas] blocking %s for %dx%dx%d (%d-pass)\n",
                         name[pick], M, N, K, PASSES);
        }
    }
    mad_by_index<T, PASSES>(it->second, q, M, N, K, Ah, Al, Bh, Bl, C, ldc);
}
template <typename IN, typename OUT, int RM, int RN, int GRF, bool ACOL, bool BCOL,
          int SM = 1, int SN = 1>
static void mad_h(sycl::queue &q, int M, int N, int K,
                  const IN *Ap, int lda, const IN *Bp, int ldb,
                  OUT *C, int ldc, int sw) {
    constexpr auto ALAY = ACOL ? matrix::layout::col_major : matrix::layout::row_major;
    constexpr auto BLAY = BCOL ? matrix::layout::col_major : matrix::layout::row_major;
    constexpr int WGR = SM * RM * TM, WGC = SN * RN * TN, NSG = SM * SN;
    const int nM = (M + WGR - 1) / WGR, nN = (N + WGC - 1) / WGC;
    const int bt = sw > 0 ? std::max(1, sw / WGC) : 0;   
    const int ntile = bt > 0 ? (nN + bt - 1) / bt : 1;
    const size_t groups = bt > 0 ? (size_t)ntile * bt * nM : (size_t)nM * nN;
    auto body = [=](sycl::nd_item<1> it) {
        auto sg = it.get_sub_group();
        const size_t gid = it.get_group(0);
        int mIdx, nIdx;
        if (bt > 0) {
            const int per = bt * nM;
            const int t = (int)(gid / per), r = (int)(gid % per);
            mIdx = r / bt;
            nIdx = t * bt + r % bt;
            if (nIdx >= nN) return;
        } else {
            mIdx = (int)(gid / nN);
            nIdx = (int)(gid % nN);
        }
        const int sgid = NSG == 1 ? 0 : (int)sg.get_group_linear_id();
        size_t m0 = (size_t)mIdx * WGR + (size_t)(sgid / SN) * (RM * TM);
        size_t n0 = (size_t)nIdx * WGC + (size_t)(sgid % SN) * (RN * TN);
        if (m0 + RM * TM > (size_t)M || n0 + RN * TN > (size_t)N) return;
        matrix::joint_matrix<sycl::sub_group, float, matrix::use::accumulator,
                             TM, TN> acc[RM][RN];
        for (int i = 0; i < RM; i++)
            for (int j = 0; j < RN; j++) matrix::joint_matrix_fill(sg, acc[i][j], 0.0f);
        for (int k = 0; k < K; k += TK) {
            matrix::joint_matrix<sycl::sub_group, IN, matrix::use::a,
                                 TM, TK, ALAY> a[RM];
            matrix::joint_matrix<sycl::sub_group, IN, matrix::use::b,
                                 TK, TN, BLAY> b[RN];
            for (int i = 0; i < RM; i++) {
                size_t off = ACOL ? (size_t)k * lda + m0 + i * TM
                                  : (m0 + i * TM) * (size_t)lda + k;
                matrix::joint_matrix_load(sg, a[i],
                    sycl::multi_ptr<const IN,
                                    sycl::access::address_space::global_space>(Ap + off),
                    lda);
            }
            for (int j = 0; j < RN; j++) {
                size_t off = BCOL ? (n0 + j * TN) * (size_t)ldb + k
                                  : (size_t)k * ldb + n0 + j * TN;
                matrix::joint_matrix_load(sg, b[j],
                    sycl::multi_ptr<const IN,
                                    sycl::access::address_space::global_space>(Bp + off),
                    ldb);
            }
            for (int i = 0; i < RM; i++)
                for (int j = 0; j < RN; j++)
                    matrix::joint_matrix_mad(sg, acc[i][j], a[i], b[j], acc[i][j]);
        }
        if constexpr (std::is_same_v<OUT, float>) {
            for (int i = 0; i < RM; i++)
                for (int j = 0; j < RN; j++)
                    matrix::joint_matrix_store(sg, acc[i][j],
                        sycl::multi_ptr<float, sycl::access::address_space::global_space>(
                            C + (m0 + i * TM) * (size_t)ldc + n0 + j * TN),
                        ldc, matrix::layout::row_major);
        } else {
            for (int i = 0; i < RM; i++)
                for (int j = 0; j < RN; j++) {
                    matrix::joint_matrix<sycl::sub_group, OUT,
                                         matrix::use::accumulator, TM, TN> o16;
                    matrix::joint_matrix_copy(sg, acc[i][j], o16);
                    matrix::joint_matrix_store(sg, o16,
                        sycl::multi_ptr<OUT, sycl::access::address_space::global_space>(
                            C + (m0 + i * TM) * (size_t)ldc + n0 + j * TN),
                        ldc, matrix::layout::row_major);
                }
        }
    };
    sycl::nd_range<1> nr(groups * (SG * NSG), SG * NSG);
    if constexpr (GRF == 256) {
        _Pragma("GCC diagnostic push")
        _Pragma("GCC diagnostic ignored \"-Wdeprecated-declarations\"")
        sycl::ext::oneapi::experimental::properties props{
            sycl::ext::oneapi::experimental::sub_group_size<SG>,
            sycl::ext::intel::experimental::grf_size<256>};
        q.parallel_for(nr, props, [=](sycl::nd_item<1> it) { body(it); }).wait();
        _Pragma("GCC diagnostic pop")
    } else {
        q.parallel_for(nr,
            [=](sycl::nd_item<1> it) [[sycl::reqd_sub_group_size(SG)]] { body(it); }).wait();
    }
}
static int slab_width(int N, int K, size_t elem) {
    long long w = (long long)(8u << 20) / ((long long)K * (long long)elem);
    w = w / 64 * 64;
    if (w < 64) w = 64;
    if (w > N) w = N;
    return (int)w;
}
constexpr int MAD_H_CANDIDATES = 16;
static bool mad_h_fits(int idx, int M, int N) {
    static const int rm[] = {8, 2, 4, 4, 2, 8, 2, 4, 4, 2, 1, 1, 4, 4, 4, 4};
    static const int rn[] = {2, 4, 2, 4, 2, 2, 4, 2, 4, 2, 1, 1, 4, 4, 4, 4};
    return M % (TM * rm[idx]) == 0 && N % (TN * rn[idx]) == 0;
}
template <typename IN, typename OUT, bool ACOL, bool BCOL>
static void mad_h_by_index(int idx, sycl::queue &q, int M, int N, int K,
                           const IN *Ap, int lda, const IN *Bp,
                           int ldb, OUT *C, int ldc, int sw) {
    switch (idx) {
    case 0:  mad_h<IN, OUT, 8, 2, 128, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 1:  mad_h<IN, OUT, 2, 4, 128, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 2:  mad_h<IN, OUT, 4, 2, 128, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 3:  mad_h<IN, OUT, 4, 4, 128, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 4:  mad_h<IN, OUT, 2, 2, 128, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 5:  mad_h<IN, OUT, 8, 2, 256, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 6:  mad_h<IN, OUT, 2, 4, 256, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 7:  mad_h<IN, OUT, 4, 2, 256, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 8:  mad_h<IN, OUT, 4, 4, 256, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 9:  mad_h<IN, OUT, 2, 2, 256, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 10: mad_h<IN, OUT, 1, 1, 256, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 11: mad_h<IN, OUT, 1, 1, 128, ACOL, BCOL>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 12: mad_h<IN, OUT, 4, 4, 128, ACOL, BCOL, 2, 2>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 13: mad_h<IN, OUT, 4, 4, 128, ACOL, BCOL, 2, 4>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    case 14: mad_h<IN, OUT, 4, 4, 128, ACOL, BCOL, 4, 1>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    default: mad_h<IN, OUT, 4, 4, 128, ACOL, BCOL, 4, 2>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc, sw); break;
    }
}
struct BlockingCache {
    std::map<MadShape, int> map;
    bool loaded = false;
    std::string path;
    void open_once() {
        if (loaded) return;
        loaded = true;
        const char *xdg = std::getenv("XDG_CACHE_HOME");
        const char *home = std::getenv("HOME");
        if (xdg && *xdg) path = std::string(xdg) + "/zlift";
        else if (home && *home) path = std::string(home) + "/.cache/zlift";
        else return;
        std::error_code ec;
        std::filesystem::create_directories(path, ec);
        path += "/blocking";
        if (std::FILE *f = std::fopen(path.c_str(), "r")) {
            MadShape k{};
            int pick;
            while (std::fscanf(f, "%d %d %d %d %d %d", &k.m, &k.n, &k.k,
                               &k.passes, &k.elem, &pick) == 6) {
                if (pick >= 0 && pick < 2 * MAD_H_CANDIDATES) map.emplace(k, pick);
            }
            std::fclose(f);
        }
    }
    void put(const MadShape &k, int pick) {
        map.emplace(k, pick);
        if (path.empty()) return;
        if (std::FILE *f = std::fopen(path.c_str(), "a")) {
            std::fprintf(f, "%d %d %d %d %d %d\n", k.m, k.n, k.k, k.passes,
                         k.elem, pick);
            std::fclose(f);
        }
    }
};
static BlockingCache &blockings() {
    static BlockingCache c;
    static std::mutex m;
    std::lock_guard<std::mutex> g(m);
    c.open_once();
    return c;
}
template <typename IN, typename OUT, bool ACOL, bool BCOL>
static void mad_h_pick(sycl::queue &q, int M, int N, int K,
                       const IN *Ap, int lda, const IN *Bp,
                       int ldb, OUT *C, int ldc) {
    Timed _t("gemm 16-bit");
    auto &best = blockings().map;
    static const bool autotune = std::getenv("ZBLAS_NO_AUTOTUNE") == nullptr;
    MadShape key{M, N, K, 1,
                 400 + (ACOL ? 1 : 0) + (BCOL ? 2 : 0)
                     + (std::is_same_v<OUT, float> ? 4 : 0)
                     + (std::is_same_v<IN, bf16> ? 8 : 0)};
    const int sw = slab_width(N, K, sizeof(IN));
    auto it = best.find(key);
    if (it == best.end()) {
        int pick = MAD_H_CANDIDATES - 1;
        if (autotune) {
            auto trial = [&](int i, int w) {
                double t_i = 1e30;
                for (int rep = 0; rep < 3; rep++) {
                    auto t0 = std::chrono::steady_clock::now();
                    mad_h_by_index<IN, OUT, ACOL, BCOL>(i, q, M, N, K, Ap, lda,
                                                        Bp, ldb, C, ldc, w);
                    double dt = std::chrono::duration<double>(
                        std::chrono::steady_clock::now() - t0).count();
                    if (dt < t_i) t_i = dt;
                }
                return t_i;
            };
            double best_t = 1e30;
            for (int i = 0; i < MAD_H_CANDIDATES; i++) {
                if (!mad_h_fits(i, M, N)) continue;
                double t_i = trial(i, sw);
                if (t_i < best_t) { best_t = t_i; pick = i; }
            }
            if (best_t < 1e30 && trial(pick, 0) < best_t) pick += MAD_H_CANDIDATES;
        } else {
            for (int i = 0; i < MAD_H_CANDIDATES; i++)
                if (mad_h_fits(i, M, N)) { pick = i; break; }
        }
        blockings().put(key, pick);
        it = best.find(key);
        if (tracing()) {
            static const char *name[] = {"8x2","2x4","4x2","4x4","2x2",
                "8x2/grf256","2x4/grf256","4x2/grf256","4x4/grf256","2x2/grf256",
                "1x1/grf256","1x1",
                "4x4 wg2x2","4x4 wg2x4","4x4 wg4x1","4x4 wg4x2"};
            std::fprintf(stderr, "[zblas] %s blocking %s %s for %dx%dx%d a%s b%s\n",
                         std::is_same_v<IN, bf16> ? "bf16" : "f16",
                         name[pick % MAD_H_CANDIDATES],
                         pick < MAD_H_CANDIDATES ? "slab" : "n-fast",
                         M, N, K, ACOL ? "T" : "N", BCOL ? "T" : "N");
        }
    }
    mad_h_by_index<IN, OUT, ACOL, BCOL>(it->second % MAD_H_CANDIDATES, q, M, N, K,
                                        Ap, lda, Bp, ldb, C, ldc,
                                        it->second < MAD_H_CANDIDATES ? sw : 0);
}
template <typename IN>
static void stage_tight(sycl::queue &q, const IN *src, int ld, int rows,
                        int cols, IN *dst) {
    Timed _t("stage transpose");
    constexpr int T = 32, V = 4;
    const size_t gc = (size_t)((cols + T - 1) / T) * T;
    const size_t gr = (size_t)((rows + T - 1) / T) * (T / V);
    q.parallel_for(sycl::nd_range<2>({gc, gr}, {T, T / V}), [=](sycl::nd_item<2> it) {
        auto grp = it.get_group();
        auto tile = sycl::ext::oneapi::group_local_memory_for_overwrite<IN[T][T + V]>(grp);
        const int c0 = (int)it.get_group(0) * T, r0 = (int)it.get_group(1) * T;
        const int lc = (int)it.get_local_id(0), lv = (int)it.get_local_id(1);
        {
            const int r = r0 + lv * V;
            if (c0 + lc < cols && r + V <= rows) {
                const IN *p = src + (size_t)(c0 + lc) * ld + r;
#pragma unroll
                for (int v = 0; v < V; v++) (*tile)[lc][lv * V + v] = p[v];
            } else if (c0 + lc < cols) {
                for (int v = 0; v < V && r + v < rows; v++)
                    (*tile)[lc][lv * V + v] = src[(size_t)(c0 + lc) * ld + r + v];
            }
        }
        sycl::group_barrier(grp);
        {
            const int c = c0 + lv * V;
            if (r0 + lc < rows && c + V <= cols) {
                IN *p = dst + (size_t)(r0 + lc) * cols + c;
#pragma unroll
                for (int v = 0; v < V; v++) p[v] = (*tile)[lv * V + v][lc];
            } else if (r0 + lc < rows) {
                for (int v = 0; v < V && c + v < cols; v++)
                    dst[(size_t)(r0 + lc) * cols + c + v] = (*tile)[lv * V + v][lc];
            }
        }
    }).wait();
}
template <typename IN, typename OUT>
static void mad_h_dispatch(sycl::queue &q, int M, int N, int K,
                           const IN *Ap, int lda, bool acol,
                           const IN *Bp, int ldb, bool bcol,
                           OUT *C, int ldc) {
    static const bool stage = std::getenv("ZBLAS_NO_STAGE") == nullptr;
    static Scratch sa, sb;
    if (stage && bcol) {
        IN *Bs = reinterpret_cast<IN *>(sb.get(q, (size_t)K * N * sizeof(IN)));
        stage_tight(q, Bp, ldb, K, N, Bs);
        Bp = Bs; ldb = N; bcol = false;
    }
    if (stage && acol) {
        IN *As = reinterpret_cast<IN *>(sa.get(q, (size_t)M * K * sizeof(IN)));
        stage_tight(q, Ap, lda, M, K, As);
        Ap = As; lda = K; acol = false;
    }
    if (acol) {
        if (bcol) mad_h_pick<IN, OUT, true, true>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc);
        else      mad_h_pick<IN, OUT, true, false>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc);
    } else {
        if (bcol) mad_h_pick<IN, OUT, false, true>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc);
        else      mad_h_pick<IN, OUT, false, false>(q, M, N, K, Ap, lda, Bp, ldb, C, ldc);
    }
}
struct FmhaParams {
    const void *query_ptr;
    const void *key_ptr;
    const void *value_ptr;
    const void *attn_bias_ptr;
    const void *seqstart_q_ptr;
    const void *seqstart_k_ptr;
    const void *seqlen_k_ptr;
    unsigned causal_diagonal_offset;
    void *output_ptr;
    void *output_accum_ptr;
    void *logsumexp_ptr;
    int window_size;
    float scale;
    int head_dim;
    int head_dim_value;
    int num_queries;
    int num_keys;
    int num_keys_absolute;
    unsigned char custom_mask_type;
    int q_strideM;
    int k_strideM;
    int v_strideM;
    int bias_strideM;
    int o_strideM;
    int q_strideH;
    int k_strideH;
    int v_strideH;
    long long bias_strideH;
    long long q_strideB;
    long long k_strideB;
    long long v_strideB;
    long long bias_strideB;
    int num_batches;
    int num_heads;
    bool use_dropout;
};
static_assert(offsetof(FmhaParams, output_ptr) == 64, "fmha Params layout");
static_assert(offsetof(FmhaParams, scale) == 92, "fmha Params layout");
static_assert(offsetof(FmhaParams, num_queries) == 104, "fmha Params layout");
static_assert(offsetof(FmhaParams, custom_mask_type) == 116, "fmha Params layout");
static_assert(offsetof(FmhaParams, q_strideM) == 120, "fmha Params layout");
static_assert(offsetof(FmhaParams, bias_strideH) == 152, "fmha Params layout");
static_assert(offsetof(FmhaParams, num_batches) == 192, "fmha Params layout");
static_assert(offsetof(FmhaParams, use_dropout) == 200, "fmha Params layout");
struct AttnDesc {
    const void *q, *k, *v;
    void *o;
    const void *bias;          
    long long qb, qh, qr;      
    long long kb, kh, kr;
    long long vb, vh, vr;
    long long ob, oh, orr;
    long long bb, bh, br;
    int batches, heads, kv_ratio;
    int sq, sk, d;
    float scale;
    bool causal;
    int diag;
};
struct FlashParams {
    void *q_ptr, *k_ptr, *v_ptr;                              
    long long q_batch_stride, k_batch_stride, v_batch_stride; 
    long long q_row_stride, k_row_stride, v_row_stride;       
    long long q_head_stride, k_head_stride, v_head_stride;    
    int h, h_k, h_h_k_ratio;                                  
    void *o_ptr, *oaccum_ptr;                                 
    long long o_batch_stride, o_row_stride, o_head_stride;    
    void *p_ptr;                                              
    void *softmax_lse_ptr, *softmax_lseaccum_ptr;             
    int b, seqlen_q, seqlen_k, seqlen_knew, d;                
    int seqlen_q_rounded, seqlen_k_rounded, d_rounded;        
    int rotary_dim, total_q;                                  
    float scale_softmax, scale_softmax_log2;                  
    unsigned char rest[148];                                  
    float p_dropout;                                          
    unsigned char p_dropout_in_uint8_t;                       
    float rp_dropout;                                         
    float scale_softmax_rp_dropout;                           
    int window_size_left, window_size_right;                  
};
static_assert(offsetof(FlashParams, h) == 96, "flash Params layout");
static_assert(offsetof(FlashParams, o_ptr) == 112, "flash Params layout");
static_assert(offsetof(FlashParams, p_ptr) == 152, "flash Params layout");
static_assert(offsetof(FlashParams, b) == 176, "flash Params layout");
static_assert(offsetof(FlashParams, scale_softmax) == 216, "flash Params layout");
static_assert(offsetof(FlashParams, rest) == 224, "flash Params layout");
static_assert(offsetof(FlashParams, p_dropout) == 372, "flash Params layout");
static_assert(offsetof(FlashParams, rp_dropout) == 380, "flash Params layout");
static_assert(offsetof(FlashParams, window_size_left) == 388, "flash Params layout");
template <typename T>
static auto gp(T *p) {
    return sycl::multi_ptr<T, sycl::access::address_space::global_space>(p);
}
template <typename T>
static auto lp(T *p) {
    return sycl::multi_ptr<T, sycl::access::address_space::local_space>(p);
}
static void fmha_f32(sycl::queue &q, const AttnDesc &p, float *scores) {
    const int S = p.sk, D = p.d, M = p.sq;
    const float scale = p.scale;
    auto *Qb = static_cast<const float *>(p.q);
    auto *Kb = static_cast<const float *>(p.k);
    auto *Vb = static_cast<const float *>(p.v);
    auto *Ob = static_cast<float *>(p.o);
    auto *Bb = static_cast<const float *>(p.bias);
    const long long qsB = p.qb, qsH = p.qh, qsM = p.qr;
    const long long ksB = p.kb, ksH = p.kh, ksM = p.kr;
    const long long vsB = p.vb, vsH = p.vh, vsM = p.vr;
    const long long osB = p.ob, osH = p.oh, osM = p.orr;
    const long long bsB = p.bb, bsH = p.bh, bsM = p.br;
    const int kvr = p.kv_ratio, H = p.heads;
    const bool causal = p.causal;
    const int diag = p.diag;
    q.parallel_for(sycl::range<3>(p.batches, H, M), [=](sycl::id<3> id) {
        const int b = (int)id[0], h = (int)id[1], i = (int)id[2];
        const int hk = h / kvr;
        const float *Q = Qb + b * qsB + h * qsH + (long long)i * qsM;
        const float *K = Kb + b * ksB + hk * ksH;
        const float *V = Vb + b * vsB + hk * vsH;
        const float *B = Bb ? Bb + b * bsB + h * bsH + (long long)i * bsM : nullptr;
        float *O = Ob + b * osB + h * osH + (long long)i * osM;
        float *row = scores + (((size_t)b * H + h) * M + i) * S;
        float mx = -INFINITY;
        for (int j = 0; j < S; j++) {
            float acc = 0.f;
            const float *Kj = K + (long long)j * ksM;
            for (int d = 0; d < D; d++) acc += Q[d] * Kj[d];
            acc *= scale;
            if (B) acc += B[j];
            if (causal && j > i + diag) acc = -INFINITY;
            row[j] = acc;
            mx = sycl::fmax(mx, acc);
        }
        float sum = 0.f;
        for (int j = 0; j < S; j++) {
            float e = mx == -INFINITY ? 0.f : sycl::exp(row[j] - mx);
            row[j] = e;
            sum += e;
        }
        float inv = sum > 0.f ? 1.f / sum : 0.f;
        for (int d = 0; d < D; d++) O[d] = 0.f;
        for (int j = 0; j < S; j++) {
            float w = row[j] * inv;
            if (w == 0.f) continue;
            const float *Vj = V + (long long)j * vsM;
            for (int d = 0; d < D; d++) O[d] += w * Vj[d];
        }
    }).wait();
}
template <typename JM, typename F>
static inline void row_apply(sycl::sub_group sg, JM &m, F f) {
    auto wi = sycl::ext::oneapi::detail::get_wi_data(sg, m);
#pragma unroll
    for (int r = 0; r < TM; r++) {
        float x = float(wi[r]);
        f(x, r);
        wi[r] = x;
    }
}
static bool fragment_layout_ok(sycl::queue &q) {
    static int cached = -1;
    if (cached >= 0) return cached != 0;
    int *ok = sycl::malloc_shared<int>(1, q);
    if (!ok) return false;
    *ok = 1;
    q.parallel_for(sycl::nd_range<1>(SG, SG), [=](sycl::nd_item<1> it)
        [[sycl::reqd_sub_group_size(SG)]] {
        auto sg = it.get_sub_group();
        const int lane = (int)sg.get_local_linear_id();
        matrix::joint_matrix<sycl::sub_group, float, matrix::use::accumulator,
                             TM, TN> acc;
        matrix::joint_matrix_fill(sg, acc, 0.f);
        {
            auto wi = sycl::ext::oneapi::detail::get_wi_data(sg, acc);
            if ((int)wi.length() != TM) { *ok = 0; return; }
        }
        sycl::ext::intel::experimental::matrix::joint_matrix_apply(sg, acc,
            [&](float &x, size_t row, size_t col) {
                if ((int)col != lane) *ok = 0;
                x = float(row);
            });
        auto wi = sycl::ext::oneapi::detail::get_wi_data(sg, acc);
        for (int r = 0; r < TM; r++)
            if (float(wi[r]) != float(r)) *ok = 0;
        matrix::joint_matrix<sycl::sub_group, bf16, matrix::use::a, TM, TK,
                             matrix::layout::row_major> a;
        matrix::joint_matrix_copy(sg, acc, a);
        auto wa = sycl::ext::oneapi::detail::get_wi_data(sg, a);
        if ((int)wa.length() != TM) { *ok = 0; return; }
        for (int r = 0; r < TM; r++)
            if (float(bf16(wa[r])) != float(r)) *ok = 0;
    }).wait();
    cached = *ok;
    sycl::free(ok, q);
    return cached != 0;
}
template <typename IN, int BN, int DV, int GRF, int SMG = 16>
static void fmha_run(sycl::queue &q, const AttnDesc &p) {
    constexpr int BM = TM;
    constexpr int NS = BN / TN;   
    constexpr int RV = DV / TN;   
    const int M = p.sq, S = p.sk, D = p.d;
    const float scale = p.scale;
    auto *Qb = static_cast<const IN *>(p.q);
    auto *Kb = static_cast<const IN *>(p.k);
    auto *Vb = static_cast<const IN *>(p.v);
    auto *Ob = static_cast<IN *>(p.o);
    auto *Bb = static_cast<const IN *>(p.bias);
    const long long qsM = p.qr, ksM = p.kr, vsM = p.vr, osM = p.orr;
    const long long qsH = p.qh, ksH = p.kh, vsH = p.vh, osH = p.oh;
    const long long qsB = p.qb, ksB = p.kb, vsB = p.vb, osB = p.ob;
    const long long bsB = p.bb, bsH = p.bh, bsM = p.br;
    const int kvr = p.kv_ratio;
    const bool causal = p.causal;
    const int diag = p.diag;
    const int nblocks = (M / BM + SMG - 1) / SMG;
    sycl::range<3> global((size_t)p.batches, (size_t)p.heads,
                          (size_t)nblocks * SG * SMG);
    sycl::range<3> local(1, 1, (size_t)SG * SMG);
    auto body = [=](sycl::nd_item<3> it) {
        auto sg = it.get_sub_group();
        const int b = (int)it.get_group(0), h = (int)it.get_group(1);
        const int m0 = ((int)it.get_group(2) * SMG
                        + (SMG == 1 ? 0 : (int)sg.get_group_linear_id())) * BM;
        if (m0 >= M) return;
        const int lane = (int)sg.get_local_linear_id();
        const int hk = h / kvr;
        const IN *Q = Qb + b * qsB + h * qsH + (size_t)m0 * qsM;
        const IN *K = Kb + b * ksB + hk * ksH;
        const IN *V = Vb + b * vsB + hk * vsH;
        IN *O = Ob + b * osB + h * osH + (size_t)m0 * osM;
        const IN *Bias = Bb ? Bb + b * bsB + h * bsH + (size_t)m0 * bsM : nullptr;
        using AFrag = matrix::joint_matrix<sycl::sub_group, IN, matrix::use::a,
                                           TM, TK, matrix::layout::row_major>;
        using Acc = matrix::joint_matrix<sycl::sub_group, float,
                                         matrix::use::accumulator, TM, TN>;
        const int kend = causal
            ? sycl::min(S, (m0 + BM - 1 + diag + BN) / BN * BN)
            : S;
        Acc ov[RV];
#pragma unroll
        for (int j = 0; j < RV; j++) matrix::joint_matrix_fill(sg, ov[j], 0.f);
        float mi[TM], li[TM];
#pragma unroll
        for (int r = 0; r < TM; r++) { mi[r] = -INFINITY; li[r] = 0.f; }
        for (int k0 = 0; k0 < kend; k0 += BN) {
            Acc acc[NS];
#pragma unroll
            for (int j = 0; j < NS; j++) matrix::joint_matrix_fill(sg, acc[j], 0.f);
            for (int d = 0; d < D; d += TK) {
                AFrag a;
                matrix::joint_matrix_load(sg, a, gp(Q + d), qsM);
                matrix::joint_matrix<sycl::sub_group, IN, matrix::use::b,
                                     TK, TN, matrix::layout::col_major> kb[NS];
#pragma unroll
                for (int j = 0; j < NS; j++)
                    matrix::joint_matrix_load(sg, kb[j],
                        gp(K + (size_t)(k0 + j * TN) * ksM + d), ksM);
#pragma unroll
                for (int j = 0; j < NS; j++)
                    matrix::joint_matrix_mad(sg, acc[j], a, kb[j], acc[j]);
            }
            float mx[TM];
#pragma unroll
            for (int r = 0; r < TM; r++) mx[r] = mi[r];
#pragma unroll
            for (int j = 0; j < NS; j++) {
                const int key = k0 + j * TN + lane;
                row_apply(sg, acc[j], [&](float &x, int r) {
                    float v = x * scale;
                    if (Bias) v += (float)Bias[(size_t)r * bsM + key];
                    if (causal && key > m0 + r + diag) v = -INFINITY;
                    x = v;
                    mx[r] = sycl::fmax(mx[r], v);
                });
            }
#pragma unroll
            for (int r = 0; r < TM; r++)
                mx[r] = sycl::reduce_over_group(sg, mx[r], sycl::maximum<float>());
            float sum[TM];
#pragma unroll
            for (int r = 0; r < TM; r++) sum[r] = 0.f;
#pragma unroll
            for (int j = 0; j < NS; j++)
                row_apply(sg, acc[j], [&](float &x, int r) {
                    float e = mx[r] == -INFINITY ? 0.f : sycl::native::exp(x - mx[r]);
                    x = e;
                    sum[r] += e;
                });
#pragma unroll
            for (int r = 0; r < TM; r++)
                sum[r] = sycl::reduce_over_group(sg, sum[r], sycl::plus<float>());
            float corr[TM];
#pragma unroll
            for (int r = 0; r < TM; r++) {
                corr[r] = mi[r] == -INFINITY ? 0.f : sycl::native::exp(mi[r] - mx[r]);
                li[r] = li[r] * corr[r] + sum[r];
                mi[r] = mx[r];
            }
#pragma unroll
            for (int j = 0; j < RV; j++)
                row_apply(sg, ov[j], [&](float &x, int r) { x *= corr[r]; });
#pragma unroll
            for (int c = 0; c < NS; c++) {
                AFrag pa;
                matrix::joint_matrix_copy(sg, acc[c], pa);
                matrix::joint_matrix<sycl::sub_group, IN, matrix::use::b,
                                     TK, TN, matrix::layout::row_major> vb[RV];
#pragma unroll
                for (int j = 0; j < RV; j++)
                    matrix::joint_matrix_load(sg, vb[j],
                        gp(V + (size_t)(k0 + c * TK) * vsM + j * TN), vsM);
#pragma unroll
                for (int j = 0; j < RV; j++)
                    matrix::joint_matrix_mad(sg, ov[j], pa, vb[j], ov[j]);
            }
        }
        float inv[TM];
#pragma unroll
        for (int r = 0; r < TM; r++) inv[r] = li[r] > 0.f ? 1.f / li[r] : 0.f;
#pragma unroll
        for (int j = 0; j < RV; j++) {
            row_apply(sg, ov[j], [&](float &x, int r) { x *= inv[r]; });
            matrix::joint_matrix<sycl::sub_group, IN, matrix::use::accumulator,
                                 TM, TN> o16;
            matrix::joint_matrix_copy(sg, ov[j], o16);
            matrix::joint_matrix_store(sg, o16, gp(O + j * TN), osM,
                                       matrix::layout::row_major);
        }
    };
    sycl::nd_range<3> nr(global, local);
    if constexpr (GRF == 256) {
        _Pragma("GCC diagnostic push")
        _Pragma("GCC diagnostic ignored \"-Wdeprecated-declarations\"")
        sycl::ext::oneapi::experimental::properties props{
            sycl::ext::oneapi::experimental::sub_group_size<SG>,
            sycl::ext::intel::experimental::grf_size<256>};
        q.parallel_for(nr, props, [=](sycl::nd_item<3> it) { body(it); }).wait();
        _Pragma("GCC diagnostic pop")
    } else {
        q.parallel_for(nr, [=](sycl::nd_item<3> it)
            [[sycl::reqd_sub_group_size(SG)]] { body(it); }).wait();
    }
}
enum { EPI_BIAS = 1, EPI_RELU = 2, EPI_GELU = 4 };
static void epilogue(sycl::queue &q, void *D, int type, int m, int n, int ldd,
                     const void *bias, int bias_type, int flags) {
    Timed _t("epilogue");
    const bool half_out = type == 2 ;
    const bool half_bias = bias_type == 2;
    const bool bf_out = type == 14 ;
    const bool bf_bias = bias_type == 14;
    auto bf_to_f = [](unsigned short b) {
        unsigned u = (unsigned)b << 16;
        float f; __builtin_memcpy(&f, &u, 4); return f;
    };
    auto f_to_bf = [](float f) {
        unsigned u; __builtin_memcpy(&u, &f, 4);
        u += 0x7fffu + ((u >> 16) & 1u);
        return (unsigned short)(u >> 16);
    };
    const bool do_bias = (flags & EPI_BIAS) && bias != nullptr;
    const bool do_relu = flags & EPI_RELU;
    const bool do_gelu = flags & EPI_GELU;
    q.parallel_for(sycl::range<2>(n, m), [=](sycl::id<2> id) {
        size_t col = id[0], row = id[1];
        size_t at = row + col * (size_t)ldd;
        float v = half_out
            ? sycl::vec<sycl::half, 1>{reinterpret_cast<sycl::half *>(D)[at]}
                  .convert<float>()[0]
            : bf_out ? bf_to_f(reinterpret_cast<unsigned short *>(D)[at])
                     : reinterpret_cast<float *>(D)[at];
        if (do_bias) {
            v += half_bias
                ? sycl::vec<sycl::half, 1>{
                      reinterpret_cast<const sycl::half *>(bias)[row]}
                      .convert<float>()[0]
                : bf_bias ? bf_to_f(reinterpret_cast<const unsigned short *>(bias)[row])
                          : reinterpret_cast<const float *>(bias)[row];
        }
        if (do_relu && v < 0.0f) v = 0.0f;
        if (do_gelu) {
            const float c = 0.7978845608028654f;   
            v = 0.5f * v * (1.0f + sycl::tanh(c * (v + 0.044715f * v * v * v)));
        }
        if (bf_out)
            reinterpret_cast<unsigned short *>(D)[at] = f_to_bf(v);
        else if (half_out)
            reinterpret_cast<sycl::half *>(D)[at] =
                sycl::vec<float, 1>{v}.convert<sycl::half>()[0];
        else
            reinterpret_cast<float *>(D)[at] = v;
    }).wait();
}
}  
}  
extern "C" {
int zblas_gpu_ready(void) { return gpu().ok ? 1 : 0; }
namespace {
using EpochFn = unsigned long long (*)(const void *);
using WrittenFn = void (*)(const void *);
EpochFn epoch_fn() {
    static EpochFn fn = [] {
        if (void *p = dlsym(RTLD_DEFAULT, "zlift_buffer_epoch")) {
            return reinterpret_cast<EpochFn>(p);
        }
        for (const char *name : {"libcuda.so.1", "libcuda.so"}) {
            if (void *lib = dlopen(name, RTLD_NOW | RTLD_GLOBAL)) {
                if (void *p = dlsym(lib, "zlift_buffer_epoch")) {
                    return reinterpret_cast<EpochFn>(p);
                }
            }
        }
        return static_cast<EpochFn>(nullptr);
    }();
    return fn;
}
WrittenFn written_fn() {
    static WrittenFn fn = [] {
        if (void *p = dlsym(RTLD_DEFAULT, "zlift_buffer_written")) {
            return reinterpret_cast<WrittenFn>(p);
        }
        for (const char *name : {"libcuda.so.1", "libcuda.so"}) {
            if (void *lib = dlopen(name, RTLD_NOW | RTLD_GLOBAL)) {
                if (void *p = dlsym(lib, "zlift_buffer_written")) {
                    return reinterpret_cast<WrittenFn>(p);
                }
            }
        }
        return static_cast<WrittenFn>(nullptr);
    }();
    return fn;
}
constexpr unsigned long long EPOCH_UNKNOWN = ~0ull;
struct SplitKey {
    const float *src;
    int ld, rows, cols;
    bool row_major, want_lo;
    bool operator<(const SplitKey &o) const {
        return std::tie(src, ld, rows, cols, row_major, want_lo)
             < std::tie(o.src, o.ld, o.rows, o.cols, o.row_major, o.want_lo);
    }
};
struct SplitEntry {
    void *mem = nullptr;      
    size_t bytes = 0;
    unsigned long long used = 0;
    unsigned long long epoch = ~0ull;
};
constexpr size_t SPLIT_CACHE_BUDGET = 192u << 20;
struct SplitCache {
    std::map<SplitKey, SplitEntry> entries;
    size_t bytes = 0;
    unsigned long long clock = 0;
    xmx::bf16 *slot(sycl::queue &q, const SplitKey &k, size_t bytes_needed,
                    unsigned long long ep, bool &fresh, const void *keep) {
        auto it = entries.find(k);
        if (it != entries.end() && it->second.bytes >= bytes_needed) {
            it->second.used = ++clock;
            fresh = (it->second.epoch == ep);
            it->second.epoch = ep;
            return static_cast<xmx::bf16 *>(it->second.mem);
        }
        if (it != entries.end()) {          
            sycl::free(it->second.mem, q);
            bytes -= it->second.bytes;
            entries.erase(it);
        }
        while (bytes + bytes_needed > SPLIT_CACHE_BUDGET && !entries.empty()) {
            auto oldest = entries.end();
            for (auto i = entries.begin(); i != entries.end(); ++i) {
                if (i->second.mem == keep) continue;
                if (oldest == entries.end() || i->second.used < oldest->second.used) {
                    oldest = i;
                }
            }
            if (oldest == entries.end()) break;
            sycl::free(oldest->second.mem, q);
            bytes -= oldest->second.bytes;
            entries.erase(oldest);
        }
        void *mem = sycl::malloc_device(bytes_needed, q);
        if (!mem) return nullptr;
        bytes += bytes_needed;
        entries[k] = SplitEntry{mem, bytes_needed, ++clock, ep};
        fresh = false;
        return static_cast<xmx::bf16 *>(mem);
    }
};
}  
int zblas_gpu_gemm_ex_f16(int transa, int transb, int m, int n, int k,
                          float alpha, const void *A, int lda,
                          const void *B, int ldb, float beta,
                          void *C, int ldc, int c_is_half) {
    if (n % xmx::TM || m % xmx::TN || k % xmx::TK) {
        if (tracing()) std::fprintf(stderr,
            "[zblas] f16 declined: shape %dx%dx%d\n", m, n, k);
        return 1;
    }
    if (alpha != 1.0f || beta != 0.0f) {
        if (tracing()) std::fprintf(stderr,
            "[zblas] f16 declined: alpha %g beta %g\n", alpha, beta);
        return 1;
    }
    if ((size_t)m * n * k < (size_t)64 * 64 * 64) {
        if (tracing()) std::fprintf(stderr, "[zblas] f16 declined: too small\n");
        return 1;
    }
    int rc = run([&](Gpu &g) {
        if (!usm_here(g, {A, B, C})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        auto &q = *g.q;
        auto ha = static_cast<const sycl::half *>(A);
        auto hb = static_cast<const sycl::half *>(B);
        if (c_is_half) {
            xmx::mad_h_dispatch<sycl::half, sycl::half>(
                q, n, m, k, hb, ldb, transb != CUBLAS_OP_N_,
                ha, lda, transa != CUBLAS_OP_N_,
                static_cast<sycl::half *>(C), ldc);
        } else {
            xmx::mad_h_dispatch<sycl::half, float>(
                q, n, m, k, hb, ldb, transb != CUBLAS_OP_N_,
                ha, lda, transa != CUBLAS_OP_N_,
                static_cast<float *>(C), ldc);
        }
        if (WrittenFn wf = written_fn()) wf(C);
        if (tracing()) {
            std::fprintf(stderr, "[zblas] XMX f16 %dx%dx%d -> %s\n",
                         m, n, k, c_is_half ? "f16" : "f32");
        }
    });
    if (rc != 0 && tracing()) {
        std::fprintf(stderr, "[zblas] f16 declined: run() returned %d\n", rc);
    }
    return rc;
}
int zblas_gpu_gemm_ex_bf16(int transa, int transb, int m, int n, int k,
                           float alpha, const void *A, int lda,
                           const void *B, int ldb, float beta,
                           void *C, int ldc, int c_is_bf16) {
    if (n % xmx::TM || m % xmx::TN || k % xmx::TK) {
        if (tracing()) std::fprintf(stderr,
            "[zblas] bf16 declined: shape %dx%dx%d\n", m, n, k);
        return 1;
    }
    if (alpha != 1.0f || beta != 0.0f) return 1;
    if ((size_t)m * n * k < (size_t)64 * 64 * 64) return 1;
    int rc = run([&](Gpu &g) {
        if (!usm_here(g, {A, B, C})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        auto &q = *g.q;
        auto ha = static_cast<const xmx::bf16 *>(A);
        auto hb = static_cast<const xmx::bf16 *>(B);
        if (c_is_bf16) {
            xmx::mad_h_dispatch<xmx::bf16, xmx::bf16>(
                q, n, m, k, hb, ldb, transb != CUBLAS_OP_N_,
                ha, lda, transa != CUBLAS_OP_N_,
                static_cast<xmx::bf16 *>(C), ldc);
        } else {
            xmx::mad_h_dispatch<xmx::bf16, float>(
                q, n, m, k, hb, ldb, transb != CUBLAS_OP_N_,
                ha, lda, transa != CUBLAS_OP_N_,
                static_cast<float *>(C), ldc);
        }
        if (WrittenFn wf = written_fn()) wf(C);
        if (tracing()) {
            std::fprintf(stderr, "[zblas] XMX bf16 %dx%dx%d -> %s\n",
                         m, n, k, c_is_bf16 ? "bf16" : "f32");
        }
    });
    if (rc != 0 && tracing()) {
        std::fprintf(stderr, "[zblas] bf16 declined: run() returned %d\n", rc);
    }
    return rc;
}
int zblas_gpu_sgemm_xmx(int transa, int transb, int m, int n, int k, float alpha,
                        const float *A, int lda, const float *B, int ldb,
                        float beta, float *C, int ldc, int tf32) {
    if (n % xmx::TM || m % xmx::TN || k % xmx::TK) return 1;
    if (alpha != 1.0f || beta != 0.0f) return 1;
    if ((size_t)m * n * k < (size_t)64 * 64 * 64) return 1;   
    return run([&](Gpu &g) {
        if (!usm_here(g, {A, B, C})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        auto &q = *g.q;
        static xmx::Scratch scratch;
        static SplitCache cache;
        static const bool cache_on = std::getenv("ZBLAS_NO_SPLIT_CACHE") == nullptr;
        size_t na = (size_t)n * k, nb = (size_t)k * m;
        int planes = tf32 ? 1 : 2;
        xmx::bf16 *base = scratch.get(q, (na + nb) * planes * sizeof(xmx::bf16));
        xmx::bf16 *Ah = base, *Al = base + na;
        xmx::bf16 *Bh = base + na * planes, *Bl = Bh + nb;
        const void *in_flight = nullptr;
        static unsigned long long cache_hits = 0, cache_calls = 0;
        auto split_cached = [&](const float *src, int ld, bool row_major,
                                int rows, int cols, xmx::bf16 *&hi,
                                xmx::bf16 *&lo, bool want_lo) {
            ++cache_calls;
            unsigned long long ep = EPOCH_UNKNOWN;
            if (cache_on) {
                if (EpochFn f = epoch_fn()) ep = f(src);
            }
            if (ep == EPOCH_UNKNOWN) {
                xmx::split_to_bf16(q, src, ld, row_major, rows, cols, hi, lo, want_lo);
                return;
            }
            SplitKey key{src, ld, rows, cols, row_major, want_lo};
            size_t words = (size_t)rows * cols * (want_lo ? 2 : 1);
            bool fresh = false;
            xmx::bf16 *mem = cache.slot(q, key, words * sizeof(xmx::bf16), ep,
                                        fresh, in_flight);
            if (!mem) {
                xmx::split_to_bf16(q, src, ld, row_major, rows, cols, hi, lo, want_lo);
                return;
            }
            hi = mem;
            if (want_lo) lo = mem + (size_t)rows * cols;
            in_flight = mem;
            if (fresh) {
                ++cache_hits;
                return;
            }
            xmx::split_to_bf16(q, src, ld, row_major, rows, cols, hi, lo, want_lo);
        };
        auto t0 = std::chrono::steady_clock::now();
        split_cached(B, ldb, transb == CUBLAS_OP_N_, n, k, Ah, Al, !tf32);
        split_cached(A, lda, transa == CUBLAS_OP_N_, k, m, Bh, Bl, !tf32);
        auto t1 = std::chrono::steady_clock::now();
        if (tf32) xmx::mad_dispatch<xmx::bf16, 1>(q, n, m, k, Ah, Al, Bh, Bl, C, ldc);
        else      xmx::mad_dispatch<xmx::bf16, 3>(q, n, m, k, Ah, Al, Bh, Bl, C, ldc);
        auto t2 = std::chrono::steady_clock::now();
        if (WrittenFn wf = written_fn()) wf(C);
        if (tracing()) {
            std::fprintf(stderr, "[zblas] split cache %llu/%llu\n",
                         cache_hits, cache_calls);
        }
        if (std::getenv("ZBLAS_TRACE_PTR")) {
            std::fprintf(stderr, "[zblas] operands A=%p(%dx%d,t%d) B=%p(%dx%d,t%d)\n",
                (const void *)B, n, k, transb != CUBLAS_OP_N_,
                (const void *)A, k, m, transa != CUBLAS_OP_N_);
        }
        if (tracing()) {
            std::fprintf(stderr, "[zblas] split %.3f ms  mad %.3f ms\n",
                std::chrono::duration<double>(t1-t0).count()*1e3,
                std::chrono::duration<double>(t2-t1).count()*1e3);
        }
        if (tracing()) {
            std::fprintf(stderr, "[zblas] XMX %s %dx%dx%d\n",
                         tf32 ? "1-pass" : "3-pass", m, n, k);
        }
    });
}
int zblas_gpu_epilogue(void *D, int type, int m, int n, int ldd,
                       const void *bias, int bias_type, int flags) {
    return run([&](Gpu &g) {
        if (!usm_here(g, {D})) {
            throw std::runtime_error("D is not USM in this context");
        }
        xmx::epilogue(*g.q, D, type, m, n, ldd, bias, bias_type, flags);
        if (tracing()) {
            std::fprintf(stderr, "[zblas] epilogue on GPU %dx%d flags=%d\n",
                         m, n, flags);
        }
    });
}
static void attn_dispatch(sycl::queue &q, const xmx::AttnDesc &d, int elem) {
    Timed _t("attention");
    if (elem == 2) {
        static xmx::Scratch scores;
        size_t n = (size_t)d.batches * d.heads * d.sq * d.sk;
        auto *buf = reinterpret_cast<float *>(scores.get(q, n * sizeof(float)));
        xmx::fmha_f32(q, d, buf);
        return;
    }
    if (!xmx::fragment_layout_ok(q)) {
        std::fprintf(stderr,
            "[zblas] WARNING attention declined: an 8x16 fragment on this "
            "device is not one column per lane, which the register kernel "
            "requires; the lifted kernel will answer it, and it is wrong\n");
        throw std::runtime_error("fragment layout not as this kernel requires");
    }
    const bool bf16 = elem == 1;
#define ATTN(T, BN, GRF)                                                      \
    do {                                                                      \
        if (d.d == 64) xmx::fmha_run<T, BN, 64, GRF>(q, d);                   \
        else           xmx::fmha_run<T, BN, 128, GRF>(q, d);                  \
    } while (0)
#define ATTN_BN(BN, GRF)                                                      \
    do {                                                                      \
        if (bf16) ATTN(xmx::bf16, BN, GRF);                                   \
        else      ATTN(sycl::half, BN, GRF);                                  \
    } while (0)
    if (d.sk % 96 == 0)      ATTN_BN(96, 128);
    else if (d.sk % 48 == 0) ATTN_BN(48, 128);
    else                     ATTN_BN(32, 256);
#undef ATTN_BN
#undef ATTN
}
static bool attn_tiles(const xmx::AttnDesc &d, const char *who, int elem) {
    constexpr int BM = xmx::TM, BN = 32;
    if (elem == 2) {
        size_t n = (size_t)d.batches * d.heads * d.sq * d.sk;
        if (n > (size_t)16 * 1024 * 1024) {
            std::fprintf(stderr,
                "[zblas] WARNING %s declined: %zu float score elements; the "
                "lifted kernel will answer it, and it is wrong\n", who, n);
            return false;
        }
        return true;
    }
    if (d.d % xmx::TK) {
        std::fprintf(stderr,
            "[zblas] WARNING %s declined: head_dim %d; the lifted kernel will "
            "answer it, and it is wrong\n", who, d.d);
        return false;
    }
    if (d.sq % BM || (d.sk % 48 && d.sk % BN)) {
        std::fprintf(stderr,
            "[zblas] WARNING %s declined: %d queries %d keys do not tile; the "
            "lifted kernel will answer it, and it is wrong\n", who, d.sq, d.sk);
        return false;
    }
    return true;
}
int zblas_gpu_fmha_f16(const void *params, unsigned bytes, int elem) {
    if (!params || bytes < sizeof(xmx::FmhaParams)) return 1;
    const auto &p = *static_cast<const xmx::FmhaParams *>(params);
    auto no = [&](const char *why) {
        if (tracing()) std::fprintf(stderr, "[zblas] fmha declined: %s\n", why);
        return 1;
    };
    if (!p.query_ptr || !p.key_ptr || !p.value_ptr || !p.output_ptr)
        return no("null operand");
    if (p.seqstart_q_ptr || p.seqstart_k_ptr || p.seqlen_k_ptr)
        return no("ragged batch");
    if (p.logsumexp_ptr) return no("logsumexp wanted");
    if (p.custom_mask_type > 2) return no("unknown mask type");
    if (p.window_size != 0) return no("sliding window");
    if (p.use_dropout) return no("dropout");
    if (p.num_batches <= 0 || p.num_heads <= 0 || p.num_queries <= 0
        || p.num_keys <= 0)
        return no("empty");
    if (p.head_dim != p.head_dim_value) return no("head_dim != head_dim_value");
    xmx::AttnDesc d{};
    d.q = p.query_ptr; d.k = p.key_ptr; d.v = p.value_ptr; d.o = p.output_ptr;
    d.qb = p.q_strideB; d.qh = p.q_strideH; d.qr = p.q_strideM;
    d.kb = p.k_strideB; d.kh = p.k_strideH; d.kr = p.k_strideM;
    d.vb = p.v_strideB; d.vh = p.v_strideH; d.vr = p.v_strideM;
    d.ob = (long long)p.num_queries * p.o_strideM;
    d.oh = p.head_dim_value;
    d.orr = p.o_strideM;
    d.bias = p.attn_bias_ptr;
    d.bb = p.bias_strideB; d.bh = p.bias_strideH; d.br = p.bias_strideM;
    d.batches = p.num_batches; d.heads = p.num_heads; d.kv_ratio = 1;
    d.sq = p.num_queries; d.sk = p.num_keys; d.d = p.head_dim;
    d.scale = p.scale;
    d.causal = p.custom_mask_type != 0;
    d.diag = p.custom_mask_type == 2 ? p.num_keys - p.num_queries : 0;
    if (!attn_tiles(d, "fmha", elem)) return 1;
    int rc = run([&](Gpu &g) {
        if (!usm_here(g, {d.q, d.k, d.v, d.o})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        attn_dispatch(*g.q, d, elem);
        if (WrittenFn wf = written_fn()) wf(d.o);
        if (tracing()) {
            std::fprintf(stderr,
                "[zblas] XMX attention %s %dx%d heads %d keys %d dim %d\n",
                elem == 2 ? "f32" : elem == 1 ? "bf16" : "f16",
                d.batches, d.sq, d.heads, d.sk, d.d);
        }
    });
    if (rc != 0 && tracing()) {
        std::fprintf(stderr, "[zblas] fmha declined: run() returned %d\n", rc);
    }
    return rc;
}
int zblas_gpu_flash_f16(const void *params, unsigned bytes, int elem) {
    if (!params || bytes < 448) return 1;
    auto *raw = static_cast<const unsigned char *>(params);
    const auto &p = *reinterpret_cast<const xmx::FlashParams *>(params);
    auto no = [&](const char *why) {
        if (tracing()) std::fprintf(stderr, "[zblas] flash declined: %s\n", why);
        return 1;
    };
    auto zeroes = [&](unsigned from, unsigned to) {
        for (unsigned i = from; i < to && i < bytes; i++)
            if (raw[i]) return false;
        return true;
    };
    if (!p.q_ptr || !p.k_ptr || !p.v_ptr || !p.o_ptr) return no("null operand");
    if (p.oaccum_ptr || p.p_ptr || p.softmax_lseaccum_ptr)
        return no("split-k or dropout mask");
    if (p.seqlen_knew || p.rotary_dim) return no("kv cache or rotary");
    const bool causal = raw[441] != 0;
    if (!causal && (p.window_size_left != -1 || p.window_size_right != -1))
        return no("local window");
    if (causal && p.window_size_right != 0) return no("local window");
    if (!zeroes(224, 372) || !zeroes(396, 440)) return no("a feature is set");
    if (p.p_dropout_in_uint8_t != 255) return no("dropout");
    if (p.p_dropout != 1.0f || p.rp_dropout != 1.0f) return no("dropout");
    if ((raw[440] != 0) != (elem == 1)) return no("dtype disagrees");
    if (p.b <= 0 || p.h <= 0 || p.seqlen_q <= 0 || p.seqlen_k <= 0)
        return no("empty");
    if (p.h_k <= 0 || p.h_h_k_ratio <= 0 || p.h != p.h_k * p.h_h_k_ratio)
        return no("head grouping");
    xmx::AttnDesc d{};
    d.q = p.q_ptr; d.k = p.k_ptr; d.v = p.v_ptr; d.o = p.o_ptr;
    d.qb = p.q_batch_stride; d.qh = p.q_head_stride; d.qr = p.q_row_stride;
    d.kb = p.k_batch_stride; d.kh = p.k_head_stride; d.kr = p.k_row_stride;
    d.vb = p.v_batch_stride; d.vh = p.v_head_stride; d.vr = p.v_row_stride;
    d.ob = p.o_batch_stride; d.oh = p.o_head_stride; d.orr = p.o_row_stride;
    d.batches = p.b; d.heads = p.h; d.kv_ratio = p.h_h_k_ratio;
    d.sq = p.seqlen_q; d.sk = p.seqlen_k; d.d = p.d;
    d.scale = p.scale_softmax;
    d.causal = causal;
    d.diag = causal ? p.seqlen_k - p.seqlen_q : 0;
    if (!attn_tiles(d, "flash", elem)) return 1;
    int rc = run([&](Gpu &g) {
        if (!usm_here(g, {d.q, d.k, d.v, d.o})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        attn_dispatch(*g.q, d, elem);
        if (WrittenFn wf = written_fn()) wf(d.o);
        if (tracing()) {
            std::fprintf(stderr,
                "[zblas] XMX flash %s %dx%d heads %d keys %d dim %d\n",
                elem == 2 ? "f32" : elem == 1 ? "bf16" : "f16",
                d.batches, d.sq, d.heads, d.sk, d.d);
        }
    });
    if (rc != 0 && tracing()) {
        std::fprintf(stderr, "[zblas] flash declined: run() returned %d\n", rc);
    }
    return rc;
}
int zblas_gpu_sgemm(int transa, int transb, int m, int n, int k, float alpha,
                    const float *A, int lda, const float *B, int ldb, float beta,
                    float *C, int ldc) {
    return run([&](Gpu &g) {
        if (!usm_here(g, {A, B, C})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        blas::gemm(*g.q, op_of(transa), op_of(transb), m, n, k, alpha, A, lda, B,
                   ldb, beta, C, ldc)
            .wait_and_throw();
    });
}
int zblas_gpu_dgemm(int transa, int transb, int m, int n, int k, double alpha,
                    const double *A, int lda, const double *B, int ldb,
                    double beta, double *C, int ldc) {
    return run([&](Gpu &g) {
        if (!usm_here(g, {A, B, C})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        blas::gemm(*g.q, op_of(transa), op_of(transb), m, n, k, alpha, A, lda, B,
                   ldb, beta, C, ldc)
            .wait_and_throw();
    });
}
int zblas_gpu_hgemm(int transa, int transb, int m, int n, int k, float alpha,
                    const void *A, int lda, const void *B, int ldb, float beta,
                    void *C, int ldc) {
    return run([&](Gpu &g) {
        if (!usm_here(g, {A, B, C})) {
            throw std::runtime_error("operands are not USM in this context");
        }
        blas::gemm(*g.q, op_of(transa), op_of(transb), m, n, k,
                   static_cast<sycl::half>(alpha),
                   reinterpret_cast<const sycl::half *>(A), lda,
                   reinterpret_cast<const sycl::half *>(B), ldb,
                   static_cast<sycl::half>(beta),
                   reinterpret_cast<sycl::half *>(C), ldc)
            .wait_and_throw();
    });
}
}  
