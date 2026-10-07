# zlift — the front door

```
zlift install [--shell]      put the driver where programs already look
zlift                        the settings, in a terminal
zlift devices                what is here, and what a CUDA program sees
zlift smi                    what `nvidia-smi` would say
zlift run -- ./program       one program, without installing anything
zlift daemon                 a shared translation cache
```

`tools/zlift` is a wrapper that builds it if it is not built and finds the tree
from its own location; symlink that onto your PATH.

## devices

Two views of the same hardware, taken separately and printed together. Level
Zero is the truth — a driver, its root devices, and each root's sub-devices,
the tiles a multi-tile card is built from. CUDA has no such concept: its device
list is flat, so a sub-device can only *be* a CUDA device by being what Level
Zero enumerates, and that is what `ZE_AFFINITY_MASK` decides. Every row carries
the mask that would make it `cuda:0`, because the mapping is not a convention
this invents — it is a variable the driver reads.

The second view is the CUDA driver API as `libzluda_ze.so` answers it, asked
rather than assumed, so that "seen as CUDA" is a measurement. When the two
disagree, the listing says so.

## install — the driver, not a wrapper

`zlift run` puts a directory first on `LD_LIBRARY_PATH` for one program. That
is a wrapper, and a wrapper is something to remember. What a machine with a GPU
actually has is a **driver**: libraries where the loader already looks, and
`nvidia-smi` on PATH, so that a program — or a framework's install check, or a
shell script somebody else wrote — finds them without being told.

Three files, because two of them are not `libcuda.so.1`:

| | |
|---|---|
| `libcuda.so.1` | the CUDA driver API — the lifter, on Level Zero |
| `libnvidia-ml.so.1` | NVML, which is what a framework asks **first** |
| `nvidia-smi` | the program everybody runs to see whether it worked |

A machine with `libcuda.so.1` and no NVML looks, to almost everything worth
running, like a machine with no GPU. `znvml/` is that half: 45 entry points
written against **this project's own CUDA driver** rather than against Level
Zero, which is not laziness — NVML and CUDA disagreeing about how many devices
there are, or which one is index 0, is a class of bug that cannot happen if one
of them is asking the other. `tests/nvml_check.c` checks exactly that, in one
process, and it is 16/16.

Two of the three places a driver installation puts files need root:
`/usr/lib/x86_64-linux-gnu` and `/etc/ld.so.conf.d`. `zlift install` does the
part that does not — `~/.local/lib/zlift` and `~/.local/bin`, plus one line in
`~/.bashrc` with `--shell` — which covers everything launched from a terminal.
For the rest it prints the four root commands and stops. It does not run `sudo`
and does not ask for a password: rewriting a system library path is the owner's
decision, with the commands in front of them.

`zlift uninstall` removes the files. The line in `~/.bashrc` is yours.

## run — for one program, without installing

The interposition is the dynamic loader and nothing else: a directory holding
`libcuda.so.1` as a symlink to `libzluda_ze.so`, first on `LD_LIBRARY_PATH`.
The same mechanism a real driver installation uses, with a different file at
the end of the link. `zlift run` builds that directory, applies the settings,
and `exec`s — it does not sit between your shell and the program, so signals
and exit status are the program's own.

## settings

Every setting is an environment variable some part of this project already
reads. `zlift config` prints them with what each one does and what it costs;
the terminal UI is the same table with arrow keys. Nothing here is a new knob,
and anything it does can be done by hand.

## daemon

Loading a cubin costs a lift: `cuModuleLoadData` writes the image out and runs
`tools/cubin2spv` on it, which is a Python process, an LLVM pipeline and about
a second. Every process pays it, for the same bytes.

The daemon owns a content-addressed cache keyed by the SHA-256 of the cubin and
answers `LIFT` over a Unix socket. Measured on `tests/nvcc_e2e.cu`:

| | |
|---|---|
| cold | 0.83 s |
| warm | 0.09 s |

The driver tries the socket and falls back to running the tool itself, so the
daemon is never required — it is only faster. Single-threaded on purpose: that
serialises translations, which is easier on a machine that is also running the
program that asked.

## no dependencies

Deliberate. It has to build on a machine that has never fetched a crate, it has
to work when the rest of the tree is half-built, and everything it needs — a
Unix socket, a terminal in raw mode, `dlopen`, SHA-256 — is either in `std` or
short enough to write down. The hash is checked against the published test
vectors by `zlift daemon --self-test`.
