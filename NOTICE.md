# What this is, and under what terms

zLift runs CUDA programs on an Intel GPU. It is an independent implementation
of a published interface. It is not associated with, endorsed by, or derived
from NVIDIA Corporation, and NVIDIA, CUDA, cuBLAS, cuDNN, NVML and nvidia-smi
are their trademarks, used here only to name the interfaces being implemented
and the files a program looks for.

## At run time, nothing of NVIDIA's is involved

This is the part that matters most and it is checkable rather than asserted:

```
$ ldd ~/.local/lib/zlift/libcuda.so.1 | grep -ci nvidia
0
```

Everything `zlift install` puts in place — `libcuda.so.1`,
`libnvidia-ml.so.1`, `libcublas.so`, `libcudnn.so` — is built from source in
this repository. Running a CUDA program on this driver requires no NVIDIA
software of any kind, so a person who uses zLift downloads nothing from
NVIDIA, installs nothing of NVIDIA's, and is not a party to any agreement with
them. The names are the ones the dynamic loader looks for; the files are ours.

## The NVIDIA toolchain is used to build the tests, and is not redistributed

The test corpus is compiled here rather than shipped: `nvcc` turns this
repository's own `.cu` files into cubins and `nvdisasm` dumps them, which is
what those tools are documented to do. Neither is included in this repository —
`.gitignore` excludes the environment they live in — and neither is needed to
*use* zLift, only to reproduce its test corpus.

Two things about that, stated plainly because a reader is entitled to check
them rather than take our word:

* The licence those tools shipped under (the CUDA 13.3 wheels'
  `License.txt`) restricts reverse engineering **of the SDK**. This project
  does not reverse engineer the SDK. It runs the SDK's own tools on its own
  source, and translates the machine code they emit for the hardware it has.
* That licence, as shipped with those wheels, contains no clause about
  translating generated output to a non-NVIDIA platform. Later CUDA end-user
  agreements published elsewhere have carried such a clause; anyone building
  the test corpus should read the licence that came with the toolkit they
  installed, because it is their agreement and not ours.

Reverse engineering for interoperability is separately permitted by statute in
several jurisdictions — Article 6 of the EU Software Directive (2009/24/EC),
and Article 101-4 of the Korean Copyright Act — which contract terms cannot
displace in those places.

## What you are responsible for

If you install an NVIDIA toolkit in order to build the test corpus, that
installation is between you and NVIDIA, under whatever terms came with it.
zLift neither obtains nor accepts anything on your behalf. Nothing here is
legal advice; if it matters to you, the licence text is in the package you
installed and is short.

## Prior work

zLift stands on [ZLUDA](https://github.com/vosen/ZLUDA) (Apache-2.0 OR MIT) —
its PTX compiler, its model of the private `cuGetExportTable` interface, its
fatbin decoder — and on LLVM, oneAPI (oneMKL, oneDNN, DPC++) and Intel's Level
Zero and Graphics Compiler. The lifter is built on CuLifter. Those projects'
licences apply to their code and are included with it.
