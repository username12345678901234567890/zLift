use crate::device::{self, CudaDevice, Device};
fn flat<'a>(devices: &'a [Device], out: &mut Vec<&'a Device>) {
    for d in devices {
        out.push(d);
        // Sub-devices are not separate CUDA devices unless ZE_AFFINITY_MASK
        // says so, and this reports what a program would see right now.
        let _ = &d.children;
    }
}
fn field(d: &Device, cu: Option<&CudaDevice>, version: i32, index: usize, name: &str) -> String {
    match name.trim() {
        "index" => index.to_string(),
        "name" | "gpu_name" => d.name.clone(),
        "uuid" | "gpu_uuid" => uuid(d),
        "memory.total" => format!("{} MiB", d.memory_bytes / (1024 * 1024)),
        "memory.free" => format!("{} MiB", d.memory_bytes / (1024 * 1024)),
        "memory.used" => "0 MiB".to_string(),
        "driver_version" => driver_version(version),
        "compute_cap" => cu
            .map(|c| format!("{}.{}", c.capability.0, c.capability.1))
            .unwrap_or_else(|| "[N/A]".into()),
        "pci.bus_id" => cu
            .map(|c| c.pci_bus_id.clone())
            .unwrap_or_else(|| "[N/A]".into()),
        "count" => "1".to_string(),
        _ => "[N/A]".to_string(),
    }
}
/// `nounits` strips the unit from a number. It must not touch a name — the
/// first attempt took the first whitespace-separated word and turned
/// "Intel(R) Arc(TM) B390 GPU" into "Intel(R)".
fn strip_units(v: &str) -> String {
    for unit in [" MiB", " W", " MHz", " %"] {
        if let Some(bare) = v.strip_suffix(unit) {
            return bare.to_string();
        }
    }
    v.to_string()
}
/// The three dotted fields a caller parses, out of the version the driver
/// reports — the same number `cuDriverGetVersion` gives.
fn driver_version(v: i32) -> String {
    format!("{}.{:02}.{:02}", v / 1000, (v % 1000) / 10, v % 10)
}
/// The form every caller matches on: `GPU-` and five dash-separated groups.
fn uuid(d: &Device) -> String {
    let u = &d.uuid;
    format!(
        "GPU-{:02x}{:02x}{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
        u[0], u[1], u[2], u[3], u[4], u[5], u[6], u[7],
        u[8], u[9], u[10], u[11], u[12], u[13], u[14], u[15]
    )
}
pub fn run(root: &std::path::Path, args: &[String]) -> i32 {
    let machine = device::survey(root);
    let mut devices = vec![];
    flat(&machine.devices, &mut devices);
    let (cuda, version) = match &machine.cuda {
        Ok((c, v)) => (c.as_slice(), *v),
        Err(_) => (&[][..], 0),
    };
    let cu = |i: usize| cuda.get(i);
    // `-L` is what a script uses when it only wants the names.
    if args.iter().any(|a| a == "-L" || a == "--list-gpus") {
        for (i, d) in devices.iter().enumerate() {
            println!("GPU {i}: {} (UUID: {})", d.name, field(d, cu(i), version, i, "uuid"));
        }
        return 0;
    }
    let query = args.iter().find_map(|a| a.strip_prefix("--query-gpu="));
    if let Some(q) = query {
        let fmt = args
            .iter()
            .find_map(|a| a.strip_prefix("--format="))
            .unwrap_or("csv");
        let noheader = fmt.contains("noheader");
        let nounits = fmt.contains("nounits");
        let fields: Vec<&str> = q.split(',').collect();
        if !noheader {
            println!("{}", fields.join(", "));
        }
        for (i, d) in devices.iter().enumerate() {
            let row: Vec<String> = fields
                .iter()
                .map(|f| {
                    let v = field(d, cu(i), version, i, f);
                    if nounits { strip_units(&v) } else { v }
                })
                .collect();
            println!("{}", row.join(", "));
        }
        return 0;
    }
    // The table, at the real one's column widths — 41, 22, 22 — because the
    fn cell(text: &str, width: usize) -> String {
        let mut t: String = text.chars().take(width).collect();
        while t.chars().count() < width {
            t.push(' ');
        }
        t
    }
    fn row(a: &str, b: &str, c: &str) -> String {
        format!("|{}|{}|{}|", cell(a, 41), cell(b, 22), cell(c, 22))
    }
    let rule = |l: char, m: char| {
        format!(
            "{l}{}{m}{}{m}{}{l}",
            "-".repeat(41),
            "-".repeat(22),
            "-".repeat(22)
        )
    };
    let top = format!("+{}+", "-".repeat(87));
    let mid = format!("|{}+{}+{}+", "-".repeat(41), "-".repeat(22), "-".repeat(22));
    let bar = format!("|{}+{}+{}|", "=".repeat(41), "=".repeat(22), "=".repeat(22));
    println!("{top}");
    println!(
        "|{}|",
        cell(
            &format!(
                " zlift {:<12}      Driver Version: {:<11} CUDA Version: {}.{}",
                env!("CARGO_PKG_VERSION"),
                driver_version(version),
                version / 1000,
                (version % 1000) / 10
            ),
            87
        )
    );
    println!("{mid}");
    println!(
        "{}",
        row(
            " GPU  Name                 Persistence-M",
            " Bus-Id        Disp.A",
            " Volatile Uncorr. ECC "
        )
    );
    println!(
        "{}",
        row(
            " Fan  Temp   Perf          Pwr:Usage/Cap",
            "         Memory-Usage ",
            " GPU-Util  Compute M. "
        )
    );
    println!("{bar}");
    if devices.is_empty() {
        println!("{}", row("  no devices", "", ""));
    }
    for (i, d) in devices.iter().enumerate() {
        let name: String = d.name.chars().take(27).collect();
        let total = d.memory_bytes / (1024 * 1024);
        println!(
            "{}",
            row(
                &format!("{i:>4}  {name:<29}{:>4} ", "Off"),
                &format!(
                    " {:<16}{:>4} ",
                    cu(i).map(|c| c.pci_bus_id.as_str()).unwrap_or("00000000:00:00.0"),
                    "Off"
                ),
                &format!("{:>21} ", "N/A")
            )
        );
        println!(
            "{}",
            row(
                &format!(" {:>3}   {:>3}    {:<9}{:>8} / {:<5}", "N/A", "N/A", "N/A", "N/A", "N/A"),
                &format!("{:>7}MiB / {:>5}MiB ", 0, total),
                &format!("{:>8}{:>13} ", "N/A", "Default")
            )
        );
        println!("{}", rule('+', '+'));
    }
    println!();
    println!("{top}");
    println!("|{}|", cell(" Processes:", 87));
    println!(
        "|{}|",
        cell("  GPU   GI   CI        PID   Type   Process name                  GPU Memory", 87)
    );
    println!("|{}|", "=".repeat(87));
    println!(
        "|{}|",
        cell(
            "  No running processes found — this driver cannot see another process's contexts",
            87
        )
    );
    println!("{top}");
    match &machine.cuda {
        Ok((n, v)) => println!("\nCUDA: {} device(s), driver {v}, through libcuda.so.1", n.len()),
        Err(e) => println!("\nCUDA: unavailable — {e}"),
    }
    0
}
