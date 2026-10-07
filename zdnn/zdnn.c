#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "oneapi/dnnl/dnnl.h"
typedef int cudnnStatus_t;
#define CUDNN_STATUS_SUCCESS 0
#define CUDNN_STATUS_NOT_INITIALIZED 1
#define CUDNN_STATUS_BAD_PARAM 3
#define CUDNN_STATUS_NOT_SUPPORTED 9
#define CUDNN_STATUS_EXECUTION_FAILED 8
typedef void *cudnnHandle_t;
typedef void *cudaStream_t;
typedef struct TensorDesc *cudnnTensorDescriptor_t;
typedef struct FilterDesc *cudnnFilterDescriptor_t;
typedef struct ConvDesc *cudnnConvolutionDescriptor_t;
typedef struct ActDesc *cudnnActivationDescriptor_t;
typedef struct PoolDesc *cudnnPoolingDescriptor_t;
enum { CUDNN_DATA_FLOAT = 0, CUDNN_DATA_DOUBLE = 1, CUDNN_DATA_HALF = 2 };
enum { CUDNN_TENSOR_NCHW = 0, CUDNN_TENSOR_NHWC = 1 };
enum { CUDNN_CONVOLUTION = 0, CUDNN_CROSS_CORRELATION = 1 };
enum { CUDNN_ACTIVATION_SIGMOID = 0, CUDNN_ACTIVATION_RELU = 1,
       CUDNN_ACTIVATION_TANH = 2, CUDNN_ACTIVATION_CLIPPED_RELU = 3,
       CUDNN_ACTIVATION_ELU = 4, CUDNN_ACTIVATION_IDENTITY = 5 };
enum { CUDNN_POOLING_MAX = 0, CUDNN_POOLING_AVERAGE_COUNT_INCLUDE_PADDING = 1,
       CUDNN_POOLING_AVERAGE_COUNT_EXCLUDE_PADDING = 2 };
enum { CUDNN_SOFTMAX_FAST = 0, CUDNN_SOFTMAX_ACCURATE = 1, CUDNN_SOFTMAX_LOG = 2 };
enum { CUDNN_SOFTMAX_MODE_INSTANCE = 0, CUDNN_SOFTMAX_MODE_CHANNEL = 1 };
struct TensorDesc { int n, c, h, w, dtype, fmt; };
struct FilterDesc { int k, c, h, w, dtype, fmt; };
struct ConvDesc { int pad_h, pad_w, str_h, str_w, dil_h, dil_w, mode, dtype, groups; };
struct ActDesc { int mode; double coef; };
struct PoolDesc { int mode, wh, ww, pad_h, pad_w, str_h, str_w; };
struct Handle { dnnl_engine_t engine; dnnl_stream_t stream; cudaStream_t cuda_stream; };
static dnnl_data_type_t dt_of(int cudnn_dt) {
    switch (cudnn_dt) {
    case CUDNN_DATA_FLOAT: return dnnl_f32;
    case CUDNN_DATA_HALF: return dnnl_f16;
    default: return dnnl_data_type_undef;
    }
}
static dnnl_format_tag_t tag_of(int fmt) {
    return fmt == CUDNN_TENSOR_NHWC ? dnnl_nhwc : dnnl_nchw;
}
cudnnStatus_t cudnnCreate(cudnnHandle_t *h) {
    if (!h) return CUDNN_STATUS_BAD_PARAM;
    struct Handle *x = calloc(1, sizeof *x);
    if (!x) return CUDNN_STATUS_NOT_INITIALIZED;
    if (dnnl_engine_create(&x->engine, dnnl_cpu, 0) != dnnl_success
        || dnnl_stream_create(&x->stream, x->engine, dnnl_stream_default_flags) != dnnl_success) {
        free(x);
        return CUDNN_STATUS_NOT_INITIALIZED;
    }
    *h = x;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnDestroy(cudnnHandle_t h) {
    struct Handle *x = h;
    if (x) { dnnl_stream_destroy(x->stream); dnnl_engine_destroy(x->engine); free(x); }
    return CUDNN_STATUS_SUCCESS;
}
size_t cudnnGetVersion(void) { return 90000; }
size_t cudnnGetCudartVersion(void) { return 13000; }
cudnnStatus_t cudnnSetStream(cudnnHandle_t h, cudaStream_t s) {
    if (!h) return CUDNN_STATUS_NOT_INITIALIZED;
    ((struct Handle *)h)->cuda_stream = s;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetStream(cudnnHandle_t h, cudaStream_t *s) {
    if (!h || !s) return CUDNN_STATUS_BAD_PARAM;
    *s = ((struct Handle *)h)->cuda_stream;
    return CUDNN_STATUS_SUCCESS;
}
#define DESC_CREATE(NAME, TYPE) \
    cudnnStatus_t NAME(TYPE *d) { \
        if (!d) return CUDNN_STATUS_BAD_PARAM; \
        *d = calloc(1, sizeof **d); \
        return *d ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_NOT_INITIALIZED; \
    }
#define DESC_DESTROY(NAME, TYPE) \
    cudnnStatus_t NAME(TYPE d) { free(d); return CUDNN_STATUS_SUCCESS; }
DESC_CREATE(cudnnCreateTensorDescriptor, cudnnTensorDescriptor_t)
DESC_DESTROY(cudnnDestroyTensorDescriptor, cudnnTensorDescriptor_t)
DESC_CREATE(cudnnCreateFilterDescriptor, cudnnFilterDescriptor_t)
DESC_DESTROY(cudnnDestroyFilterDescriptor, cudnnFilterDescriptor_t)
DESC_CREATE(cudnnCreateConvolutionDescriptor, cudnnConvolutionDescriptor_t)
DESC_DESTROY(cudnnDestroyConvolutionDescriptor, cudnnConvolutionDescriptor_t)
DESC_CREATE(cudnnCreateActivationDescriptor, cudnnActivationDescriptor_t)
DESC_DESTROY(cudnnDestroyActivationDescriptor, cudnnActivationDescriptor_t)
DESC_CREATE(cudnnCreatePoolingDescriptor, cudnnPoolingDescriptor_t)
DESC_DESTROY(cudnnDestroyPoolingDescriptor, cudnnPoolingDescriptor_t)
cudnnStatus_t cudnnSetTensor4dDescriptor(cudnnTensorDescriptor_t d, int fmt,
                                         int dtype, int n, int c, int h, int w) {
    if (!d) return CUDNN_STATUS_BAD_PARAM;
    if (dt_of(dtype) == dnnl_data_type_undef) return CUDNN_STATUS_NOT_SUPPORTED;
    *d = (struct TensorDesc){n, c, h, w, dtype, fmt};
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetTensor4dDescriptor(const cudnnTensorDescriptor_t d, int *dtype,
                                         int *n, int *c, int *h, int *w,
                                         int *ns, int *cs, int *hs, int *ws) {
    if (!d) return CUDNN_STATUS_BAD_PARAM;
    if (dtype) *dtype = d->dtype;
    if (n) *n = d->n; if (c) *c = d->c; if (h) *h = d->h; if (w) *w = d->w;
    if (d->fmt == CUDNN_TENSOR_NHWC) {
        if (ws) *ws = d->c; if (cs) *cs = 1;
        if (hs) *hs = d->w * d->c; if (ns) *ns = d->h * d->w * d->c;
    } else {
        if (ws) *ws = 1; if (hs) *hs = d->w;
        if (cs) *cs = d->h * d->w; if (ns) *ns = d->c * d->h * d->w;
    }
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnSetFilter4dDescriptor(cudnnFilterDescriptor_t d, int dtype,
                                         int fmt, int k, int c, int h, int w) {
    if (!d) return CUDNN_STATUS_BAD_PARAM;
    if (dt_of(dtype) == dnnl_data_type_undef) return CUDNN_STATUS_NOT_SUPPORTED;
    *d = (struct FilterDesc){k, c, h, w, dtype, fmt};
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnSetConvolution2dDescriptor(cudnnConvolutionDescriptor_t d,
                                              int pad_h, int pad_w, int u, int v,
                                              int dil_h, int dil_w, int mode, int dtype) {
    if (!d) return CUDNN_STATUS_BAD_PARAM;
    *d = (struct ConvDesc){pad_h, pad_w, u, v, dil_h, dil_w, mode, dtype, 1};
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnSetConvolutionGroupCount(cudnnConvolutionDescriptor_t d, int g) {
    if (!d || g < 1) return CUDNN_STATUS_BAD_PARAM;
    d->groups = g;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnSetConvolutionMathType(cudnnConvolutionDescriptor_t d, int t) {
    (void)d; (void)t;   
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetConvolution2dForwardOutputDim(
    const cudnnConvolutionDescriptor_t conv, const cudnnTensorDescriptor_t in,
    const cudnnFilterDescriptor_t filt, int *n, int *c, int *h, int *w) {
    if (!conv || !in || !filt) return CUDNN_STATUS_BAD_PARAM;
    if (n) *n = in->n;
    if (c) *c = filt->k;
    int eff_h = (filt->h - 1) * conv->dil_h + 1;
    int eff_w = (filt->w - 1) * conv->dil_w + 1;
    if (h) *h = (in->h + 2 * conv->pad_h - eff_h) / conv->str_h + 1;
    if (w) *w = (in->w + 2 * conv->pad_w - eff_w) / conv->str_w + 1;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnSetActivationDescriptor(cudnnActivationDescriptor_t d, int mode,
                                           int nan_opt, double coef) {
    (void)nan_opt;
    if (!d) return CUDNN_STATUS_BAD_PARAM;
    *d = (struct ActDesc){mode, coef};
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnSetPooling2dDescriptor(cudnnPoolingDescriptor_t d, int mode,
                                          int nan_opt, int wh, int ww,
                                          int pad_h, int pad_w, int str_h, int str_w) {
    (void)nan_opt;
    if (!d) return CUDNN_STATUS_BAD_PARAM;
    *d = (struct PoolDesc){mode, wh, ww, pad_h, pad_w, str_h, str_w};
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetPooling2dForwardOutputDim(const cudnnPoolingDescriptor_t p,
                                                const cudnnTensorDescriptor_t in,
                                                int *n, int *c, int *h, int *w) {
    if (!p || !in) return CUDNN_STATUS_BAD_PARAM;
    if (n) *n = in->n;
    if (c) *c = in->c;
    if (h) *h = (in->h + 2 * p->pad_h - p->wh) / p->str_h + 1;
    if (w) *w = (in->w + 2 * p->pad_w - p->ww) / p->str_w + 1;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetConvolutionForwardWorkspaceSize(cudnnHandle_t h, const void *a,
                                                      const void *b, const void *c,
                                                      const void *d, int algo, size_t *sz) {
    (void)h; (void)a; (void)b; (void)c; (void)d; (void)algo;
    if (!sz) return CUDNN_STATUS_BAD_PARAM;
    *sz = 0;
    return CUDNN_STATUS_SUCCESS;
}
static dnnl_status_t run_primitive(struct Handle *h, dnnl_primitive_desc_t pd,
                                   dnnl_exec_arg_t *args, int nargs) {
    dnnl_primitive_t prim = NULL;
    dnnl_status_t s = dnnl_primitive_create(&prim, pd);
    if (s == dnnl_success) {
        s = dnnl_primitive_execute(prim, h->stream, nargs, args);
        if (s == dnnl_success) s = dnnl_stream_wait(h->stream);
        dnnl_primitive_destroy(prim);
    }
    dnnl_primitive_desc_destroy(pd);
    return s;
}
static dnnl_status_t wrap(dnnl_memory_t *m, dnnl_engine_t e,
                          const dnnl_dims_t dims, int ndims,
                          dnnl_data_type_t dt, dnnl_format_tag_t tag, void *p) {
    dnnl_memory_desc_t md = NULL;
    dnnl_status_t s = dnnl_memory_desc_create_with_tag(&md, ndims, dims, dt, tag);
    if (s != dnnl_success) return s;
    s = dnnl_memory_create(m, md, e, p);
    dnnl_memory_desc_destroy(md);
    return s;
}
cudnnStatus_t cudnnConvolutionForward(
    cudnnHandle_t handle, const void *alpha,
    const cudnnTensorDescriptor_t xd, const void *x,
    const cudnnFilterDescriptor_t wd, const void *w,
    const cudnnConvolutionDescriptor_t cd, int algo,
    void *workspace, size_t workspace_bytes,
    const void *beta, const cudnnTensorDescriptor_t yd, void *y) {
    (void)algo; (void)workspace; (void)workspace_bytes;
    struct Handle *h = handle;
    if (!h || !xd || !wd || !cd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (cd->groups != 1) return CUDNN_STATUS_NOT_SUPPORTED;
    if (cd->mode == CUDNN_CONVOLUTION) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t xdims = {xd->n, xd->c, xd->h, xd->w};
    dnnl_dims_t wdims = {wd->k, wd->c, wd->h, wd->w};
    dnnl_dims_t ydims = {yd->n, yd->c, yd->h, yd->w};
    dnnl_dims_t strides = {cd->str_h, cd->str_w};
    dnnl_dims_t dilates = {cd->dil_h - 1, cd->dil_w - 1};   
    dnnl_dims_t padl = {cd->pad_h, cd->pad_w};
    dnnl_dims_t padr = {cd->pad_h, cd->pad_w};
    dnnl_memory_desc_t xmd = NULL, wmd = NULL, ymd = NULL;
    if (dnnl_memory_desc_create_with_tag(&xmd, 4, xdims, dt, tag_of(xd->fmt)) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&wmd, 4, wdims, dt, dnnl_oihw) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&ymd, 4, ydims, dt, tag_of(yd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t pd = NULL;
    dnnl_status_t s = dnnl_convolution_forward_primitive_desc_create(
        &pd, h->engine, dnnl_forward_inference, dnnl_convolution_direct,
        xmd, wmd, NULL, ymd, strides, dilates, padl, padr, NULL);
    dnnl_memory_desc_destroy(xmd);
    dnnl_memory_desc_destroy(wmd);
    dnnl_memory_desc_destroy(ymd);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t xm = NULL, wm = NULL, ym = NULL;
    wrap(&xm, h->engine, xdims, 4, dt, tag_of(xd->fmt), (void *)x);
    wrap(&wm, h->engine, wdims, 4, dt, dnnl_oihw, (void *)w);
    wrap(&ym, h->engine, ydims, 4, dt, tag_of(yd->fmt), y);
    dnnl_exec_arg_t args[] = {
        {DNNL_ARG_SRC, xm}, {DNNL_ARG_WEIGHTS, wm}, {DNNL_ARG_DST, ym},
    };
    s = run_primitive(h, pd, args, 3);
    dnnl_memory_destroy(xm); dnnl_memory_destroy(wm); dnnl_memory_destroy(ym);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnActivationForward(cudnnHandle_t handle,
                                     const cudnnActivationDescriptor_t ad,
                                     const void *alpha,
                                     const cudnnTensorDescriptor_t xd, const void *x,
                                     const void *beta,
                                     const cudnnTensorDescriptor_t yd, void *y) {
    struct Handle *h = handle;
    if (!h || !ad || !xd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_alg_kind_t alg;
    float a = 0.0f, b = 0.0f;
    switch (ad->mode) {
    case CUDNN_ACTIVATION_RELU: alg = dnnl_eltwise_relu; break;
    case CUDNN_ACTIVATION_TANH: alg = dnnl_eltwise_tanh; break;
    case CUDNN_ACTIVATION_SIGMOID: alg = dnnl_eltwise_logistic; break;
    case CUDNN_ACTIVATION_ELU: alg = dnnl_eltwise_elu; a = (float)ad->coef; break;
    case CUDNN_ACTIVATION_CLIPPED_RELU:
        alg = dnnl_eltwise_clip; a = 0.0f; b = (float)ad->coef; break;
    case CUDNN_ACTIVATION_IDENTITY: alg = dnnl_eltwise_linear; a = 1.0f; break;
    default: return CUDNN_STATUS_NOT_SUPPORTED;
    }
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t dims = {xd->n, xd->c, xd->h, xd->w};
    dnnl_memory_desc_t md = NULL;
    if (dnnl_memory_desc_create_with_tag(&md, 4, dims, dt, tag_of(xd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t pd = NULL;
    dnnl_status_t s = dnnl_eltwise_forward_primitive_desc_create(
        &pd, h->engine, dnnl_forward_inference, alg, md, md, a, b, NULL);
    dnnl_memory_desc_destroy(md);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t xm = NULL, ym = NULL;
    wrap(&xm, h->engine, dims, 4, dt, tag_of(xd->fmt), (void *)x);
    wrap(&ym, h->engine, dims, 4, dt, tag_of(yd->fmt), y);
    dnnl_exec_arg_t args[] = {{DNNL_ARG_SRC, xm}, {DNNL_ARG_DST, ym}};
    s = run_primitive(h, pd, args, 2);
    dnnl_memory_destroy(xm); dnnl_memory_destroy(ym);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnPoolingForward(cudnnHandle_t handle,
                                  const cudnnPoolingDescriptor_t pd_,
                                  const void *alpha,
                                  const cudnnTensorDescriptor_t xd, const void *x,
                                  const void *beta,
                                  const cudnnTensorDescriptor_t yd, void *y) {
    struct Handle *h = handle;
    if (!h || !pd_ || !xd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_alg_kind_t alg =
        pd_->mode == CUDNN_POOLING_MAX ? dnnl_pooling_max
      : pd_->mode == CUDNN_POOLING_AVERAGE_COUNT_INCLUDE_PADDING
            ? dnnl_pooling_avg_include_padding
            : dnnl_pooling_avg_exclude_padding;
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t xdims = {xd->n, xd->c, xd->h, xd->w};
    dnnl_dims_t ydims = {yd->n, yd->c, yd->h, yd->w};
    dnnl_dims_t strides = {pd_->str_h, pd_->str_w};
    dnnl_dims_t kernel = {pd_->wh, pd_->ww};
    dnnl_dims_t dilation = {0, 0};
    dnnl_dims_t padl = {pd_->pad_h, pd_->pad_w};
    dnnl_dims_t padr = {pd_->pad_h, pd_->pad_w};
    dnnl_memory_desc_t xmd = NULL, ymd = NULL;
    if (dnnl_memory_desc_create_with_tag(&xmd, 4, xdims, dt, tag_of(xd->fmt)) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&ymd, 4, ydims, dt, tag_of(yd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t pd = NULL;
    dnnl_status_t s = dnnl_pooling_forward_primitive_desc_create(
        &pd, h->engine, dnnl_forward_inference, alg, xmd, ymd,
        strides, kernel, dilation, padl, padr, NULL);
    dnnl_memory_desc_destroy(xmd); dnnl_memory_desc_destroy(ymd);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t xm = NULL, ym = NULL;
    wrap(&xm, h->engine, xdims, 4, dt, tag_of(xd->fmt), (void *)x);
    wrap(&ym, h->engine, ydims, 4, dt, tag_of(yd->fmt), y);
    dnnl_exec_arg_t args[] = {{DNNL_ARG_SRC, xm}, {DNNL_ARG_DST, ym}};
    s = run_primitive(h, pd, args, 2);
    dnnl_memory_destroy(xm); dnnl_memory_destroy(ym);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnSoftmaxForward(cudnnHandle_t handle, int algo, int mode,
                                  const void *alpha,
                                  const cudnnTensorDescriptor_t xd, const void *x,
                                  const void *beta,
                                  const cudnnTensorDescriptor_t yd, void *y) {
    struct Handle *h = handle;
    if (!h || !xd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t dims = {xd->n, xd->c, xd->h, xd->w};
    int axis = mode == CUDNN_SOFTMAX_MODE_CHANNEL ? 1
             : (xd->h == 1 && xd->w == 1) ? 1 : -1;
    if (axis < 0) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_desc_t md = NULL;
    if (dnnl_memory_desc_create_with_tag(&md, 4, dims, dt, tag_of(xd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t pd = NULL;
    dnnl_status_t s = dnnl_softmax_forward_primitive_desc_create(
        &pd, h->engine, dnnl_forward_inference,
        algo == CUDNN_SOFTMAX_LOG ? dnnl_softmax_log : dnnl_softmax_accurate,
        md, md, axis, NULL);
    dnnl_memory_desc_destroy(md);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t xm = NULL, ym = NULL;
    wrap(&xm, h->engine, dims, 4, dt, tag_of(xd->fmt), (void *)x);
    wrap(&ym, h->engine, dims, 4, dt, tag_of(yd->fmt), y);
    dnnl_exec_arg_t args[] = {{DNNL_ARG_SRC, xm}, {DNNL_ARG_DST, ym}};
    s = run_primitive(h, pd, args, 2);
    dnnl_memory_destroy(xm); dnnl_memory_destroy(ym);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnAddTensor(cudnnHandle_t handle, const void *alpha,
                             const cudnnTensorDescriptor_t ad, const void *a,
                             const void *beta,
                             const cudnnTensorDescriptor_t cd, void *c) {
    struct Handle *h = handle;
    if (!h || !ad || !cd) return CUDNN_STATUS_BAD_PARAM;
    float al = alpha ? *(const float *)alpha : 1.0f;
    float be = beta ? *(const float *)beta : 1.0f;
    if (ad->dtype != CUDNN_DATA_FLOAT || cd->dtype != CUDNN_DATA_FLOAT)
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (!(ad->n == 1 && ad->h == 1 && ad->w == 1 && ad->c == cd->c))
        return CUDNN_STATUS_NOT_SUPPORTED;
    const float *bias = a;
    float *out = c;
    for (int n = 0; n < cd->n; n++)
        for (int ch = 0; ch < cd->c; ch++)
            for (int i = 0; i < cd->h * cd->w; i++) {
                size_t at = cd->fmt == CUDNN_TENSOR_NHWC
                    ? ((size_t)n * cd->h * cd->w + i) * cd->c + ch
                    : ((size_t)n * cd->c + ch) * cd->h * cd->w + i;
                out[at] = be * out[at] + al * bias[ch];
            }
    return CUDNN_STATUS_SUCCESS;
}
const char *cudnnGetErrorString(cudnnStatus_t s) {
    switch (s) {
    case CUDNN_STATUS_SUCCESS: return "CUDNN_STATUS_SUCCESS";
    case CUDNN_STATUS_NOT_INITIALIZED: return "CUDNN_STATUS_NOT_INITIALIZED";
    case CUDNN_STATUS_BAD_PARAM: return "CUDNN_STATUS_BAD_PARAM";
    case CUDNN_STATUS_NOT_SUPPORTED: return "CUDNN_STATUS_NOT_SUPPORTED";
    case CUDNN_STATUS_EXECUTION_FAILED: return "CUDNN_STATUS_EXECUTION_FAILED";
    default: return "CUDNN_STATUS_INTERNAL_ERROR";
    }
}
cudnnStatus_t cudnnBatchNormalizationForwardInference(
    cudnnHandle_t handle, int mode, const void *alpha, const void *beta,
    const cudnnTensorDescriptor_t xd, const void *x,
    const cudnnTensorDescriptor_t yd, void *y,
    const cudnnTensorDescriptor_t bnd, const void *scale, const void *bias,
    const void *mean, const void *variance, double eps) {
    (void)bnd;
    if (!handle || !xd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (xd->dtype != CUDNN_DATA_FLOAT) return CUDNN_STATUS_NOT_SUPPORTED;
    if (mode == 0) return CUDNN_STATUS_NOT_SUPPORTED;
    const float *s = scale, *b = bias, *m = mean, *v = variance;
    const float *in = x;
    float *out = y;
    int hw = xd->h * xd->w;
    for (int n = 0; n < xd->n; n++)
        for (int c = 0; c < xd->c; c++) {
            float inv = 1.0f / sqrtf((float)((double)v[c] + eps));
            float k = s[c] * inv, off = b[c] - m[c] * k;
            for (int i = 0; i < hw; i++) {
                size_t at = xd->fmt == CUDNN_TENSOR_NHWC
                    ? ((size_t)n * hw + i) * xd->c + c
                    : ((size_t)n * xd->c + c) * hw + i;
                out[at] = in[at] * k + off;
            }
        }
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnScaleTensor(cudnnHandle_t handle,
                               const cudnnTensorDescriptor_t yd, void *y,
                               const void *alpha) {
    if (!handle || !yd) return CUDNN_STATUS_BAD_PARAM;
    if (yd->dtype != CUDNN_DATA_FLOAT) return CUDNN_STATUS_NOT_SUPPORTED;
    float a = alpha ? *(const float *)alpha : 1.0f;
    float *p = y;
    size_t n = (size_t)yd->n * yd->c * yd->h * yd->w;
    for (size_t i = 0; i < n; i++) p[i] *= a;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnTransformTensor(cudnnHandle_t handle, const void *alpha,
                                   const cudnnTensorDescriptor_t xd, const void *x,
                                   const void *beta,
                                   const cudnnTensorDescriptor_t yd, void *y) {
    if (!handle || !xd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (xd->dtype != CUDNN_DATA_FLOAT || yd->dtype != CUDNN_DATA_FLOAT)
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (xd->n != yd->n || xd->c != yd->c || xd->h != yd->h || xd->w != yd->w)
        return CUDNN_STATUS_BAD_PARAM;
    const float *in = x;
    float *out = y;
    int hw = xd->h * xd->w;
    for (int n = 0; n < xd->n; n++)
        for (int c = 0; c < xd->c; c++)
            for (int i = 0; i < hw; i++) {
                size_t si = xd->fmt == CUDNN_TENSOR_NHWC
                    ? ((size_t)n * hw + i) * xd->c + c
                    : ((size_t)n * xd->c + c) * hw + i;
                size_t di = yd->fmt == CUDNN_TENSOR_NHWC
                    ? ((size_t)n * hw + i) * yd->c + c
                    : ((size_t)n * yd->c + c) * hw + i;
                out[di] = in[si];
            }
    return CUDNN_STATUS_SUCCESS;
}
typedef struct { int algo; int status; float time; size_t memory;
                 int determinism; int mathType; int reserved[3]; } cudnnConvAlgoPerf_t;
cudnnStatus_t cudnnGetConvolutionForwardAlgorithmMaxCount(cudnnHandle_t h, int *count) {
    (void)h;
    if (!count) return CUDNN_STATUS_BAD_PARAM;
    *count = 1;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetConvolutionForwardAlgorithm_v7(
    cudnnHandle_t h, const void *xd, const void *wd, const void *cd,
    const void *yd, int requested, int *returned, cudnnConvAlgoPerf_t *perf) {
    (void)h; (void)xd; (void)wd; (void)cd; (void)yd;
    if (!returned || (requested > 0 && !perf)) return CUDNN_STATUS_BAD_PARAM;
    if (requested < 1) { *returned = 0; return CUDNN_STATUS_SUCCESS; }
    memset(perf, 0, sizeof *perf);
    perf[0].algo = 0;                 
    perf[0].status = CUDNN_STATUS_SUCCESS;
    perf[0].time = -1.0f;             
    perf[0].memory = 0;
    perf[0].determinism = 1;
    *returned = 1;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnFindConvolutionForwardAlgorithm(
    cudnnHandle_t h, const void *xd, const void *wd, const void *cd,
    const void *yd, int requested, int *returned, cudnnConvAlgoPerf_t *perf) {
    return cudnnGetConvolutionForwardAlgorithm_v7(h, xd, wd, cd, yd, requested,
                                                  returned, perf);
}
cudnnStatus_t cudnnConvolutionBiasActivationForward(
    cudnnHandle_t handle, const void *alpha1,
    const cudnnTensorDescriptor_t xd, const void *x,
    const cudnnFilterDescriptor_t wd, const void *w,
    const cudnnConvolutionDescriptor_t cd, int algo,
    void *workspace, size_t workspace_bytes,
    const void *alpha2, const cudnnTensorDescriptor_t zd, const void *z,
    const cudnnTensorDescriptor_t bd, const void *bias,
    const cudnnActivationDescriptor_t ad,
    const cudnnTensorDescriptor_t yd, void *y) {
    float one = 1.0f, zero = 0.0f;
    if (z && zd && *(const float *)alpha2 != 0.0f)
        return CUDNN_STATUS_NOT_SUPPORTED;
    cudnnStatus_t s = cudnnConvolutionForward(handle, alpha1, xd, x, wd, w, cd,
                                              algo, workspace, workspace_bytes,
                                              &zero, yd, y);
    if (s != CUDNN_STATUS_SUCCESS) return s;
    if (bias && bd) {
        s = cudnnAddTensor(handle, &one, bd, bias, &one, yd, y);
        if (s != CUDNN_STATUS_SUCCESS) return s;
    }
    if (ad) s = cudnnActivationForward(handle, ad, &one, yd, y, &zero, yd, y);
    return s;
}
static dnnl_status_t conv_fwd_hint(dnnl_primitive_desc_t *out, dnnl_engine_t e,
                                   const dnnl_memory_desc_t xmd,
                                   const dnnl_memory_desc_t wmd,
                                   const dnnl_memory_desc_t ymd,
                                   const dnnl_dims_t strides,
                                   const dnnl_dims_t dilates,
                                   const dnnl_dims_t padl,
                                   const dnnl_dims_t padr) {
    return dnnl_convolution_forward_primitive_desc_create(
        out, e, dnnl_forward_training, dnnl_convolution_direct,
        xmd, wmd, NULL, ymd, strides, dilates, padl, padr, NULL);
}
#define ZDNN_PLAIN_SCALES(alpha, beta)                                        \
    do {                                                                       \
        if ((alpha && *(const float *)(alpha) != 1.0f)                         \
            || (beta && *(const float *)(beta) != 0.0f))                       \
            return CUDNN_STATUS_NOT_SUPPORTED;                                 \
    } while (0)
cudnnStatus_t cudnnConvolutionBackwardData(
    cudnnHandle_t handle, const void *alpha,
    const cudnnFilterDescriptor_t wd, const void *w,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const cudnnConvolutionDescriptor_t cd, int algo,
    void *workspace, size_t workspace_bytes,
    const void *beta, const cudnnTensorDescriptor_t dxd, void *dx) {
    (void)algo; (void)workspace; (void)workspace_bytes;
    struct Handle *h = handle;
    if (!h || !wd || !dyd || !cd || !dxd) return CUDNN_STATUS_BAD_PARAM;
    ZDNN_PLAIN_SCALES(alpha, beta);
    if (cd->groups != 1 || cd->mode == CUDNN_CONVOLUTION)
        return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_data_type_t dt = dt_of(dxd->dtype);
    dnnl_dims_t xdims = {dxd->n, dxd->c, dxd->h, dxd->w};
    dnnl_dims_t wdims = {wd->k, wd->c, wd->h, wd->w};
    dnnl_dims_t ydims = {dyd->n, dyd->c, dyd->h, dyd->w};
    dnnl_dims_t strides = {cd->str_h, cd->str_w};
    dnnl_dims_t dilates = {cd->dil_h - 1, cd->dil_w - 1};
    dnnl_dims_t padl = {cd->pad_h, cd->pad_w}, padr = {cd->pad_h, cd->pad_w};
    dnnl_memory_desc_t xmd = NULL, wmd = NULL, ymd = NULL;
    if (dnnl_memory_desc_create_with_tag(&xmd, 4, xdims, dt, tag_of(dxd->fmt)) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&wmd, 4, wdims, dt, dnnl_oihw) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&ymd, 4, ydims, dt, tag_of(dyd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t hint = NULL, pd = NULL;
    dnnl_status_t s = conv_fwd_hint(&hint, h->engine, xmd, wmd, ymd,
                                    strides, dilates, padl, padr);
    if (s == dnnl_success)
        s = dnnl_convolution_backward_data_primitive_desc_create(
            &pd, h->engine, dnnl_convolution_direct, xmd, wmd, ymd,
            strides, dilates, padl, padr, hint, NULL);
    if (hint) dnnl_primitive_desc_destroy(hint);
    dnnl_memory_desc_destroy(xmd);
    dnnl_memory_desc_destroy(wmd);
    dnnl_memory_desc_destroy(ymd);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t dxm = NULL, wm = NULL, dym = NULL;
    wrap(&dxm, h->engine, xdims, 4, dt, tag_of(dxd->fmt), dx);
    wrap(&wm, h->engine, wdims, 4, dt, dnnl_oihw, (void *)w);
    wrap(&dym, h->engine, ydims, 4, dt, tag_of(dyd->fmt), (void *)dy);
    dnnl_exec_arg_t args[] = {
        {DNNL_ARG_DIFF_DST, dym}, {DNNL_ARG_WEIGHTS, wm}, {DNNL_ARG_DIFF_SRC, dxm},
    };
    s = run_primitive(h, pd, args, 3);
    dnnl_memory_destroy(dxm); dnnl_memory_destroy(wm); dnnl_memory_destroy(dym);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnConvolutionBackwardFilter(
    cudnnHandle_t handle, const void *alpha,
    const cudnnTensorDescriptor_t xd, const void *x,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const cudnnConvolutionDescriptor_t cd, int algo,
    void *workspace, size_t workspace_bytes,
    const void *beta, const cudnnFilterDescriptor_t dwd, void *dw) {
    (void)algo; (void)workspace; (void)workspace_bytes;
    struct Handle *h = handle;
    if (!h || !xd || !dyd || !cd || !dwd) return CUDNN_STATUS_BAD_PARAM;
    ZDNN_PLAIN_SCALES(alpha, beta);
    if (cd->groups != 1 || cd->mode == CUDNN_CONVOLUTION)
        return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t xdims = {xd->n, xd->c, xd->h, xd->w};
    dnnl_dims_t wdims = {dwd->k, dwd->c, dwd->h, dwd->w};
    dnnl_dims_t ydims = {dyd->n, dyd->c, dyd->h, dyd->w};
    dnnl_dims_t strides = {cd->str_h, cd->str_w};
    dnnl_dims_t dilates = {cd->dil_h - 1, cd->dil_w - 1};
    dnnl_dims_t padl = {cd->pad_h, cd->pad_w}, padr = {cd->pad_h, cd->pad_w};
    dnnl_memory_desc_t xmd = NULL, wmd = NULL, ymd = NULL;
    if (dnnl_memory_desc_create_with_tag(&xmd, 4, xdims, dt, tag_of(xd->fmt)) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&wmd, 4, wdims, dt, dnnl_oihw) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&ymd, 4, ydims, dt, tag_of(dyd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t hint = NULL, pd = NULL;
    dnnl_status_t s = conv_fwd_hint(&hint, h->engine, xmd, wmd, ymd,
                                    strides, dilates, padl, padr);
    if (s == dnnl_success)
        s = dnnl_convolution_backward_weights_primitive_desc_create(
            &pd, h->engine, dnnl_convolution_direct, xmd, wmd, NULL, ymd,
            strides, dilates, padl, padr, hint, NULL);
    if (hint) dnnl_primitive_desc_destroy(hint);
    dnnl_memory_desc_destroy(xmd);
    dnnl_memory_desc_destroy(wmd);
    dnnl_memory_desc_destroy(ymd);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t xm = NULL, dwm = NULL, dym = NULL;
    wrap(&xm, h->engine, xdims, 4, dt, tag_of(xd->fmt), (void *)x);
    wrap(&dwm, h->engine, wdims, 4, dt, dnnl_oihw, dw);
    wrap(&dym, h->engine, ydims, 4, dt, tag_of(dyd->fmt), (void *)dy);
    dnnl_exec_arg_t args[] = {
        {DNNL_ARG_SRC, xm}, {DNNL_ARG_DIFF_DST, dym}, {DNNL_ARG_DIFF_WEIGHTS, dwm},
    };
    s = run_primitive(h, pd, args, 3);
    dnnl_memory_destroy(xm); dnnl_memory_destroy(dwm); dnnl_memory_destroy(dym);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnConvolutionBackwardBias(
    cudnnHandle_t handle, const void *alpha,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const void *beta, const cudnnTensorDescriptor_t dbd, void *db) {
    struct Handle *h = handle;
    if (!h || !dyd || !dbd) return CUDNN_STATUS_BAD_PARAM;
    ZDNN_PLAIN_SCALES(alpha, beta);
    if (dyd->dtype != CUDNN_DATA_FLOAT || dbd->dtype != CUDNN_DATA_FLOAT)
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (dyd->fmt != CUDNN_TENSOR_NCHW) return CUDNN_STATUS_NOT_SUPPORTED;
    const float *g = dy;
    float *out = db;
    const long hw = (long)dyd->h * dyd->w;
    for (int c = 0; c < dyd->c; c++) {
        float sum = 0.0f;
        for (int n = 0; n < dyd->n; n++) {
            const float *plane = g + ((long)n * dyd->c + c) * hw;
            for (long i = 0; i < hw; i++) sum += plane[i];
        }
        out[c] = sum;
    }
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnActivationBackward(
    cudnnHandle_t handle, const cudnnActivationDescriptor_t ad,
    const void *alpha,
    const cudnnTensorDescriptor_t yd, const void *y,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const cudnnTensorDescriptor_t xd, const void *x,
    const void *beta, const cudnnTensorDescriptor_t dxd, void *dx) {
    (void)yd; (void)y;
    struct Handle *h = handle;
    if (!h || !ad || !dyd || !xd || !dxd) return CUDNN_STATUS_BAD_PARAM;
    ZDNN_PLAIN_SCALES(alpha, beta);
    dnnl_alg_kind_t alg;
    float a = 0.0f, b = 0.0f;
    switch (ad->mode) {
    case CUDNN_ACTIVATION_RELU:    alg = dnnl_eltwise_relu; break;
    case CUDNN_ACTIVATION_TANH:    alg = dnnl_eltwise_tanh; break;
    case CUDNN_ACTIVATION_SIGMOID: alg = dnnl_eltwise_logistic; break;
    case CUDNN_ACTIVATION_ELU:     alg = dnnl_eltwise_elu; a = 1.0f; break;
    default: return CUDNN_STATUS_NOT_SUPPORTED;
    }
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t dims = {xd->n, xd->c, xd->h, xd->w};
    dnnl_memory_desc_t md = NULL;
    if (dnnl_memory_desc_create_with_tag(&md, 4, dims, dt, tag_of(xd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t hint = NULL, pd = NULL;
    dnnl_status_t s = dnnl_eltwise_forward_primitive_desc_create(
        &hint, h->engine, dnnl_forward_training, alg, md, md, a, b, NULL);
    if (s == dnnl_success)
        s = dnnl_eltwise_backward_primitive_desc_create(
            &pd, h->engine, alg, md, md, md, a, b, hint, NULL);
    if (hint) dnnl_primitive_desc_destroy(hint);
    dnnl_memory_desc_destroy(md);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t xm = NULL, dym = NULL, dxm = NULL;
    wrap(&xm, h->engine, dims, 4, dt, tag_of(xd->fmt), (void *)x);
    wrap(&dym, h->engine, dims, 4, dt, tag_of(dyd->fmt), (void *)dy);
    wrap(&dxm, h->engine, dims, 4, dt, tag_of(dxd->fmt), dx);
    dnnl_exec_arg_t args[] = {
        {DNNL_ARG_SRC, xm}, {DNNL_ARG_DIFF_DST, dym}, {DNNL_ARG_DIFF_SRC, dxm},
    };
    s = run_primitive(h, pd, args, 3);
    dnnl_memory_destroy(xm); dnnl_memory_destroy(dym); dnnl_memory_destroy(dxm);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnSoftmaxBackward(
    cudnnHandle_t handle, int algo, int mode, const void *alpha,
    const cudnnTensorDescriptor_t yd, const void *y,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const void *beta, const cudnnTensorDescriptor_t dxd, void *dx) {
    (void)algo;
    struct Handle *h = handle;
    if (!h || !yd || !dyd || !dxd) return CUDNN_STATUS_BAD_PARAM;
    ZDNN_PLAIN_SCALES(alpha, beta);
    if (mode != 1) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_data_type_t dt = dt_of(yd->dtype);
    dnnl_dims_t dims = {yd->n, yd->c, yd->h, yd->w};
    dnnl_memory_desc_t md = NULL;
    if (dnnl_memory_desc_create_with_tag(&md, 4, dims, dt, tag_of(yd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t hint = NULL, pd = NULL;
    dnnl_status_t s = dnnl_softmax_forward_primitive_desc_create(
        &hint, h->engine, dnnl_forward_training, dnnl_softmax_accurate, md, md, 1, NULL);
    if (s == dnnl_success)
        s = dnnl_softmax_backward_primitive_desc_create(
            &pd, h->engine, dnnl_softmax_accurate, md, md, md, 1, hint, NULL);
    if (hint) dnnl_primitive_desc_destroy(hint);
    dnnl_memory_desc_destroy(md);
    if (s != dnnl_success) return CUDNN_STATUS_NOT_SUPPORTED;
    dnnl_memory_t ym = NULL, dym = NULL, dxm = NULL;
    wrap(&ym, h->engine, dims, 4, dt, tag_of(yd->fmt), (void *)y);
    wrap(&dym, h->engine, dims, 4, dt, tag_of(dyd->fmt), (void *)dy);
    wrap(&dxm, h->engine, dims, 4, dt, tag_of(dxd->fmt), dx);
    dnnl_exec_arg_t args[] = {
        {DNNL_ARG_DST, ym}, {DNNL_ARG_DIFF_DST, dym}, {DNNL_ARG_DIFF_SRC, dxm},
    };
    s = run_primitive(h, pd, args, 3);
    dnnl_memory_destroy(ym); dnnl_memory_destroy(dym); dnnl_memory_destroy(dxm);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnPoolingBackward(
    cudnnHandle_t handle, const cudnnPoolingDescriptor_t pdsc, const void *alpha,
    const cudnnTensorDescriptor_t yd, const void *y,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const cudnnTensorDescriptor_t xd, const void *x,
    const void *beta, const cudnnTensorDescriptor_t dxd, void *dx) {
    (void)y;
    struct Handle *h = handle;
    if (!h || !pdsc || !yd || !dyd || !xd || !dxd) return CUDNN_STATUS_BAD_PARAM;
    ZDNN_PLAIN_SCALES(alpha, beta);
    dnnl_alg_kind_t alg;
    switch (pdsc->mode) {
    case CUDNN_POOLING_MAX: alg = dnnl_pooling_max; break;
    case CUDNN_POOLING_AVERAGE_COUNT_INCLUDE_PADDING:
        alg = dnnl_pooling_avg_include_padding; break;
    case CUDNN_POOLING_AVERAGE_COUNT_EXCLUDE_PADDING:
        alg = dnnl_pooling_avg_exclude_padding; break;
    default: return CUDNN_STATUS_NOT_SUPPORTED;
    }
    dnnl_data_type_t dt = dt_of(xd->dtype);
    dnnl_dims_t xdims = {xd->n, xd->c, xd->h, xd->w};
    dnnl_dims_t ydims = {yd->n, yd->c, yd->h, yd->w};
    dnnl_dims_t kernel = {pdsc->wh, pdsc->ww};
    dnnl_dims_t strides = {pdsc->str_h, pdsc->str_w};
    dnnl_dims_t dilation = {0, 0};
    dnnl_dims_t padl = {pdsc->pad_h, pdsc->pad_w}, padr = {pdsc->pad_h, pdsc->pad_w};
    dnnl_memory_desc_t xmd = NULL, ymd = NULL;
    if (dnnl_memory_desc_create_with_tag(&xmd, 4, xdims, dt, tag_of(xd->fmt)) != dnnl_success
     || dnnl_memory_desc_create_with_tag(&ymd, 4, ydims, dt, tag_of(yd->fmt)) != dnnl_success)
        return CUDNN_STATUS_EXECUTION_FAILED;
    dnnl_primitive_desc_t hint = NULL, pd = NULL;
    dnnl_status_t s = dnnl_pooling_forward_primitive_desc_create(
        &hint, h->engine, dnnl_forward_training, alg, xmd, ymd,
        strides, kernel, dilation, padl, padr, NULL);
    if (s == dnnl_success)
        s = dnnl_pooling_backward_primitive_desc_create(
            &pd, h->engine, alg, xmd, ymd, strides, kernel, dilation,
            padl, padr, hint, NULL);
    if (s != dnnl_success) {
        if (hint) dnnl_primitive_desc_destroy(hint);
        dnnl_memory_desc_destroy(xmd);
        dnnl_memory_desc_destroy(ymd);
        return CUDNN_STATUS_NOT_SUPPORTED;
    }
    dnnl_memory_t wsm = NULL;
    const_dnnl_memory_desc_t wsmd =
        dnnl_primitive_desc_query_md(hint, dnnl_query_workspace_md, 0);
    if (wsmd) {
        dnnl_memory_t xm = NULL, ym = NULL;
        void *ybuf = malloc(dnnl_memory_desc_get_size(ymd));
        if (!ybuf || dnnl_memory_create(&wsm, wsmd, h->engine, DNNL_MEMORY_ALLOCATE)
                     != dnnl_success) {
            free(ybuf);
            dnnl_primitive_desc_destroy(hint);
            dnnl_primitive_desc_destroy(pd);
            dnnl_memory_desc_destroy(xmd);
            dnnl_memory_desc_destroy(ymd);
            return CUDNN_STATUS_EXECUTION_FAILED;
        }
        wrap(&xm, h->engine, xdims, 4, dt, tag_of(xd->fmt), (void *)x);
        wrap(&ym, h->engine, ydims, 4, dt, tag_of(yd->fmt), ybuf);
        dnnl_exec_arg_t fargs[] = {
            {DNNL_ARG_SRC, xm}, {DNNL_ARG_DST, ym}, {DNNL_ARG_WORKSPACE, wsm},
        };
        dnnl_primitive_t fwd = NULL;
        if (dnnl_primitive_create(&fwd, hint) == dnnl_success) {
            dnnl_primitive_execute(fwd, h->stream, 3, fargs);
            dnnl_stream_wait(h->stream);
            dnnl_primitive_destroy(fwd);
        }
        dnnl_memory_destroy(xm); dnnl_memory_destroy(ym);
        free(ybuf);
    }
    dnnl_primitive_desc_destroy(hint);
    dnnl_memory_desc_destroy(xmd);
    dnnl_memory_desc_destroy(ymd);
    dnnl_memory_t dym = NULL, dxm = NULL;
    wrap(&dym, h->engine, ydims, 4, dt, tag_of(dyd->fmt), (void *)dy);
    wrap(&dxm, h->engine, xdims, 4, dt, tag_of(dxd->fmt), dx);
    dnnl_exec_arg_t args[3];
    int nargs = 0;
    args[nargs++] = (dnnl_exec_arg_t){DNNL_ARG_DIFF_DST, dym};
    args[nargs++] = (dnnl_exec_arg_t){DNNL_ARG_DIFF_SRC, dxm};
    if (wsm) args[nargs++] = (dnnl_exec_arg_t){DNNL_ARG_WORKSPACE, wsm};
    s = run_primitive(h, pd, args, nargs);
    dnnl_memory_destroy(dym); dnnl_memory_destroy(dxm);
    if (wsm) dnnl_memory_destroy(wsm);
    return s == dnnl_success ? CUDNN_STATUS_SUCCESS : CUDNN_STATUS_EXECUTION_FAILED;
}
cudnnStatus_t cudnnBatchNormalizationForwardTraining(
    cudnnHandle_t handle, int mode, const void *alpha, const void *beta,
    const cudnnTensorDescriptor_t xd, const void *x,
    const cudnnTensorDescriptor_t yd, void *y,
    const cudnnTensorDescriptor_t bnd, const void *scale, const void *bias,
    double exp_avg_factor, void *running_mean, void *running_var,
    double eps, void *saved_mean, void *saved_inv_var) {
    (void)bnd; (void)yd;
    if (!handle || !xd || !yd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha && *(const float *)alpha != 1.0f)
        || (beta && *(const float *)beta != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (xd->dtype != CUDNN_DATA_FLOAT) return CUDNN_STATUS_NOT_SUPPORTED;
    if (mode == 0) return CUDNN_STATUS_NOT_SUPPORTED;
    const float *s = scale, *b = bias, *in = x;
    float *out = y, *rm = running_mean, *rv = running_var;
    float *sm = saved_mean, *siv = saved_inv_var;
    const int hw = xd->h * xd->w;
    const double count = (double)xd->n * hw;
#define ZDNN_AT(n, c, i) (xd->fmt == CUDNN_TENSOR_NHWC                        \
        ? ((size_t)(n) * hw + (i)) * xd->c + (c)                              \
        : ((size_t)(n) * xd->c + (c)) * hw + (i))
    for (int c = 0; c < xd->c; c++) {
        double sum = 0.0, sumsq = 0.0;
        for (int n = 0; n < xd->n; n++)
            for (int i = 0; i < hw; i++) {
                double v = in[ZDNN_AT(n, c, i)];
                sum += v;
                sumsq += v * v;
            }
        double mean = sum / count;
        double var = sumsq / count - mean * mean;
        if (var < 0.0) var = 0.0;
        float inv = (float)(1.0 / sqrt(var + eps));
        if (sm) sm[c] = (float)mean;
        if (siv) siv[c] = inv;
        if (rm) rm[c] = (float)(rm[c] * (1.0 - exp_avg_factor) + mean * exp_avg_factor);
        if (rv) {
            double unbiased = count > 1.0 ? var * count / (count - 1.0) : var;
            rv[c] = (float)(rv[c] * (1.0 - exp_avg_factor) + unbiased * exp_avg_factor);
        }
        float k = s[c] * inv, off = b[c] - (float)mean * k;
        for (int n = 0; n < xd->n; n++)
            for (int i = 0; i < hw; i++) {
                size_t at = ZDNN_AT(n, c, i);
                out[at] = in[at] * k + off;
            }
    }
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnBatchNormalizationBackward(
    cudnnHandle_t handle, int mode,
    const void *alpha_data, const void *beta_data,
    const void *alpha_param, const void *beta_param,
    const cudnnTensorDescriptor_t xd, const void *x,
    const cudnnTensorDescriptor_t dyd, const void *dy,
    const cudnnTensorDescriptor_t dxd, void *dx,
    const cudnnTensorDescriptor_t bnd, const void *scale,
    void *dscale, void *dbias, double eps,
    const void *saved_mean, const void *saved_inv_var) {
    (void)bnd; (void)dyd; (void)dxd;
    if (!handle || !xd) return CUDNN_STATUS_BAD_PARAM;
    if ((alpha_data && *(const float *)alpha_data != 1.0f)
        || (beta_data && *(const float *)beta_data != 0.0f)
        || (alpha_param && *(const float *)alpha_param != 1.0f)
        || (beta_param && *(const float *)beta_param != 0.0f))
        return CUDNN_STATUS_NOT_SUPPORTED;
    if (xd->dtype != CUDNN_DATA_FLOAT) return CUDNN_STATUS_NOT_SUPPORTED;
    if (mode == 0) return CUDNN_STATUS_NOT_SUPPORTED;
    if (!saved_mean || !saved_inv_var) return CUDNN_STATUS_NOT_SUPPORTED;
    (void)eps;
    const float *in = x, *g = dy, *s = scale;
    const float *mean = saved_mean, *inv = saved_inv_var;
    float *dxo = dx, *ds = dscale, *db = dbias;
    const int hw = xd->h * xd->w;
    const float count = (float)((double)xd->n * hw);
    for (int c = 0; c < xd->c; c++) {
        double sum_dy = 0.0, sum_dy_xhat = 0.0;
        for (int n = 0; n < xd->n; n++)
            for (int i = 0; i < hw; i++) {
                size_t at = ZDNN_AT(n, c, i);
                double xhat = (in[at] - mean[c]) * inv[c];
                sum_dy += g[at];
                sum_dy_xhat += (double)g[at] * xhat;
            }
        if (db) db[c] = (float)sum_dy;
        if (ds) ds[c] = (float)sum_dy_xhat;
        if (!dxo) continue;
        for (int n = 0; n < xd->n; n++)
            for (int i = 0; i < hw; i++) {
                size_t at = ZDNN_AT(n, c, i);
                float xhat = (in[at] - mean[c]) * inv[c];
                dxo[at] = s[c] * inv[c]
                        * (g[at] - (float)sum_dy / count
                           - xhat * (float)sum_dy_xhat / count);
            }
    }
#undef ZDNN_AT
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetConvolutionBackwardDataAlgorithmMaxCount(
    cudnnHandle_t handle, int *count) {
    if (!handle || !count) return CUDNN_STATUS_BAD_PARAM;
    *count = 1;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetConvolutionBackwardFilterAlgorithmMaxCount(
    cudnnHandle_t handle, int *count) {
    return cudnnGetConvolutionBackwardDataAlgorithmMaxCount(handle, count);
}
cudnnStatus_t cudnnGetConvolutionBackwardDataWorkspaceSize(
    cudnnHandle_t handle, const cudnnFilterDescriptor_t wd,
    const cudnnTensorDescriptor_t dyd, const cudnnConvolutionDescriptor_t cd,
    const cudnnTensorDescriptor_t dxd, int algo, size_t *bytes) {
    (void)wd; (void)dyd; (void)cd; (void)dxd; (void)algo;
    if (!handle || !bytes) return CUDNN_STATUS_BAD_PARAM;
    *bytes = 0;
    return CUDNN_STATUS_SUCCESS;
}
cudnnStatus_t cudnnGetConvolutionBackwardFilterWorkspaceSize(
    cudnnHandle_t handle, const cudnnTensorDescriptor_t xd,
    const cudnnTensorDescriptor_t dyd, const cudnnConvolutionDescriptor_t cd,
    const cudnnFilterDescriptor_t dwd, int algo, size_t *bytes) {
    (void)xd; (void)dyd; (void)cd; (void)dwd; (void)algo;
    if (!handle || !bytes) return CUDNN_STATUS_BAD_PARAM;
    *bytes = 0;
    return CUDNN_STATUS_SUCCESS;
}
