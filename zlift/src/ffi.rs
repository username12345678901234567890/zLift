use std::ffi::{c_char, c_int, c_void, CStr, CString};
pub const RTLD_NOW: c_int = 2;
extern "C" {
    fn dlopen(filename: *const c_char, flags: c_int) -> *mut c_void;
    fn dlsym(handle: *mut c_void, symbol: *const c_char) -> *mut c_void;
    fn dlerror() -> *const c_char;
}
pub struct Library {
    handle: *mut c_void,
    pub path: String,
}
impl Library {
    pub fn open(paths: &[String]) -> Result<Library, String> {
        let mut last = String::from("no candidate paths");
        for p in paths {
            let Ok(c) = CString::new(p.as_str()) else { continue };
            let handle = unsafe { dlopen(c.as_ptr(), RTLD_NOW) };
            if !handle.is_null() {
                return Ok(Library { handle, path: p.clone() });
            }
            let err = unsafe { dlerror() };
            last = if err.is_null() {
                format!("{p}: could not be opened")
            } else {
                unsafe { CStr::from_ptr(err) }.to_string_lossy().into_owned()
            };
        }
        Err(last)
    }
    pub unsafe fn sym<T>(&self, name: &str) -> Option<T> {
        let c = CString::new(name).ok()?;
        let p = dlsym(self.handle, c.as_ptr());
        if p.is_null() {
            return None;
        }
        Some(std::mem::transmute_copy::<*mut c_void, T>(&p))
    }
}
pub type ZeHandle = *mut c_void;
pub const ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES: u32 = 0x3;
pub const ZE_STRUCTURE_TYPE_DEVICE_COMPUTE_PROPERTIES: u32 = 0x4;
pub const ZE_STRUCTURE_TYPE_DEVICE_MEMORY_PROPERTIES: u32 = 0x6;
pub const ZE_DEVICE_PROPERTY_FLAG_INTEGRATED: u32 = 1;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct ZeDeviceProperties {
    pub stype: u32,
    pub p_next: *const c_void,
    pub type_: u32,
    pub vendor_id: u32,
    pub device_id: u32,
    pub flags: u32,
    pub sub_device_id: u32,
    pub core_clock_rate: u32,
    pub max_mem_alloc_size: u64,
    pub max_hardware_contexts: u32,
    pub max_command_queue_priority: u32,
    pub num_threads_per_eu: u32,
    pub physical_eu_simd_width: u32,
    pub num_eus_per_sub_slice: u32,
    pub num_sub_slices_per_slice: u32,
    pub num_slices: u32,
    pub timer_resolution: u64,
    pub timestamp_valid_bits: u32,
    pub kernel_timestamp_valid_bits: u32,
    pub uuid: [u8; 16],
    pub name: [c_char; 256],
}
impl Default for ZeDeviceProperties {
    fn default() -> Self {
        let mut p: ZeDeviceProperties = unsafe { std::mem::zeroed() };
        p.stype = ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES;
        p
    }
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct ZeComputeProperties {
    pub stype: u32,
    pub p_next: *const c_void,
    pub max_total_group_size: u32,
    pub max_group_size_x: u32,
    pub max_group_size_y: u32,
    pub max_group_size_z: u32,
    pub max_group_count_x: u32,
    pub max_group_count_y: u32,
    pub max_group_count_z: u32,
    pub max_shared_local_memory: u32,
    pub num_sub_group_sizes: u32,
    pub sub_group_sizes: [u32; 8],
}
impl Default for ZeComputeProperties {
    fn default() -> Self {
        let mut p: ZeComputeProperties = unsafe { std::mem::zeroed() };
        p.stype = ZE_STRUCTURE_TYPE_DEVICE_COMPUTE_PROPERTIES;
        p
    }
}
#[repr(C)]
#[derive(Clone, Copy)]
pub struct ZeMemoryProperties {
    pub stype: u32,
    pub p_next: *const c_void,
    pub flags: u32,
    pub max_clock_rate: u32,
    pub max_bus_width: u32,
    pub total_size: u64,
    pub name: [c_char; 256],
}
impl Default for ZeMemoryProperties {
    fn default() -> Self {
        let mut p: ZeMemoryProperties = unsafe { std::mem::zeroed() };
        p.stype = ZE_STRUCTURE_TYPE_DEVICE_MEMORY_PROPERTIES;
        p
    }
}
pub fn cstr_name(raw: &[c_char]) -> String {
    let bytes: Vec<u8> = raw
        .iter()
        .take_while(|c| **c != 0)
        .map(|c| *c as u8)
        .collect();
    String::from_utf8_lossy(&bytes).into_owned()
}
