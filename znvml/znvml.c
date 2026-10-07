#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef int nvmlReturn_t;
enum {
    NVML_SUCCESS = 0,
    NVML_ERROR_UNINITIALIZED = 1,
    NVML_ERROR_INVALID_ARGUMENT = 2,
    NVML_ERROR_NOT_SUPPORTED = 3,
    NVML_ERROR_NOT_FOUND = 6,
    NVML_ERROR_INSUFFICIENT_SIZE = 7,
    NVML_ERROR_DRIVER_NOT_LOADED = 9,
    NVML_ERROR_FUNCTION_NOT_FOUND = 13,
    NVML_ERROR_UNKNOWN = 999,
};
enum { ZNVML_MAX_DEVICES = 32 };
typedef struct { int index; } *nvmlDevice_t;
static struct { int index; } g_devices[ZNVML_MAX_DEVICES];
typedef struct { unsigned long long total, free, used; } nvmlMemory_t;
typedef struct {
    unsigned int version;
    unsigned long long total, reserved, free, used;
} nvmlMemory_v2_t;
typedef struct { unsigned int gpu, memory; } nvmlUtilization_t;
typedef struct {
    char busIdLegacy[16];
    unsigned int domain, bus, device;
    unsigned int pciDeviceId, pciSubSystemId;
    char busId[32];
} nvmlPciInfo_t;
static void *g_cuda;
static int g_ready;
static int g_count;
static int (*p_cuInit)(unsigned);
static int (*p_cuDeviceGetCount)(int *);
static int (*p_cuDeviceGet)(int *, int);
static int (*p_cuDeviceGetName)(char *, int, int);
static int (*p_cuDeviceTotalMem)(size_t *, int);
static int (*p_cuDeviceGetAttribute)(int *, int, int);
static int (*p_cuDeviceGetUuid)(void *, int);
static int (*p_cuDeviceGetPCIBusId)(char *, int, int);
static int (*p_cuDeviceComputeCapability)(int *, int *, int);
static int (*p_cuDriverGetVersion)(int *);
static int (*p_cuMemGetInfo)(size_t *, size_t *);
#define BIND(name, into) (into = dlsym(g_cuda, name))
static int load_driver(void) {
    if (g_ready) return 1;
    const char *names[] = {"libcuda.so.1", "libcuda.so", NULL};
    for (int i = 0; names[i] && !g_cuda; i++)
        g_cuda = dlopen(names[i], RTLD_NOW | RTLD_GLOBAL);
    if (!g_cuda) return 0;
    BIND("cuInit", p_cuInit);
    BIND("cuDeviceGetCount", p_cuDeviceGetCount);
    BIND("cuDeviceGet", p_cuDeviceGet);
    BIND("cuDeviceGetName", p_cuDeviceGetName);
    BIND("cuDeviceTotalMem_v2", p_cuDeviceTotalMem);
    BIND("cuDeviceGetAttribute", p_cuDeviceGetAttribute);
    BIND("cuDeviceGetUuid", p_cuDeviceGetUuid);
    BIND("cuDeviceGetPCIBusId", p_cuDeviceGetPCIBusId);
    BIND("cuDeviceComputeCapability", p_cuDeviceComputeCapability);
    BIND("cuDriverGetVersion", p_cuDriverGetVersion);
    BIND("cuMemGetInfo_v2", p_cuMemGetInfo);
    if (!p_cuInit || !p_cuDeviceGetCount) return 0;
    if (p_cuInit(0) != 0) return 0;
    if (p_cuDeviceGetCount(&g_count) != 0) return 0;
    if (g_count > ZNVML_MAX_DEVICES) g_count = ZNVML_MAX_DEVICES;
    for (int i = 0; i < g_count; i++) g_devices[i].index = i;
    g_ready = 1;
    return 1;
}
static nvmlReturn_t need_init(void) {
    return g_ready ? NVML_SUCCESS : NVML_ERROR_UNINITIALIZED;
}
static int index_of(nvmlDevice_t d) {
    if (!d) return -1;
    for (int i = 0; i < g_count; i++)
        if (d == (nvmlDevice_t)&g_devices[i]) return i;
    return -1;
}
static nvmlReturn_t put(const char *src, char *dst, unsigned len) {
    if (!dst) return NVML_ERROR_INVALID_ARGUMENT;
    size_t n = strlen(src);
    if (n + 1 > len) return NVML_ERROR_INSUFFICIENT_SIZE;
    memcpy(dst, src, n + 1);
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlInit_v2(void) {
    return load_driver() ? NVML_SUCCESS : NVML_ERROR_DRIVER_NOT_LOADED;
}
nvmlReturn_t nvmlInit(void) { return nvmlInit_v2(); }
nvmlReturn_t nvmlInitWithFlags(unsigned flags) { (void)flags; return nvmlInit_v2(); }
nvmlReturn_t nvmlShutdown(void) { return NVML_SUCCESS; }
const char *nvmlErrorString(nvmlReturn_t r) {
    switch (r) {
    case NVML_SUCCESS: return "The operation was successful";
    case NVML_ERROR_UNINITIALIZED: return "NVML was not first initialized with nvmlInit()";
    case NVML_ERROR_INVALID_ARGUMENT: return "Invalid argument";
    case NVML_ERROR_NOT_SUPPORTED: return "Not supported on this device";
    case NVML_ERROR_NOT_FOUND: return "A query to find an object was unsuccessful";
    case NVML_ERROR_INSUFFICIENT_SIZE: return "An input argument is not large enough";
    case NVML_ERROR_DRIVER_NOT_LOADED: return "The driver is not loaded";
    case NVML_ERROR_FUNCTION_NOT_FOUND: return "Function not found";
    default: return "An internal driver error occurred";
    }
}
nvmlReturn_t nvmlSystemGetDriverVersion(char *out, unsigned len) {
    if (!load_driver()) return NVML_ERROR_DRIVER_NOT_LOADED;
    int v = 0;
    if (p_cuDriverGetVersion) p_cuDriverGetVersion(&v);
    char buf[64];
    snprintf(buf, sizeof buf, "%d.%02d.%02d", v / 1000, (v % 1000) / 10, v % 10);
    return put(buf, out, len);
}
nvmlReturn_t nvmlSystemGetNVMLVersion(char *out, unsigned len) {
    return put("13.0.0", out, len);
}
nvmlReturn_t nvmlSystemGetCudaDriverVersion(int *v) {
    if (!v) return NVML_ERROR_INVALID_ARGUMENT;
    if (!load_driver()) return NVML_ERROR_DRIVER_NOT_LOADED;
    *v = 0;
    if (p_cuDriverGetVersion) p_cuDriverGetVersion(v);
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlSystemGetCudaDriverVersion_v2(int *v) {
    return nvmlSystemGetCudaDriverVersion(v);
}
nvmlReturn_t nvmlDeviceGetCount_v2(unsigned *n) {
    if (!n) return NVML_ERROR_INVALID_ARGUMENT;
    if (!load_driver()) return NVML_ERROR_DRIVER_NOT_LOADED;
    *n = (unsigned)g_count;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetCount(unsigned *n) { return nvmlDeviceGetCount_v2(n); }
nvmlReturn_t nvmlDeviceGetPciInfo_v3(nvmlDevice_t d, nvmlPciInfo_t *p);
nvmlReturn_t nvmlDeviceGetHandleByIndex_v2(unsigned i, nvmlDevice_t *out) {
    if (!out) return NVML_ERROR_INVALID_ARGUMENT;
    if (!load_driver()) return NVML_ERROR_DRIVER_NOT_LOADED;
    if ((int)i >= g_count) return NVML_ERROR_INVALID_ARGUMENT;
    *out = (nvmlDevice_t)&g_devices[i];
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetHandleByIndex(unsigned i, nvmlDevice_t *out) {
    return nvmlDeviceGetHandleByIndex_v2(i, out);
}
nvmlReturn_t nvmlDeviceGetHandleByPciBusId_v2(const char *busId, nvmlDevice_t *out) {
    if (!busId || !out) return NVML_ERROR_INVALID_ARGUMENT;
    if (!load_driver()) return NVML_ERROR_DRIVER_NOT_LOADED;
    unsigned wb = 0, wd = 0, wf = 0;
    if (sscanf(busId, "%*x:%x:%x.%x", &wb, &wd, &wf) != 3 &&
        sscanf(busId, "%x:%x.%x", &wb, &wd, &wf) != 3) {
        return NVML_ERROR_INVALID_ARGUMENT;
    }
    for (int i = 0; i < g_count; i++) {
        nvmlPciInfo_t p;
        if (nvmlDeviceGetPciInfo_v3((nvmlDevice_t)&g_devices[i], &p) != NVML_SUCCESS) {
            continue;
        }
        unsigned b = 0, d2 = 0, f = 0;
        if (sscanf(p.busId, "%*x:%x:%x.%x", &b, &d2, &f) != 3) continue;
        if (b == wb && d2 == wd && f == wf) {
            *out = (nvmlDevice_t)&g_devices[i];
            return NVML_SUCCESS;
        }
    }
    return NVML_ERROR_NOT_FOUND;
}
nvmlReturn_t nvmlDeviceGetHandleByPciBusId(const char *busId, nvmlDevice_t *out) {
    return nvmlDeviceGetHandleByPciBusId_v2(busId, out);
}
nvmlReturn_t nvmlDeviceGetNvLinkRemoteDeviceType(nvmlDevice_t d, unsigned link,
                                                 int *out) {
    (void)link;
    if (index_of(d) < 0 || !out) return NVML_ERROR_INVALID_ARGUMENT;
    return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetNvLinkState(nvmlDevice_t d, unsigned link, unsigned *out) {
    (void)link;
    if (index_of(d) < 0 || !out) return NVML_ERROR_INVALID_ARGUMENT;
    *out = 0;                      
    return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetNvLinkRemotePciInfo_v2(nvmlDevice_t d, unsigned link,
                                                 nvmlPciInfo_t *p) {
    (void)link; (void)p;
    if (index_of(d) < 0) return NVML_ERROR_INVALID_ARGUMENT;
    return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetIndex(nvmlDevice_t d, unsigned *out) {
    int i = index_of(d);
    if (i < 0 || !out) return NVML_ERROR_INVALID_ARGUMENT;
    *out = (unsigned)i;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetName(nvmlDevice_t d, char *out, unsigned len) {
    int i = index_of(d);
    if (i < 0) return need_init() ? need_init() : NVML_ERROR_INVALID_ARGUMENT;
    char buf[256] = {0};
    int dev = 0;
    if (!p_cuDeviceGet || p_cuDeviceGet(&dev, i) != 0) return NVML_ERROR_UNKNOWN;
    if (!p_cuDeviceGetName || p_cuDeviceGetName(buf, sizeof buf, dev) != 0)
        return NVML_ERROR_UNKNOWN;
    return put(buf, out, len);
}
nvmlReturn_t nvmlDeviceGetUUID(nvmlDevice_t d, char *out, unsigned len) {
    int i = index_of(d);
    if (i < 0) return NVML_ERROR_INVALID_ARGUMENT;
    unsigned char u[16] = {0};
    int dev = 0;
    if (p_cuDeviceGet) p_cuDeviceGet(&dev, i);
    if (p_cuDeviceGetUuid) p_cuDeviceGetUuid(u, dev);
    char buf[64];
    snprintf(buf, sizeof buf,
             "GPU-%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
             u[0], u[1], u[2], u[3], u[4], u[5], u[6], u[7],
             u[8], u[9], u[10], u[11], u[12], u[13], u[14], u[15]);
    return put(buf, out, len);
}
nvmlReturn_t nvmlDeviceGetSerial(nvmlDevice_t d, char *out, unsigned len) {
    (void)d; (void)out; (void)len;
    return NVML_ERROR_NOT_SUPPORTED;
}
static nvmlReturn_t memory_of(int i, unsigned long long *total,
                              unsigned long long *freeb) {
    int dev = 0;
    size_t t = 0;
    if (!p_cuDeviceGet || p_cuDeviceGet(&dev, i) != 0) return NVML_ERROR_UNKNOWN;
    if (!p_cuDeviceTotalMem || p_cuDeviceTotalMem(&t, dev) != 0) return NVML_ERROR_UNKNOWN;
    *total = t;
    size_t f = 0, tt = 0;
    if (p_cuMemGetInfo && p_cuMemGetInfo(&f, &tt) == 0 && f > 0) {
        *freeb = f;
    } else {
        *freeb = t;
    }
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetMemoryInfo(nvmlDevice_t d, nvmlMemory_t *m) {
    int i = index_of(d);
    if (i < 0 || !m) return NVML_ERROR_INVALID_ARGUMENT;
    unsigned long long total = 0, freeb = 0;
    nvmlReturn_t r = memory_of(i, &total, &freeb);
    if (r != NVML_SUCCESS) return r;
    m->total = total;
    m->free = freeb;
    m->used = total > freeb ? total - freeb : 0;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetMemoryInfo_v2(nvmlDevice_t d, nvmlMemory_v2_t *m) {
    int i = index_of(d);
    if (i < 0 || !m) return NVML_ERROR_INVALID_ARGUMENT;
    unsigned long long total = 0, freeb = 0;
    nvmlReturn_t r = memory_of(i, &total, &freeb);
    if (r != NVML_SUCCESS) return r;
    m->total = total;
    m->reserved = 0;
    m->free = freeb;
    m->used = total > freeb ? total - freeb : 0;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetPciInfo_v3(nvmlDevice_t d, nvmlPciInfo_t *p) {
    int i = index_of(d);
    if (i < 0 || !p) return NVML_ERROR_INVALID_ARGUMENT;
    memset(p, 0, sizeof *p);
    int dev = 0;
    char bus[32] = "0000:00:00.0";
    if (p_cuDeviceGet) p_cuDeviceGet(&dev, i);
    if (p_cuDeviceGetPCIBusId) p_cuDeviceGetPCIBusId(bus, sizeof bus, dev);
    snprintf(p->busId, sizeof p->busId, "%s", bus);
    const char *legacy = strlen(bus) > 5 ? bus + 5 : bus;
    strncpy(p->busIdLegacy, legacy, sizeof p->busIdLegacy - 1);
    p->busIdLegacy[sizeof p->busIdLegacy - 1] = 0;
    unsigned domain = 0, b = 0, dv = 0;
    sscanf(bus, "%x:%x:%x", &domain, &b, &dv);
    p->domain = domain;
    p->bus = b;
    p->device = dv;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetPciInfo_v2(nvmlDevice_t d, nvmlPciInfo_t *p) {
    return nvmlDeviceGetPciInfo_v3(d, p);
}
nvmlReturn_t nvmlDeviceGetPciInfo(nvmlDevice_t d, nvmlPciInfo_t *p) {
    return nvmlDeviceGetPciInfo_v3(d, p);
}
nvmlReturn_t nvmlDeviceGetCudaComputeCapability(nvmlDevice_t d, int *major, int *minor) {
    int i = index_of(d);
    if (i < 0 || !major || !minor) return NVML_ERROR_INVALID_ARGUMENT;
    int dev = 0;
    if (p_cuDeviceGet) p_cuDeviceGet(&dev, i);
    if (!p_cuDeviceComputeCapability
        || p_cuDeviceComputeCapability(major, minor, dev) != 0)
        return NVML_ERROR_NOT_SUPPORTED;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetUtilizationRates(nvmlDevice_t d, nvmlUtilization_t *u) {
    (void)d; (void)u; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetTemperature(nvmlDevice_t d, int s, unsigned *t) {
    (void)d; (void)s; (void)t; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetPowerUsage(nvmlDevice_t d, unsigned *w) {
    (void)d; (void)w; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetEnforcedPowerLimit(nvmlDevice_t d, unsigned *w) {
    (void)d; (void)w; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetClockInfo(nvmlDevice_t d, int t, unsigned *c) {
    (void)d; (void)t; (void)c; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetMaxClockInfo(nvmlDevice_t d, int t, unsigned *c) {
    (void)d; (void)t; (void)c; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetFanSpeed(nvmlDevice_t d, unsigned *s) {
    (void)d; (void)s; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetTotalEnergyConsumption(nvmlDevice_t d, unsigned long long *e) {
    (void)d; (void)e; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetEccMode(nvmlDevice_t d, int *cur, int *pend) {
    (void)d; (void)cur; (void)pend; return NVML_ERROR_NOT_SUPPORTED;
}
nvmlReturn_t nvmlDeviceGetMinorNumber(nvmlDevice_t d, unsigned *n) {
    int i = index_of(d);
    if (i < 0 || !n) return NVML_ERROR_INVALID_ARGUMENT;
    *n = (unsigned)i;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetPersistenceMode(nvmlDevice_t d, int *mode) {
    (void)d;
    if (!mode) return NVML_ERROR_INVALID_ARGUMENT;
    *mode = 0;               
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetComputeMode(nvmlDevice_t d, int *mode) {
    (void)d;
    if (!mode) return NVML_ERROR_INVALID_ARGUMENT;
    *mode = 0;               
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetDisplayMode(nvmlDevice_t d, int *mode) {
    (void)d;
    if (!mode) return NVML_ERROR_INVALID_ARGUMENT;
    *mode = 0;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetDisplayActive(nvmlDevice_t d, int *mode) {
    return nvmlDeviceGetDisplayMode(d, mode);
}
nvmlReturn_t nvmlDeviceGetMultiGpuBoard(nvmlDevice_t d, unsigned *on) {
    (void)d;
    if (!on) return NVML_ERROR_INVALID_ARGUMENT;
    *on = 0;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetBrand(nvmlDevice_t d, int *brand) {
    (void)d;
    if (!brand) return NVML_ERROR_INVALID_ARGUMENT;
    *brand = 0;              
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetArchitecture(nvmlDevice_t d, unsigned *arch) {
    (void)d;
    if (!arch) return NVML_ERROR_INVALID_ARGUMENT;
    *arch = 0xffffffff;      
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetComputeRunningProcesses_v3(nvmlDevice_t d, unsigned *n, void *p) {
    (void)d; (void)p;
    if (!n) return NVML_ERROR_INVALID_ARGUMENT;
    *n = 0;
    return NVML_SUCCESS;
}
nvmlReturn_t nvmlDeviceGetComputeRunningProcesses_v2(nvmlDevice_t d, unsigned *n, void *p) {
    return nvmlDeviceGetComputeRunningProcesses_v3(d, n, p);
}
nvmlReturn_t nvmlDeviceGetComputeRunningProcesses(nvmlDevice_t d, unsigned *n, void *p) {
    return nvmlDeviceGetComputeRunningProcesses_v3(d, n, p);
}
nvmlReturn_t nvmlDeviceGetGraphicsRunningProcesses_v3(nvmlDevice_t d, unsigned *n, void *p) {
    return nvmlDeviceGetComputeRunningProcesses_v3(d, n, p);
}
nvmlReturn_t nvmlDeviceGetGraphicsRunningProcesses(nvmlDevice_t d, unsigned *n, void *p) {
    return nvmlDeviceGetComputeRunningProcesses_v3(d, n, p);
}
