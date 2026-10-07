use std::path::{Path, PathBuf};
fn home() -> PathBuf {
    PathBuf::from(std::env::var("HOME").unwrap_or_else(|_| ".".into()))
}
pub fn lib_dir() -> PathBuf {
    home().join(".local/lib/zlift")
}
pub fn bin_dir() -> PathBuf {
    home().join(".local/bin")
}
pub fn env_file() -> PathBuf {
    crate::config::path().with_file_name("env.sh")
}
struct Artifact {
    installed: &'static str,
    /// Where this project builds it.
    built: &'static str,
    how: &'static str,
    also: &'static [&'static str],
}
const ARTIFACTS: &[Artifact] = &[
    Artifact {
        installed: "libcuda.so.1",
        built: "ZLUDA/target/release/libzluda_ze.so",
        how: "cd ZLUDA && cargo build --release -p zluda_ze",
        also: &["libcuda.so"],
    },
    // The libraries a program links against by name. Not the driver, but a
    // machine that has `libcuda.so.1` and no `libcublas.so` fails at the link,
    // which looks the same to whoever is trying to run something.
    Artifact {
        installed: "libcublas.so.13",
        built: "zblas/libcublas.so.13",
        how: "zblas/build.sh",
        also: &["libcublas.so"],
    },
    Artifact {
        installed: "libcudnn.so.9",
        built: "zdnn/libcudnn.so.9",
        how: "zdnn/build.sh",
        also: &["libcudnn.so"],
    },
    Artifact {
        installed: "libnvidia-ml.so.1",
        built: "znvml/libnvidia-ml.so.1",
        how: "znvml/build.sh",
        also: &["libnvidia-ml.so"],
    },
];
fn link(target: &Path, at: &Path) -> Result<(), String> {
    let _ = std::fs::remove_file(at);
    std::os::unix::fs::symlink(target, at).map_err(|e| format!("{}: {e}", at.display()))
}
pub fn install(root: &Path, shell: bool) -> i32 {
    let lib = lib_dir();
    let bin = bin_dir();
    if let Err(e) = std::fs::create_dir_all(&lib).and_then(|_| std::fs::create_dir_all(&bin)) {
        eprintln!("zlift install: {e}");
        return 1;
    }
    let mut missing = vec![];
    for a in ARTIFACTS {
        let src = root.join(a.built);
        if !src.exists() {
            missing.push((a.built, a.how));
            continue;
        }
        let src = match src.canonicalize() {
            Ok(p) => p,
            Err(e) => {
                eprintln!("zlift install: {}: {e}", src.display());
                return 1;
            }
        };
        for name in std::iter::once(a.installed).chain(a.also.iter().copied()) {
            if let Err(e) = link(&src, &lib.join(name)) {
                eprintln!("zlift install: {e}");
                return 1;
            }
        }
        println!("  {:<20} -> {}", a.installed, src.display());
    }
    if !missing.is_empty() {
        println!();
        for (what, how) in &missing {
            println!("  {what} is not built yet — `{how}`");
        }
        println!();
        return 1;
    }
    // `zlift` itself, first. It was not installed at all until someone typed it
    // and got nothing back: an installer that puts a driver on the system and
    // leaves out its own command has left out the one file everybody reaches
    // for first.
    //
    // Under both spellings. The project is written zLift and the binary is
    // zlift, and a filesystem that tells them apart answers "command not
    // found" to whichever one you did not guess.
    let exe = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("zlift"));
    for name in ["zlift", "zLift"] {
        let at = bin.join(name);
        // Unless that is the binary being installed: linking a file over
        // itself deletes it.
        if at == exe {
            continue;
        }
        if let Err(e) = link(&exe, &at) {
            eprintln!("zlift install: {e}");
            return 1;
        }
    }
    println!("  {:<20} -> {}", "zlift, zLift", exe.display());
    // `nvidia-smi` as a script rather than a second binary: it is three lines
    // and it keeps working when `zlift` is rebuilt somewhere else.
    let smi = bin.join("nvidia-smi");
    let script = format!(
        "#!/bin/sh\n# Installed by `zlift install`. The real thing is `zlift smi`.\nexec {} smi \"$@\"\n",
        exe.display()
    );
    if let Err(e) = std::fs::write(&smi, script) {
        eprintln!("zlift install: {}: {e}", smi.display());
        return 1;
    }
    let _ = std::process::Command::new("chmod").arg("+x").arg(&smi).status();
    println!("  {:<20} -> {} smi", "nvidia-smi", exe.display());
    let env = format!(
        "# Written by `zlift install`. Source it, or let your shell do it.\n\
         export LD_LIBRARY_PATH=\"{}${{LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}}\"\n\
         case \":$PATH:\" in *\":{}:\"*) ;; *) export PATH=\"{}:$PATH\" ;; esac\n",
        lib.display(),
        bin.display(),
        bin.display()
    );
    if let Some(d) = env_file().parent() {
        let _ = std::fs::create_dir_all(d);
    }
    if let Err(e) = std::fs::write(env_file(), env) {
        eprintln!("zlift install: {}: {e}", env_file().display());
        return 1;
    }
    println!("  {:<20} {}", "environment", env_file().display());
    if shell {
        match hook_shell() {
            Ok(true) => println!("  {:<20} added to ~/.bashrc", "shell"),
            Ok(false) => println!("  {:<20} already in ~/.bashrc", "shell"),
            Err(e) => println!("  {:<20} {e}", "shell"),
        }
    }
    println!();
    println!("  Now, in this shell:");
    println!("      . {}", env_file().display());
    if !shell {
        println!("  and in every future one:");
        println!("      zlift install --shell        # adds one line to ~/.bashrc");
    }
    println!();
    println!("  System-wide instead — every user, every process, no environment.");
    println!("  These need root, so they are yours to run:");
    println!();
    println!("      sudo install -d /usr/local/lib/zlift");
    for a in ARTIFACTS {
        println!(
            "      sudo ln -sf {} /usr/local/lib/zlift/{}",
            root.join(a.built).display(),
            a.installed
        );
    }
    println!("      echo /usr/local/lib/zlift | sudo tee /etc/ld.so.conf.d/zlift.conf");
    println!("      sudo ldconfig");
    println!();
    0
}
fn hook_shell() -> Result<bool, String> {
    let rc = home().join(".bashrc");
    let line = format!(". {}", env_file().display());
    let existing = std::fs::read_to_string(&rc).unwrap_or_default();
    if existing.contains(&line) {
        return Ok(false);
    }
    use std::io::Write;
    let mut f = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&rc)
        .map_err(|e| format!("{}: {e}", rc.display()))?;
    writeln!(f, "\n# zlift: CUDA on this machine's GPU\n{line}")
        .map_err(|e| format!("{}: {e}", rc.display()))?;
    Ok(true)
}
pub fn uninstall() -> i32 {
    let mut gone = 0;
    for a in ARTIFACTS {
        for name in std::iter::once(a.installed).chain(a.also.iter().copied()) {
            if std::fs::remove_file(lib_dir().join(name)).is_ok() {
                gone += 1;
            }
        }
    }
    if std::fs::remove_file(bin_dir().join("nvidia-smi")).is_ok() {
        gone += 1;
    }
    let _ = std::fs::remove_file(env_file());
    let _ = std::fs::remove_dir(lib_dir());
    println!("  removed {gone} file(s)");
    println!("  the line in ~/.bashrc, if you added one, is yours to remove");
    0
}
/// Whether a program that did not ask would find this driver.
pub fn state() -> String {
    let lib = lib_dir().join("libcuda.so.1");
    if !lib.exists() {
        return "not installed (`zlift install`)".into();
    }
    let on_path = std::env::var("LD_LIBRARY_PATH")
        .map(|v| v.split(':').any(|p| Path::new(p) == lib_dir()))
        .unwrap_or(false);
    if on_path {
        format!("{} — on this shell's LD_LIBRARY_PATH", lib_dir().display())
    } else {
        format!(
            "{} — but not on this shell's LD_LIBRARY_PATH (. {})",
            lib_dir().display(),
            env_file().display()
        )
    }
}
