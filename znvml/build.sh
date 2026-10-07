
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gcc -O2 -fPIC -shared -Wall -Wextra -o "$HERE/libnvidia-ml.so.1" "$HERE/znvml.c" -ldl \
    -Wl,-soname,libnvidia-ml.so.1
ln -sf libnvidia-ml.so.1 "$HERE/libnvidia-ml.so"
echo "NVML shim: $(nm -D --defined-only "$HERE/libnvidia-ml.so.1" | grep -c ' T nvml') entry points"
