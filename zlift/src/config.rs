use std::collections::BTreeMap;
use std::path::PathBuf;
pub struct Setting {
    pub key: &'static str,
    pub values: &'static [&'static str],
    pub default: &'static str,
    pub summary: &'static str,
    pub detail: &'static str,
}
pub const SETTINGS: &[Setting] = &[
    Setting {
        key: "device",
        values: &[],
        default: "cuda:0",
        summary: "which device a program gets",
        detail: "A row from `zlift devices`. A sub-device becomes the CUDA device \
                 by way of ZE_AFFINITY_MASK, which is what this sets.",
    },
    Setting {
        key: "ZLIFT_XMX",
        values: &["", "1", "0"],
        default: "(auto)",
        summary: "wgmma on the matrix engine",
        detail: "Unset means on wherever a backend that knows the SPIR-V matrix \
                 extension exists. 1 forces the tile, 0 forces the element path. \
                 The two agree register for register; this is a speed choice.",
    },
    Setting {
        key: "ZLIFT_SUBGROUP_PIN",
        values: &["always", "auto"],
        default: "always",
        summary: "pin the sub-group to 32 lanes",
        detail: "always is the only safe setting: lifted SASS carries the 32-lane \
                 assumption in its control flow, not only in its instructions. \
                 auto drops the pin where no warp operation is named — a \
                 measuring tool, and it has hung a device.",
    },
    Setting {
        key: "ZLIFT_SPIRV_OPT",
        values: &["-O2", "-O1", "-O0"],
        default: "-O2",
        summary: "how hard the SPIR-V backend optimises",
        detail: "IGC has taken an internal segmentation fault building three of \
                 NPP's kernels from the -O2 module and built all three from -O0.",
    },
    Setting {
        key: "ZLIFT_SHARED_BYTES",
        values: &[],
        default: "32768",
        summary: "workgroup memory a lifted kernel may address",
        detail: "The static shared memory plus whatever `extern __shared__` a \
                 launch asks for. Only the first is knowable at translation \
                 time, so this is the room left for the second.",
    },
    Setting {
        key: "ZLUDA_TRACE_CALLS",
        values: &["", "1"],
        default: "(off)",
        summary: "log every driver call, in order",
        detail: "To stderr. The fastest way to see where a program stops.",
    },
    Setting {
        key: "ZLUDA_TRACE_MISSING",
        values: &["", "1"],
        default: "(off)",
        summary: "log entry points a program wanted and did not get",
        detail: "To stderr, once per name. 360 of the 535 entry points answer \
                 NOT_SUPPORTED; this says which of them a program actually needs.",
    },
    Setting {
        key: "ZBLAS_TRACE",
        values: &["", "1"],
        default: "(off)",
        summary: "log whether cuBLAS ran on the GPU or the CPU",
        detail: "The GEMMs go through oneMKL's SYCL interface on a queue that \
                 adopted the driver's context, and fall back to the CPU path \
                 whenever they cannot. This says which happened.",
    },
];
pub fn setting(key: &str) -> Option<&'static Setting> {
    SETTINGS.iter().find(|s| s.key == key)
}
pub fn path() -> PathBuf {
    let base = std::env::var("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| ".".into())).join(".config")
        });
    base.join("zlift").join("config")
}
pub fn load() -> BTreeMap<String, String> {
    let mut out = BTreeMap::new();
    let Ok(text) = std::fs::read_to_string(path()) else {
        return out;
    };
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if let Some((k, v)) = line.split_once('=') {
            out.insert(k.trim().to_string(), v.trim().to_string());
        }
    }
    out
}
pub fn save(values: &BTreeMap<String, String>) -> std::io::Result<()> {
    let p = path();
    if let Some(dir) = p.parent() {
        std::fs::create_dir_all(dir)?;
    }
    let mut text = String::from("# zlift settings. Each key is an environment variable\n\
                                 # the rest of the project reads; `zlift` applies them.\n");
    for (k, v) in values {
        if v.is_empty() {
            continue;
        }
        text.push_str(&format!("{k} = {v}\n"));
    }
    std::fs::write(p, text)
}
/// The settings as a program should see them, config first and the caller's
pub fn env_overlay(values: &BTreeMap<String, String>) -> Vec<(String, String)> {
    let mut out = vec![];
    for (k, v) in values {
        if k == "device" || v.is_empty() {
            continue;
        }
        if std::env::var_os(k).is_none() {
            out.push((k.clone(), v.clone()));
        }
    }
    out
}
