#include <level_zero/ze_api.h>
#include <stdio.h>
#include <stdlib.h>
#define ZE(c) do { ze_result_t r=(c); if(r){printf("%s -> 0x%x\n",#c,r);exit(2);} } while(0)
static void caps(const char *what, ze_memory_access_cap_flags_t f) {
    printf("  %-22s %s%s%s%s\n", what,
           (f & ZE_MEMORY_ACCESS_CAP_FLAG_RW) ? "rw " : "",
           (f & ZE_MEMORY_ACCESS_CAP_FLAG_ATOMIC) ? "atomic " : "",
           (f & ZE_MEMORY_ACCESS_CAP_FLAG_CONCURRENT) ? "concurrent " : "",
           f ? "" : "(none)");
}
int main(void) {
    ZE(zeInit(0));
    uint32_t nd = 0;
    ZE(zeDriverGet(&nd, NULL));
    ze_driver_handle_t *dr = calloc(nd, sizeof *dr);
    ZE(zeDriverGet(&nd, dr));
    for (uint32_t d = 0; d < nd; d++) {
        uint32_t n = 0;
        ZE(zeDeviceGet(dr[d], &n, NULL));
        ze_device_handle_t *devs = calloc(n, sizeof *devs);
        ZE(zeDeviceGet(dr[d], &n, devs));
        for (uint32_t i = 0; i < n; i++) {
            ze_device_properties_t p = {ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES};
            ZE(zeDeviceGetProperties(devs[i], &p));
            if (p.type != ZE_DEVICE_TYPE_GPU)
                continue;
            printf("device: %s\n", p.name);
            printf("  threads/EU %u, simd width %u\n", p.numThreadsPerEU,
                   p.physicalEUSimdWidth);
            ze_device_memory_access_properties_t m = {
                ZE_STRUCTURE_TYPE_DEVICE_MEMORY_ACCESS_PROPERTIES};
            ZE(zeDeviceGetMemoryAccessProperties(devs[i], &m));
            caps("host alloc", m.hostAllocCapabilities);
            caps("device alloc", m.deviceAllocCapabilities);
            caps("shared single-device", m.sharedSingleDeviceAllocCapabilities);
            caps("shared system", m.sharedSystemAllocCapabilities);
            ze_device_compute_properties_t c = {
                ZE_STRUCTURE_TYPE_DEVICE_COMPUTE_PROPERTIES};
            ZE(zeDeviceGetComputeProperties(devs[i], &c));
            printf("  sub-group sizes     ");
            for (uint32_t k = 0; k < c.numSubGroupSizes; k++)
                printf(" %u", c.subGroupSizes[k]);
            printf("\n  max group size       %u  (%u x %u x %u)\n",
                   c.maxTotalGroupSize, c.maxGroupSizeX,
                   c.maxGroupSizeY, c.maxGroupSizeZ);
            printf("  max shared local mem %u B\n", c.maxSharedLocalMemory);
        }
    }
    return 0;
}
