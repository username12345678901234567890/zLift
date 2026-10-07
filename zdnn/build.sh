
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INC="${ONEDNN_INCLUDE:-}"
if [ -z "$INC" ]; then
    for c in /usr/include /opt/intel/oneapi/dnnl/*/include \
             "$HOME"/.cache/uv/archive-v0/*/torch/include \
             "$HOME"/master/lib/python3.*/site-packages/torch/include; do
        [ -f "$c/oneapi/dnnl/dnnl.h" ] && INC="$c" && break
    done
fi
[ -n "$INC" ] || { echo "no oneDNN headers found" >&2; exit 2; }
LIB="${ONEDNN_LIB:-$(ls /usr/lib/x86_64-linux-gnu/libdnnl.so.3* 2>/dev/null | tail -1)}"
[ -n "$LIB" ] || { echo "no oneDNN library found" >&2; exit 2; }
gcc -O2 -fPIC -shared -o "$HERE/libcudnn.so.9" "$HERE/zdnn.c" \
    -I"$INC" "$LIB" -Wl,-rpath,"$(dirname "$LIB")"
ln -sf libcudnn.so.9 "$HERE/libcudnn.so"
echo "cuDNN shim: $(nm -D --defined-only "$HERE/libcudnn.so.9" | grep -c ' T cudnn') entry points"
