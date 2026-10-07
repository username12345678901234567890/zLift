use crate::ffi::*;
use std::ffi::{c_char, c_int, c_uint};
pub struct Device {
    pub uuid: [u8; 16],
    pub path: String,
    pub name: String,
    pub integrated: bool,
    pub memory_bytes: u64,
    pub sub_group_sizes: Vec<u32>,
    pub simd_width: u32,
    pub eus: u32,
    pub max_group_size: u32,
    pub slm_bytes: u32,
    pub children: Vec<Device>,
}
impl Device {
    pub fn memory_gib(&self) -> f64 {
        self.memory_bytes as f64 / (1024.0 * 1024.0 * 1024.0)
    }
}
pub struct CudaDevice {
    pub name: String,
    pub capability: (i32, i32),
    pub pci_bus_id: String,
    pub total_bytes: u64,
}
pub struct Machine {
    pub devices: Vec<Device>,
    pub cuda: Result<(Vec<CudaDevice>, i32), String>,
    pub level_zero: Result<String, String>,
}
type ZeInit = unsafe extern "C" fn(u32) -> u32;
type ZeDriverGet = unsafe extern "C" fn(*mut u32, *mut ZeHandle) -> u32;
type ZeDeviceGet = unsafe extern "C" fn(ZeHandle, *mut u32, *mut ZeHandle) -> u32;
type ZeDeviceGetSub = unsafe extern "C" fn(ZeHandle, *mut u32, *mut ZeHandle) -> u32;
type ZeDeviceProps = unsafe extern "C" fn(ZeHandle, *mut ZeDeviceProperties) -> u32;
type ZeComputeProps = unsafe extern "C" fn(ZeHandle, *mut ZeComputeProperties) -> u32;
type ZeMemProps = unsafe extern "C" fn(ZeHandle, *mut u32, *mut ZeMemoryProperties) -> u32;
fn ze_paths() -> Vec<String> {
    vec![
        "libze_loader.so.1".to_string(),
        "libze_loader.so".to_string(),
        "/usr/lib/x86_64-linux-gnu/libze_loader.so.1".to_string(),
    ]
}
pub fn driver_paths(root: &std::path::Path) -> Vec<String> {
    let mut v = vec![];
    if let Ok(p) = std::env::var("ZLIFT_DRIVER") {
        v.push(p);
    }
    v.push(
        root.join("ZLUDA/target/release/libzluda_ze.so")
            .to_string_lossy()
            .into_owned(),
    );
    v.push("libzluda_ze.so".to_string());
    v
}
unsafe fn describe(
    lib: &Library,
    handle: ZeHandle,
    path: String,
    recurse: bool,
) -> Option<Device> {
    let get_props: ZeDeviceProps = lib.sym("zeDeviceGetProperties")?;
    let get_compute: Option<ZeComputeProps> = lib.sym("zeDeviceGetComputeProperties");
    let get_mem: Option<ZeMemProps> = lib.sym("zeDeviceGetMemoryProperties");
    let mut props = ZeDeviceProperties::default();
    if get_props(handle, &mut props) != 0 {
        return None;
    }
    let mut compute = ZeComputeProperties::default();
    let have_compute = matches!(get_compute, Some(f) if f(handle, &mut compute) == 0);
    let mut memory_bytes = 0u64;
    if let Some(f) = get_mem {
        let mut n: u32 = 0;
        if f(handle, &mut n, std::ptr::null_mut()) == 0 && n > 0 {
            let mut mems = vec![ZeMemoryProperties::default(); n as usize];
            if f(handle, &mut n, mems.as_mut_ptr()) == 0 {
                memory_bytes = mems.iter().take(n as usize).map(|m| m.total_size).sum();
            }
        }
    }
    let mut children = vec![];
    if recurse {
        if let Some(get_sub) = lib.sym::<ZeDeviceGetSub>("zeDeviceGetSubDevices") {
            let mut n: u32 = 0;
            if get_sub(handle, &mut n, std::ptr::null_mut()) == 0 && n > 0 {
                let mut subs = vec![std::ptr::null_mut(); n as usize];
                if get_sub(handle, &mut n, subs.as_mut_ptr()) == 0 {
                    for (i, s) in subs.iter().take(n as usize).enumerate() {
                        if let Some(d) = describe(lib, *s, format!("{path}.{i}"), false) {
                            children.push(d);
                        }
                    }
                }
            }
        }
    }
    Some(Device {
        path,
        uuid: props.uuid,
        name: cstr_name(&props.name),
        integrated: props.flags & ZE_DEVICE_PROPERTY_FLAG_INTEGRATED != 0,
        memory_bytes,
        sub_group_sizes: if have_compute {
            compute.sub_group_sizes[..(compute.num_sub_group_sizes as usize).min(8)].to_vec()
        } else {
            vec![]
        },
        simd_width: props.physical_eu_simd_width,
        eus: props.num_slices * props.num_sub_slices_per_slice * props.num_eus_per_sub_slice,
        max_group_size: if have_compute { compute.max_total_group_size } else { 0 },
        slm_bytes: if have_compute { compute.max_shared_local_memory } else { 0 },
        children,
    })
}
fn enumerate_level_zero() -> (Vec<Device>, Result<String, String>) {
    let lib = match Library::open(&ze_paths()) {
        Ok(l) => l,
        Err(e) => return (vec![], Err(e)),
    };
    let path = lib.path.clone();
    unsafe {
        let Some(init) = lib.sym::<ZeInit>("zeInit") else {
            return (vec![], Err(format!("{path}: no zeInit")));
        };
        if init(0) != 0 {
            return (vec![], Err(format!("{path}: zeInit failed")));
        }
        let Some(driver_get) = lib.sym::<ZeDriverGet>("zeDriverGet") else {
            return (vec![], Err(format!("{path}: no zeDriverGet")));
        };
        let Some(device_get) = lib.sym::<ZeDeviceGet>("zeDeviceGet") else {
            return (vec![], Err(format!("{path}: no zeDeviceGet")));
        };
        let mut ndrv: u32 = 0;
        if driver_get(&mut ndrv, std::ptr::null_mut()) != 0 || ndrv == 0 {
            return (vec![], Err(format!("{path}: no driver")));
        }
        let mut drivers = vec![std::ptr::null_mut(); ndrv as usize];
        driver_get(&mut ndrv, drivers.as_mut_ptr());
        let mut out = vec![];
        let mut index = 0usize;
        for d in drivers.iter().take(ndrv as usize) {
            let mut ndev: u32 = 0;
            if device_get(*d, &mut ndev, std::ptr::null_mut()) != 0 || ndev == 0 {
                continue;
            }
            let mut devs = vec![std::ptr::null_mut(); ndev as usize];
            device_get(*d, &mut ndev, devs.as_mut_ptr());
            for dev in devs.iter().take(ndev as usize) {
                if let Some(desc) = describe(&lib, *dev, index.to_string(), true) {
                    out.push(desc);
                    index += 1;
                }
            }
        }
        (out, Ok(path))
    }
}
type CuInit = unsafe extern "C" fn(c_uint) -> c_int;
type CuDeviceGetCount = unsafe extern "C" fn(*mut c_int) -> c_int;
type CuDeviceGet = unsafe extern "C" fn(*mut c_int, c_int) -> c_int;
type CuDeviceGetName = unsafe extern "C" fn(*mut c_char, c_int, c_int) -> c_int;
type CuDriverGetVersion = unsafe extern "C" fn(*mut c_int) -> c_int;
type CuDeviceTotalMem = unsafe extern "C" fn(*mut usize, c_int) -> c_int;
type CuDeviceComputeCapability = unsafe extern "C" fn(*mut c_int, *mut c_int, c_int) -> c_int;
type CuDeviceGetPCIBusId = unsafe extern "C" fn(*mut c_char, c_int, c_int) -> c_int;
fn ask_cuda(root: &std::path::Path) -> Result<(Vec<CudaDevice>, i32), String> {
    let lib = Library::open(&driver_paths(root))?;
    unsafe {
        let init: CuInit = lib.sym("cuInit").ok_or("no cuInit")?;
        if init(0) != 0 {
            return Err(format!("{}: cuInit failed", lib.path));
        }
        let mut version = 0;
        if let Some(f) = lib.sym::<CuDriverGetVersion>("cuDriverGetVersion") {
            f(&mut version);
        }
        let count_fn: CuDeviceGetCount = lib.sym("cuDeviceGetCount").ok_or("no cuDeviceGetCount")?;
        let get: CuDeviceGet = lib.sym("cuDeviceGet").ok_or("no cuDeviceGet")?;
        let name_fn: CuDeviceGetName = lib.sym("cuDeviceGetName").ok_or("no cuDeviceGetName")?;
        let mut n: c_int = 0;
        if count_fn(&mut n) != 0 {
            return Err("cuDeviceGetCount failed".into());
        }
        let total_fn: Option<CuDeviceTotalMem> = lib.sym("cuDeviceTotalMem_v2");
        let cap_fn: Option<CuDeviceComputeCapability> = lib.sym("cuDeviceComputeCapability");
        let pci_fn: Option<CuDeviceGetPCIBusId> = lib.sym("cuDeviceGetPCIBusId");
        let mut out = vec![];
        for i in 0..n {
            let mut dev: c_int = 0;
            if get(&mut dev, i) != 0 {
                continue;
            }
            let mut buf = [0i8; 256];
            let name = if name_fn(buf.as_mut_ptr(), 256, dev) == 0 {
                cstr_name(&buf)
            } else {
                continue;
            };
            let mut total: usize = 0;
            if let Some(f) = total_fn {
                f(&mut total, dev);
            }
            let (mut major, mut minor) = (0, 0);
            if let Some(f) = cap_fn {
                f(&mut major, &mut minor, dev);
            }
            let mut pci = [0i8; 64];
            if let Some(f) = pci_fn {
                f(pci.as_mut_ptr(), 64, dev);
            }
            out.push(CudaDevice {
                name,
                capability: (major, minor),
                pci_bus_id: cstr_name(&pci),
                total_bytes: total as u64,
            });
        }
        Ok((out, version))
    }
}
pub fn survey(root: &std::path::Path) -> Machine {
    let (devices, level_zero) = enumerate_level_zero();
    Machine { devices, cuda: ask_cuda(root), level_zero }
}
pub fn parse_selector(s: &str) -> Option<String> {
    let t = s.trim();
    let t = t.strip_prefix("cuda:").unwrap_or(t);
    if t.is_empty() || !t.chars().all(|c| c.is_ascii_digit() || c == '.') {
        return None;
    }
    Some(t.to_string())
}
pub fn find<'a>(devices: &'a [Device], path: &str) -> Option<&'a Device> {
    for d in devices {
        if d.path == path {
            return Some(d);
        }
        if let Some(found) = find(&d.children, path) {
            return Some(found);
        }
    }
    None
}
