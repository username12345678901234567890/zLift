// zlift_devlib — the Intel device library for translated NVIDIA code.
//
// PTX and SASS both reach a handful of primitives that have no single OpenCL
// builtin behind them: byte permutes, bitfield inserts, lane election, warp
// value matching. ZLUDA solves the same problem for AMD with
// `ptx/lib/zluda_ptx_impl.cpp`; this is that file's Intel counterpart, and it
// exists for the same reason — a rewriter can map one call to one builtin, but
// it should not be synthesising thirty instructions of straight-line IR.
//
// Built once into `zlift_devlib.ll` (spir64 LLVM IR) and linked into each
// translated module with `llvm-link`, which is what keeps the attribute
// groups and metadata numbering from colliding. Whatever the module does not
// call is dead after linking and -O2 removes it.
//
// Warp width. Every routine here assumes a 32-lane sub-group, which is what
// both rewriters pin with `intel_reqd_sub_group_size`. Nothing here is
// correct at any other width.
//
// Everything is `always_inline`. Left as real calls, IGC reports "Stack call
// has been detected", gives the kernel a private-memory stack, and then
// `zeKernelCreate` fails outright with INVALID_KERNEL_NAME. Inlining also
// removes the call overhead from what are mostly a few instructions each.
//
// Build:
//   clang -cl-std=CL2.0 -target spir64-unknown-unknown -O2 -emit-llvm -S \
//         -x cl zlift_devlib.cl -o zlift_devlib.ll

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

#define WARP_SIZE 32u

// PTX `match.any.sync.b32`: the mask of lanes whose `value` equals mine.
//
// The obvious formulation — compare against every lane's value in turn — is
// also the clearest, and the loop bound is a compile-time constant so it
// unrolls. `sub_group_broadcast` needs a uniform lane index, which `j` is.
__attribute__((always_inline)) uint __zlift_match_any_b32(uint value) {
    uint result = 0u;
    for (uint j = 0u; j < WARP_SIZE; j++) {
        uint other = sub_group_broadcast(value, j);
        if (other == value)
            result |= (1u << j);
    }
    return result;
}

// The mask of lanes currently executing. Each present lane contributes its own
// bit and nothing else, so the disjoint sum is exactly the ballot.
__attribute__((always_inline)) uint __zlift_activemask(void) {
    return (uint)sub_group_reduce_add((int)(1u << get_sub_group_local_id()));
}

// PTX `elect.sync`: true for exactly one lane of the active set, false for the
// rest. PTX does not promise *which* lane, so the lowest is as good as any and
// is what the SASS idiom (`flo` of the active mask) picks too.
__attribute__((always_inline)) int __zlift_elect_sync(void) {
    uint lid = get_sub_group_local_id();
    uint active = __zlift_activemask();
    return lid == (uint)ctz(active);
}

// PTX `prmt.b32`: assemble four bytes out of the eight in {a, b}.
//
// Each nibble of `sel` names a source byte; its high bit asks for that byte's
// sign replicated across the result byte instead of the byte itself.
__attribute__((always_inline)) uint __zlift_prmt_b32(uint a, uint b, uint sel) {
    ulong src = ((ulong)b << 32) | (ulong)a;
    uint result = 0u;
    for (int i = 0; i < 4; i++) {
        uint control = (sel >> (i * 4)) & 0xFu;
        uint byte = (uint)((src >> ((control & 0x7u) * 8u)) & 0xFFu);
        if (control & 0x8u)
            byte = (byte & 0x80u) ? 0xFFu : 0x00u;
        result |= byte << (i * 8);
    }
    return result;
}

// PTX `bfi.b64`: insert `len` bits of `insert` into `base` starting at `pos`.
// PTX clamps rather than wrapping, and a zero-length insert is a no-op.
__attribute__((always_inline)) ulong __zlift_bfi_b64(ulong insert, ulong base, uint pos, uint len) {
    if (pos >= 64u || len == 0u)
        return base;
    uint width = (pos + len > 64u) ? (64u - pos) : len;
    ulong mask = (width >= 64u) ? ~0UL : ((((ulong)1 << width) - 1UL) << pos);
    return (base & ~mask) | ((insert << pos) & mask);
}

// PTX `bfe.u32` / `bfe.s32`: extract `len` bits at `pos`, zero- or
// sign-extended. PTX defines a zero length as producing zero, and clamps a
// position past the word.
__attribute__((always_inline)) uint __zlift_bfe_u32(uint value, uint pos, uint len) {
    if (len == 0u || pos >= 32u)
        return 0u;
    uint width = (pos + len > 32u) ? (32u - pos) : len;
    return (value >> pos) & ((width >= 32u) ? ~0u : ((1u << width) - 1u));
}

__attribute__((always_inline)) int __zlift_bfe_s32(int value, uint pos, uint len) {
    if (len == 0u)
        return 0;
    if (pos >= 32u)
        return value >> 31;  // clamped: the sign bit, replicated
    uint width = (pos + len > 32u) ? (32u - pos) : len;
    int shifted = value >> pos;
    uint slack = 32u - width;
    return (shifted << slack) >> slack;
}

// PTX `bfi.b32`, same contract as the 64-bit form.
__attribute__((always_inline)) uint __zlift_bfi_b32(uint insert, uint base, uint pos, uint len) {
    if (pos >= 32u || len == 0u)
        return base;
    uint width = (pos + len > 32u) ? (32u - pos) : len;
    uint mask = (width >= 32u) ? ~0u : (((1u << width) - 1u) << pos);
    return (base & ~mask) | ((insert << pos) & mask);
}

// PTX `vote.sync.ballot.b32`: the mask of lanes whose predicate is true.
// Disjoint bits again, so the sub-group sum is the ballot.
__attribute__((always_inline)) uint __zlift_vote_ballot(int predicate) {
    uint bit = predicate ? (1u << get_sub_group_local_id()) : 0u;
    return (uint)sub_group_reduce_add((int)bit);
}

// PTX `div.rn.f32`. ZLUDA splits this into two halves for AMD because the
// hardware needs an explicit Newton-Raphson dance around `div_scale`; Xe has a
// real divide, and the second half is handed the original operands, so all the
// work fits there and the first half only has to produce a struct nobody reads.
//
// Accuracy: OpenCL `/` is 2.5 ulp unless the module is built with
// `-cl-fp32-correctly-rounded-divide-sqrt`, which is what PTX `div.rn`
// promises. zerun and zebuild pass that flag by default.
__attribute__((always_inline)) float __zlift_div_rn_f32(float x, float y) {
    return x / y;
}

// `intel_sub_group_shuffle` comes from cl_intel_subgroups, which this clang
// knows how to mangle and lower but does not declare in the CL2.0 header. The
// prototype is all that is missing; SPIRV_EXTS carries the matching
// `+SPV_INTEL_subgroups` through to llc.
int intel_sub_group_shuffle(int value, uint index);
float __spirv_GroupNonUniformShuffle(int scope, float value, uint id);

// PTX `mma.sync.aligned.*`, emulated.
//
// D = C + A*B across the 32 lanes of a warp, with A, B, C and D each split
// among the lanes in a layout the PTX ISA fixes per shape. Nine shapes appear
// in the corpus and all nine obey the same three rules, which is why they share
// one loop instead of getting nine hand-written kernels:
//
//   groupID g = lane >> 2,  tig t = lane & 3
//   P  = how many k-elements one register holds (2 for f16/bf16, 1 for
//        tf32/f64, 4 for s8), so one register spans KB = 4*P values of k
//
//   A[m][k]  lane (m%8)*4 + (k%KB)/P, register (k/KB)*(M/8) + m/8, element k%P
//   B[k][n]  lane n*4     + (k%KB)/P, register  k/KB,              element k%P
//   C[m][n]  lane (m%8)*4 + n/2,      register (m/8)*2 + (n&1)
//
// So a lane holds D at rows {g, g+8} and columns {2t, 2t+1}, and for each k it
// needs exactly two A elements and two B elements — four shuffles per k, however
// large the shape.
//
// This is *emulation*, not XMX: K steps of sub-group shuffles and scalar FMAs.
// It is correct and it is slow. Reaching the matrix engines means
// SPV_INTEL_subgroup_matrix_multiply_accumulate, whose operand layout is not
// this one, so it is a rewrite rather than a substitution.
//
// Accumulation is in the accumulator's own width except for the `.f16` output
// forms, which accumulate in f32 and round once at the end — no worse than the
// hardware, which is free to do the same.

__attribute__((always_inline))
static float zlift_frag_f16(int reg, uint src, uint e) {
    return (float)as_half2(intel_sub_group_shuffle(reg, src))[e];
}

__attribute__((always_inline))
static float zlift_frag_bf16(int reg, uint src, uint e) {
    int v = intel_sub_group_shuffle(reg, src);
    return as_float((uint)as_ushort2(v)[e] << 16);
}

__attribute__((always_inline))
static float zlift_frag_tf32(int reg, uint src, uint e) {
    (void)e;
    return as_float(intel_sub_group_shuffle(reg, src));
}

__attribute__((always_inline))
static int zlift_frag_s8(int reg, uint src, uint e) {
    int v = intel_sub_group_shuffle(reg, src);
    return (v << (24u - 8u * e)) >> 24;
}

// `intel_sub_group_shuffle` is not guaranteed for double, so a double moves as
// the two words it is made of.
__attribute__((always_inline))
static double zlift_frag_f64(double reg, uint src, uint e) {
    (void)e;
    int2 w = as_int2(reg);
    return as_double((int2)(intel_sub_group_shuffle(w.s0, src),
                            intel_sub_group_shuffle(w.s1, src)));
}

/// The shared loop. `A`, `B` and `acc` are in scope at the call site; `MR` is
/// M/8, the number of row groups a lane holds.
///
/// Both loops are unrolled on purpose rather than by luck. The fragments are
/// local arrays, and only a fully unrolled body turns their indices into
/// constants and lets the arrays disappear into registers — left as private
/// memory they survive `always-inline,globaldce`, which is the whole pipeline
/// between here and llc, and arrive at IGC as scratch traffic inside the
/// innermost loop of a matrix multiply.
#define ZLIFT_MMA_LOOP(MR, K, P, ELEM, FRAG, MAD)                              \
    do {                                                                       \
        uint lane = get_sub_group_local_id();                                  \
        uint g = lane >> 2, t = lane & 3u;                                     \
        __attribute__((opencl_unroll_hint))                                    \
        for (uint k = 0u; k < (uint)(K); k++) {                                \
            uint ka = (k % (4u * (P))) / (uint)(P);                            \
            uint ke = k % (uint)(P);                                           \
            uint kg = k / (4u * (P));                                          \
            ELEM b0 = FRAG(B[kg], (2u * t) * 4u + ka, ke);                     \
            ELEM b1 = FRAG(B[kg], (2u * t + 1u) * 4u + ka, ke);                \
            __attribute__((opencl_unroll_hint))                                \
            for (uint mi = 0u; mi < (uint)(MR); mi++) {                        \
                ELEM a = FRAG(A[kg * (uint)(MR) + mi], g * 4u + ka, ke);        \
                acc[mi * 2u] = MAD(a, b0, acc[mi * 2u]);                       \
                acc[mi * 2u + 1u] = MAD(a, b1, acc[mi * 2u + 1u]);             \
            }                                                                  \
        }                                                                      \
    } while (0)

#define ZLIFT_MAD_F(a, b, c) fma((a), (b), (c))
#define ZLIFT_MAD_I(a, b, c) ((c) + (a) * (b))

// --- f16 inputs, f32 accumulator -------------------------------------------

__attribute__((always_inline))
float4 __zlift_mma_m16n8k8_f32_f16(int a0, int a1, int b0, float4 c) {
    int A[2] = {a0, a1};
    int B[1] = {b0};
    float acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 8, 2, float, zlift_frag_f16, ZLIFT_MAD_F);
    return (float4)(acc[0], acc[1], acc[2], acc[3]);
}

__attribute__((always_inline))
float4 __zlift_mma_m16n8k16_f32_f16(int a0, int a1, int a2, int a3,
                                    int b0, int b1, float4 c) {
    int A[4] = {a0, a1, a2, a3};
    int B[2] = {b0, b1};
    float acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 16, 2, float, zlift_frag_f16, ZLIFT_MAD_F);
    return (float4)(acc[0], acc[1], acc[2], acc[3]);
}

// --- bf16 inputs, f32 accumulator ------------------------------------------

__attribute__((always_inline))
float4 __zlift_mma_m16n8k8_f32_bf16(int a0, int a1, int b0, float4 c) {
    int A[2] = {a0, a1};
    int B[1] = {b0};
    float acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 8, 2, float, zlift_frag_bf16, ZLIFT_MAD_F);
    return (float4)(acc[0], acc[1], acc[2], acc[3]);
}

__attribute__((always_inline))
float4 __zlift_mma_m16n8k16_f32_bf16(int a0, int a1, int a2, int a3,
                                     int b0, int b1, float4 c) {
    int A[4] = {a0, a1, a2, a3};
    int B[2] = {b0, b1};
    float acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 16, 2, float, zlift_frag_bf16, ZLIFT_MAD_F);
    return (float4)(acc[0], acc[1], acc[2], acc[3]);
}

// --- f16 inputs, f16 accumulator -------------------------------------------
//
// C and D are packed pairs, and the pairing is by column, not by the (m/8)*2
// rule the f32 forms use: register 0 is row g, register 1 is row g+8.

__attribute__((always_inline))
int2 __zlift_mma_m16n8k8_f16_f16(int a0, int a1, int b0, int2 c) {
    int A[2] = {a0, a1};
    int B[1] = {b0};
    float acc[4] = {(float)as_half2(c.s0)[0], (float)as_half2(c.s0)[1],
                    (float)as_half2(c.s1)[0], (float)as_half2(c.s1)[1]};
    ZLIFT_MMA_LOOP(2, 8, 2, float, zlift_frag_f16, ZLIFT_MAD_F);
    return (int2)(as_int((half2)(convert_half(acc[0]), convert_half(acc[1]))),
                  as_int((half2)(convert_half(acc[2]), convert_half(acc[3]))));
}

__attribute__((always_inline))
int2 __zlift_mma_m16n8k16_f16_f16(int a0, int a1, int a2, int a3,
                                  int b0, int b1, int2 c) {
    int A[4] = {a0, a1, a2, a3};
    int B[2] = {b0, b1};
    float acc[4] = {(float)as_half2(c.s0)[0], (float)as_half2(c.s0)[1],
                    (float)as_half2(c.s1)[0], (float)as_half2(c.s1)[1]};
    ZLIFT_MMA_LOOP(2, 16, 2, float, zlift_frag_f16, ZLIFT_MAD_F);
    return (int2)(as_int((half2)(convert_half(acc[0]), convert_half(acc[1]))),
                  as_int((half2)(convert_half(acc[2]), convert_half(acc[3]))));
}

// --- tf32 inputs, f32 accumulator ------------------------------------------
//
// A tf32 register is one f32 whose low mantissa bits are already zero, so the
// element is the word itself.

__attribute__((always_inline))
float4 __zlift_mma_m16n8k8_f32_tf32(int a0, int a1, int a2, int a3,
                                    int b0, int b1, float4 c) {
    int A[4] = {a0, a1, a2, a3};
    int B[2] = {b0, b1};
    float acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 8, 1, float, zlift_frag_tf32, ZLIFT_MAD_F);
    return (float4)(acc[0], acc[1], acc[2], acc[3]);
}

// --- f64 ------------------------------------------------------------------

__attribute__((always_inline))
double2 __zlift_mma_m8n8k4_f64(double a0, double b0, double2 c) {
    double A[1] = {a0};
    double B[1] = {b0};
    double acc[2] = {c.s0, c.s1};
    ZLIFT_MMA_LOOP(1, 4, 1, double, zlift_frag_f64, ZLIFT_MAD_F);
    return (double2)(acc[0], acc[1]);
}

__attribute__((always_inline))
double4 __zlift_mma_m16n8k16_f64(double a0, double a1, double a2, double a3,
                                 double a4, double a5, double a6, double a7,
                                 double b0, double b1, double b2, double b3,
                                 double4 c) {
    double A[8] = {a0, a1, a2, a3, a4, a5, a6, a7};
    double B[4] = {b0, b1, b2, b3};
    double acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 16, 1, double, zlift_frag_f64, ZLIFT_MAD_F);
    return (double4)(acc[0], acc[1], acc[2], acc[3]);
}

// --- s8 inputs, s32 accumulator --------------------------------------------
//
// `.satfinite` saturates the s32 result, which cannot be reached: the largest
// magnitude a K=32 dot product of signed bytes can have is 32*127*127, so the
// plain sum is the saturated sum.

__attribute__((always_inline))
int2 __zlift_mma_m8n8k16_s32_s8(int a0, int b0, int2 c) {
    int A[1] = {a0};
    int B[1] = {b0};
    int acc[2] = {c.s0, c.s1};
    ZLIFT_MMA_LOOP(1, 16, 4, int, zlift_frag_s8, ZLIFT_MAD_I);
    return (int2)(acc[0], acc[1]);
}

__attribute__((always_inline))
int4 __zlift_mma_m16n8k32_s32_s8(int a0, int a1, int a2, int a3,
                                 int b0, int b1, int4 c) {
    int A[4] = {a0, a1, a2, a3};
    int B[2] = {b0, b1};
    int acc[4] = {c.s0, c.s1, c.s2, c.s3};
    ZLIFT_MMA_LOOP(2, 32, 4, int, zlift_frag_s8, ZLIFT_MAD_I);
    return (int4)(acc[0], acc[1], acc[2], acc[3]);
}

// PTX `ldmatrix.sync.aligned.m8n8.x4.shared.b16`, emulated.
//
// Thirty-two lanes cooperatively load four 8x8 matrices of 16-bit elements out
// of shared memory. Lane i supplies the address of row i%8 of matrix i/8, and
// afterwards every lane holds, in register k, the two elements of matrix k at
// row = lane>>2, columns (lane&3)*2 and +1.
//
// The exchange shuffles the *data*, not the addresses: each lane reads its own
// row (8 halves = 4 words) and the lanes then trade words. Shuffling the
// address instead would mean shuffling a pointer, which the sub-group builtins
// do not do. All four words have to be shuffled because `intel_sub_group_shuffle`
// evaluates its data operand in the *source* lane — indexing by the destination
// lane's word number inside the shuffle would read the wrong element.
__attribute__((always_inline))
int4 __zlift_ldmatrix_x4_b16(__local const uint *row) {
    uint lane = get_sub_group_local_id();
    uint want_row = lane >> 2;     // the row this lane wants from each matrix
    uint word = lane & 3u;         // and which of its four words

    int w0 = (int)row[0], w1 = (int)row[1];
    int w2 = (int)row[2], w3 = (int)row[3];

    int4 out;
    for (uint k = 0u; k < 4u; k++) {
        uint src = k * 8u + want_row;
        int s0 = intel_sub_group_shuffle(w0, src);
        int s1 = intel_sub_group_shuffle(w1, src);
        int s2 = intel_sub_group_shuffle(w2, src);
        int s3 = intel_sub_group_shuffle(w3, src);
        int v = (word == 0u) ? s0 : (word == 1u) ? s1 : (word == 2u) ? s2 : s3;
        if (k == 0u) out.s0 = v;
        else if (k == 1u) out.s1 = v;
        else if (k == 2u) out.s2 = v;
        else out.s3 = v;
    }
    return out;
}

// ---------------------------------------------------------------------------
// ldmatrix / stmatrix, the rest of the family
// ---------------------------------------------------------------------------
//
// `x4` above is the common case; `x1` and `x2` load one and two tiles, and the
// `.trans` forms hand back the transpose. All of them move the *data* between
// lanes rather than the addresses, for the reason given above, so they share
// two helpers: one that hands a whole row of some tile to whoever asks for it,
// and one that picks a single 16-bit element out of such a row.
//
// The layouts, once, since every routine below is an expression of them:
//
//   addressing   lane i supplies the address of row i%8 of tile i/8
//   fragment     lane l's register k holds tile k at row l>>2,
//                columns (l&3)*2 and (l&3)*2+1
//   transposed   lane l's register k holds tile k at column l>>2,
//                rows (l&3)*2 and (l&3)*2+1
//
// A tile row is 8 halves — four 32-bit words — and every lane has read its own
// row before any exchange happens, so `src` below is always a lane that did.

__attribute__((always_inline))
static int zlift_ldsm_row_word(int w0, int w1, int w2, int w3, uint src,
                               uint word) {
    int s0 = intel_sub_group_shuffle(w0, src);
    int s1 = intel_sub_group_shuffle(w1, src);
    int s2 = intel_sub_group_shuffle(w2, src);
    int s3 = intel_sub_group_shuffle(w3, src);
    return (word == 0u) ? s0 : (word == 1u) ? s1 : (word == 2u) ? s2 : s3;
}

/// Element `col` of the row held by lane `src`.
__attribute__((always_inline))
static uint zlift_ldsm_elem(int w0, int w1, int w2, int w3, uint src,
                            uint col) {
    int word = zlift_ldsm_row_word(w0, w1, w2, w3, src, col >> 1);
    return ((uint)word >> ((col & 1u) * 16u)) & 0xffffu;
}

/// The fragment register for tile `k`, in the ordinary layout.
__attribute__((always_inline))
static int zlift_ldsm_frag(int w0, int w1, int w2, int w3, uint k, uint lane) {
    return zlift_ldsm_row_word(w0, w1, w2, w3, k * 8u + (lane >> 2), lane & 3u);
}

/// The fragment register for tile `k`, transposed: one column, two rows.
__attribute__((always_inline))
static int zlift_ldsm_frag_t(int w0, int w1, int w2, int w3, uint k,
                             uint lane) {
    uint col = lane >> 2;
    uint row = (lane & 3u) * 2u;
    uint lo = zlift_ldsm_elem(w0, w1, w2, w3, k * 8u + row, col);
    uint hi = zlift_ldsm_elem(w0, w1, w2, w3, k * 8u + row + 1u, col);
    return (int)(lo | (hi << 16));
}

#define ZLIFT_LDSM_BODY                                                        \
    uint lane = get_sub_group_local_id();                                      \
    int w0 = (int)row[0], w1 = (int)row[1];                                    \
    int w2 = (int)row[2], w3 = (int)row[3];

__attribute__((always_inline))
int __zlift_ldmatrix_x1_b16(__local const uint *row) {
    ZLIFT_LDSM_BODY
    return zlift_ldsm_frag(w0, w1, w2, w3, 0u, lane);
}

__attribute__((always_inline))
int2 __zlift_ldmatrix_x2_b16(__local const uint *row) {
    ZLIFT_LDSM_BODY
    return (int2)(zlift_ldsm_frag(w0, w1, w2, w3, 0u, lane),
                  zlift_ldsm_frag(w0, w1, w2, w3, 1u, lane));
}

__attribute__((always_inline))
int __zlift_ldmatrix_x1_trans_b16(__local const uint *row) {
    ZLIFT_LDSM_BODY
    return zlift_ldsm_frag_t(w0, w1, w2, w3, 0u, lane);
}

__attribute__((always_inline))
int2 __zlift_ldmatrix_x2_trans_b16(__local const uint *row) {
    ZLIFT_LDSM_BODY
    return (int2)(zlift_ldsm_frag_t(w0, w1, w2, w3, 0u, lane),
                  zlift_ldsm_frag_t(w0, w1, w2, w3, 1u, lane));
}

__attribute__((always_inline))
int4 __zlift_ldmatrix_x4_trans_b16(__local const uint *row) {
    ZLIFT_LDSM_BODY
    return (int4)(zlift_ldsm_frag_t(w0, w1, w2, w3, 0u, lane),
                  zlift_ldsm_frag_t(w0, w1, w2, w3, 1u, lane),
                  zlift_ldsm_frag_t(w0, w1, w2, w3, 2u, lane),
                  zlift_ldsm_frag_t(w0, w1, w2, w3, 3u, lane));
}

// `stmatrix` is the same layouts run backwards. The lane that *writes* row r of
// tile k is lane k*8+r, and the four words of that row are spread across lanes
// 4r..4r+3 in register k — so every lane shuffles out of those four, then keeps
// the tile its own address belongs to. Lanes past 8*tiles have no address and
// must not store.

/// Word `j` of row `r` of tile `k`, gathered from the fragment registers.
__attribute__((always_inline))
static int zlift_stsm_word(int r0, int r1, int r2, int r3, uint tiles, uint k,
                           uint r, uint j) {
    uint src = r * 4u + j;
    int v0 = intel_sub_group_shuffle(r0, src);
    int v1 = tiles > 1u ? intel_sub_group_shuffle(r1, src) : 0;
    int v2 = tiles > 2u ? intel_sub_group_shuffle(r2, src) : 0;
    int v3 = tiles > 2u ? intel_sub_group_shuffle(r3, src) : 0;
    return (k == 0u) ? v0 : (k == 1u) ? v1 : (k == 2u) ? v2 : v3;
}

/// The same, when the fragments hold the transpose: element (r, c) sits in
/// lane c*4 + r/2, half r&1, of register k.
__attribute__((always_inline))
static int zlift_stsm_word_t(int r0, int r1, int r2, int r3, uint tiles,
                             uint k, uint r, uint j) {
    uint out = 0u;
    for (uint h = 0u; h < 2u; h++) {
        uint col = j * 2u + h;
        uint src = col * 4u + (r >> 1);
        int v0 = intel_sub_group_shuffle(r0, src);
        int v1 = tiles > 1u ? intel_sub_group_shuffle(r1, src) : 0;
        int v2 = tiles > 2u ? intel_sub_group_shuffle(r2, src) : 0;
        int v3 = tiles > 2u ? intel_sub_group_shuffle(r3, src) : 0;
        int reg = (k == 0u) ? v0 : (k == 1u) ? v1 : (k == 2u) ? v2 : v3;
        out |= (((uint)reg >> ((r & 1u) * 16u)) & 0xffffu) << (h * 16u);
    }
    return (int)out;
}

__attribute__((always_inline))
static void zlift_stmatrix(__local uint *row, int r0, int r1, int r2, int r3,
                           uint tiles, bool trans) {
    uint lane = get_sub_group_local_id();
    uint r = lane & 7u;
    uint k = lane >> 3;
    int g0, g1, g2, g3;
    if (trans) {
        g0 = zlift_stsm_word_t(r0, r1, r2, r3, tiles, k, r, 0u);
        g1 = zlift_stsm_word_t(r0, r1, r2, r3, tiles, k, r, 1u);
        g2 = zlift_stsm_word_t(r0, r1, r2, r3, tiles, k, r, 2u);
        g3 = zlift_stsm_word_t(r0, r1, r2, r3, tiles, k, r, 3u);
    } else {
        g0 = zlift_stsm_word(r0, r1, r2, r3, tiles, k, r, 0u);
        g1 = zlift_stsm_word(r0, r1, r2, r3, tiles, k, r, 1u);
        g2 = zlift_stsm_word(r0, r1, r2, r3, tiles, k, r, 2u);
        g3 = zlift_stsm_word(r0, r1, r2, r3, tiles, k, r, 3u);
    }
    // Every shuffle above is executed by every lane; only the store is guarded.
    if (lane < tiles * 8u) {
        row[0] = (uint)g0;
        row[1] = (uint)g1;
        row[2] = (uint)g2;
        row[3] = (uint)g3;
    }
}

__attribute__((always_inline))
void __zlift_stmatrix_x1_b16(__local uint *row, int a) {
    zlift_stmatrix(row, a, 0, 0, 0, 1u, false);
}
__attribute__((always_inline))
void __zlift_stmatrix_x2_b16(__local uint *row, int a, int b) {
    zlift_stmatrix(row, a, b, 0, 0, 2u, false);
}
__attribute__((always_inline))
void __zlift_stmatrix_x4_b16(__local uint *row, int a, int b, int c, int d) {
    zlift_stmatrix(row, a, b, c, d, 4u, false);
}
__attribute__((always_inline))
void __zlift_stmatrix_x1_trans_b16(__local uint *row, int a) {
    zlift_stmatrix(row, a, 0, 0, 0, 1u, true);
}
__attribute__((always_inline))
void __zlift_stmatrix_x2_trans_b16(__local uint *row, int a, int b) {
    zlift_stmatrix(row, a, b, 0, 0, 2u, true);
}
__attribute__((always_inline))
void __zlift_stmatrix_x4_trans_b16(__local uint *row, int a, int b, int c,
                                   int d) {
    zlift_stmatrix(row, a, b, c, d, 4u, true);
}

// ---------------------------------------------------------------------------
// Odds and ends the rewriter cannot express as one builtin
// ---------------------------------------------------------------------------

// PTX `cvt.rp/rm/rz.f32.<int>`. OpenCL spells the rounding mode in the name;
// the point of routing through here rather than emitting the mangled builtin
// directly is that clang, not the SPIR-V backend, is made to produce it.
#define ZLIFT_CVT(name, mode, ctype)                                           \
    __attribute__((always_inline)) float name(ctype x) {                       \
        return convert_float_##mode(x);                                        \
    }
ZLIFT_CVT(__zlift_cvt_rtp_s32, rtp, int)
ZLIFT_CVT(__zlift_cvt_rtn_s32, rtn, int)
ZLIFT_CVT(__zlift_cvt_rtz_s32, rtz, int)
ZLIFT_CVT(__zlift_cvt_rtp_u32, rtp, uint)
ZLIFT_CVT(__zlift_cvt_rtn_u32, rtn, uint)
ZLIFT_CVT(__zlift_cvt_rtz_u32, rtz, uint)
ZLIFT_CVT(__zlift_cvt_rtp_s64, rtp, long)
ZLIFT_CVT(__zlift_cvt_rtn_s64, rtn, long)
ZLIFT_CVT(__zlift_cvt_rtz_s64, rtz, long)
ZLIFT_CVT(__zlift_cvt_rtp_u64, rtp, ulong)
ZLIFT_CVT(__zlift_cvt_rtn_u64, rtn, ulong)
ZLIFT_CVT(__zlift_cvt_rtz_u64, rtz, ulong)
#undef ZLIFT_CVT

// PTX `rsqrt.approx.f64`. There is no double-precision `native_rsqrt`, and the
// approximation PTX promises is weaker than this, not stronger — so a correctly
// rounded divide by a correctly rounded square root is within tolerance for
// anything that asked for `.approx`.
__attribute__((always_inline)) double __zlift_rsqrt_approx_f64(double x) {
    return 1.0 / sqrt(x);
}

// PTX `rcp.approx.ftz.f64`. The approximation is NVIDIA's answer to a hardware
// reciprocal it has and this device does not; an exact division is *more*
// accurate, not less, so nothing that depended on the approximation's error
// budget can be hurt by it. `ftz` flushes denormal inputs and results to zero,
// and this device keeps denormals in f64 (measured, see tests/devlib_check), so
// that part is not reproduced either — again in the direction of more precision.
__attribute__((always_inline)) double __zlift_rcp_approx_f64(double x) {
    return 1.0 / x;
}

// PTX `atom.global.add.noftz.f16x2` — one 32-bit word holding two halves, added
// componentwise, returning the old value. There is no packed-half atomic here,
// and doing the two halves as separate atomics would not be atomic in the pair,
// so it is a compare-and-swap loop on the word.
__attribute__((always_inline))
uint __zlift_atom_add_f16x2(volatile __global uint *p, uint addend) {
    half2 b = as_half2(addend);
    uint old = *p, seen;
    do {
        seen = old;
        half2 sum = as_half2(seen) + b;
        old = atomic_cmpxchg(p, seen, as_uint(sum));
    } while (old != seen);
    return seen;
}

// ---------------------------------------------------------------------------
// mbarrier
// ---------------------------------------------------------------------------
//
// An SM90 `mbarrier` is eight bytes of shared memory that a producer arrives at
// and a consumer polls, with the phase flipping each time the expected number of
// arrivals is reached. Xe has no such object, but it has shared memory and
// atomics, which is all the object is:
//
//   word 0   arrivals still outstanding in this phase
//   word 1   bit 0 the phase parity, the rest the expected count to reload
//
// Two simplifications are deliberate and both are sound *here*, not in general:
//
//   - The transaction-count forms (`expect_tx`, `cp.async.mbarrier.arrive`)
//     become plain arrivals. They exist to make the barrier wait for an
//     asynchronous copy, and every copy on this path is synchronous already —
//     `cp.async` is lowered to a load and a store — so the data is in place
//     before the arrival happens, which is exactly what the count was for.
//   - The `.cluster` forms become the CTA-local ones. The lifted blob picks
//     between them on `%cluster_ctarank != target`, and with a one-CTA cluster
//     that is always false. A multi-CTA cluster would need distributed shared
//     memory, which this device does not have at all.

__attribute__((always_inline))
void __zlift_mbarrier_init(__local uint *bar, uint count) {
    bar[0] = count;
    bar[1] = count << 1;   // phase parity 0
}

__attribute__((always_inline))
void __zlift_mbarrier_arrive(__local uint *bar) {
    volatile __local uint *pending = (volatile __local uint *)&bar[0];
    if (atomic_dec(pending) == 1u) {
        // Last in: rearm the count, then flip the phase. That order matters —
        // a waiter wakes on the phase, and must not find a zero count waiting
        // for it when it comes back round to arrive.
        uint state = bar[1];
        bar[0] = state >> 1;
        mem_fence(CLK_LOCAL_MEM_FENCE);
        bar[1] = state ^ 1u;
    }
}

/// True once the barrier has left the phase whose parity is `parity`.
__attribute__((always_inline))
int __zlift_mbarrier_try_wait(__local uint *bar, uint parity) {
    // Read through an atomic so the spin loop this sits in re-reads it. A plain
    // load is loop-invariant as far as the optimiser can tell, and hoisting it
    // turns the poll into a hang.
    uint state = atomic_or((volatile __local uint *)&bar[1], 0u);
    return (state & 1u) != (parity & 1u);
}

// ---------------------------------------------------------------------------
// TMA — `cp.async.bulk.tensor`
// ---------------------------------------------------------------------------
//
// The Hopper tensor-memory accelerator copies a tile of a multidimensional
// tensor from global memory into shared, laid out the way a `wgmma` wants to
// read it. Its descriptor is a `CUtensorMap`: 128 opaque bytes the host builds
// with `cuTensorMapEncodeTiled`, whose layout NVIDIA does not document.
//
// That would be the end of it, except the corpus does not use one. The drivers
// materialise a `SlifterTmaDesc` of their own at the address the kernel's
// descriptor load resolves to — the same convention CuLifter's x86 backend
// already lowers `UTMALDG` against — so what is needed here is not a decoder
// but the copy itself, against a struct whose fields are known.
//
// Three layouts, which is what the corpus asks for:
//
//   swizzle 4   linear: element (m, k) of the tile at m*K + k
//   swizzle 0   K-INTER: eight-wide K blocks, one `UTMALDG` per block, block j
//               at tile_base + j*rows*8*elements; within a block (m, k) sits at
//               m*8 + k
//   swizzle 3   the GMMA swizzle: row-major within an atom of 8<<B elements,
//               with the element index XORed by ((e >> 7) & ((1<<B)-1)) << 4
//
// The copy is spread across the warp by row. On hardware one lane issues it and
// the copy engine does the work; here every lane reaches this call — the
// `elect.sync` in the lifted blob is inside the instruction being replaced, not
// around it — so having them share the rows is both correct and faster than
// electing one to do all of it.

struct SlifterTmaDesc {
    ulong global_base;
    int rows;
    int cols_k;
    int elem_bytes;
    int swizzle;
    int ld;
    int tile_base_off;
    int max_rows;
    int stride_c2;
    int stride_c3;
    int vt_load;
    int store_dkv;
    int swiz_b;
};

/// cute's `Swizzle<B,4,3>` on a linear element index.
__attribute__((always_inline))
static int zlift_gmma_swizzle(int e, int b) {
    return e ^ (((e >> 7) & ((1 << b) - 1)) << 4);
}

__attribute__((always_inline))
static void zlift_tma_copy_elem(__local uchar *dst, int s_byte,
                                __global const uchar *src, int eb) {
    for (int i = 0; i < eb; i++)
        dst[s_byte + i] = src[i];
}

__attribute__((always_inline))
void __zlift_utma_load(__global const struct SlifterTmaDesc *d,
                       __local uchar *dst, uint smem_off,
                       int c0, int c1, int c2, int c3) {
    // Not just null: a descriptor chain rooted at a slot nobody filled reads
    // zero and then has the ABI's 0x30 added to it, so what arrives is the
    // address 0x30 — non-null, and a fault to dereference. Anything below the
    // first page is not a descriptor.
    if ((ulong)d < 0x10000UL || !d->global_base) {
        // Leave a marker rather than nothing: a TMA that silently does not run
        // looks exactly like a tile of zeros, and the input often has zeros.
        if (get_sub_group_local_id() == 0) {
            dst[0] = 0xAD;
            dst[1] = 0xDE;
        }
        return;
    }
    uint lane = get_sub_group_local_id();
    const int rows = d->rows, K = d->cols_k, eb = d->elem_bytes;
    const int ld = d->ld ? d->ld : K;
    const int k_base = c0, m_base = c1;
    long outer = (long)c2 * (long)d->stride_c2 + (long)c3 * (long)d->stride_c3;
    __global const uchar *gbase =
        (__global const uchar *)(d->global_base) + (ulong)(outer * eb);

    if (d->swizzle == 4) {
        for (int m = 0; m < rows; m++)
            for (int k = 0; k < K; k++)
                zlift_tma_copy_elem(dst, (m * K + k) * eb,
                                    gbase + (ulong)((m_base + m) * ld
                                                    + (k_base + k)) * eb, eb);
        return;
    }

    if (d->swizzle == 3) {
        const int maxr = d->max_rows;            // 0 => no clamp
        const int swb = d->swiz_b ? d->swiz_b : 3;
        const int atom_w = (eb == 1) ? 128 : (8 << swb);
        for (int m = 0; m < rows; m++) {
            // A partial last tile reads rows the tensor does not have; the
            // consumer masks them, so they are zeroed rather than fetched.
            bool oob = (maxr > 0 && (m_base + m) >= maxr);
            for (int k = 0; k < K; k++) {
                int s_elem = (k / atom_w) * (rows * atom_w)
                             + zlift_gmma_swizzle(m * atom_w + (k % atom_w), swb);
                if (oob) {
                    for (int i = 0; i < eb; i++)
                        dst[s_elem * eb + i] = 0;
                    continue;
                }
                zlift_tma_copy_elem(dst, s_elem * eb,
                                    gbase + (ulong)((m_base + m) * ld
                                                    + (k_base + k)) * eb, eb);
            }
        }
        return;
    }

    // K-INTER. Which eight-wide K block this call carries is recoverable from
    // where in shared memory it was told to land, relative to the tile's base —
    // the host records that base precisely so this arithmetic can work.
    const int kblock_bytes = rows * 8 * eb;
    int block = kblock_bytes > 0
                    ? ((int)smem_off - d->tile_base_off) / kblock_bytes
                    : 0;
    if (block < 0)
        block = 0;
    // Where in K this call starts. Two things can say it and they must not
    // both be believed: the coordinate operand (`c0`) when the kernel walks K
    // by descriptor coordinate, and the destination offset when it walks K by
    // where in shared memory the block lands. `tma_hgmma` does both — the
    // second block arrives with c0 = 8 *and* a destination one block along —
    // and adding them read K elements 16..23 of a 16-wide tile.
    const int k_lo = block * 8;
    const int kstart = k_base ? k_base : k_lo;
    for (int m = 0; m < rows; m++)
        for (int kk = 0; kk < 8 && kstart + kk < K; kk++)
            zlift_tma_copy_elem(dst, (m * 8 + kk) * eb,
                                gbase + (ulong)((m_base + m) * ld
                                                + (kstart + kk)) * eb, eb);
}

// ---------------------------------------------------------------------------
// wgmma — warpgroup matrix multiply-accumulate
// ---------------------------------------------------------------------------
//
// `wgmma.mma_async` is the sm_90 tensor-core instruction, and it is the one
// NVIDIA op whose *operands* are easier to emulate than `mma.sync`'s: A and B
// are not register fragments handed round the warp, they are tiles sitting in
// shared memory, described by a 64-bit descriptor. Every thread can read what
// it needs directly, so there is no shuffling here at all — only addressing.
//
// The descriptor, per the PTX ISA:
//
//     bits  0-13  start address >> 4
//     bits 16-29  leading dimension byte offset >> 4   (step along K)
//     bits 32-45  stride dimension byte offset >> 4    (step along M or N)
//     bits 49-51  matrix base offset (swizzled layouts only)
//     bits 62-63  swizzle: 0 none, 1 = 128B, 2 = 64B, 3 = 32B
//
// The start address is not used here: the caller has already turned it into a
// byte offset into @shared_mem, because the descriptor's 14-bit field is
// relative to the CTA's shared window on real hardware and to nothing at all
// here.
//
// The tile is a grid of "core matrices", each eight rows of eight halves — 128
// bytes, one row per 16 bytes. Element (mn, k) is therefore
//
//     (mn/8)*SBO + (k/8)*LBO + (mn%8)*16 + (k%8)*2
//
// and a swizzled layout then XORs bits 9..7 of that offset (fewer bits for the
// narrower modes) into bits 6..4, which is the same pattern the TMA GMMA path
// above applies.
static int zlift_gmma_off(int base, int mn, int k, ulong desc)
{
    const int lbo = (int)((desc >> 16) & 0x3FFF) << 4;
    const int sbo = (int)((desc >> 32) & 0x3FFF) << 4;
    const int sw  = (int)((desc >> 62) & 0x3);
    // Rows inside a core matrix are 16 bytes apart only when nothing is
    // swizzled. A swizzled tile's row is the swizzle width — 128, 64 or 32
    // bytes — and using 16 there makes `(mn%8)*16` collide with `(k/8)*LBO`,
    // which is also 16 for those modes: two different elements at one address.
    const int rowb = sw ? (128 >> (sw - 1)) : 16;
    int o = base + (mn >> 3) * sbo + (k >> 3) * lbo + (mn & 7) * rowb
            + (k & 7) * 2;
    if (sw) {
        // Two things this has to get right. cute's `Swizzle<B,4,3>` is defined
        // on the *element* index, not the byte offset — it XORs bits 9..7 into
        // bits 6..4 of a count of halves — and the TMA path above, which laid
        // this tile out, uses exactly that. And the index it applies to is the
        // absolute one: the descriptor's start address moves between calls (by
        // 32 bytes per k16 block here), and swizzling a tile-relative offset
        // and adding the base afterwards is not the same function.
        const int bits = 4 - sw;      // 128B -> 3, 64B -> 2, 32B -> 1
        int e = o >> 1;
        e ^= ((e >> 7) & ((1 << bits) - 1)) << 4;
        o = e << 1;
    }
    return o;
}

// The accumulator layout is the `m16n8k16` C layout tiled over four warps.
// Warp w owns rows w*16 .. w*16+15; register i of lane l is row
// w*16 + ((i%4)/2)*8 + l/4 and column (i/4)*8 + (l%4)*2 + (i&1). With N/2
// registers per thread that covers 16 rows by N columns per warp, which is the
// whole 64 x N tile across the warpgroup.
//
// One register per call. The alternative — one call filling an array — needs
// somewhere to put the array, and the only somewhere available is an `alloca`
// that would sit inside whatever loop the mainloop wraps this in. A scalar
// return needs no storage at all, and the work is the same either way.
//
// `acc_in` is what PTX's `scaleD` selects: the caller passes the accumulator
// when scaleD is 1 and zero when it is 0. `scale_ab` is the product of PTX's
// `scaleA` and `scaleB`, which are +1/-1 and fold into the sign of the term.
__attribute__((convergent))
float __zlift_wgmma_elem_f32_f16_f16(__local const uchar *sm,
                                     int a_off, ulong desc_a,
                                     int b_off, ulong desc_b,
                                     int i, int scale_ab, float acc_in)
{
    // A descriptor that never arrived reads as zero, and the offset derived
    // from it is a 14-bit wrap of the shared-memory base — far outside the
    // tile, and an illegal access rather than a wrong answer. That happens on
    // the `cubin` path, where the drivers hand the descriptor over by writing a
    // *driver* constant-bank slot and `cuLaunchKernel` has no way to say so.
    // Returning the accumulator untouched keeps the answer wrong and the device
    // healthy, which is the right trade: a fault costs the whole run.
    if (!desc_a || !desc_b)
        return acc_in;

    const uint tid = (uint)get_local_linear_id() & 127u;
    const int  w   = (int)(tid >> 5);
    const int  l   = (int)(tid & 31u);
    // Indexed from @shared_mem, not from the tile: the swizzle is a function of
    // the absolute address.
    const __local half *S = (const __local half *)sm;

    const int m = w * 16 + ((i & 3) >> 1) * 8 + (l >> 2);
    const int c = (i >> 2) * 8 + (l & 3) * 2 + (i & 1);
    const float sgn = scale_ab < 0 ? -1.0f : 1.0f;

    float s = acc_in;
    // `vload_half` rather than a dereference: without cl_khr_fp16 a half is a
    // storage type only, and this is the builtin OpenCL provides for reading
    // one. It converts to float on the way, which is what is wanted.
    for (int k = 0; k < 16; k++) {
        const float av = vload_half(zlift_gmma_off(a_off, m, k, desc_a) >> 1, S);
        const float bv = vload_half(zlift_gmma_off(b_off, c, k, desc_b) >> 1, S);
        s += sgn * (av * bv);
    }
    return s;
}

// ---------------------------------------------------------------------------
// Atomic float add
// ---------------------------------------------------------------------------
//
// `SPV_EXT_shader_atomic_float_add` is in the extension list this module is
// translated with, and it does not arrive: the backend emits a call to
// `__spirv_AtomicFAddEXT` instead of the instruction, and IGC answers
// "undefined reference to _Z21__spirv_AtomicFAddEXTPU3AS1ciif" — mangled for a
// `char*`, because under opaque pointers there is no element type left to
// mangle from. `cross_cta_spin` is the only kernel in the corpus that reaches
// for one, so nothing has ever depended on the native path working.
//
// A compare-exchange loop is the portable answer and is what every library
// writes when the hardware op is missing. Bit-level compare-exchange on the
// integer alias, so a value that happens to be NaN does not spin forever the
// way an `==` on floats would.
__attribute__((convergent))
float __zlift_atomic_fadd_global(__global float *p, float v)
{
    volatile __global uint *w = (volatile __global uint *)p;
    uint old = *w, prev;
    do {
        prev = old;
        const float sum = as_float(old) + v;
        old = atomic_cmpxchg(w, prev, as_uint(sum));
    } while (old != prev);
    return as_float(prev);
}

// ---------------------------------------------------------------------------
// LDSM.16.MT88.4 feeding an fp8 byte de-interleave
// ---------------------------------------------------------------------------
//
// FA3's e4m3 V-transpose is `LDSM.16.MT88.4` followed by
// `PRMT 0x6420`/`PRMT 0x7531` and a plain `STSM.16.M88.4`. Composed with the
// transpose this ISA documents — 16-bit units, so a register half is two
// *adjacent* bytes — that sequence does not produce the transpose it is written
// to produce, and `sm90_synth/fp8_vt_transpose` is wrong by exactly that.
//
// The test carries a real oracle (a CPU transpose), and the other two
// instructions are not in doubt, so what the load must return is not a guess:
// it can be solved for. Doing that gives one closed form, and it fits all 512
// constraints — 32 lanes x 4 registers x 4 bytes:
//
//     s = 4*(L&3) + 2*(k%2) + (j>>1)
//     h = (L>>2) + 8*(j&1) + 16*(k>>1)
//
// Lane L receives seq rows 4m..4m+3 by hdim bytes {c, c+8, c+16, c+24}, with
// m = L&3 and c = L>>2, and the 32 lanes tile the 16x32 byte matrix exactly. So
// the hardware's transpose here pairs bytes *eight apart* in one 16-bit unit
// rather than adjacent ones, and the PRMT then completes the 8-bit transpose,
// which is what the kernel's own comment says is supposed to happen.
//
// This is inference, not documentation: it is derived from one access pattern
// and confirmed against that pattern's oracle. Whether the same rule holds for
// other shapes would need an NVIDIA device to measure.
__attribute__((always_inline))
static uint zlift_ldsm_byte(int w0, int w1, int w2, int w3, uint src, uint off) {
    int word = zlift_ldsm_row_word(w0, w1, w2, w3, src, off >> 2);
    return ((uint)word >> ((off & 3u) * 8u)) & 0xffu;
}

__attribute__((convergent))
int4 __zlift_ldmatrix_x4_mt88_fp8(__local const uint *row) {
    ZLIFT_LDSM_BODY
    const uint m = lane & 3u, c = lane >> 2;
    int out[4];
    __attribute__((opencl_unroll_hint))
    for (uint k = 0u; k < 4u; k++) {
        uint v = 0u;
        __attribute__((opencl_unroll_hint))
        for (uint j = 0u; j < 4u; j++) {
            const uint s = 4u * m + 2u * (k & 1u) + (j >> 1);
            const uint h = c + 8u * (j & 1u) + 16u * (k >> 1);
            // Which lane holds byte (s, h): each lane addressed seq row L&15 of
            // the 16-byte half L>>4, so the byte is in lane s + 16*(h/16) at
            // offset h%16.
            v |= zlift_ldsm_byte(w0, w1, w2, w3, s + 16u * (h >> 4), h & 15u)
                 << (8u * j);
        }
        out[k] = (int)v;
    }
    return (int4)(out[0], out[1], out[2], out[3]);
}

// ---------------------------------------------------------------------------
// 2:4 structured-sparse IMMA
// ---------------------------------------------------------------------------
//
// `mma.sp.sync.aligned.m16n8k64.row.col.s32.s8.s8.s32.satfinite`. A is stored
// compressed — two of every four K columns kept — and E says which two: four
// bits per group of four columns, holding the two 2-bit indices.
//
// The fragment maps are a bijection, which is what makes this straightforward.
// A's compressed value `p` of lane `t` sits at
//
//     off = 64*(t&3) + (t>>2) + 16*(p%4) + 8*((p/4)%2) + 256*((p/8)%2)
//     m = off % 16, ccol = off / 16
//
// and writing `off` out in bits — [2:0]=t>>2, [3]=(p/4)%2, [5:4]=p%4,
// [7:6]=t&3, [8]=(p/8)%2 — shows every (m, ccol) has exactly one (t, p). So
// rather than gathering, each consumer inverts: it knows which (m, ccol) it
// wants and computes the lane and byte holding it. B inverts the same way.
//
// E travels with A: the selector for a value's group is in the *same* lane's E,
// at bits [4j .. 4j+3] with j = p/2, and the low or high half of that nibble
// depending on p's parity — the two kept columns of a group are consecutive
// values of p.
//
// `satfinite` is not reproduced: the accumulator is s32 and these products
// cannot reach it. A kernel that relied on saturation would need it.
__attribute__((always_inline))
static int zlift_sp_byte(int r0, int r1, int r2, int r3, uint src, uint p) {
    int w = zlift_ldsm_row_word(r0, r1, r2, r3, src, p >> 2);
    return (int)(char)((w >> (8u * (p & 3u))) & 0xff);
}

__attribute__((convergent))
int4 __zlift_mma_sp_m16n8k64_s32_s8(int a0, int a1, int a2, int a3,
                                    int b0, int b1, int b2, int b3,
                                    int4 c, int e)
{
    const uint lane = get_sub_group_local_id();
    int acc[4] = {c.s0, c.s1, c.s2, c.s3};

    __attribute__((opencl_unroll_hint))
    for (uint v = 0u; v < 4u; v++) {
        const uint m = (lane >> 2) + 8u * (v >> 1);
        const uint n = (lane & 3u) * 2u + (v & 1u);
        int s = acc[v];
        for (uint ccol = 0u; ccol < 32u; ccol++) {
            // Where A_comp[m][ccol] lives.
            const uint ta = ((ccol >> 2) & 3u) | ((m & 7u) << 2);
            const uint pa = (ccol & 3u) + 4u * ((m >> 3) & 1u)
                            + 8u * ((ccol >> 4) & 1u);
            const int av = zlift_sp_byte(a0, a1, a2, a3, ta, pa);

            // Its group's selector, from the same lane's metadata.
            const int ev = intel_sub_group_shuffle(e, ta);
            const uint nib = ((uint)ev >> (4u * (pa >> 1))) & 0xfu;
            const uint idx = (pa & 1u) ? ((nib >> 2) & 3u) : (nib & 3u);
            const uint k = 4u * (ccol >> 1) + idx;

            // Where B[n][k] lives.
            const uint bk = k & 31u;
            const uint ps = (bk & 3u) + 4u * ((bk >> 4) & 1u);
            const uint pb = ps + 8u * (k >> 5);
            const uint tb = ((bk >> 2) & 3u) | (n << 2);
            const int bv = zlift_sp_byte(b0, b1, b2, b3, tb, pb);

            s += av * bv;
        }
        acc[v] = s;
    }
    return (int4)(acc[0], acc[1], acc[2], acc[3]);
}

// ---------------------------------------------------------------------------
// wgmma through XMX
// ---------------------------------------------------------------------------
//
// `__zlift_wgmma_elem_f32_f16_f16` reads sixteen halves of A and sixteen of B
// out of shared memory FOR EVERY ACCUMULATOR ELEMENT, so a 64xN tile re-reads
// each element of A once per column. That is the cost worth attacking, and
// wgmma is where the attack works: its operands are in memory rather than in a
// fragment somebody else chose the layout of, so each lane can load straight
// into the layout XMX wants and never shuffle to get there.
//
// One call computes EIGHT accumulator registers — two of wgmma's eight-column
// blocks over all sixteen of the warp's rows — as two
// `OpSubgroupMatrixMultiplyAccumulateINTEL` of M8 N16 K16. Twelve loads per
// lane instead of two hundred and fifty-six.
//
// Needs LLVM 22: the extension does not exist in LLVM 20, which is what the
// offline path compiles with today. Unreferenced it is `linkonce_odr` and
// `globaldce` drops it, so carrying it costs modules that do not call it
// nothing.

float4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int K, short4 A, int4 B,
                                                     float4 C, int Operands);

// Which of A's sixteen k slots each of the sixteen lanes in a half-subgroup
// holds — measured, see tools/xmx_probe.sh. This is the inverse: lane index to
// k. The forward map is 0 1 4 5 8 9 12 13 2 3 6 7 10 11 14 15.
__constant static const uchar ZLIFT_DPAS_K[16] =
    {0, 1, 8, 9, 2, 3, 10, 11, 4, 5, 12, 13, 6, 7, 14, 15};

// `always_inline` is load-bearing, not tidiness: the fragment widths XMX
// requires depend on the sub-group size the code is compiled FOR, and left as a
// separate function this is compiled at the default sixteen and IGC asks for
// eight B components where a thirty-two-lane sub-group takes four. Inlined into
// the kernel — which carries `intel_reqd_sub_group_size(32)` — it is compiled
// against the width it will actually run at.

/// One component of a shuffled `float4`, with ALL FOUR shuffles executed.
///
/// Selecting first and shuffling second is the obvious way to write it and it
/// is wrong: `intel_sub_group_shuffle` is a sub-group collective, and a ternary
/// puts three of the four in branches the lane does not take. Written that way
/// exactly a quarter of the accumulator registers came back right, which is
/// what one working component out of four looks like.
__attribute__((always_inline))
static float zlift_pick4(float4 d, uint src, int comp) {
    const float v0 = intel_sub_group_shuffle(d.s0, src);
    const float v1 = intel_sub_group_shuffle(d.s1, src);
    const float v2 = intel_sub_group_shuffle(d.s2, src);
    const float v3 = intel_sub_group_shuffle(d.s3, src);
    return comp == 0 ? v0 : comp == 1 ? v1 : comp == 2 ? v2 : v3;
}

// The same tile, with the readback through memory instead of across lanes.
//
// The shuffle version above is right everywhere it can be checked in isolation:
// `tools/wgmma_xmx_probe.sh` runs it against the element-at-a-time oracle over
// four descriptor shapes, four swizzle modes and both column blocks, and it
// agrees on all 1024 accumulator elements of all 32 configurations. In a real
// lifted kernel it does not. Every ingredient was checked there too, on the
// kernel's own data: the fragments are read from the right addresses, the
// multiply returns non-zero, and each lane's own component 0 is exactly the dot
// product the measured layout says it should be. What fails is the move: ask a
// lane for component 0 of lane 0 — a uniform source, a value verified correct
// where it sits — and it receives something else. The identical shuffle in the
// probe delivers it, 128 lanes out of 128.
//
// So this one does not move anything between lanes. Each lane writes the eight
// values it computed to workgroup memory laid out as the 16x16 tile, and reads
// back the eight wgmma wants. `scratch_off` is a tail `define_shared_memory`
// appends past everything the kernel itself addresses, 1 KB per sub-group;
// beyond the eighth sub-group there is no room and the element path answers
// instead, which is slow and right rather than fast and wrong.
#define ZLIFT_XMX_SCRATCH_SUBGROUPS 8

float8 __zlift_wgmma_tile8_ref_f32_f16_f16(__local const uchar *sm,
                                           int a_off, ulong desc_a,
                                           int b_off, ulong desc_b,
                                           int cb2, int scale_ab,
                                           float8 acc_in);

__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_mem_f32_f16_f16(__local const uchar *sm,
                                           int a_off, ulong desc_a,
                                           int b_off, ulong desc_b,
                                           int cb2, int scale_ab, float8 acc_in,
                                           int scratch_off)
{
    if (!desc_a || !desc_b)
        return acc_in;
    const uint sg = get_sub_group_id();
    if (sg >= (uint)ZLIFT_XMX_SCRATCH_SUBGROUPS)
        return __zlift_wgmma_tile8_ref_f32_f16_f16(sm, a_off, desc_a, b_off,
                                                   desc_b, cb2, scale_ab,
                                                   acc_in);

    const uint tid = (uint)get_local_linear_id() & 127u;
    const int  w   = (int)(tid >> 5);
    const int  l   = (int)(tid & 31u);
    const __local ushort *R = (const __local ushort *)sm;
    const int hi16 = l >> 4, lo16 = l & 15, c0 = cb2 * 16;
    const float sgn = scale_ab < 0 ? -1.0f : 1.0f;

    // Not arrays: see the warning on the tile above. A fragment that lands in
    // private memory comes back zero in a large kernel.
#define ZLIFT_B_HALF(hh) \
    ((ushort)R[zlift_gmma_off(b_off, c0 + lo16, 8 * hi16 + (hh), desc_b) >> 1])
    const int4 bfrag = (int4)(
        (int)(((uint)ZLIFT_B_HALF(1) << 16) | ZLIFT_B_HALF(0)),
        (int)(((uint)ZLIFT_B_HALF(3) << 16) | ZLIFT_B_HALF(2)),
        (int)(((uint)ZLIFT_B_HALF(5) << 16) | ZLIFT_B_HALF(4)),
        (int)(((uint)ZLIFT_B_HALF(7) << 16) | ZLIFT_B_HALF(6)));
#undef ZLIFT_B_HALF

    const int ka = ZLIFT_DPAS_K[lo16];
#define ZLIFT_A_FRAG(rh)                                                       \
    ((short4)((short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 0,  \
                                      ka, desc_a) >> 1],                       \
              (short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 1,  \
                                      ka, desc_a) >> 1],                       \
              (short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 2,  \
                                      ka, desc_a) >> 1],                       \
              (short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 3,  \
                                      ka, desc_a) >> 1]))
    const float4 d0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
        16, ZLIFT_A_FRAG(0), bfrag, (float4)(0.0f), 3072);
    const float4 d1 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
        16, ZLIFT_A_FRAG(1), bfrag, (float4)(0.0f), 3072);
#undef ZLIFT_A_FRAG

    // D[m][n] of a multiply sits in lane 16*(m/4) + n, component m%4 — so this
    // lane holds rows 4*(l/16) + 0..3 of each half, all in column l%16.
    __local float *scr = (__local float *)((__local uchar *)sm + scratch_off)
                       + sg * 256u;
    const int r0 = 4 * hi16;
    scr[(r0 + 0) * 16 + lo16] = d0.s0;
    scr[(r0 + 1) * 16 + lo16] = d0.s1;
    scr[(r0 + 2) * 16 + lo16] = d0.s2;
    scr[(r0 + 3) * 16 + lo16] = d0.s3;
    scr[(8 + r0 + 0) * 16 + lo16] = d1.s0;
    scr[(8 + r0 + 1) * 16 + lo16] = d1.s1;
    scr[(8 + r0 + 2) * 16 + lo16] = d1.s2;
    scr[(8 + r0 + 3) * 16 + lo16] = d1.s3;
    // A sub-group barrier, not a workgroup one: the tile is reached under
    // predicates in a lifted kernel, and a workgroup barrier some threads never
    // arrive at is a hang rather than a wrong answer.
    sub_group_barrier(CLK_LOCAL_MEM_FENCE);

    // Register r of lane l is row ((r&3)>>1)*8 + l/4, column
    // (r>>2)*8 + (l&3)*2 + (r&1) — both inside this 16x16 tile.
#define ZLIFT_AT(r) scr[((((r) & 3) >> 1) * 8 + (l >> 2)) * 16                 \
                        + (((r) >> 2) * 8 + (l & 3) * 2 + ((r) & 1))]
    const float8 got = (float8)(
        ZLIFT_AT(0), ZLIFT_AT(1), ZLIFT_AT(2), ZLIFT_AT(3),
        ZLIFT_AT(4), ZLIFT_AT(5), ZLIFT_AT(6), ZLIFT_AT(7));
#undef ZLIFT_AT
    return acc_in + sgn * got;
}

__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_f32_f16_f16(__local const uchar *sm,
                                       int a_off, ulong desc_a,
                                       int b_off, ulong desc_b,
                                       int cb2, int scale_ab, float8 acc_in)
{
    if (!desc_a || !desc_b)
        return acc_in;

    const uint tid = (uint)get_local_linear_id() & 127u;
    const int  w   = (int)(tid >> 5);
    const int  l   = (int)(tid & 31u);
    // The raw sixteen-bit storage, because what XMX wants is the bits and not
    // a float: `vload_half` converts on the way, which would have to be undone.
    const __local ushort *R = (const __local ushort *)sm;

    const int hi16 = l >> 4;          // which half-subgroup this lane is in
    const int lo16 = l & 15;          // its index inside it
    const int c0   = cb2 * 16;
    const float sgn = scale_ab < 0 ? -1.0f : 1.0f;

    // NOT ARRAYS. Written with `short bh[8]` and `float4 d[2]` this compiles to
    // an `alloca` that survives `always-inline,globaldce` in a real module —
    // the multiply's result went to memory and came back zero, while the same
    // source promoted to registers in a smaller kernel and gave the right
    // answer. The device library's own MMA loop carries the same warning about
    // fragments left in private memory. Scalars cannot be spilled to an
    // address that something else rewrites.
#define ZLIFT_B_HALF(hh) \
    ((ushort)R[zlift_gmma_off(b_off, c0 + lo16, 8 * hi16 + (hh), desc_b) >> 1])
    const int4 bfrag = (int4)(
        (int)(((uint)ZLIFT_B_HALF(1) << 16) | ZLIFT_B_HALF(0)),
        (int)(((uint)ZLIFT_B_HALF(3) << 16) | ZLIFT_B_HALF(2)),
        (int)(((uint)ZLIFT_B_HALF(5) << 16) | ZLIFT_B_HALF(4)),
        (int)(((uint)ZLIFT_B_HALF(7) << 16) | ZLIFT_B_HALF(6)));
#undef ZLIFT_B_HALF

    const int ka = ZLIFT_DPAS_K[lo16];
#define ZLIFT_A_FRAG(rh)                                                       \
    ((short4)((short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 0,  \
                                      ka, desc_a) >> 1],                       \
              (short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 1,  \
                                      ka, desc_a) >> 1],                       \
              (short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 2,  \
                                      ka, desc_a) >> 1],                       \
              (short)R[zlift_gmma_off(a_off, w * 16 + (rh) * 8 + 4 * hi16 + 3,  \
                                      ka, desc_a) >> 1]))

    // 3072 = MatrixAPackedFloat16INTEL | MatrixBPackedFloat16INTEL.
    const float4 d0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
        16, ZLIFT_A_FRAG(0), bfrag, (float4)(0.0f), 3072);
    const float4 d1 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
        16, ZLIFT_A_FRAG(1), bfrag, (float4)(0.0f), 3072);
#undef ZLIFT_A_FRAG

    // Back to wgmma's accumulator layout. Register r of lane l is row
    // ((r&3)>>1)*8 + l/4 and column c0 + (r>>2)*8 + (l&3)*2 + (r&1); the value
    // sits in XMX lane 16*((l/4)>>2) + n, component (l/4)&3, of the half
    // ((r&3)>>1). The component varies per lane, so all four are shuffled and
    // the right one selected — a shuffle moves a variable, not an index.
    const int mm   = l >> 2;                     // 0..7, the row inside a half
    const int comp = mm & 3;
    const int lbase = 16 * (mm >> 2);
#define ZLIFT_PICK(d, n) zlift_pick4((d), (uint)((lbase) + (n)), comp)
#define ZLIFT_N(r) ((((r) >> 2) * 8) + ((l & 3) * 2) + ((r) & 1))
    const float8 got = (float8)(
        ZLIFT_PICK(d0, ZLIFT_N(0)), ZLIFT_PICK(d0, ZLIFT_N(1)),
        ZLIFT_PICK(d1, ZLIFT_N(2)), ZLIFT_PICK(d1, ZLIFT_N(3)),
        ZLIFT_PICK(d0, ZLIFT_N(4)), ZLIFT_PICK(d0, ZLIFT_N(5)),
        ZLIFT_PICK(d1, ZLIFT_N(6)), ZLIFT_PICK(d1, ZLIFT_N(7)));
#undef ZLIFT_PICK
#undef ZLIFT_N
    return acc_in + sgn * got;
}

// The same eight registers computed the slow way, for telling a wrong LOWERING
// apart from a wrong tile: point `lower_wgmma` at this and a case that still
// fails is failing in how the call is emitted, not in the matrix multiply.
__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_ref_f32_f16_f16(__local const uchar *sm,
                                           int a_off, ulong desc_a,
                                           int b_off, ulong desc_b,
                                           int cb2, int scale_ab, float8 acc_in)
{
    float o[8];
    float a[8] = {acc_in.s0, acc_in.s1, acc_in.s2, acc_in.s3,
                  acc_in.s4, acc_in.s5, acc_in.s6, acc_in.s7};
    for (int r = 0; r < 8; r++)
        o[r] = __zlift_wgmma_elem_f32_f16_f16(sm, a_off, desc_a, b_off, desc_b,
                                              cb2 * 8 + r, scale_ab, a[r]);
    return (float8)(o[0], o[1], o[2], o[3], o[4], o[5], o[6], o[7]);
}

// The diagnostic tiles, behind a build flag.
//
// These answered the question of why the shuffle readback is right in the
// probe and wrong in a real kernel — the account is in docs/session-state.md
// — and they are kept for the next time something in this path disagrees
// with itself. They are not built by default: the device library is linked
// whole into every module, external definitions survive `globaldce`, and the
// comparison loops in `_ask_` vectorise into a `bitcast <4 x i1> to i4` that
// the SPIR-V backend aborts on. Build with -DZLIFT_DEVLIB_DIAG to get them.
#ifdef ZLIFT_DEVLIB_DIAG

// Compare the two INSIDE a real kernel, using the driver's mismatch count as
// the only channel there is: every accumulator register the multiply gets wrong
// is returned a thousand too high, so "N / 1024 elements exceed eps" counts the
// disagreements. `ZLIFT_XMX_FN` points the lowering at this.
__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_diff_f32_f16_f16(__local const uchar *sm,
                                            int a_off, ulong desc_a,
                                            int b_off, ulong desc_b,
                                            int cb2, int scale_ab, float8 acc_in)
{
    float8 x = __zlift_wgmma_tile8_f32_f16_f16(sm, a_off, desc_a, b_off, desc_b,
                                               cb2, scale_ab, acc_in);
    float8 r = __zlift_wgmma_tile8_ref_f32_f16_f16(sm, a_off, desc_a, b_off,
                                                   desc_b, cb2, scale_ab, acc_in);
    float xs[8] = {x.s0, x.s1, x.s2, x.s3, x.s4, x.s5, x.s6, x.s7};
    float rs[8] = {r.s0, r.s1, r.s2, r.s3, r.s4, r.s5, r.s6, r.s7};
    // How many lanes are here at all. A matrix multiply is a sub-group
    // collective: every lane has to supply its slice of A and B, and a lane
    // that took a different branch supplies nothing. The element path does not
    // care — it is per-lane arithmetic — which is exactly why one can be right
    // where the other is wrong.
    const int active = sub_group_reduce_add(1);
    float o[8];
    for (int i = 0; i < 8; i++)
        o[i] = rs[i]
             + (fabs(xs[i] - rs[i]) > 1e-3f ? 1000.0f : 0.0f)
             + (active != 32 ? 1000000.0f : 0.0f);
    return (float8)(o[0], o[1], o[2], o[3], o[4], o[5], o[6], o[7]);
}

// Is the multiply getting zeros, or producing them? Returns the reference
// answer plus a marker, so the driver's mismatch count says which:
//   +1000    the A fragment this lane supplies is all zero
//   +10000   the B fragment is all zero
//   +100000  both fragments are non-zero and the multiply still returned zero
__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_why_f32_f16_f16(__local const uchar *sm,
                                           int a_off, ulong desc_a,
                                           int b_off, ulong desc_b,
                                           int cb2, int scale_ab, float8 acc_in)
{
    const uint tid = (uint)get_local_linear_id() & 127u;
    const int  w   = (int)(tid >> 5);
    const int  l   = (int)(tid & 31u);
    const __local ushort *R = (const __local ushort *)sm;
    const int hi16 = l >> 4, lo16 = l & 15, c0 = cb2 * 16;
    const int ka = ZLIFT_DPAS_K[lo16];

    int anz = 0, bnz = 0;
    for (int s2 = 0; s2 < 4; s2++)
        anz |= (int)R[zlift_gmma_off(a_off, w * 16 + 4 * hi16 + s2, ka, desc_a) >> 1];
    for (int hh = 0; hh < 8; hh++)
        bnz |= (int)R[zlift_gmma_off(b_off, c0 + lo16, 8 * hi16 + hh, desc_b) >> 1];

    float8 x = __zlift_wgmma_tile8_f32_f16_f16(sm, a_off, desc_a, b_off, desc_b,
                                               cb2, scale_ab, (float8)(0.0f));
    float8 r = __zlift_wgmma_tile8_ref_f32_f16_f16(sm, a_off, desc_a, b_off,
                                                   desc_b, cb2, scale_ab, acc_in);
    const float prod = fabs(x.s0) + fabs(x.s1) + fabs(x.s2) + fabs(x.s3)
                     + fabs(x.s4) + fabs(x.s5) + fabs(x.s6) + fabs(x.s7);
    const float mark = (anz == 0 ? 1000.0f : 0.0f)
                     + (bnz == 0 ? 10000.0f : 0.0f)
                     + ((anz != 0 && bnz != 0 && prod == 0.0f) ? 100000.0f : 0.0f);
    return r + mark;
}

// Does the instruction work AT ALL in this module? A and B are constant 1.0h,
// K is 16, so every component of the result must be 16.0 whatever the lane
// layout is — the identity that needs no mapping to be right. Marker:
//   +1000    the constant multiply did not return 16
//   +10000   it did, so the instruction works and the operands are the problem
__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_ident_f32_f16_f16(__local const uchar *sm,
                                             int a_off, ulong desc_a,
                                             int b_off, ulong desc_b,
                                             int cb2, int scale_ab, float8 acc_in)
{
    const short4 ones_a = (short4)((short)0x3C00);
    const int4   ones_b = (int4)(0x3C003C00);
    const float4 id = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
        16, ones_a, ones_b, (float4)(0.0f), 3072);
    float8 r = __zlift_wgmma_tile8_ref_f32_f16_f16(sm, a_off, desc_a, b_off,
                                                   desc_b, cb2, scale_ab, acc_in);
    const int good = (fabs(id.s0 - 16.0f) < 1e-3f) && (fabs(id.s1 - 16.0f) < 1e-3f)
                  && (fabs(id.s2 - 16.0f) < 1e-3f) && (fabs(id.s3 - 16.0f) < 1e-3f);
    return r + (good ? 10000.0f : 1000.0f);
}

// A channel, not a computation. The drivers report "N of M elements exceed
// eps" and nothing else, so a question has to be asked in those terms: return
// the reference answer where the answer is expected and something enormous
// where it is not, and the mismatch COUNT is the reply.
//
//   what:  0 = are A's four halves all zero?
//          1 = are B's eight halves all zero?
//          2 = did the multiply return all zeros for non-zero operands?
__attribute__((always_inline))
__attribute__((convergent))
float8 __zlift_wgmma_tile8_ask_f32_f16_f16(__local const uchar *sm,
                                           int a_off, ulong desc_a,
                                           int b_off, ulong desc_b,
                                           int cb2, int scale_ab, float8 acc_in,
                                           int what)
{
    const uint tid = (uint)get_local_linear_id() & 127u;
    const int  w   = (int)(tid >> 5);
    const int  l   = (int)(tid & 31u);
    const __local ushort *R = (const __local ushort *)sm;
    const int hi16 = l >> 4, lo16 = l & 15, c0 = cb2 * 16;

    float amag = 0.0f, bmag = 0.0f, dmag = 0.0f;
    short bh[8];
    for (int hh = 0; hh < 8; hh++) {
        bh[hh] = (short)R[zlift_gmma_off(b_off, c0 + lo16, 8 * hi16 + hh, desc_b) >> 1];
        bmag += fabs(vload_half(zlift_gmma_off(b_off, c0 + lo16, 8 * hi16 + hh, desc_b) >> 1,
                                (const __local half *)sm));
    }
    const int4 bfrag = (int4)(
        ((int)(ushort)bh[1] << 16) | (ushort)bh[0],
        ((int)(ushort)bh[3] << 16) | (ushort)bh[2],
        ((int)(ushort)bh[5] << 16) | (ushort)bh[4],
        ((int)(ushort)bh[7] << 16) | (ushort)bh[6]);
    for (int rh = 0; rh < 2; rh++) {
        const int k = ZLIFT_DPAS_K[lo16];
        short ah[4];
        for (int s = 0; s < 4; s++) {
            const int m = w * 16 + rh * 8 + 4 * hi16 + s;
            ah[s] = (short)R[zlift_gmma_off(a_off, m, k, desc_a) >> 1];
            amag += fabs(vload_half(zlift_gmma_off(a_off, m, k, desc_a) >> 1,
                                    (const __local half *)sm));
        }
        const float4 d = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(ah[0], ah[1], ah[2], ah[3]), bfrag, (float4)(0.0f), 3072);
        dmag += fabs(d.s0) + fabs(d.s1) + fabs(d.s2) + fabs(d.s3);
    }

    float8 good = __zlift_wgmma_tile8_ref_f32_f16_f16(sm, a_off, desc_a, b_off,
                                                      desc_b, cb2, scale_ab,
                                                      acc_in);

    // Does the multiply put its answer where the measured layout says?
    //
    // Asked of the CALLER's data rather than a synthetic tile, and without any
    // of the readback: for this lane's own DPAS position — row
    // w*16 + rh*8 + 4*(l/16) + comp, column c0 + (l%16) — compute the dot
    // product straight out of shared memory and compare. If this disagrees the
    // fault is in assembling the fragments or in where D lands; if it agrees,
    // the fault is downstream in the shuffle back to wgmma's layout.
    // The tile assembles its fragments by `get_local_linear_id() & 31` and then
    // shuffles by lane number. Those are the same number only if the sub-group
    // is laid over the work-group in order — which is an assumption, not a
    // guarantee, and the element path never had to make it because it does not
    // shuffle.
    if (what == 8) {
        const uint sgl = get_sub_group_local_id();
        return good + ((sgl != (uint)l) ? 1.0e6f : 0.0f);
    }
    // And the other half of the same assumption: that the sub-group is the
    // warp, so a shuffle stays inside the sixteen rows this lane's warp owns.
    if (what == 9) {
        return good + ((get_sub_group_size() != 32u
                        || get_sub_group_id() != (uint)w) ? 1.0e6f : 0.0f);
    }

    // Does the shuffle deliver from the lane the readback asks for? Shuffling
    // the lane index itself must return the index shuffled from.
    if (what == 11) {
        // Unrolled and with the converted value hoisted: written as a loop over
        // a converted lane index this crashed llc, which is a fact about the
        // backend and not about the shuffle.
        const int mm = l >> 2, lbase = 16 * (mm >> 2);
        const float me = (float)l;
        const uint s0 = (uint)(lbase + (l & 3) * 2);
        const uint s1 = s0 + 1u;
        const uint s2 = s0 + 8u;
        const uint s3 = s0 + 9u;
        const float g0 = intel_sub_group_shuffle(me, s0);
        const float g1 = intel_sub_group_shuffle(me, s1);
        const float g2 = intel_sub_group_shuffle(me, s2);
        const float g3 = intel_sub_group_shuffle(me, s3);
        const int okall = (g0 == (float)s0) && (g1 == (float)s1)
                       && (g2 == (float)s2) && (g3 == (float)s3);
        return good + (okall ? 0.0f : 1.0e6f);
    }
    // And is the destination this lane actually wants the one the readback
    // computes? Compare the brute-force answer for (row = w*16 + rh*8 + l/4,
    // col = c0 + N(r)) against the element path's own answer for register r.
    if (what == 12) {
        float bad = 0.0f;
        for (int r = 0; r < 8; r++) {
            const int rh = (r >> 1) & 1;
            const int m  = w * 16 + rh * 8 + (l >> 2);
            const int c  = c0 + ((r >> 2) * 8) + ((l & 3) * 2) + (r & 1);
            float want = 0.0f;
            for (int k = 0; k < 16; k++)
                want += vload_half(zlift_gmma_off(a_off, m, k, desc_a) >> 1,
                                   (const __local half *)sm)
                      * vload_half(zlift_gmma_off(b_off, c, k, desc_b) >> 1,
                                   (const __local half *)sm);
            const float gvv[8] = {good.s0, good.s1, good.s2, good.s3,
                                  good.s4, good.s5, good.s6, good.s7};
            if (fabs(want - gvv[r]) > 1e-2f)
                bad = 1.0e6f;
        }
        return good + bad;
    }

    // The whole thing again, written plainly here, compared against the element
    // path. If THIS is right the difference is the tile's own code; if it is
    // wrong the readback algebra is wrong and the probe agrees with it only
    // because the probe uses the same algebra.
    if (what == 14) {
        const int ka = ZLIFT_DPAS_K[lo16];
        short a0[4], a1[4];
        for (int s2 = 0; s2 < 4; s2++) {
            a0[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + 0 + 4 * hi16 + s2, ka, desc_a) >> 1];
            a1[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + 8 + 4 * hi16 + s2, ka, desc_a) >> 1];
        }
        const float4 e0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a0[0], a0[1], a0[2], a0[3]), bfrag, (float4)(0.0f), 3072);
        const float4 e1 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a1[0], a1[1], a1[2], a1[3]), bfrag, (float4)(0.0f), 3072);
        const int mm = l >> 2, comp = mm & 3, lbase = 16 * (mm >> 2);
        const float gvv[8] = {good.s0, good.s1, good.s2, good.s3,
                              good.s4, good.s5, good.s6, good.s7};
        // The reference carries the incoming accumulator and the sign; the
        // multiply's output does not. Comparing the raw product against it
        // marks everything and says nothing — which is what the first version
        // of this check did.
        const float av[8] = {acc_in.s0, acc_in.s1, acc_in.s2, acc_in.s3,
                             acc_in.s4, acc_in.s5, acc_in.s6, acc_in.s7};
        const float sg = scale_ab < 0 ? -1.0f : 1.0f;
        // Per register, not one flag for all eight: a single flag added to
        // everything reports 1024 of 1024 when one register is wrong, which is
        // a fact about the check and not about the code.
        float mk[8];
        for (int r = 0; r < 8; r++) {
            const uint src = (uint)(lbase + ((r >> 2) * 8) + ((l & 3) * 2) + (r & 1));
            const float4 d = ((r >> 1) & 1) ? e1 : e0;
            const float v = av[r] + sg * zlift_pick4(d, src, comp);
            // Relative, not absolute. The two paths sum the same sixteen
            // products in a different ORDER, and an absolute tolerance that
            // suits a probe filled with small integers is meaningless against
            // a real accumulator that runs to hundreds.
            const float scale = fmax(fabs(gvv[r]), 1.0f);
            mk[r] = fabs(v - gvv[r]) > 1.0e-2f * scale ? 1.0e6f : 0.0f;
        }
        return good + (float8)(mk[0], mk[1], mk[2], mk[3],
                               mk[4], mk[5], mk[6], mk[7]);
    }

    // Where the value the destination needs ACTUALLY is.
    //
    // Analysis kept saying the mapping was right and the device kept saying it
    // was not, so this stops deriving and searches: for register 0 of this
    // lane, look through all thirty-two lanes and all four components of the
    // multiply's output for the value the element path says register 0 should
    // hold, and report one bit of where it was found. `what` 20..24 are the
    // five bits of the lane, 25..26 the two bits of the component; each run
    // marks the lanes where that bit differs from what the readback computed.
    if (what >= 20 && what < 27) {
        const int ka = ZLIFT_DPAS_K[lo16];
        short a0[4];
        for (int s2 = 0; s2 < 4; s2++)
            a0[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + 4 * hi16 + s2,
                                             ka, desc_a) >> 1];
        const float4 e0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a0[0], a0[1], a0[2], a0[3]), bfrag, (float4)(0.0f), 3072);
        const float sg = scale_ab < 0 ? -1.0f : 1.0f;
        const float want = (good.s0 - acc_in.s0) / sg;   // register 0's product
        int found_lane = -1, found_comp = -1;
        for (uint src = 0; src < 32u; src++) {
            const float v0 = intel_sub_group_shuffle(e0.s0, src);
            const float v1 = intel_sub_group_shuffle(e0.s1, src);
            const float v2 = intel_sub_group_shuffle(e0.s2, src);
            const float v3 = intel_sub_group_shuffle(e0.s3, src);
            const float sc = fmax(fabs(want), 1.0f) * 1.0e-2f;
            if (found_lane < 0 && fabs(v0 - want) <= sc) { found_lane = (int)src; found_comp = 0; }
            if (found_lane < 0 && fabs(v1 - want) <= sc) { found_lane = (int)src; found_comp = 1; }
            if (found_lane < 0 && fabs(v2 - want) <= sc) { found_lane = (int)src; found_comp = 2; }
            if (found_lane < 0 && fabs(v3 - want) <= sc) { found_lane = (int)src; found_comp = 3; }
        }
        const int mm = l >> 2;
        const int want_lane = 16 * (mm >> 2) + ((l & 3) * 2);
        const int want_comp = mm & 3;
        int bad;
        if (found_lane < 0)
            bad = 1;                                   // nowhere at all
        else if (what < 25)
            bad = (((found_lane >> (what - 20)) & 1) != ((want_lane >> (what - 20)) & 1));
        else
            bad = (((found_comp >> (what - 25)) & 1) != ((want_comp >> (what - 25)) & 1));
        return good + (bad ? 1.0e6f : 0.0f);
    }

    // Is register 0's value in the multiply the readback picks, or the other
    // one? `what` 27 searches the half the readback does not use, 28 the half
    // it does; whichever comes back clean says where the value actually is.
    if (what == 27 || what == 28) {
        const int ka = ZLIFT_DPAS_K[lo16];
        const int rh = (what == 28) ? 0 : 1;
        short a0[4];
        for (int s2 = 0; s2 < 4; s2++)
            a0[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + rh * 8 + 4 * hi16 + s2,
                                             ka, desc_a) >> 1];
        const float4 e = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a0[0], a0[1], a0[2], a0[3]), bfrag, (float4)(0.0f), 3072);
        const float sg = scale_ab < 0 ? -1.0f : 1.0f;
        const float want = (good.s0 - acc_in.s0) / sg;
        const float sc = fmax(fabs(want), 1.0f) * 1.0e-2f;
        int found = 0;
        for (uint src = 0; src < 32u; src++) {
            if (fabs(intel_sub_group_shuffle(e.s0, src) - want) <= sc) found = 1;
            if (fabs(intel_sub_group_shuffle(e.s1, src) - want) <= sc) found = 1;
            if (fabs(intel_sub_group_shuffle(e.s2, src) - want) <= sc) found = 1;
            if (fabs(intel_sub_group_shuffle(e.s3, src) - want) <= sc) found = 1;
        }
        return good + (found ? 0.0f : 1.0e6f);
    }

    // What the real descriptors actually say, against what the probe assumes.
    // The probe passes on every shape and swizzle it has been given and the real
    // kernels fail, so the difference is in these numbers; each run marks the
    // lanes where one field is not what the probe drives.
    if (what >= 30 && what < 40) {
        const int lbo_a = (int)((desc_a >> 16) & 0x3FFF) << 4;
        const int sbo_a = (int)((desc_a >> 32) & 0x3FFF) << 4;
        const int sw_a  = (int)((desc_a >> 62) & 0x3);
        const int lbo_b = (int)((desc_b >> 16) & 0x3FFF) << 4;
        const int sbo_b = (int)((desc_b >> 32) & 0x3FFF) << 4;
        const int sw_b  = (int)((desc_b >> 62) & 0x3);
        int bad = 0;
        switch (what) {
        case 30: bad = (lbo_a != 128); break;
        case 31: bad = (sbo_a != 256); break;
        case 32: bad = (sw_a != 0); break;
        case 33: bad = (lbo_b != 256); break;
        case 34: bad = (sbo_b != 512); break;
        case 35: bad = (sw_b != 0); break;
        case 36: bad = (a_off != 0); break;
        case 37: bad = (b_off != 2048); break;
        case 38: bad = (lbo_a != lbo_b); break;
        case 39: bad = (sw_a != sw_b); break;
        }
        return good + (bad ? 1.0e6f : 0.0f);
    }

    // Does `zlift_pick4` return the component it is asked for, from the lane it
    // is asked for? Shuffling from the lane's own index makes the answer the
    // lane's own component, which it can check without any cross-lane
    // reasoning. If this fails the selection is wrong — the four shuffles being
    // sunk into branches the lane does not take, which is exactly what an
    // earlier version of this function did.
    if (what == 41) {
        const int ka = ZLIFT_DPAS_K[lo16];
        short a0[4];
        for (int s2 = 0; s2 < 4; s2++)
            a0[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + 4 * hi16 + s2,
                                             ka, desc_a) >> 1];
        const float4 e0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a0[0], a0[1], a0[2], a0[3]), bfrag, (float4)(0.0f), 3072);
        const float direct[4] = {e0.s0, e0.s1, e0.s2, e0.s3};
        int bad = 0;
        for (int c = 0; c < 4; c++)
            if (zlift_pick4(e0, (uint)l, c) != direct[c])
                bad = 1;
        return good + (bad ? 1.0e6f : 0.0f);
    }
    // And the cross-lane version of the same question, with a source this lane
    // can predict: lane 0's components, fetched by every lane.
    if (what == 42) {
        const int ka = ZLIFT_DPAS_K[lo16];
        short a0[4];
        for (int s2 = 0; s2 < 4; s2++)
            a0[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + 4 * hi16 + s2,
                                             ka, desc_a) >> 1];
        const float4 e0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a0[0], a0[1], a0[2], a0[3]), bfrag, (float4)(0.0f), 3072);
        int bad = 0;
        for (int c = 0; c < 4; c++) {
            const float viaPick = zlift_pick4(e0, 0u, c);
            const float viaShuf = c == 0 ? intel_sub_group_shuffle(e0.s0, 0u)
                                : c == 1 ? intel_sub_group_shuffle(e0.s1, 0u)
                                : c == 2 ? intel_sub_group_shuffle(e0.s2, 0u)
                                         : intel_sub_group_shuffle(e0.s3, 0u);
            if (viaPick != viaShuf) bad = 1;
        }
        return good + (bad ? 1.0e6f : 0.0f);
    }

    // Shuffling the MULTIPLY'S OUTPUT, against a brute-force expectation.
    // `ask 11` showed a shuffle delivers a lane index from a non-uniform source,
    // and `ask 42` showed the component selection is right from a uniform one —
    // but neither shuffled a value the matrix instruction produced from a
    // source that varies per lane, which is what the readback does.
    //
    //   43 = uniform source (lane 0, component 0)
    //   44 = non-uniform source (lane l%16, component 0)
    if (what == 43 || what == 44) {
        const int ka = ZLIFT_DPAS_K[lo16];
        short a0[4];
        for (int s2 = 0; s2 < 4; s2++)
            a0[s2] = (short)R[zlift_gmma_off(a_off, w * 16 + 4 * hi16 + s2,
                                             ka, desc_a) >> 1];
        const float4 e0 = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
            16, (short4)(a0[0], a0[1], a0[2], a0[3]), bfrag, (float4)(0.0f), 3072);
        const uint src = (what == 43) ? 0u : (uint)lo16;
        const float got_v = zlift_pick4(e0, src, 0);
        // Component 0 of lane `src` is row 4*(src/16) + 0, column c0 + src%16.
        const int m = w * 16 + 4 * (int)(src >> 4);
        const int c = c0 + (int)(src & 15u);
        float want = 0.0f;
        for (int k = 0; k < 16; k++)
            want += vload_half(zlift_gmma_off(a_off, m, k, desc_a) >> 1,
                               (const __local half *)sm)
                  * vload_half(zlift_gmma_off(b_off, c, k, desc_b) >> 1,
                               (const __local half *)sm);
        const float sc = fmax(fabs(want), 1.0f) * 1.0e-2f;
        return good + ((fabs(got_v - want) > sc) ? 1.0e6f : 0.0f);
    }

    if (what == 5) {
        float bad = 0.0f;
        for (int rh = 0; rh < 2; rh++) {
            const int k0 = ZLIFT_DPAS_K[lo16];
            short ah[4];
            for (int s = 0; s < 4; s++)
                ah[s] = (short)R[zlift_gmma_off(a_off, w * 16 + rh * 8 + 4 * hi16 + s,
                                                k0, desc_a) >> 1];
            const float4 d = __spirv_SubgroupMatrixMultiplyAccumulateINTEL(
                16, (short4)(ah[0], ah[1], ah[2], ah[3]), bfrag,
                (float4)(0.0f), 3072);
            const float dv[4] = {d.s0, d.s1, d.s2, d.s3};
            for (int comp = 0; comp < 4; comp++) {
                const int m = w * 16 + rh * 8 + 4 * hi16 + comp;
                const int c = c0 + lo16;
                float want = 0.0f;
                for (int k = 0; k < 16; k++)
                    want += vload_half(zlift_gmma_off(a_off, m, k, desc_a) >> 1,
                                       (const __local half *)sm)
                          * vload_half(zlift_gmma_off(b_off, c, k, desc_b) >> 1,
                                       (const __local half *)sm);
                if (fabs(dv[comp] - want) > 1e-2f)
                    bad = 1.0e6f;
            }
        }
        return good + bad;
    }

    if (what < 3) {
        const int bad = what == 0 ? (amag == 0.0f)
                      : what == 1 ? (bmag == 0.0f)
                      : (dmag == 0.0f && amag != 0.0f && bmag != 0.0f);
        return good + (bad ? 1.0e6f : 0.0f);
    }

    // The comparison the probe makes, on the caller's real data instead of a
    // synthetic tile: run the XMX path and mark every register where it
    // disagrees. The mismatch count the driver prints is then the number of
    // accumulator elements the two paths do not agree on.
    const float8 t = __zlift_wgmma_tile8_f32_f16_f16(sm, a_off, desc_a, b_off,
                                                     desc_b, cb2, scale_ab,
                                                     acc_in);
    const float gv[8] = {good.s0, good.s1, good.s2, good.s3,
                         good.s4, good.s5, good.s6, good.s7};
    const float tv[8] = {t.s0, t.s1, t.s2, t.s3, t.s4, t.s5, t.s6, t.s7};
    float mark[8];
    for (int r = 0; r < 8; r++) {
        // `what == 3` marks any disagreement. `what == 4` asks a sharper
        // question: is the XMX value one of the OTHER seven registers' answers?
        // If it is, the fault is a permutation of the accumulator and not the
        // arithmetic.
        int bad = fabs(tv[r] - gv[r]) > 1e-2f;
        // `what` 10..17 asks about ONE accumulator register, so the mismatch
        // count becomes the number of LANES that register is wrong in — which
        // separates "the mapping is wrong for some registers" from "it is
        // wrong for some lanes".
        if (what >= 10 && what < 18)
            bad = bad && (r == what - 10);
        if (bad && what == 4) {
            int found = 0;
            for (int q = 0; q < 8; q++)
                if (q != r && fabs(tv[r] - gv[q]) <= 1e-2f)
                    found = 1;
            bad = !found;      // a permutation is not marked; anything else is
        }
        mark[r] = bad ? 1.0e6f : 0.0f;
    }
    return good + (float8)(mark[0], mark[1], mark[2], mark[3],
                           mark[4], mark[5], mark[6], mark[7]);
}

#endif  /* ZLIFT_DEVLIB_DIAG */
