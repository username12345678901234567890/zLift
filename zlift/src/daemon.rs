use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::{Path, PathBuf};
use std::time::{Instant, SystemTime, UNIX_EPOCH};
#[path = "sha256.rs"]
mod sha256;
const VERSION: &str = env!("CARGO_PKG_VERSION");
const PRODUCTS: &[&str] = &["spv", "args.json", "nvglobal.bin"];
pub fn cache_root() -> PathBuf {
    let base = std::env::var("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| ".".into())).join(".cache")
        });
    base.join("zlift")
}
pub fn socket_path() -> PathBuf {
    if let Ok(p) = std::env::var("ZLIFT_DAEMON_SOCKET") {
        return PathBuf::from(p);
    }
    if let Ok(run) = std::env::var("XDG_RUNTIME_DIR") {
        return PathBuf::from(run).join("zlift.sock");
    }
    cache_root().join("zlift.sock")
}
fn pid_path() -> PathBuf {
    cache_root().join("daemon.pid")
}
fn log_path() -> PathBuf {
    cache_root().join("daemon.log")
}
pub fn ask(request: &str) -> Result<String, String> {
    let mut s = UnixStream::connect(socket_path()).map_err(|e| e.to_string())?;
    s.set_read_timeout(Some(std::time::Duration::from_secs(120))).ok();
    writeln!(s, "{request}").map_err(|e| e.to_string())?;
    s.flush().ok();
    let mut reply = String::new();
    BufReader::new(&s)
        .read_line(&mut reply)
        .map_err(|e| e.to_string())?;
    Ok(reply.trim_end().to_string())
}
pub fn status_line() -> String {
    match ask("STAT") {
        Ok(s) => format!("running — {s}"),
        Err(_) => format!("not running (start it with `zlift daemon`)"),
    }
}
fn cubin2spv(root: &Path) -> PathBuf {
    std::env::var("ZLUDA_CUBIN2SPV")
        .map(PathBuf::from)
        .unwrap_or_else(|_| root.join("tools/cubin2spv"))
}
struct Server {
    root: PathBuf,
    started: Instant,
    hits: u64,
    misses: u64,
}
fn toolchain_fingerprint(root: &Path) -> String {
    fn walk(dir: &Path, out: &mut Vec<String>) {
        let Ok(entries) = std::fs::read_dir(dir) else { return };
        let mut items: Vec<_> = entries.filter_map(|e| e.ok()).collect();
        items.sort_by_key(|e| e.path());
        for e in items {
            let path = e.path();
            if path.is_dir() {
                if path.file_name().is_some_and(|n| n == "__pycache__") {
                    continue;
                }
                walk(&path, out);
            } else if path.extension().is_some_and(|x| x == "py") {
                out.push(stamp(&path));
            }
        }
    }
    fn stamp(path: &Path) -> String {
        let (len, secs) = std::fs::metadata(path)
            .map(|m| {
                let t = m.modified().ok()
                    .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
                    .map(|d| d.as_secs())
                    .unwrap_or(0);
                (m.len(), t)
            })
            .unwrap_or((0, 0));
        format!("{} {len} {secs}", path.display())
    }
    let mut parts = Vec::new();
    for dir in ["CuLifter", "nvvm2spirv"] {
        walk(&root.join(dir), &mut parts);
    }
    for file in ["tools/cubin2spv", "nvvm2spirv/zlift_devlib.ll",
                 "nvvm2spirv/zlift_devlib.cl"] {
        parts.push(stamp(&root.join(file)));
    }
    sha256::hex(parts.join("\n").as_bytes())
}
impl Server {
    fn entries(&self) -> usize {
        std::fs::read_dir(cache_root().join("spv"))
            .map(|d| d.filter_map(|e| e.ok()).count())
            .unwrap_or(0)
    }
    fn deliver(&self, from: &Path, stem: &Path) -> std::io::Result<()> {
        for ext in PRODUCTS {
            let src = from.join(format!("module.{ext}"));
            if src.exists() {
                std::fs::copy(&src, stem.with_extension(ext))?;
            }
        }
        Ok(())
    }
    fn lift(&mut self, cubin: &str, stem: &str, kernel: Option<&str>,
            shared: Option<&str>) -> String {
        let cubin = Path::new(cubin);
        let stem = Path::new(stem);
        let Ok(key) = sha256::file(cubin) else {
            return format!("ERR cannot read {}", cubin.display());
        };
        let key = sha256::hex(
            format!("{key}:{}:{}:{}", kernel.unwrap_or("-"), shared.unwrap_or("-"),
                    toolchain_fingerprint(&self.root))
                .as_bytes());
        let slot = cache_root().join("spv").join(&key);
        if slot.join("module.spv").exists() {
            self.hits += 1;
            return match self.deliver(&slot, stem) {
                Ok(()) => "HIT".into(),
                Err(e) => format!("ERR cache copy: {e}"),
            };
        }
        self.misses += 1;
        if let Err(e) = std::fs::create_dir_all(&slot) {
            return format!("ERR {}: {e}", slot.display());
        }
        let out = slot.join("module");
        let mut cmd = std::process::Command::new(cubin2spv(&self.root));
        cmd.arg(cubin).arg(&out);
        if let Some(k) = kernel {
            cmd.arg(k);
        }
        if let Some(n) = shared {
            cmd.env("ZLIFT_SHARED_BYTES", n);
        }
        let result = cmd.output();
        match result {
            Ok(o) if o.status.success() => match self.deliver(&slot, stem) {
                Ok(()) => "OK".into(),
                Err(e) => format!("ERR copy: {e}"),
            },
            Ok(o) => {
                let _ = std::fs::remove_file(out.with_extension("spv"));
                let msg = String::from_utf8_lossy(&o.stderr);
                format!("ERR lift: {}", msg.lines().last().unwrap_or("failed"))
            }
            Err(e) => format!("ERR cannot run the lifter: {e}"),
        }
    }
    fn handle(&mut self, line: &str) -> (String, bool) {
        let mut parts = line.split_whitespace();
        match parts.next() {
            Some("PING") => (format!("PONG zlift {VERSION}"), false),
            Some("STAT") => (
                format!(
                    "entries={} hits={} misses={} uptime={}s",
                    self.entries(),
                    self.hits,
                    self.misses,
                    self.started.elapsed().as_secs()
                ),
                false,
            ),
            Some("LIFT") => {
                let (Some(cubin), Some(stem)) = (parts.next(), parts.next()) else {
                    return ("ERR LIFT needs a cubin and an output stem".into(), false);
                };
                fn given(v: Option<&str>) -> Option<String> {
                    v.filter(|s| *s != "-").map(str::to_string)
                }
                let kernel = given(parts.next());
                let shared = given(parts.next());
                (self.lift(cubin, stem, kernel.as_deref(), shared.as_deref()), false)
            }
            Some("STOP") => ("BYE".into(), true),
            _ => ("ERR unknown request".into(), false),
        }
    }
}
fn serve(root: &Path) -> i32 {
    let sock = socket_path();
    if let Some(d) = sock.parent() {
        let _ = std::fs::create_dir_all(d);
    }
    if ask("PING").is_ok() {
        eprintln!("zlift daemon: already running at {}", sock.display());
        return 1;
    }
    let _ = std::fs::remove_file(&sock);
    let listener = match UnixListener::bind(&sock) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("zlift daemon: {}: {e}", sock.display());
            return 1;
        }
    };
    let _ = std::fs::create_dir_all(cache_root().join("spv"));
    let _ = std::fs::write(pid_path(), format!("{}\n", std::process::id()));
    println!(
        "zlift daemon {VERSION} on {} (cache {})",
        sock.display(),
        cache_root().join("spv").display()
    );
    let mut server = Server {
        root: root.to_path_buf(),
        started: Instant::now(),
        hits: 0,
        misses: 0,
    };
    for stream in listener.incoming() {
        let Ok(stream) = stream else { continue };
        let reader = BufReader::new(match stream.try_clone() {
            Ok(s) => s,
            Err(_) => continue,
        });
        let mut writer = stream;
        let mut stop = false;
        for line in reader.lines() {
            let Ok(line) = line else { break };
            let (reply, done) = server.handle(line.trim());
            if writeln!(writer, "{reply}").is_err() {
                break;
            }
            let _ = writer.flush();
            stop |= done;
            if done {
                break;
            }
        }
        if stop {
            break;
        }
    }
    let _ = std::fs::remove_file(&sock);
    let _ = std::fs::remove_file(pid_path());
    println!("zlift daemon: stopped");
    0
}
fn start_detached(root: &Path) -> i32 {
    if ask("PING").is_ok() {
        println!("zlift daemon: already running");
        return 0;
    }
    let exe = match std::env::current_exe() {
        Ok(e) => e,
        Err(e) => {
            eprintln!("zlift daemon: {e}");
            return 1;
        }
    };
    let _ = std::fs::create_dir_all(cache_root());
    let log = match std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_path())
    {
        Ok(f) => f,
        Err(e) => {
            eprintln!("zlift daemon: {}: {e}", log_path().display());
            return 1;
        }
    };
    let err = match log.try_clone() {
        Ok(f) => f,
        Err(e) => {
            eprintln!("zlift daemon: {e}");
            return 1;
        }
    };
    let spawned = std::process::Command::new(exe)
        .arg("daemon")
        .arg("--foreground")
        .env("ZLIFT_ROOT", root)
        .stdin(std::process::Stdio::null())
        .stdout(log)
        .stderr(err)
        .spawn();
    match spawned {
        Ok(child) => {
            for _ in 0..50 {
                if ask("PING").is_ok() {
                    println!(
                        "zlift daemon: started (pid {}), log {}",
                        child.id(),
                        log_path().display()
                    );
                    return 0;
                }
                std::thread::sleep(std::time::Duration::from_millis(40));
            }
            eprintln!(
                "zlift daemon: started but did not answer; see {}",
                log_path().display()
            );
            1
        }
        Err(e) => {
            eprintln!("zlift daemon: {e}");
            1
        }
    }
}
fn stop() -> i32 {
    match ask("STOP") {
        Ok(_) => {
            println!("zlift daemon: stopped");
            0
        }
        Err(_) => {
            println!("zlift daemon: not running");
            0
        }
    }
}
fn self_test() -> i32 {
    let cases: [(&str, &str); 2] = [
        ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
        ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
    ];
    let mut bad = 0;
    for (input, want) in cases {
        let got = sha256::hex(input.as_bytes());
        let ok = got == want;
        println!("  {} sha256({input:?})", if ok { "ok  " } else { "FAIL" });
        if !ok {
            println!("      got  {got}\n      want {want}");
            bad += 1;
        }
    }
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    println!("  ok   cache at {}", cache_root().join("spv").display());
    println!("  ok   socket at {} (clock {now})", socket_path().display());
    if bad == 0 { 0 } else { 1 }
}
pub fn main(root: &Path, args: &[String]) -> i32 {
    match args.first().map(|s| s.as_str()) {
        None => start_detached(root),
        Some("--foreground") | Some("-f") => serve(root),
        Some("--stop") => stop(),
        Some("--status") => {
            println!("{}", status_line());
            0
        }
        Some("--self-test") => self_test(),
        Some(other) => {
            eprintln!("zlift daemon: no such option: {other}");
            2
        }
    }
}
