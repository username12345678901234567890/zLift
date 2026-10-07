mod config;
mod daemon;
mod device;
mod ffi;
mod install;
mod run;
mod smi;
mod tui;
use std::path::PathBuf;
const VERSION: &str = env!("CARGO_PKG_VERSION");
fn project_root() -> PathBuf {
    if let Ok(p) = std::env::var("ZLIFT_ROOT") {
        return PathBuf::from(p);
    }
    if let Ok(exe) = std::env::current_exe() {
        for up in [3usize, 4] {
            let mut p = exe.clone();
            for _ in 0..up {
                p = match p.parent() {
                    Some(q) => q.to_path_buf(),
                    None => break,
                };
            }
            if p.join("ZLUDA").is_dir() && p.join("nvvm2spirv").is_dir() {
                return p;
            }
        }
    }
    std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."))
}
fn help() {
    print!(
        "\
zlift {VERSION} — CUDA on this machine's GPU
  zlift                        settings, in a terminal
  zlift devices                what is here, and what a CUDA program sees
  zlift run [-d DEV] -- CMD    run CMD on this driver
  zlift config                 show every setting
  zlift config KEY             show one
  zlift config KEY VALUE       set one (empty VALUE clears it)
  zlift install [--shell]      put the driver where programs already look
  zlift uninstall              take it away again
  zlift smi                    what `nvidia-smi` would say
  zlift daemon [--foreground]  start the translation cache
  zlift daemon --stop          stop it
  zlift status                 driver, device and daemon in one line each
  -d, --device DEV             cuda:0, cuda:0.1, or a bare 0 / 0.1
  -h, --help                   this
  -V, --version                the version
Everything `zlift run` sets is an environment variable the rest of the project
already reads, so anything it does can be done by hand — `zlift config` prints
them. What it adds is one place to say it.
"
    );
}
fn print_device(d: &device::Device, cuda_index: &mut usize, depth: usize) {
    let pad = "  ".repeat(depth);
    let label = if depth == 0 {
        format!("cuda:{}", *cuda_index)
    } else {
        format!("cuda:{}", d.path)
    };
    if depth == 0 {
        *cuda_index += 1;
    }
    println!("  {pad}{label:<10} {}", d.name);
    let kind = if d.integrated { "integrated" } else { "discrete" };
    let mut bits = vec![kind.to_string()];
    if d.memory_bytes > 0 {
        bits.push(format!("{:.2} GiB", d.memory_gib()));
    }
    if d.eus > 0 {
        bits.push(format!("{} EUs", d.eus));
    }
    if d.simd_width > 0 {
        bits.push(format!("SIMD {}", d.simd_width));
    }
    if !d.sub_group_sizes.is_empty() {
        let s: Vec<String> = d.sub_group_sizes.iter().map(|v| v.to_string()).collect();
        bits.push(format!("sub-groups {}", s.join(",")));
    }
    if d.max_group_size > 0 {
        bits.push(format!("{} threads/group", d.max_group_size));
    }
    if d.slm_bytes > 0 {
        bits.push(format!("{} KiB workgroup memory", d.slm_bytes / 1024));
    }
    println!("  {pad}{:<10} {}", "", bits.join(" · "));
    println!(
        "  {pad}{:<10} ZE_AFFINITY_MASK={}",
        "",
        run::affinity_for(&d.path)
    );
    for c in &d.children {
        print_device(c, cuda_index, depth + 1);
    }
    if depth == 0 && d.children.is_empty() {
        println!("  {pad}{:<10} (no sub-devices)", "");
    }
}
fn cmd_devices(root: &PathBuf) -> i32 {
    let m = device::survey(root);
    println!();
    match &m.level_zero {
        Ok(p) => println!("  Level Zero: {p}"),
        Err(e) => println!("  Level Zero: unavailable ({e})"),
    }
    match &m.cuda {
        Ok((names, v)) => println!(
            "  as CUDA:    {} device{}, driver {}",
            names.len(),
            if names.len() == 1 { "" } else { "s" },
            v
        ),
        Err(e) => println!("  as CUDA:    unavailable ({e})"),
    }
    println!();
    if m.devices.is_empty() {
        println!("  no devices");
        println!();
        return 1;
    }
    let mut i = 0usize;
    for d in &m.devices {
        print_device(d, &mut i, 0);
        println!();
    }
    if let Ok((names, _)) = &m.cuda {
        let roots: Vec<&str> = m.devices.iter().map(|d| d.name.as_str()).collect();
        if names.len() != roots.len() || names.iter().zip(&roots).any(|(a, b)| a.name != *b) {
            println!("  note: the CUDA driver enumerates a different set:");
            for (i, n) in names.iter().enumerate() {
                println!("        cuda:{i} {} (sm_{}{})", n.name, n.capability.0, n.capability.1);
            }
            println!("        (ZE_AFFINITY_MASK is set, or a device was filtered)");
            println!();
        }
    }
    0
}
pub fn cmd_config_public(args: &[String]) -> i32 {
    cmd_config(args)
}
fn cmd_config(args: &[String]) -> i32 {
    let mut values = config::load();
    match args.len() {
        0 => {
            println!();
            println!("  {}", config::path().display());
            println!();
            for s in config::SETTINGS {
                let set = values.get(s.key).cloned().unwrap_or_default();
                let shown = if set.is_empty() {
                    format!("{}  (default)", s.default)
                } else {
                    set
                };
                println!("  {:<22} {:<18} {}", s.key, shown, s.summary);
            }
            println!();
            0
        }
        1 => match config::setting(&args[0]) {
            Some(s) => {
                let set = values.get(s.key).cloned().unwrap_or_default();
                println!();
                println!("  {}", s.key);
                println!("  {}", s.summary);
                println!();
                for line in s.detail.split_whitespace().collect::<Vec<_>>().chunks(11) {
                    println!("    {}", line.join(" "));
                }
                println!();
                println!(
                    "  now: {}",
                    if set.is_empty() { format!("{} (default)", s.default) } else { set }
                );
                if !s.values.is_empty() {
                    let vs: Vec<String> = s
                        .values
                        .iter()
                        .map(|v| if v.is_empty() { "(unset)".into() } else { v.to_string() })
                        .collect();
                    println!("  choices: {}", vs.join("  "));
                }
                println!();
                0
            }
            None => {
                eprintln!("no such setting: {}", args[0]);
                1
            }
        },
        _ => {
            let key = &args[0];
            if config::setting(key).is_none() {
                eprintln!("no such setting: {key}");
                return 1;
            }
            let value = args[1..].join(" ");
            if value.is_empty() {
                values.remove(key);
            } else {
                values.insert(key.clone(), value.clone());
            }
            match config::save(&values) {
                Ok(()) => {
                    println!(
                        "{key} = {}",
                        if value.is_empty() { "(cleared)".into() } else { value }
                    );
                    0
                }
                Err(e) => {
                    eprintln!("could not write {}: {e}", config::path().display());
                    1
                }
            }
        }
    }
}
fn cmd_run(root: &PathBuf, device: Option<String>, argv: &[String]) -> i32 {
    if argv.is_empty() {
        eprintln!("zlift run: nothing to run (put the command after `--`)");
        return 2;
    }
    let mut cfg = config::load();
    if let Some(d) = device {
        let Some(path) = device::parse_selector(&d) else {
            eprintln!("zlift run: {d} is not a device (try `cuda:0`)");
            return 2;
        };
        let machine = device::survey(root);
        if device::find(&machine.devices, &path).is_none() {
            eprintln!("zlift run: no device {d}; `zlift devices` lists them");
            return 2;
        }
        cfg.insert("device".into(), d);
    }
    let launch = match run::plan(root, &cfg) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("zlift run: {e}");
            return 1;
        }
    };
    match run::exec(&launch, argv) {
        Ok(_) => unreachable!(),
        Err(e) => {
            eprintln!("zlift run: {e}");
            127
        }
    }
}
fn cmd_status(root: &PathBuf) -> i32 {
    let m = device::survey(root);
    println!();
    println!(
        "  driver    {}",
        match &m.cuda {
            Ok((n, v)) => format!("{} device(s), CUDA {v}", n.len()),
            Err(e) => format!("unavailable — {e}"),
        }
    );
    println!(
        "  device    {}",
        m.devices
            .first()
            .map(|d| d.name.clone())
            .unwrap_or_else(|| "none".into())
    );
    println!(
        "  shim      {}",
        match run::prepare_shim(root) {
            Ok(p) => format!("{} -> libzluda_ze.so", p.display()),
            Err(e) => e,
        }
    );
    println!("  installed {}", install::state());
    println!("  settings  {}", config::path().display());
    println!("  daemon    {}", daemon::status_line());
    println!();
    0
}
fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let root = project_root();
    let split = args.iter().position(|a| a == "--");
    let (mine, theirs) = match split {
        Some(i) => (&args[..i], args[i + 1..].to_vec()),
        None => (&args[..], vec![]),
    };
    let mut device = None;
    let mut positional: Vec<String> = vec![];
    let mut i = 0;
    while i < mine.len() {
        match mine[i].as_str() {
            "-h" | "--help" => {
                help();
                return;
            }
            "-V" | "--version" => {
                println!("zlift {VERSION}");
                return;
            }
            "-d" | "--device" => {
                i += 1;
                device = mine.get(i).cloned();
            }
            "--devices" => positional.push("devices".into()),
            other => positional.push(other.to_string()),
        }
        i += 1;
    }
    let code = match positional.first().map(|s| s.as_str()) {
        None => tui::run(&root),
        Some("devices") => cmd_devices(&root),
        Some("config") => cmd_config(&positional[1..]),
        Some("run") => {
            let argv = if theirs.is_empty() { positional[1..].to_vec() } else { theirs };
            cmd_run(&root, device, &argv)
        }
        Some("status") => cmd_status(&root),
        Some("daemon") => daemon::main(&root, &positional[1..]),
        Some("install") => install::install(&root, mine.iter().any(|a| a == "--shell")),
        Some("uninstall") => install::uninstall(),
        Some("smi") => smi::run(&root, &positional[1..]),
        Some(other) => {
            eprintln!("zlift: no such command: {other}");
            eprintln!("try `zlift --help`");
            2
        }
    };
    std::process::exit(code);
}
