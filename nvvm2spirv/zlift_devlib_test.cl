// Unit test for zlift_devlib. Each kernel writes one lane's answer per slot so
// the whole 32-lane result is visible at once from the host.
//
// Build and run:
//   clang -cl-std=CL2.0 -target spir64-unknown-unknown -O2 -emit-llvm -S \
//         -x cl zlift_devlib_test.cl -o /tmp/t.ll
//   llvm-link /tmp/t.ll zlift_devlib.ll -S -o /tmp/tl.ll
//   llc -mtriple=spirv64-unknown-unknown -O2 --spirv-ext=+SPV_INTEL_subgroups \
//       -filetype=obj /tmp/tl.ll -o /tmp/t.spv
//   zerun /tmp/t.spv test_elect 1 32 o32

uint __zlift_match_any_b32(uint value);
uint __zlift_activemask(void);
int __zlift_elect_sync(void);
uint __zlift_prmt_b32(uint a, uint b, uint sel);
ulong __zlift_bfi_b64(ulong insert, ulong base, uint pos, uint len);
uint __zlift_bfe_u32(uint value, uint pos, uint len);
int __zlift_bfe_s32(int value, uint pos, uint len);

__attribute__((intel_reqd_sub_group_size(32)))
__kernel void test_elect(__global int *out) {
    // Exactly one lane must report 1.
    out[get_local_id(0)] = __zlift_elect_sync();
}

__attribute__((intel_reqd_sub_group_size(32)))
__kernel void test_activemask(__global int *out) {
    // A full 32-lane group: every lane sees 0xFFFFFFFF, printed as -1.
    out[get_local_id(0)] = (int)__zlift_activemask();
}

__attribute__((intel_reqd_sub_group_size(32)))
__kernel void test_match_any(__global int *out, __global const int *in) {
    // popcount of the match mask == how many lanes share my value.
    out[get_local_id(0)] = popcount(__zlift_match_any_b32((uint)in[get_local_id(0)]));
}

__attribute__((intel_reqd_sub_group_size(32)))
__kernel void test_prmt(__global int *out) {
    // a = 0x03020100, b = 0x07060504, so the eight source bytes are 0..7.
    // sel 0x7531 selects bytes 1,3,5,7 -> 0x07050301.
    // sel 0x0000 selects byte 0 four times -> 0x00000000.
    // sel 0x8888 sign-replicates byte 0 (0x00) -> 0x00000000.
    // sel 0xBBBB sign-replicates byte 3 (0x03, positive) -> 0.
    // sel 0x7777 selects byte 7 (0x07) four times -> 0x07070707.
    out[0] = (int)__zlift_prmt_b32(0x03020100u, 0x07060504u, 0x7531u);
    out[1] = (int)__zlift_prmt_b32(0x03020100u, 0x07060504u, 0x7777u);
    out[2] = (int)__zlift_prmt_b32(0x000000FFu, 0u, 0x8888u);  // 0xFF is negative
}

__attribute__((intel_reqd_sub_group_size(32)))
__kernel void test_bits(__global int *out) {
    // insert 0b1111 at bit 4, width 4, into 0 -> 0xF0
    out[0] = (int)__zlift_bfi_b64(0xFUL, 0UL, 4u, 4u);
    // width 0 is a no-op
    out[1] = (int)__zlift_bfi_b64(0xFUL, 0x1234UL, 4u, 0u);
    // extract 4 bits at 8 from 0xABCD -> 0xB
    out[2] = (int)__zlift_bfe_u32(0xABCDu, 8u, 4u);
    // signed extract of 0b1111 at 8 -> -1
    out[3] = __zlift_bfe_s32((int)0xF00, 8u, 4u);
    // zero length is zero
    out[4] = (int)__zlift_bfe_u32(0xFFFFFFFFu, 0u, 0u);
}
