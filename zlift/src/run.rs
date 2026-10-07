use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
pub fn shim_dir() -> PathBuf {
    let base = std::env::var("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| ".".into())).join(".cache")
        });
    base.join("zlift").join("lib")
}
pub fn prepare_shim(root: &Path) -> Result<PathBuf, String> {
    let driver = crate::device::driver_paths(root)
        .into_iter()
        .map(PathBuf::from)
        .find(|p| p.exists())
        .ok_or_else(|| {
            format!(
                "no driver: build it with `cargo build --release -p zluda_ze` in {}",
                root.join("ZLUDA").display()
            )
        })?;
    let driver = driver
        .canonicalize()
        .map_err(|e| format!("{}: {e}", driver.display()))?;
    let dir = shim_dir();
    std::fs::create_dir_all(&dir).map_err(|e| format!("{}: {e}", dir.display()))?;
    for name in ["libcuda.so.1", "libcuda.so"] {
        let link = dir.join(name);
        let _ = std::fs::remove_file(&link);
        std::os::unix::fs::symlink(&driver, &link)
            .map_err(|e| format!("{}: {e}", link.display()))?;
    }
    for (built, names) in [
        ("zblas/libcublas.so.13", &["libcublas.so.13", "libcublas.so"][..]),
        ("zdnn/libcudnn.so.9", &["libcudnn.so.9", "libcudnn.so"][..]),
        ("znvml/libnvidia-ml.so.1",
         &["libnvidia-ml.so.1", "libnvidia-ml.so"][..]),
    ] {
        let src = root.join(built);
        let Ok(src) = src.canonicalize() else { continue };
        for name in names {
            let link = dir.join(name);
            let _ = std::fs::remove_file(&link);
            let _ = std::os::unix::fs::symlink(&src, &link);
        }
    }
    Ok(dir)
}
pub fn affinity_for(path: &str) -> String {
    path.to_string()
}
pub struct Launch {
    pub env: Vec<(String, String)>,
}
pub fn plan(root: &Path, cfg: &BTreeMap<String, String>) -> Result<Launch, String> {
    let shim = prepare_shim(root)?;
    let mut env = crate::config::env_overlay(cfg);
    if let Some(dev) = cfg.get("device") {
        if let Some(p) = crate::device::parse_selector(dev) {
            if std::env::var_os("ZE_AFFINITY_MASK").is_none() {
                env.push(("ZE_AFFINITY_MASK".to_string(), affinity_for(&p)));
            }
        }
    }
    let mut ld = shim.to_string_lossy().into_owned();
    if let Ok(existing) = std::env::var("LD_LIBRARY_PATH") {
        if !existing.is_empty() {
            ld.push(':');
            ld.push_str(&existing);
        }
    }
    env.push(("LD_LIBRARY_PATH".to_string(), ld));
    let cublas = shim.join("libcublas.so.13");
    if cublas.exists() {
        let mut pre = cublas.to_string_lossy().into_owned();
        if let Ok(existing) = std::env::var("LD_PRELOAD") {
            if !existing.is_empty() {
                pre.push(' ');
                pre.push_str(&existing);
            }
        }
        env.push(("LD_PRELOAD".to_string(), pre));
    }
    Ok(Launch { env })
}
pub fn exec(launch: &Launch, argv: &[String]) -> Result<std::convert::Infallible, String> {
    use std::os::unix::process::CommandExt;
    let (program, args) = argv.split_first().ok_or("nothing to run")?;
    let mut cmd = std::process::Command::new(program);
    cmd.args(args);
    for (k, v) in &launch.env {
        cmd.env(k, v);
    }
    Err(format!("{program}: {}", cmd.exec()))
}
