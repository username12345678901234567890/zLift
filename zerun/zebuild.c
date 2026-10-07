#include <level_zero/ze_api.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define ZE(call)                                                               \
    do {                                                                       \
        ze_result_t _r = (call);                                               \
        if (_r != ZE_RESULT_SUCCESS) {                                         \
            fprintf(stderr, "%s:%d: %s -> 0x%x\n", __FILE__, __LINE__, #call,  \
                    (unsigned)_r);                                             \
            exit(2);                                                           \
        }                                                                      \
    } while (0)
int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <module.spv>\n", argv[0]);
        return 1;
    }
    FILE *f = fopen(argv[1], "rb");
    if (!f) {
        fprintf(stderr, "cannot open %s\n", argv[1]);
        return 2;
    }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *spv = malloc((size_t)n);
    if (fread(spv, 1, (size_t)n, f) != (size_t)n) {
        fprintf(stderr, "short read\n");
        return 2;
    }
    fclose(f);
    ZE(zeInit(0));
    uint32_t ndrv = 0;
    ZE(zeDriverGet(&ndrv, NULL));
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
    ze_module_desc_t mdesc = {ZE_STRUCTURE_TYPE_MODULE_DESC};
    mdesc.format = ZE_MODULE_FORMAT_IL_SPIRV;
    mdesc.inputSize = (size_t)n;
    mdesc.pInputModule = spv;
    const char *build_flags = getenv("ZERUN_BUILD_FLAGS");
    mdesc.pBuildFlags =
        build_flags ? build_flags : "-cl-fp32-correctly-rounded-divide-sqrt";
    ze_module_handle_t module;
    ze_module_build_log_handle_t blog = NULL;
    ze_result_t res = zeModuleCreate(ctx, device, &mdesc, &module, &blog);
    if (blog) {
        size_t len = 0;
        zeModuleBuildLogGetString(blog, &len, NULL);
        if (len > 1) {
            char *txt = malloc(len);
            zeModuleBuildLogGetString(blog, &len, txt);
            fprintf(stderr, "%s\n", txt);
            free(txt);
        }
        zeModuleBuildLogDestroy(blog);
    }
    if (res != ZE_RESULT_SUCCESS) {
        fprintf(stderr, "zeModuleCreate -> 0x%x\n", (unsigned)res);
        return 3;
    }
    uint32_t nk = 0;
    ZE(zeModuleGetKernelNames(module, &nk, NULL));
    const char **names = calloc(nk ? nk : 1, sizeof *names);
    ZE(zeModuleGetKernelNames(module, &nk, names));
    if (!nk) {
        fprintf(stderr, "module exposes no kernels\n");
        return 3;
    }
    for (uint32_t i = 0; i < nk; i++) {
        ze_kernel_desc_t kd = {ZE_STRUCTURE_TYPE_KERNEL_DESC};
        kd.pKernelName = names[i];
        ze_kernel_handle_t k;
        ze_result_t kr = zeKernelCreate(module, &kd, &k);
        if (kr != ZE_RESULT_SUCCESS) {
            fprintf(stderr, "zeKernelCreate('%s') -> 0x%x\n", names[i],
                    (unsigned)kr);
            return 3;
        }
        zeKernelDestroy(k);
    }
    printf("ok");
    for (uint32_t i = 0; i < nk; i++)
        printf(" %s", names[i]);
    printf("\n");
    return 0;
}
