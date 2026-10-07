set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HERE/../CuLifter/.conda_env/bin"
: "${ZLIFT_CLANG:=$BIN/clang}"
: "${ZLIFT_LLVM_LINK:=$BIN/llvm-link}"
: "${ZLIFT_LLVM_AS:=$BIN/llvm-as}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# `-fno-builtin-memset`: a zero-fill loop is otherwise recognised and replaced
# with `llvm.memset`, and the SPIR-V backend cannot translate one into the
# workgroup address space — "unable to translate instruction: call", which is
# how `tma_sw128` and `tma_hgmma` failed. The loop it came from translates
# fine, so the answer is to leave it a loop.
for src in zlift_devlib zluda_ptx_impl_intel; do
    "$ZLIFT_CLANG" -cl-std=CL2.0 -target spir64-unknown-unknown -O2 \
        -fno-builtin-memset -fno-builtin-memcpy \
        -emit-llvm -S -x cl "$HERE/$src.cl" -o "$tmp/$src.ll"
done

# Link first, weaken second. `linkonce_odr` lets the linker discard an
# unreferenced symbol, and nothing inside the library references anything, so
# weakening before this step deletes the whole library.
"$ZLIFT_LLVM_LINK" "$tmp/zlift_devlib.ll" "$tmp/zluda_ptx_impl_intel.ll" \
    "$HERE/zlift_extra.ll" -S -o "$tmp/linked.ll"
sed -e 's/^define dso_local spir_func/define linkonce_odr spir_func/' \
    -e 's/^define spir_func/define linkonce_odr spir_func/' \
    "$tmp/linked.ll" > "$HERE/zlift_devlib.ll"
"$ZLIFT_LLVM_AS" "$HERE/zlift_devlib.ll" \
    -o "$HERE/../ZLUDA/llvm_zluda/src/device-libs/zlift_devlib.bc"

echo "device library: $(grep -c '^define' "$HERE/zlift_devlib.ll") functions"
