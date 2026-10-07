#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <math.h>
#include "mkl_cblas.h"
typedef int cublasStatus_t;
typedef void *cublasHandle_t;
typedef void *cudaStream_t;
#define CUBLAS_STATUS_SUCCESS 0
#define CUBLAS_STATUS_NOT_INITIALIZED 1
#define CUBLAS_STATUS_INVALID_VALUE 7
#define CUBLAS_STATUS_NOT_SUPPORTED 15
#define CUBLAS_TF32_TENSOR_OP_MATH 3
enum { CUBLAS_OP_N = 0, CUBLAS_OP_T = 1, CUBLAS_OP_C = 2 };
static CBLAS_TRANSPOSE cb_op(int op) {
    return op == CUBLAS_OP_T ? CblasTrans
         : op == CUBLAS_OP_C ? CblasConjTrans : CblasNoTrans;
}
struct Handle {
    cudaStream_t stream;
    int pointer_mode;   
    int math_mode;      
};
static void drain_driver(void) {
    static int (*sync)(void) = NULL;
    static int looked = 0;
    if (!looked) {
        looked = 1;
        void *h = dlopen("libcuda.so.1", RTLD_NOW | RTLD_NOLOAD);
        if (!h) h = dlopen("libcuda.so.1", RTLD_NOW);
        if (h) sync = (int (*)(void))dlsym(h, "cuCtxSynchronize");
    }
    if (sync) sync();
}
static int trace(void) {
    static int on = -1;
    if (on < 0) on = getenv("ZBLAS_TRACE") != NULL;
    return on;
}
#define T(fmt, ...) do { if (trace()) fprintf(stderr, "[zblas] " fmt "\n", ##__VA_ARGS__); } while (0)
cublasStatus_t cublasCreate_v2(cublasHandle_t *h) {
    if (!h) return CUBLAS_STATUS_INVALID_VALUE;
    struct Handle *x = calloc(1, sizeof *x);
    if (!x) return CUBLAS_STATUS_NOT_INITIALIZED;
    *h = x;
    T("create");
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasDestroy_v2(cublasHandle_t h) { free(h); return CUBLAS_STATUS_SUCCESS; }
cublasStatus_t cublasGetVersion_v2(cublasHandle_t h, int *version) {
    (void)h;
    if (!version) return CUBLAS_STATUS_INVALID_VALUE;
    *version = 130000;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSetStream_v2(cublasHandle_t h, cudaStream_t s) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    ((struct Handle *)h)->stream = s;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasGetStream_v2(cublasHandle_t h, cudaStream_t *s) {
    if (!h || !s) return CUBLAS_STATUS_INVALID_VALUE;
    *s = ((struct Handle *)h)->stream;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSetPointerMode_v2(cublasHandle_t h, int mode) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    ((struct Handle *)h)->pointer_mode = mode;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasGetPointerMode_v2(cublasHandle_t h, int *mode) {
    if (!h || !mode) return CUBLAS_STATUS_INVALID_VALUE;
    *mode = ((struct Handle *)h)->pointer_mode;
    return CUBLAS_STATUS_SUCCESS;
}
static float f_scalar(cublasHandle_t h, const float *p) {
    (void)h; return p ? *p : 0.0f;
}
#ifdef ZBLAS_GPU
int zblas_gpu_ready(void);
int zblas_gpu_sgemm(int, int, int, int, int, float, const float *, int,
                    const float *, int, float, float *, int);
int zblas_gpu_sgemm_xmx(int, int, int, int, int, float, const float *, int,
                        const float *, int, float, float *, int, int);
int zblas_gpu_gemm_ex_bf16(int transa, int transb, int m, int n, int k,
                           float alpha, const void *A, int lda,
                           const void *B, int ldb, float beta,
                           void *C, int ldc, int c_is_bf16);
int zblas_gpu_gemm_ex_f16(int transa, int transb, int m, int n, int k,
                          float alpha, const void *A, int lda,
                          const void *B, int ldb, float beta,
                          void *C, int ldc, int c_is_half);
int zblas_gpu_epilogue(void *, int, int, int, int, const void *, int, int);
int zblas_gpu_dgemm(int, int, int, int, int, double, const double *, int,
                    const double *, int, double, double *, int);
int zblas_gpu_hgemm(int, int, int, int, int, float, const void *, int,
                    const void *, int, float, void *, int);
#else
#define zblas_gpu_ready() 0
#define zblas_gpu_sgemm(...) 1
#define zblas_gpu_sgemm_xmx(...) 1
#define zblas_gpu_epilogue(...) 1
#define zblas_gpu_gemm_ex_bf16(...) 1
#define zblas_gpu_dgemm(...) 1
#define zblas_gpu_hgemm(...) 1
#endif
static double d_scalar(cublasHandle_t h, const double *p) {
    (void)h; return p ? *p : 0.0;
}
cublasStatus_t cublasSgemm_v2(cublasHandle_t h, int transa, int transb,
                              int m, int n, int k, const float *alpha,
                              const float *A, int lda, const float *B, int ldb,
                              const float *beta, float *C, int ldc) {
    drain_driver();
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    T("sgemm %dx%dx%d ta=%d tb=%d lda=%d ldb=%d ldc=%d", m, n, k,
      transa, transb, lda, ldb, ldc);
    if (!getenv("ZBLAS_NO_XMX")
        && zblas_gpu_sgemm_xmx(transa, transb, m, n, k, f_scalar(h, alpha),
                               A, lda, B, ldb, f_scalar(h, beta), C, ldc,
                               ((struct Handle *)h)->math_mode == CUBLAS_TF32_TENSOR_OP_MATH) == 0)
        return CUBLAS_STATUS_SUCCESS;
    if (zblas_gpu_sgemm(transa, transb, m, n, k, f_scalar(h, alpha), A, lda,
                        B, ldb, f_scalar(h, beta), C, ldc) == 0)
        return CUBLAS_STATUS_SUCCESS;
    cblas_sgemm(CblasColMajor, cb_op(transa), cb_op(transb), m, n, k,
                f_scalar(h, alpha), A, lda, B, ldb, f_scalar(h, beta), C, ldc);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasDgemm_v2(cublasHandle_t h, int transa, int transb,
                              int m, int n, int k, const double *alpha,
                              const double *A, int lda, const double *B, int ldb,
                              const double *beta, double *C, int ldc) {
    drain_driver();
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    T("dgemm %dx%dx%d", m, n, k);
    if (zblas_gpu_dgemm(transa, transb, m, n, k, d_scalar(h, alpha), A, lda,
                        B, ldb, d_scalar(h, beta), C, ldc) == 0)
        return CUBLAS_STATUS_SUCCESS;
    cblas_dgemm(CblasColMajor, cb_op(transa), cb_op(transb), m, n, k,
                d_scalar(h, alpha), A, lda, B, ldb, d_scalar(h, beta), C, ldc);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSgemmStridedBatched(cublasHandle_t h, int transa, int transb,
                                         int m, int n, int k, const float *alpha,
                                         const float *A, int lda, long long sa,
                                         const float *B, int ldb, long long sb,
                                         const float *beta, float *C, int ldc,
                                         long long sc, int batch) {
    drain_driver();
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    T("sgemm_strided_batched %dx%dx%d x%d", m, n, k, batch);
    if (zblas_gpu_ready()) {
        int done = 1;
        for (int i = 0; i < batch && done; i++)
            done = zblas_gpu_sgemm(transa, transb, m, n, k, f_scalar(h, alpha),
                                   A + i * sa, lda, B + i * sb, ldb,
                                   f_scalar(h, beta), C + i * sc, ldc) == 0;
        if (done)
            return CUBLAS_STATUS_SUCCESS;
    }
    for (int i = 0; i < batch; i++)
        cblas_sgemm(CblasColMajor, cb_op(transa), cb_op(transb), m, n, k,
                    f_scalar(h, alpha), A + i * sa, lda, B + i * sb, ldb,
                    f_scalar(h, beta), C + i * sc, ldc);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSgemv_v2(cublasHandle_t h, int trans, int m, int n,
                              const float *alpha, const float *A, int lda,
                              const float *x, int incx, const float *beta,
                              float *y, int incy) {
    drain_driver();
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    T("sgemv %dx%d", m, n);
    cblas_sgemv(CblasColMajor, cb_op(trans), m, n, f_scalar(h, alpha), A, lda,
                x, incx, f_scalar(h, beta), y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSaxpy_v2(cublasHandle_t h, int n, const float *alpha,
                              const float *x, int incx, float *y, int incy) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    cblas_saxpy(n, f_scalar(h, alpha), x, incx, y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSscal_v2(cublasHandle_t h, int n, const float *alpha,
                              float *x, int incx) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    cblas_sscal(n, f_scalar(h, alpha), x, incx);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSdot_v2(cublasHandle_t h, int n, const float *x, int incx,
                             const float *y, int incy, float *result) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    if (!result) return CUBLAS_STATUS_INVALID_VALUE;
    *result = cblas_sdot(n, x, incx, y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSnrm2_v2(cublasHandle_t h, int n, const float *x, int incx,
                              float *result) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    if (!result) return CUBLAS_STATUS_INVALID_VALUE;
    *result = cblas_snrm2(n, x, incx);
    return CUBLAS_STATUS_SUCCESS;
}
static cublasStatus_t copy2d(int rows, int cols, int esize,
                             const void *src, int lds, void *dst, int ldd) {
    if (rows < 0 || cols < 0 || lds < rows || ldd < rows)
        return CUBLAS_STATUS_INVALID_VALUE;
    for (int c = 0; c < cols; c++)
        memcpy((char *)dst + (size_t)c * ldd * esize,
               (const char *)src + (size_t)c * lds * esize,
               (size_t)rows * esize);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSetMatrix(int rows, int cols, int esize, const void *a,
                               int lda, void *b, int ldb) {
    return copy2d(rows, cols, esize, a, lda, b, ldb);
}
cublasStatus_t cublasGetMatrix(int rows, int cols, int esize, const void *a,
                               int lda, void *b, int ldb) {
    return copy2d(rows, cols, esize, a, lda, b, ldb);
}
cublasStatus_t cublasSetVector(int n, int esize, const void *x, int incx,
                               void *y, int incy) {
    return copy2d(1, n, esize, x, incx, y, incy);
}
cublasStatus_t cublasGetVector(int n, int esize, const void *x, int incx,
                               void *y, int incy) {
    return copy2d(1, n, esize, x, incx, y, incy);
}
const char *cublasGetStatusName(cublasStatus_t s) {
    switch (s) {
    case CUBLAS_STATUS_SUCCESS: return "CUBLAS_STATUS_SUCCESS";
    case CUBLAS_STATUS_NOT_INITIALIZED: return "CUBLAS_STATUS_NOT_INITIALIZED";
    case CUBLAS_STATUS_INVALID_VALUE: return "CUBLAS_STATUS_INVALID_VALUE";
    case CUBLAS_STATUS_NOT_SUPPORTED: return "CUBLAS_STATUS_NOT_SUPPORTED";
    default: return "CUBLAS_STATUS_INTERNAL_ERROR";
    }
}
static float half_to_float(unsigned short h) {
    unsigned sign = (h >> 15) & 1, exp = (h >> 10) & 0x1f, man = h & 0x3ff;
    unsigned bits;
    if (exp == 0) {
        if (man == 0) bits = sign << 31;
        else {  
            int e = -1;
            do { man <<= 1; e++; } while (!(man & 0x400));
            bits = (sign << 31) | ((127 - 15 - e) << 23) | ((man & 0x3ff) << 13);
        }
    } else if (exp == 31) {
        bits = (sign << 31) | 0x7f800000u | (man << 13);
    } else {
        bits = (sign << 31) | ((exp - 15 + 127) << 23) | (man << 13);
    }
    float f;
    memcpy(&f, &bits, 4);
    return f;
}
static unsigned short float_to_half(float f) {
    unsigned bits;
    memcpy(&bits, &f, 4);
    unsigned sign = (bits >> 16) & 0x8000;
    int exp = (int)((bits >> 23) & 0xff) - 127;
    unsigned man = bits & 0x7fffff;
    if (exp > 15) return (unsigned short)(sign | 0x7c00);        
    if (exp < -24) return (unsigned short)sign;                  
    if (exp < -14) {                                             
        man |= 0x800000;
        int shift = -14 - exp;
        return (unsigned short)(sign | (man >> (13 + shift)));
    }
    unsigned half = sign | ((unsigned)(exp + 15) << 10) | (man >> 13);
    if ((man & 0x1fff) > 0x1000 || ((man & 0x1fff) == 0x1000 && (half & 1)))
        half++;
    return (unsigned short)half;
}
cublasStatus_t cublasHgemm(cublasHandle_t h, int transa, int transb,
                           int m, int n, int k, const unsigned short *alpha,
                           const unsigned short *A, int lda,
                           const unsigned short *B, int ldb,
                           const unsigned short *beta, unsigned short *C, int ldc) {
    drain_driver();
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    if (m < 0 || n < 0 || k < 0) return CUBLAS_STATUS_INVALID_VALUE;
    T("hgemm %dx%dx%d", m, n, k);
    if (zblas_gpu_hgemm(transa, transb, m, n, k, half_to_float(*alpha), A, lda,
                        B, ldb, half_to_float(*beta), C, ldc) == 0)
        return CUBLAS_STATUS_SUCCESS;
    size_t na = (size_t)lda * (transa == CUBLAS_OP_N ? k : m);
    size_t nb = (size_t)ldb * (transb == CUBLAS_OP_N ? n : k);
    size_t nc = (size_t)ldc * n;
    float *fa = malloc(na * sizeof *fa), *fb = malloc(nb * sizeof *fb);
    float *fc = malloc(nc * sizeof *fc);
    if (!fa || !fb || !fc) { free(fa); free(fb); free(fc); return CUBLAS_STATUS_NOT_INITIALIZED; }
    for (size_t i = 0; i < na; i++) fa[i] = half_to_float(A[i]);
    for (size_t i = 0; i < nb; i++) fb[i] = half_to_float(B[i]);
    for (size_t i = 0; i < nc; i++) fc[i] = half_to_float(C[i]);
    cblas_sgemm(CblasColMajor, cb_op(transa), cb_op(transb), m, n, k,
                half_to_float(*alpha), fa, lda, fb, ldb, half_to_float(*beta), fc, ldc);
    for (size_t i = 0; i < nc; i++) C[i] = float_to_half(fc[i]);
    free(fa); free(fb); free(fc);
    return CUBLAS_STATUS_SUCCESS;
}
enum { CUDA_R_16F = 2, CUDA_R_32F = 0, CUDA_R_16BF = 14 };
static float bf16_to_float(unsigned short b) {
    unsigned u = (unsigned)b << 16;
    float f;
    memcpy(&f, &u, 4);
    return f;
}
static unsigned short float_to_bf16(float f) {
    unsigned u;
    memcpy(&u, &f, 4);
    u += 0x7fffu + ((u >> 16) & 1u);   
    return (unsigned short)(u >> 16);
}
static cublasStatus_t gemm_ex_host(int transa, int transb, int m, int n, int k,
                                   const void *alpha, const void *A, int lda,
                                   const void *B, int ldb, const void *beta,
                                   void *C, int Ctype, int ldc, int wide) {
    size_t na = (size_t)lda * (transa == CUBLAS_OP_N ? k : m);
    size_t nb = (size_t)ldb * (transb == CUBLAS_OP_N ? n : k);
    size_t nc = (size_t)ldc * n;
    const unsigned short *ha = A, *hb = B;
    int c_narrow = wide ? Ctype == CUDA_R_16BF : Ctype == CUDA_R_16F;
    float *fa = malloc(na * sizeof *fa), *fb = malloc(nb * sizeof *fb);
    float *fc = malloc(nc * sizeof *fc);
    if (!fa || !fb || !fc) {
        free(fa); free(fb); free(fc);
        return CUBLAS_STATUS_NOT_INITIALIZED;
    }
    for (size_t i = 0; i < na; i++)
        fa[i] = wide ? bf16_to_float(ha[i]) : half_to_float(ha[i]);
    for (size_t i = 0; i < nb; i++)
        fb[i] = wide ? bf16_to_float(hb[i]) : half_to_float(hb[i]);
    if (c_narrow) {
        const unsigned short *hc = C;
        for (size_t i = 0; i < nc; i++)
            fc[i] = wide ? bf16_to_float(hc[i]) : half_to_float(hc[i]);
    } else {
        memcpy(fc, C, nc * sizeof *fc);
    }
    cblas_sgemm(CblasColMajor, cb_op(transa), cb_op(transb), m, n, k,
                *(const float *)alpha, fa, lda, fb, ldb,
                *(const float *)beta, fc, ldc);
    if (c_narrow) {
        unsigned short *hc = C;
        for (size_t i = 0; i < nc; i++)
            hc[i] = wide ? float_to_bf16(fc[i]) : float_to_half(fc[i]);
    } else {
        memcpy(C, fc, nc * sizeof *fc);
    }
    free(fa); free(fb); free(fc);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasGemmEx(cublasHandle_t h, int transa, int transb,
                            int m, int n, int k, const void *alpha,
                            const void *A, int Atype, int lda,
                            const void *B, int Btype, int ldb,
                            const void *beta, void *C, int Ctype, int ldc,
                            int computeType, int algo) {
    drain_driver();
    (void)algo;
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    if (computeType != CUDA_R_32F && computeType != 68 )
        return CUBLAS_STATUS_NOT_SUPPORTED;
    if (Atype == CUDA_R_32F && Btype == CUDA_R_32F && Ctype == CUDA_R_32F)
        return cublasSgemm_v2(h, transa, transb, m, n, k, alpha, A, lda,
                              B, ldb, beta, C, ldc);
    if (Atype == CUDA_R_16BF && Btype == CUDA_R_16BF) {
        T("gemmEx bf16 in, %s out %dx%dx%d",
          Ctype == CUDA_R_16BF ? "bf16" : "f32", m, n, k);
        if (zblas_gpu_gemm_ex_bf16(transa, transb, m, n, k,
                                   *(const float *)alpha, A, lda, B, ldb,
                                   *(const float *)beta, C, ldc,
                                   Ctype == CUDA_R_16BF) == 0)
            return CUBLAS_STATUS_SUCCESS;
        return gemm_ex_host(transa, transb, m, n, k, alpha, A, lda, B, ldb,
                            beta, C, Ctype, ldc, 1);
    }
    if (!(Atype == CUDA_R_16F && Btype == CUDA_R_16F))
        return CUBLAS_STATUS_NOT_SUPPORTED;
    T("gemmEx f16 in, %s out %dx%dx%d", Ctype == CUDA_R_16F ? "f16" : "f32", m, n, k);
    if (zblas_gpu_gemm_ex_f16(transa, transb, m, n, k, *(const float *)alpha,
                              A, lda, B, ldb, *(const float *)beta,
                              C, ldc, Ctype == CUDA_R_16F) == 0)
        return CUBLAS_STATUS_SUCCESS;
    return gemm_ex_host(transa, transb, m, n, k, alpha, A, lda, B, ldb,
                        beta, C, Ctype, ldc, 0);
}
cublasStatus_t cublasDgemv_v2(cublasHandle_t h, int trans, int m, int n,
                              const double *alpha, const double *A, int lda,
                              const double *x, int incx, const double *beta,
                              double *y, int incy) {
    drain_driver();
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    cblas_dgemv(CblasColMajor, cb_op(trans), m, n, d_scalar(h, alpha), A, lda,
                x, incx, d_scalar(h, beta), y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasDaxpy_v2(cublasHandle_t h, int n, const double *alpha,
                              const double *x, int incx, double *y, int incy) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    cblas_daxpy(n, d_scalar(h, alpha), x, incx, y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasDdot_v2(cublasHandle_t h, int n, const double *x, int incx,
                             const double *y, int incy, double *result) {
    if (!h || !result) return CUBLAS_STATUS_INVALID_VALUE;
    *result = cblas_ddot(n, x, incx, y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasScopy_v2(cublasHandle_t h, int n, const float *x, int incx,
                              float *y, int incy) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    cblas_scopy(n, x, incx, y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSswap_v2(cublasHandle_t h, int n, float *x, int incx,
                              float *y, int incy) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    cblas_sswap(n, x, incx, y, incy);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasIsamax_v2(cublasHandle_t h, int n, const float *x, int incx,
                               int *result) {
    if (!h || !result) return CUBLAS_STATUS_INVALID_VALUE;
    *result = (int)cblas_isamax(n, x, incx) + 1;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSasum_v2(cublasHandle_t h, int n, const float *x, int incx,
                              float *result) {
    if (!h || !result) return CUBLAS_STATUS_INVALID_VALUE;
    *result = cblas_sasum(n, x, incx);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSgeam(cublasHandle_t h, int transa, int transb,
                           int m, int n, const float *alpha,
                           const float *A, int lda, const float *beta,
                           const float *B, int ldb, float *C, int ldc) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    float al = f_scalar(h, alpha), be = f_scalar(h, beta);
    for (int j = 0; j < n; j++)
        for (int i = 0; i < m; i++) {
            float a = A ? (transa == CUBLAS_OP_N ? A[i + (size_t)j * lda]
                                                 : A[j + (size_t)i * lda]) : 0.0f;
            float b = B ? (transb == CUBLAS_OP_N ? B[i + (size_t)j * ldb]
                                                 : B[j + (size_t)i * ldb]) : 0.0f;
            C[i + (size_t)j * ldc] = al * a + be * b;
        }
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSetWorkspace_v2(cublasHandle_t h, void *ws, size_t bytes) {
    (void)ws; (void)bytes;
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    T("setWorkspace %zu", bytes);
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSetMathMode(cublasHandle_t h, int mode) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    ((struct Handle *)h)->math_mode = mode;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasGetMathMode(cublasHandle_t h, int *mode) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    if (!mode) return CUBLAS_STATUS_INVALID_VALUE;
    *mode = ((struct Handle *)h)->math_mode;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSetSmCountTarget(cublasHandle_t h, int count) {
    (void)count;
    return h ? CUBLAS_STATUS_SUCCESS : CUBLAS_STATUS_NOT_INITIALIZED;
}
cublasStatus_t cublasGetSmCountTarget(cublasHandle_t h, int *count) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    if (count) *count = 0;   
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasSgemmEx(cublasHandle_t h, int transa, int transb,
                             int m, int n, int k, const float *alpha,
                             const void *A, int Atype, int lda,
                             const void *B, int Btype, int ldb,
                             const float *beta, void *C, int Ctype, int ldc) {
    return cublasGemmEx(h, transa, transb, m, n, k, alpha, A, Atype, lda,
                        B, Btype, ldb, beta, C, Ctype, ldc, CUDA_R_32F, 0);
}
static size_t elem_size(int type) {
    return (type == CUDA_R_16F || type == CUDA_R_16BF) ? 2 : 4;
}
cublasStatus_t cublasGemmStridedBatchedEx(
        cublasHandle_t h, int transa, int transb, int m, int n, int k,
        const void *alpha,
        const void *A, int Atype, int lda, long long strideA,
        const void *B, int Btype, int ldb, long long strideB,
        const void *beta,
        void *C, int Ctype, int ldc, long long strideC,
        int batch, int computeType, int algo) {
    if (!h) return CUBLAS_STATUS_NOT_INITIALIZED;
    T("gemmStridedBatchedEx %dx%dx%d x%d", m, n, k, batch);
    for (int i = 0; i < batch; i++) {
        const char *a = (const char *)A + (size_t)i * strideA * elem_size(Atype);
        const char *b = (const char *)B + (size_t)i * strideB * elem_size(Btype);
        char *c = (char *)C + (size_t)i * strideC * elem_size(Ctype);
        cublasStatus_t rc = cublasGemmEx(h, transa, transb, m, n, k, alpha,
                                         a, Atype, lda, b, Btype, ldb,
                                         beta, c, Ctype, ldc, computeType, algo);
        if (rc != CUBLAS_STATUS_SUCCESS) return rc;
    }
    return CUBLAS_STATUS_SUCCESS;
}
enum {
    LT_DESC_COMPUTE_TYPE = 0, LT_DESC_SCALE_TYPE = 1, LT_DESC_POINTER_MODE = 2,
    LT_DESC_TRANSA = 3, LT_DESC_TRANSB = 4, LT_DESC_TRANSC = 5,
    LT_DESC_FILL_MODE = 6, LT_DESC_EPILOGUE = 7, LT_DESC_BIAS_POINTER = 8,
};
enum {
    LT_LAYOUT_TYPE = 0, LT_LAYOUT_ORDER = 1, LT_LAYOUT_ROWS = 2,
    LT_LAYOUT_COLS = 3, LT_LAYOUT_LD = 4, LT_LAYOUT_BATCH_COUNT = 5,
    LT_LAYOUT_STRIDED_BATCH_OFFSET = 6,
};
enum {
    LT_EPILOGUE_DEFAULT = 1, LT_EPILOGUE_RELU = 2, LT_EPILOGUE_BIAS = 4,
    LT_EPILOGUE_RELU_BIAS = 6, LT_EPILOGUE_GELU = 32, LT_EPILOGUE_GELU_BIAS = 36,
};
struct LtDesc {
    int compute_type, scale_type, pointer_mode;
    int transa, transb;
    int epilogue;
    const void *bias;
};
struct LtLayout {
    int type;
    long long rows, cols, ld;
    int batch;
    long long batch_stride;
};
cublasStatus_t cublasLtGetVersion(void) { return 130100; }
cublasStatus_t cublasLtMatmulDescCreate(void **desc, int computeType, int scaleType) {
    if (!desc) return CUBLAS_STATUS_INVALID_VALUE;
    struct LtDesc *d = calloc(1, sizeof *d);
    if (!d) return CUBLAS_STATUS_NOT_INITIALIZED;
    d->compute_type = computeType;
    d->scale_type = scaleType;
    d->epilogue = LT_EPILOGUE_DEFAULT;
    *desc = d;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasLtMatmulDescDestroy(void *desc) { free(desc); return CUBLAS_STATUS_SUCCESS; }
cublasStatus_t cublasLtMatmulDescSetAttribute(void *desc, int attr,
                                              const void *buf, size_t bytes) {
    struct LtDesc *d = desc;
    if (!d || !buf) return CUBLAS_STATUS_INVALID_VALUE;
    switch (attr) {
    case LT_DESC_TRANSA:  memcpy(&d->transa, buf, sizeof d->transa); break;
    case LT_DESC_TRANSB:  memcpy(&d->transb, buf, sizeof d->transb); break;
    case LT_DESC_EPILOGUE: memcpy(&d->epilogue, buf, sizeof d->epilogue); break;
    case LT_DESC_BIAS_POINTER: memcpy(&d->bias, buf, sizeof d->bias); break;
    case LT_DESC_POINTER_MODE: memcpy(&d->pointer_mode, buf, sizeof d->pointer_mode); break;
    case LT_DESC_COMPUTE_TYPE: memcpy(&d->compute_type, buf, sizeof d->compute_type); break;
    case LT_DESC_SCALE_TYPE: memcpy(&d->scale_type, buf, sizeof d->scale_type); break;
    default: (void)bytes; break;   
    }
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasLtMatmulDescGetAttribute(void *desc, int attr, void *buf,
                                              size_t bytes, size_t *written) {
    struct LtDesc *d = desc;
    if (!d || !buf) return CUBLAS_STATUS_INVALID_VALUE;
    int v = attr == LT_DESC_TRANSA ? d->transa
          : attr == LT_DESC_TRANSB ? d->transb
          : attr == LT_DESC_EPILOGUE ? d->epilogue : 0;
    if (bytes < sizeof v) return CUBLAS_STATUS_INVALID_VALUE;
    memcpy(buf, &v, sizeof v);
    if (written) *written = sizeof v;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasLtMatrixLayoutCreate(void **layout, int type,
                                          unsigned long long rows,
                                          unsigned long long cols, long long ld) {
    if (!layout) return CUBLAS_STATUS_INVALID_VALUE;
    struct LtLayout *l = calloc(1, sizeof *l);
    if (!l) return CUBLAS_STATUS_NOT_INITIALIZED;
    l->type = type; l->rows = (long long)rows; l->cols = (long long)cols;
    l->ld = ld; l->batch = 1;
    *layout = l;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasLtMatrixLayoutDestroy(void *layout) { free(layout); return CUBLAS_STATUS_SUCCESS; }
cublasStatus_t cublasLtMatrixLayoutSetAttribute(void *layout, int attr,
                                                const void *buf, size_t bytes) {
    struct LtLayout *l = layout;
    if (!l || !buf) return CUBLAS_STATUS_INVALID_VALUE;
    switch (attr) {
    case LT_LAYOUT_TYPE: memcpy(&l->type, buf, sizeof l->type); break;
    case LT_LAYOUT_ROWS: memcpy(&l->rows, buf, sizeof l->rows); break;
    case LT_LAYOUT_COLS: memcpy(&l->cols, buf, sizeof l->cols); break;
    case LT_LAYOUT_LD:   memcpy(&l->ld, buf, sizeof l->ld); break;
    case LT_LAYOUT_BATCH_COUNT: memcpy(&l->batch, buf, sizeof l->batch); break;
    case LT_LAYOUT_STRIDED_BATCH_OFFSET:
        memcpy(&l->batch_stride, buf, sizeof l->batch_stride); break;
    default: (void)bytes; break;
    }
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasLtMatmulPreferenceCreate(void **pref) {
    if (!pref) return CUBLAS_STATUS_INVALID_VALUE;
    void *p = calloc(1, 8);
    if (!p) return CUBLAS_STATUS_NOT_INITIALIZED;
    *pref = p;
    return CUBLAS_STATUS_SUCCESS;
}
cublasStatus_t cublasLtMatmulPreferenceDestroy(void *pref) { free(pref); return CUBLAS_STATUS_SUCCESS; }
cublasStatus_t cublasLtMatmulPreferenceSetAttribute(void *pref, int attr,
                                                    const void *buf, size_t bytes) {
    (void)attr; (void)buf; (void)bytes;
    return pref ? CUBLAS_STATUS_SUCCESS : CUBLAS_STATUS_INVALID_VALUE;
}
struct LtHeuristic {
    unsigned long long algo[8];
    size_t workspace;
    cublasStatus_t state;
    float waves;
    int reserved[4];
};
cublasStatus_t cublasLtMatmulAlgoGetHeuristic(
        void *lt, void *desc, void *Adesc, void *Bdesc, void *Cdesc, void *Ddesc,
        void *pref, int requested, void *results, int *returned) {
    (void)lt; (void)desc; (void)Adesc; (void)Bdesc; (void)Cdesc; (void)Ddesc; (void)pref;
    if (!results || !returned || requested < 1) return CUBLAS_STATUS_INVALID_VALUE;
    struct LtHeuristic *r = results;
    memset(r, 0, sizeof *r);
    r->state = CUBLAS_STATUS_SUCCESS;
    r->waves = 1.0f;
    *returned = 1;
    return CUBLAS_STATUS_SUCCESS;
}
static float gelu_tanh(float x) {
    const float c = 0.7978845608028654f;   
    float inner = c * (x + 0.044715f * x * x * x);
    return 0.5f * x * (1.0f + tanhf(inner));
}
cublasStatus_t cublasLtMatmul(void *lt, void *desc,
                              const void *alpha,
                              const void *A, void *Adesc,
                              const void *B, void *Bdesc,
                              const void *beta,
                              const void *C, void *Cdesc,
                              void *D, void *Ddesc,
                              const void *algo, void *workspace,
                              size_t workspace_bytes, void *stream) {
    drain_driver();
    (void)algo; (void)workspace; (void)workspace_bytes; (void)stream;
    struct LtDesc *d = desc;
    struct LtLayout *la = Adesc, *lb = Bdesc, *lc = Cdesc, *ld_ = Ddesc;
    if (!lt || !d || !la || !lb || !ld_) return CUBLAS_STATUS_INVALID_VALUE;
    if (la->batch > 1 || lb->batch > 1 || ld_->batch > 1)
        return CUBLAS_STATUS_NOT_SUPPORTED;
    int m = (int)ld_->rows, n = (int)ld_->cols;
    int k = d->transa == CUBLAS_OP_N ? (int)la->cols : (int)la->rows;
    T("ltMatmul %dx%dx%d epilogue=%d", m, n, k, d->epilogue);
    size_t esz = elem_size(ld_->type);
    if (C && D && C != D && lc) {
        for (int j = 0; j < n; j++)
            memcpy((char *)D + (size_t)j * ld_->ld * esz,
                   (const char *)C + (size_t)j * lc->ld * esz, (size_t)m * esz);
    }
    cublasStatus_t rc = cublasGemmEx(lt, d->transa, d->transb, m, n, k, alpha,
                                     A, la->type, (int)la->ld,
                                     B, lb->type, (int)lb->ld,
                                     beta, D, ld_->type, (int)ld_->ld,
                                     d->compute_type ? d->compute_type : CUDA_R_32F, 0);
    if (rc != CUBLAS_STATUS_SUCCESS) return rc;
    int want_bias = d->epilogue == LT_EPILOGUE_BIAS
                 || d->epilogue == LT_EPILOGUE_RELU_BIAS
                 || d->epilogue == LT_EPILOGUE_GELU_BIAS;
    int want_relu = d->epilogue == LT_EPILOGUE_RELU || d->epilogue == LT_EPILOGUE_RELU_BIAS;
    int want_gelu = d->epilogue == LT_EPILOGUE_GELU || d->epilogue == LT_EPILOGUE_GELU_BIAS;
    if (!want_bias && !want_relu && !want_gelu)
        return CUBLAS_STATUS_SUCCESS;
    {
        int flags = (want_bias ? 1 : 0) | (want_relu ? 2 : 0) | (want_gelu ? 4 : 0);
        const void *bias = want_bias ? d->bias : NULL;
        if (zblas_gpu_epilogue(D, ld_->type, m, n, (int)ld_->ld, bias,
                               la->type, flags) == 0)
            return CUBLAS_STATUS_SUCCESS;
    }
    const int d_half = ld_->type == CUDA_R_16F, d_bf = ld_->type == CUDA_R_16BF;
    const int b_half = la->type == CUDA_R_16F && d_half;
    const int b_bf = la->type == CUDA_R_16BF && d_bf;
    for (int j = 0; j < n; j++) {
        for (int i = 0; i < m; i++) {
            size_t at = (size_t)i + (size_t)j * ld_->ld;
            float v;
            if (d_half)     v = half_to_float(((unsigned short *)D)[at]);
            else if (d_bf)  v = bf16_to_float(((unsigned short *)D)[at]);
            else            v = ((float *)D)[at];
            if (want_bias && d->bias) {
                v += b_half ? half_to_float(((const unsigned short *)d->bias)[i])
                   : b_bf   ? bf16_to_float(((const unsigned short *)d->bias)[i])
                            : ((const float *)d->bias)[i];
            }
            if (want_relu && v < 0.0f) v = 0.0f;
            if (want_gelu) v = gelu_tanh(v);
            if (d_half)     ((unsigned short *)D)[at] = float_to_half(v);
            else if (d_bf)  ((unsigned short *)D)[at] = float_to_bf16(v);
            else            ((float *)D)[at] = v;
        }
    }
    return CUBLAS_STATUS_SUCCESS;
}
#define UNSUPPORTED(name) \
    cublasStatus_t name(void) { T("unsupported: %s", #name); \
                                return CUBLAS_STATUS_NOT_SUPPORTED; }
UNSUPPORTED(cublasCdotc_v2)      UNSUPPORTED(cublasCdotu_v2)
UNSUPPORTED(cublasZdotc_v2)      UNSUPPORTED(cublasZdotu_v2)
UNSUPPORTED(cublasDotEx)
UNSUPPORTED(cublasCgemm_v2)      UNSUPPORTED(cublasZgemm_v2)
UNSUPPORTED(cublasCgemv_v2)      UNSUPPORTED(cublasZgemv_v2)
UNSUPPORTED(cublasCgemmStridedBatched)
UNSUPPORTED(cublasZgemmStridedBatched)
UNSUPPORTED(cublasDgemmStridedBatched)
UNSUPPORTED(cublasStrsm_v2)      UNSUPPORTED(cublasDtrsm_v2)
UNSUPPORTED(cublasCtrsm_v2)      UNSUPPORTED(cublasZtrsm_v2)
UNSUPPORTED(cublasStrsmBatched)  UNSUPPORTED(cublasDtrsmBatched)
UNSUPPORTED(cublasCtrsmBatched)  UNSUPPORTED(cublasZtrsmBatched)
UNSUPPORTED(cublasSgetrfBatched) UNSUPPORTED(cublasDgetrfBatched)
UNSUPPORTED(cublasCgetrfBatched) UNSUPPORTED(cublasZgetrfBatched)
UNSUPPORTED(cublasSgetrsBatched) UNSUPPORTED(cublasDgetrsBatched)
UNSUPPORTED(cublasCgetrsBatched) UNSUPPORTED(cublasZgetrsBatched)
UNSUPPORTED(cublasSgeqrfBatched) UNSUPPORTED(cublasDgeqrfBatched)
UNSUPPORTED(cublasCgeqrfBatched) UNSUPPORTED(cublasZgeqrfBatched)
UNSUPPORTED(cublasSgelsBatched)  UNSUPPORTED(cublasDgelsBatched)
UNSUPPORTED(cublasCgelsBatched)  UNSUPPORTED(cublasZgelsBatched)
