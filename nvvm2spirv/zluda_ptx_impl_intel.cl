// zluda_ptx_impl_intel — the Intel implementation of ZLUDA's PTX device library.
//
// ZLUDA's PTX front end lowers the instructions that are not a single LLVM
// operation into calls to `__zluda_ptx_impl_*`, and expects a backend-specific
// module to define them; `ptx/lib/zluda_ptx_impl.cpp` is the AMD one. This is
// the Intel one, so that `zoc --target intel` output links without any textual
// post-processing — which is what makes the whole PTX path usable from inside
// a CUDA driver, where shelling out to a rewriter is not an option.
//
// Most entry points are one line over an OpenCL builtin or over
// `zlift_devlib.cl`, which holds the primitives both this and the SASS path
// need. The few whose signatures OpenCL C cannot spell (a literal struct
// return) are appended as hand-written IR by `build_devlib.sh`.

#pragma OPENCL EXTENSION cl_khr_subgroups : enable
#pragma OPENCL EXTENSION cl_khr_fp16 : enable

uint __zlift_match_any_b32(uint);
uint __zlift_activemask(void);
uint __zlift_prmt_b32(uint, uint, uint);
uint __zlift_bfi_b32(uint, uint, uint, uint);
ulong __zlift_bfi_b64(ulong, ulong, uint, uint);
uint __zlift_bfe_u32(uint, uint, uint);
int __zlift_bfe_s32(int, uint, uint);
uint __zlift_vote_ballot(int);
int __zlift_elect_sync(void);
int __attribute__((overloadable)) intel_sub_group_shuffle(int, uint);
int __attribute__((overloadable)) intel_sub_group_shuffle_down(int, int, uint);
int __attribute__((overloadable)) intel_sub_group_shuffle_up(int, int, uint);
int __attribute__((overloadable)) intel_sub_group_shuffle_xor(int, uint);

#define INL __attribute__((always_inline))

// Special registers. PTX names the register family and passes the dimension;
// the OpenCL builtins take it the same way, so these are pure widening.
INL int __zluda_ptx_impl_sreg_tid(uchar d)    { return (int)get_local_id(d); }
INL int __zluda_ptx_impl_sreg_ntid(uchar d)   { return (int)get_local_size(d); }
INL int __zluda_ptx_impl_sreg_ctaid(uchar d)  { return (int)get_group_id(d); }
INL int __zluda_ptx_impl_sreg_nctaid(uchar d) { return (int)get_num_groups(d); }
INL int __zluda_ptx_impl_sreg_laneid(void) { return (int)get_sub_group_local_id(); }
INL int __zluda_ptx_impl_sreg_warpsize(void) { return 32; }

// Xe has no cluster hierarchy: a CTA is its own cluster of one.
INL int __zluda_ptx_impl_sreg_clusterid(uchar d)  { (void)d; return 0; }
INL int __zluda_ptx_impl_sreg_nclusterid(uchar d) { (void)d; return 1; }

// `bar.sync` names a barrier; OpenCL has exactly one per work-group, so the
// id is dropped and the fence covers both address spaces.
INL void __zluda_ptx_impl_bar_sync(int id) {
    (void)id;
    barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
}

INL uint __zluda_ptx_impl_activemask(void) { return __zlift_activemask(); }

INL uint __zluda_ptx_impl_match_any_sync_b32(uint value, uint membermask) {
    (void)membermask;
    return __zlift_match_any_b32(value);
}

INL uint __zluda_ptx_impl_prmt_b32(uint x, uint y, uint s) {
    return __zlift_prmt_b32(x, y, s);
}

INL uint __zluda_ptx_impl_bfi_b32(uint insert, uint base, uint pos, uint len) {
    return __zlift_bfi_b32(insert, base, pos, len);
}
INL ulong __zluda_ptx_impl_bfi_b64(ulong insert, ulong base, uint pos, uint len) {
    return __zlift_bfi_b64(insert, base, pos, len);
}
INL uint __zluda_ptx_impl_bfe_u32(uint v, uint pos, uint len) {
    return __zlift_bfe_u32(v, pos, len);
}
INL int __zluda_ptx_impl_bfe_s32(int v, uint pos, uint len) {
    return __zlift_bfe_s32(v, pos, len);
}

// PTX `.approx` maths against OpenCL `native_*`: both sides are explicitly
// low-precision, so this is like for like rather than a downgrade.
INL float __zluda_ptx_impl_rcp_approx_f32(float x)   { return native_recip(x); }
INL float __zluda_ptx_impl_rsqrt_approx_f32(float x) { return native_rsqrt(x); }
INL float __zluda_ptx_impl_ex2_approx_f32(float x)   { return native_exp2(x); }
INL float __zluda_ptx_impl_lg2_approx_f32(float x)   { return native_log2(x); }
INL float __zluda_ptx_impl_sin_approx_f32(float x)   { return native_sin(x); }
INL float __zluda_ptx_impl_cos_approx_f32(float x)   { return native_cos(x); }
INL float __zluda_ptx_impl_sqrt_rn_f32(float x)      { return sqrt(x); }

// Sub-group reductions. PTX's member mask is dropped, matching the pinned
// full-warp assumption the sub-group size metadata makes.
INL int  __zluda_ptx_impl_redux_sync_add_s32(int v, uint m)  { (void)m; return sub_group_reduce_add(v); }
INL int  __zluda_ptx_impl_redux_sync_min_s32(int v, uint m)  { (void)m; return sub_group_reduce_min(v); }
INL int  __zluda_ptx_impl_redux_sync_max_s32(int v, uint m)  { (void)m; return sub_group_reduce_max(v); }
INL uint __zluda_ptx_impl_redux_sync_add_u32(uint v, uint m) { (void)m; return sub_group_reduce_add(v); }
INL uint __zluda_ptx_impl_redux_sync_min_u32(uint v, uint m) { (void)m; return sub_group_reduce_min(v); }
INL uint __zluda_ptx_impl_redux_sync_max_u32(uint v, uint m) { (void)m; return sub_group_reduce_max(v); }

// Shuffles. CUDA clamps at the warp edge — an out-of-range source lane keeps
// its own value — while Intel's shuffles wrap around the concatenation of
// their two operands, so `down` and `up` need the select. `bfly` and `idx`
// cannot go out of range with a 32-lane warp and a mask below 32.
static INL int shfl_down(int v, uint delta) {
    uint lane = get_sub_group_local_id();
    int s = intel_sub_group_shuffle_down(v, v, delta);
    return (lane + delta < 32u) ? s : v;
}
static INL int shfl_up(int v, uint delta) {
    uint lane = get_sub_group_local_id();
    int s = intel_sub_group_shuffle_up(v, v, delta);
    return (lane >= delta) ? s : v;
}

INL int __zluda_ptx_impl_shfl_sync_down_b32(int v, uint delta, uint c, uint m) {
    (void)c; (void)m;
    return shfl_down(v, delta);
}
INL int __zluda_ptx_impl_shfl_sync_up_b32(int v, uint delta, uint c, uint m) {
    (void)c; (void)m;
    return shfl_up(v, delta);
}
INL int __zluda_ptx_impl_shfl_sync_bfly_b32(int v, uint mask, uint c, uint m) {
    (void)c; (void)m;
    return intel_sub_group_shuffle_xor(v, mask);
}
INL int __zluda_ptx_impl_shfl_sync_idx_b32(int v, uint src, uint c, uint m) {
    (void)c; (void)m;
    return intel_sub_group_shuffle(v, src);
}

// The `_pred` forms also report whether the source lane was in range.
INL int2 __zluda_ptx_impl_shfl_sync_down_b32_pred(int v, uint delta, uint c, uint m) {
    (void)c; (void)m;
    uint lane = get_sub_group_local_id();
    return (int2)(shfl_down(v, delta), (lane + delta < 32u) ? 1 : 0);
}
INL int2 __zluda_ptx_impl_shfl_sync_up_b32_pred(int v, uint delta, uint c, uint m) {
    (void)c; (void)m;
    uint lane = get_sub_group_local_id();
    return (int2)(shfl_up(v, delta), (lane >= delta) ? 1 : 0);
}
INL int2 __zluda_ptx_impl_shfl_sync_bfly_b32_pred(int v, uint mask, uint c, uint m) {
    (void)c; (void)m;
    return (int2)(intel_sub_group_shuffle_xor(v, mask), 1);
}
INL int2 __zluda_ptx_impl_shfl_sync_idx_b32_pred(int v, uint src, uint c, uint m) {
    (void)c; (void)m;
    return (int2)(intel_sub_group_shuffle(v, src), 1);
}

// PTX `elect.sync _|p, membermask` — true for exactly one lane of the active
// set. The mask is dropped like every other one; see `__zlift_elect_sync`.
INL bool __zluda_ptx_impl_elect_sync_pred(uint membermask) {
    (void)membermask;
    return __zlift_elect_sync() != 0;
}

// ---------------------------------------------------------------------------
// wmma — the CUDA C tensor-core API's PTX form
// ---------------------------------------------------------------------------
//
// `wmma` differs from `mma.sync` in one way that makes it much easier to
// emulate: the fragment layout is **opaque**. PTX does not say which lane holds
// which element, and a program is not allowed to look — it has to use
// `wmma.load` and `wmma.store` to get data in and out. So the layout is ours to
// choose, and only these five routines ever see it.
//
// The choice:
//
//   lane l, register r  ->  element l*8 + r of the row-major 16x16
//
// which means lane l owns row l/2 and columns (l%2)*8 .. +7 — one contiguous
// run, so `load.a.row` and `load.c`/`store.d` are coalesced reads of eight
// consecutive elements. The `.f16` fragments keep one half per 32-bit register
// rather than two; half the register file goes unused and every index stays
// trivial, which for an emulation is the right trade.
//
// The multiply then needs nine shuffles per k rather than sixteen: a lane's
// eight outputs all share one row, so they need one A element and eight
// consecutive B elements, and those eight live in one source lane.

#define WMMA_UNPACK8(v, name)                                                  \
    int name[8] = {v.s0, v.s1, v.s2, v.s3, v.s4, v.s5, v.s6, v.s7}
#define WMMA_UNPACK8F(v, name)                                                 \
    float name[8] = {v.s0, v.s1, v.s2, v.s3, v.s4, v.s5, v.s6, v.s7}

// --- loads ---------------------------------------------------------------
//
// `.row` means element (i, j) is at `p[i*stride + j]`, `.col` at
// `p[j*stride + i]`. The fragment index says which (i, j) this lane wants.

#define WMMA_LOAD_F16(name, space, addr_t, transposed)                         \
    INL int8 name(addr_t addr, uint stride) {                                  \
        space const half *p = (space const half *)(size_t)addr;                        \
        uint lane = get_sub_group_local_id();                                  \
        uint i = lane >> 1, j0 = (lane & 1u) * 8u;                             \
        int out[8];                                                            \
        for (uint r = 0u; r < 8u; r++) {                                       \
            uint j = j0 + r;                                                   \
            out[r] = (int)(uint)as_ushort((transposed) ? p[j * stride + i]     \
                                                       : p[i * stride + j]);   \
        }                                                                      \
        return (int8)(out[0], out[1], out[2], out[3],                          \
                      out[4], out[5], out[6], out[7]);                         \
    }

WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_a_row_f16_global, __global, ulong, 0)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_a_col_f16_global, __global, ulong, 1)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_b_row_f16_global, __global, ulong, 0)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_b_col_f16_global, __global, ulong, 1)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_a_row_f16_shared, __local, uint, 0)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_a_col_f16_shared, __local, uint, 1)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_b_row_f16_shared, __local, uint, 0)
WMMA_LOAD_F16(__zluda_ptx_impl_wmma_load_b_col_f16_shared, __local, uint, 1)

#define WMMA_LOAD_F32(name, space, addr_t, transposed)                         \
    INL float8 name(addr_t addr, uint stride) {                                \
        space const float *p = (space const float *)(size_t)addr;                      \
        uint lane = get_sub_group_local_id();                                  \
        uint i = lane >> 1, j0 = (lane & 1u) * 8u;                             \
        float out[8];                                                          \
        for (uint r = 0u; r < 8u; r++) {                                       \
            uint j = j0 + r;                                                   \
            out[r] = (transposed) ? p[j * stride + i] : p[i * stride + j];     \
        }                                                                      \
        return (float8)(out[0], out[1], out[2], out[3],                        \
                        out[4], out[5], out[6], out[7]);                       \
    }

WMMA_LOAD_F32(__zluda_ptx_impl_wmma_load_c_row_f32_global, __global, ulong, 0)
WMMA_LOAD_F32(__zluda_ptx_impl_wmma_load_c_col_f32_global, __global, ulong, 1)
WMMA_LOAD_F32(__zluda_ptx_impl_wmma_load_c_row_f32_shared, __local, uint, 0)
WMMA_LOAD_F32(__zluda_ptx_impl_wmma_load_c_col_f32_shared, __local, uint, 1)

// --- store ---------------------------------------------------------------

#define WMMA_STORE_F32(name, space, addr_t, transposed)                        \
    INL void name(addr_t addr, float8 d, uint stride) {                        \
        space float *p = (space float *)(size_t)addr;                                  \
        uint lane = get_sub_group_local_id();                                  \
        uint i = lane >> 1, j0 = (lane & 1u) * 8u;                             \
        WMMA_UNPACK8F(d, v);                                                   \
        for (uint r = 0u; r < 8u; r++) {                                       \
            uint j = j0 + r;                                                   \
            if (transposed)                                                    \
                p[j * stride + i] = v[r];                                      \
            else                                                               \
                p[i * stride + j] = v[r];                                      \
        }                                                                      \
    }

WMMA_STORE_F32(__zluda_ptx_impl_wmma_store_d_row_f32_global, __global, ulong, 0)
WMMA_STORE_F32(__zluda_ptx_impl_wmma_store_d_col_f32_global, __global, ulong, 1)
WMMA_STORE_F32(__zluda_ptx_impl_wmma_store_d_row_f32_shared, __local, uint, 0)
WMMA_STORE_F32(__zluda_ptx_impl_wmma_store_d_col_f32_shared, __local, uint, 1)

// --- multiply ------------------------------------------------------------
//
// D[m][n] = C[m][n] + sum_k A[m][k] * B[k][n], with this lane's eight outputs
// all on row m = lane/2, columns (lane%2)*8 .. +7.
//
// Every shuffle below reads a register chosen by a loop counter, never by
// something that varies across lanes: `intel_sub_group_shuffle` evaluates its
// data operand in the *source* lane, so a per-lane register index would fetch
// whatever that lane happened to be asking for instead.
INL float8 __zluda_ptx_impl_wmma_mma_row_col_f32_f32(int8 a, int8 b, float8 c) {
    uint lane = get_sub_group_local_id();
    WMMA_UNPACK8(a, av);
    WMMA_UNPACK8(b, bv);
    WMMA_UNPACK8F(c, acc);

    __attribute__((opencl_unroll_hint))
    for (uint k = 0u; k < 16u; k++) {
        // A[m][k], flat m*16+k, so lane (m*2 + k/8) register k%8. m = lane/2,
        // hence the lane index below; the register index is the loop's.
        float ak;
        {
            uint src = (lane & ~1u) + (k >> 3);
            int w = intel_sub_group_shuffle(av[k & 7u], src);
            ak = (float)as_half((ushort)(uint)w);
        }
        // B[k][n] for this lane's eight n, flat k*16 + (lane%2)*8 + r — all in
        // lane k*2 + lane%2, registers 0..7.
        uint bsrc = k * 2u + (lane & 1u);
        __attribute__((opencl_unroll_hint))
        for (uint r = 0u; r < 8u; r++) {
            int w = intel_sub_group_shuffle(bv[r], bsrc);
            acc[r] = fma(ak, (float)as_half((ushort)(uint)w), acc[r]);
        }
    }
    return (float8)(acc[0], acc[1], acc[2], acc[3],
                    acc[4], acc[5], acc[6], acc[7]);
}
