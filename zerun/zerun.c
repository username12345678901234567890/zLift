#include <level_zero/ze_api.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define ZE(call)                                                               \
    do {                                                                       \
        ze_result_t _r = (call);                                               \
        if (_r != ZE_RESULT_SUCCESS) {                                         \
            fprintf(stderr, "%s:%d: %s -> 0x%x\n", __FILE__, __LINE__, #call,  \
                    (unsigned)_r);                                             \
            exit(2);                                                           \
        }                                                                      \
    } while (0)
enum arg_kind { ARG_IN, ARG_OUT_I32, ARG_OUT_F32, ARG_SCALAR };
struct arg {
    enum arg_kind kind;
    void *dev;      
    size_t nelem;   
    int32_t scalar; 
};
static void *read_file(const char *path, size_t *len) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "cannot open %s\n", path);
        exit(2);
    }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    void *buf = malloc((size_t)n);
    if (fread(buf, 1, (size_t)n, f) != (size_t)n) {
        fprintf(stderr, "short read on %s\n", path);
        exit(2);
    }
    fclose(f);
    *len = (size_t)n;
    return buf;
}
static void fill_from_spec(const char *spec, size_t nelem, bool is_float,
                           void *host) {
    memset(host, 0, nelem * 4);
    const char *colon = strchr(spec, ':');
    if (!colon)
        return;
    const char *p = colon + 1;
    for (size_t i = 0; i < nelem && *p; i++) {
        if (is_float)
            ((float *)host)[i] = strtof(p, (char **)&p);
        else
            ((int32_t *)host)[i] = (int32_t)strtol(p, (char **)&p, 0);
        if (*p == ',')
            p++;
    }
}
int main(int argc, char **argv) {
    if (argc < 5) {
        fprintf(stderr,
                "usage: %s <module.spv> <kernel> <groups> <local> [specs...]\n",
                argv[0]);
        return 1;
    }
    const char *spv_path = argv[1];
    const char *kernel_name = argv[2];
    uint32_t groups = (uint32_t)strtoul(argv[3], NULL, 0);
    uint32_t local = (uint32_t)strtoul(argv[4], NULL, 0);
    ZE(zeInit(0));
    uint32_t ndrv = 0;
    ZE(zeDriverGet(&ndrv, NULL));
    if (!ndrv) {
        fprintf(stderr, "no Level Zero drivers\n");
        return 2;
    }
    ze_driver_handle_t *drivers = calloc(ndrv, sizeof *drivers);
    ZE(zeDriverGet(&ndrv, drivers));
    ze_driver_handle_t driver = NULL;
    ze_device_handle_t device = NULL;
    for (uint32_t d = 0; d < ndrv && !device; d++) {
        uint32_t ndev = 0;
        ZE(zeDeviceGet(drivers[d], &ndev, NULL));
        ze_device_handle_t *devs = calloc(ndev, sizeof *devs);
        ZE(zeDeviceGet(drivers[d], &ndev, devs));
        for (uint32_t i = 0; i < ndev; i++) {
            ze_device_properties_t p = {ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES};
            ZE(zeDeviceGetProperties(devs[i], &p));
            if (p.type == ZE_DEVICE_TYPE_GPU) {
                driver = drivers[d];
                device = devs[i];
                fprintf(stderr, "[zerun] device: %s\n", p.name);
                break;
            }
        }
        free(devs);
    }
    if (!device) {
        fprintf(stderr, "no GPU device\n");
        return 2;
    }
    ze_context_desc_t cdesc = {ZE_STRUCTURE_TYPE_CONTEXT_DESC};
    ze_context_handle_t ctx;
    ZE(zeContextCreate(driver, &cdesc, &ctx));
    size_t spv_len = 0;
    void *spv = read_file(spv_path, &spv_len);
    ze_module_desc_t mdesc = {ZE_STRUCTURE_TYPE_MODULE_DESC};
    mdesc.format = ZE_MODULE_FORMAT_IL_SPIRV;
    mdesc.inputSize = spv_len;
    mdesc.pInputModule = (const uint8_t *)spv;
    const char *build_flags = getenv("ZERUN_BUILD_FLAGS");
    mdesc.pBuildFlags =
        build_flags ? build_flags : "-cl-fp32-correctly-rounded-divide-sqrt";
    ze_module_handle_t module;
    ze_module_build_log_handle_t blog = NULL;
    ze_result_t mres = zeModuleCreate(ctx, device, &mdesc, &module, &blog);
    if (blog) {
        size_t n = 0;
        zeModuleBuildLogGetString(blog, &n, NULL);
        if (n > 1) {
            char *txt = malloc(n);
            zeModuleBuildLogGetString(blog, &n, txt);
            fprintf(stderr, "[zerun] build log:\n%s\n", txt);
            free(txt);
        }
        zeModuleBuildLogDestroy(blog);
    }
    if (mres != ZE_RESULT_SUCCESS) {
        fprintf(stderr, "[zerun] zeModuleCreate failed: 0x%x\n",
                (unsigned)mres);
        return 3;
    }
    ze_kernel_desc_t kdesc = {ZE_STRUCTURE_TYPE_KERNEL_DESC};
    kdesc.pKernelName = kernel_name;
    ze_kernel_handle_t kernel;
    ZE(zeKernelCreate(module, &kdesc, &kernel));
    int nargs = argc - 5;
    struct arg *args = calloc((size_t)(nargs > 0 ? nargs : 1), sizeof *args);
    ze_device_mem_alloc_desc_t mem = {ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC};
    ze_host_mem_alloc_desc_t hmem = {ZE_STRUCTURE_TYPE_HOST_MEM_ALLOC_DESC};
    for (int i = 0; i < nargs; i++) {
        const char *spec = argv[5 + i];
        char tag = spec[0];
        size_t n = (size_t)strtoul(spec + 1, NULL, 10);
        struct arg *a = &args[i];
        bool by_address = strchr(spec, '@') != NULL;
        if (tag == 's') {
            a->kind = ARG_SCALAR;
            a->scalar = (int32_t)strtol(spec + 1, NULL, 0);
            ZE(zeKernelSetArgumentValue(kernel, (uint32_t)i, sizeof(int32_t),
                                        &a->scalar));
            continue;
        }
        a->nelem = n;
        size_t bytes = n * 4;
        ZE(zeMemAllocShared(ctx, &mem, &hmem, bytes, 64, device, &a->dev));
        if (tag == 'i' || tag == 'f') {
            a->kind = ARG_IN;
            fill_from_spec(spec, n, tag == 'f', a->dev);
        } else if (tag == 'o') {
            a->kind = ARG_OUT_I32;
            memset(a->dev, 0, bytes);
        } else if (tag == 'g') {
            a->kind = ARG_OUT_F32;
            memset(a->dev, 0, bytes);
        } else {
            fprintf(stderr, "bad spec '%s'\n", spec);
            return 1;
        }
        if (by_address) {
            uint64_t addr = (uint64_t)(uintptr_t)a->dev;
            ZE(zeKernelSetArgumentValue(kernel, (uint32_t)i, sizeof(uint64_t),
                                        &addr));
        } else {
            ZE(zeKernelSetArgumentValue(kernel, (uint32_t)i, sizeof(void *),
                                        &a->dev));
        }
    }
    ZE(zeKernelSetIndirectAccess(kernel,
                                 ZE_KERNEL_INDIRECT_ACCESS_FLAG_HOST |
                                     ZE_KERNEL_INDIRECT_ACCESS_FLAG_DEVICE |
                                     ZE_KERNEL_INDIRECT_ACCESS_FLAG_SHARED));
    ZE(zeKernelSetGroupSize(kernel, local, 1, 1));
    ze_command_queue_desc_t qdesc = {ZE_STRUCTURE_TYPE_COMMAND_QUEUE_DESC};
    qdesc.mode = ZE_COMMAND_QUEUE_MODE_SYNCHRONOUS;
    ze_command_list_handle_t list;
    ZE(zeCommandListCreateImmediate(ctx, device, &qdesc, &list));
    ze_group_count_t grp = {groups, 1, 1};
    ZE(zeCommandListAppendLaunchKernel(list, kernel, &grp, NULL, 0, NULL));
    ZE(zeCommandListHostSynchronize(list, UINT64_MAX));
    for (int i = 0; i < nargs; i++) {
        struct arg *a = &args[i];
        if (a->kind != ARG_OUT_I32 && a->kind != ARG_OUT_F32)
            continue;
        printf("arg%d:", i);
        for (size_t j = 0; j < a->nelem; j++) {
            if (a->kind == ARG_OUT_I32)
                printf(" %d", ((int32_t *)a->dev)[j]);
            else
                printf(" %g", ((float *)a->dev)[j]);
        }
        printf("\n");
    }
    return 0;
}
