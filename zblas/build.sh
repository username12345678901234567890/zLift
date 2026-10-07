
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MKL="${ONEMKL_ROOT:-$(ls -d /opt/intel/oneapi/mkl/[0-9]* 2>/dev/null | tail -1)}"
[ -n "${MKL:-}" ] && [ -d "$MKL/include" ] || { echo "no oneMKL found" >&2; exit 2; }

ICPX="${ZLIFT_ICPX:-$(command -v icpx || ls /opt/intel/oneapi/compiler/latest/bin/icpx 2>/dev/null || true)}"
GPU_OBJ=""
GPU_LIBS=""
GPU_DEF=""
GPU_RPATH=""
if [ -n "${ICPX:-}" ] && [ -x "$ICPX" ]; then

    ICPX_LIB="$(dirname "$(dirname "$ICPX")")/lib"
    GPU_RPATH="-L$ICPX_LIB"
    DIRS=""
    for d in "$ICPX_LIB" "$(dirname "$(dirname "$ICPX")")/opt/compiler/lib" \
             /opt/intel/oneapi/umf/*/lib /opt/intel/oneapi/tcm/*/lib \
             /opt/intel/oneapi/tbb/*/lib/intel64/gcc4.8; do
        [ -d "$d" ] || continue
        GPU_RPATH="$GPU_RPATH -Wl,-rpath,$d"
        DIRS="$DIRS\"$d\","
    done

    "$ICPX" -fsycl -O2 -fPIC -c "$HERE/zblas_gpu.cpp" -o "$HERE/zblas_gpu.o" \
        -I"$MKL/include" -DZBLAS_ONEAPI_LIBS="$DIRS"
    GPU_OBJ="$HERE/zblas_gpu.o"
    GPU_LIBS="-lmkl_sycl_blas -lsycl -lstdc++"
    GPU_DEF="-DZBLAS_GPU"
else
    echo "no SYCL compiler; the GEMMs stay on the CPU" >&2
fi
if [ -n "$GPU_OBJ" ]; then
    gcc -O2 -fPIC -c -o "$HERE/zblas.o" "$HERE/zblas.c" $GPU_DEF -I"$MKL/include"
    "$ICPX" -fsycl -O2 -fPIC -shared -o "$HERE/libcublas.so.13" \
        "$HERE/zblas.o" $GPU_OBJ \
        -L"$MKL/lib/intel64" -Wl,--no-as-needed \
        -lmkl_intel_lp64 -lmkl_gnu_thread -lmkl_core -lgomp $GPU_LIBS -lpthread -lm -ldl \
        -Wl,-rpath,"$MKL/lib/intel64" \
        $GPU_RPATH
else
    gcc -O2 -fPIC -shared -o "$HERE/libcublas.so.13" "$HERE/zblas.c" \
        $GPU_DEF -I"$MKL/include" -L"$MKL/lib/intel64" -Wl,--no-as-needed \
        -lmkl_intel_lp64 -lmkl_gnu_thread -lmkl_core -lgomp -lpthread -lm -ldl \
        -Wl,-rpath,"$MKL/lib/intel64"
fi
ln -sf libcublas.so.13 "$HERE/libcublas.so"
echo "cuBLAS shim: $(nm -D --defined-only "$HERE/libcublas.so.13" | grep -c ' T cublas') entry points"
