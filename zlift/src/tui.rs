use crate::{config, daemon, device};
use std::collections::BTreeMap;
use std::io::{Read, Write};
const ALT_ON: &str = "\x1b[?1049h";
const ALT_OFF: &str = "\x1b[?1049l";
const HIDE: &str = "\x1b[?25l";
const SHOW: &str = "\x1b[?25h";
const CLEAR: &str = "\x1b[2J";
const DIM: &str = "\x1b[2m";
const BOLD: &str = "\x1b[1m";
const REV: &str = "\x1b[7m";
const OFF: &str = "\x1b[0m";
fn stty(args: &[&str]) -> bool {
    std::process::Command::new("stty")
        .args(args)
        .stdin(std::process::Stdio::inherit())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}
fn is_tty() -> bool {
    std::process::Command::new("stty")
        .arg("-a")
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}
fn at(row: usize, col: usize) -> String {
    format!("\x1b[{row};{col}H")
}
enum Key {
    Up,
    Down,
    Left,
    Right,
    Enter,
    Char(char),
    Other,
}
fn read_key() -> Key {
    let mut b = [0u8; 1];
    if std::io::stdin().read(&mut b).unwrap_or(0) == 0 {
        return Key::Char('q');
    }
    match b[0] {
        0x1b => {
            let mut rest = [0u8; 2];
            if std::io::stdin().read(&mut rest).unwrap_or(0) < 2 {
                return Key::Char('q');
            }
            match rest[1] {
                b'A' => Key::Up,
                b'B' => Key::Down,
                b'C' => Key::Right,
                b'D' => Key::Left,
                _ => Key::Other,
            }
        }
        b'\r' | b'\n' => Key::Enter,
        c => Key::Char(c as char),
    }
}
fn choices(key: &str, devices: &[String]) -> Vec<String> {
    if key == "device" {
        return devices.iter().map(|d| format!("cuda:{d}")).collect();
    }
    config::setting(key)
        .map(|s| s.values.iter().map(|v| v.to_string()).collect())
        .unwrap_or_default()
}
fn flatten(d: &device::Device, out: &mut Vec<String>) {
    out.push(d.path.clone());
    for c in &d.children {
        flatten(c, out);
    }
}
fn wrap(text: &str, width: usize) -> Vec<String> {
    let mut lines = vec![];
    let mut line = String::new();
    for word in text.split_whitespace() {
        if !line.is_empty() && line.len() + 1 + word.len() > width {
            lines.push(std::mem::take(&mut line));
        }
        if !line.is_empty() {
            line.push(' ');
        }
        line.push_str(word);
    }
    if !line.is_empty() {
        lines.push(line);
    }
    lines
}
struct Ui {
    values: BTreeMap<String, String>,
    devices: Vec<String>,
    header: Vec<String>,
    row: usize,
    dirty: bool,
    message: String,
}
impl Ui {
    fn draw(&self) {
        let mut s = String::new();
        s.push_str(CLEAR);
        s.push_str(&at(1, 1));
        s.push_str(&format!("{BOLD}zlift{OFF} {DIM}— CUDA on this machine's GPU{OFF}\r\n"));
        for h in &self.header {
            s.push_str(&format!("{DIM}  {h}{OFF}\r\n"));
        }
        s.push_str("\r\n");
        for (i, setting) in config::SETTINGS.iter().enumerate() {
            let set = self.values.get(setting.key).cloned().unwrap_or_default();
            let shown = if set.is_empty() {
                format!("{}", setting.default)
            } else {
                set
            };
            let marker = if i == self.row { "›" } else { " " };
            let body = format!(" {marker} {:<22} {:<20} ", setting.key, shown);
            if i == self.row {
                s.push_str(&format!("{REV}{body}{OFF}\r\n"));
            } else {
                s.push_str(&format!("{body}\r\n"));
            }
        }
        s.push_str("\r\n");
        if let Some(sel) = config::SETTINGS.get(self.row) {
            s.push_str(&format!("  {BOLD}{}{OFF}\r\n", sel.summary));
            for line in wrap(sel.detail, 72) {
                s.push_str(&format!("  {DIM}{line}{OFF}\r\n"));
            }
            let ch = choices(sel.key, &self.devices);
            if !ch.is_empty() {
                let shown: Vec<String> = ch
                    .iter()
                    .map(|v| if v.is_empty() { "(unset)".into() } else { v.clone() })
                    .collect();
                s.push_str(&format!("\r\n  {DIM}choices:{OFF} {}\r\n", shown.join("  ")));
            }
        }
        s.push_str("\r\n");
        if !self.message.is_empty() {
            s.push_str(&format!("  {BOLD}{}{OFF}\r\n", self.message));
        }
        let star = if self.dirty { " *unsaved*" } else { "" };
        s.push_str(&format!(
            "{DIM}  ↑↓ move   ←→ change   e type a value   s save{star}   d daemon   q quit{OFF}\r\n"
        ));
        print!("{s}");
        let _ = std::io::stdout().flush();
    }
    fn cycle(&mut self, delta: isize) {
        let Some(sel) = config::SETTINGS.get(self.row) else { return };
        let ch = choices(sel.key, &self.devices);
        if ch.is_empty() {
            self.message = format!("{} takes a value; press e", sel.key);
            return;
        }
        let cur = self.values.get(sel.key).cloned().unwrap_or_default();
        let at = ch.iter().position(|v| *v == cur).unwrap_or(0) as isize;
        let next = ((at + delta).rem_euclid(ch.len() as isize)) as usize;
        let v = ch[next].clone();
        if v.is_empty() {
            self.values.remove(sel.key);
        } else {
            self.values.insert(sel.key.to_string(), v);
        }
        self.dirty = true;
        self.message.clear();
    }
    fn type_value(&mut self) {
        let Some(sel) = config::SETTINGS.get(self.row) else { return };
        stty(&["sane"]);
        print!("{SHOW}{CLEAR}{}", at(1, 1));
        println!("  {}\n  {}\n", sel.key, sel.summary);
        print!("  value (empty clears it): ");
        let _ = std::io::stdout().flush();
        let mut line = String::new();
        let _ = std::io::stdin().read_line(&mut line);
        let v = line.trim().to_string();
        if v.is_empty() {
            self.values.remove(sel.key);
        } else {
            self.values.insert(sel.key.to_string(), v);
        }
        self.dirty = true;
        stty(&["raw", "-echo"]);
        print!("{HIDE}");
    }
}
pub fn run(root: &std::path::Path) -> i32 {
    if !is_tty() {
        return crate::cmd_config_public(&[]);
    }
    let machine = device::survey(root);
    let mut devices = vec![];
    for d in &machine.devices {
        flatten(d, &mut devices);
    }
    let header = vec![
        match &machine.cuda {
            Ok((n, v)) => format!(
                "{} device{} as CUDA {v}",
                n.len(),
                if n.len() == 1 { "" } else { "s" }
            ),
            Err(e) => format!("driver unavailable — {e}"),
        },
        machine
            .devices
            .first()
            .map(|d| {
                format!(
                    "{} · {:.2} GiB · sub-groups {}",
                    d.name,
                    d.memory_gib(),
                    d.sub_group_sizes
                        .iter()
                        .map(|v| v.to_string())
                        .collect::<Vec<_>>()
                        .join(",")
                )
            })
            .unwrap_or_else(|| "no device".into()),
        format!("daemon: {}", daemon::status_line()),
    ];
    let mut ui = Ui {
        values: config::load(),
        devices,
        header,
        row: 0,
        dirty: false,
        message: String::new(),
    };
    stty(&["raw", "-echo"]);
    print!("{ALT_ON}{HIDE}");
    let code = 0;
    loop {
        ui.draw();
        match read_key() {
            Key::Up | Key::Char('k') => {
                ui.row = if ui.row == 0 { config::SETTINGS.len() - 1 } else { ui.row - 1 };
                ui.message.clear();
            }
            Key::Down | Key::Char('j') => {
                ui.row = (ui.row + 1) % config::SETTINGS.len();
                ui.message.clear();
            }
            Key::Right | Key::Char('l') | Key::Enter | Key::Char(' ') => ui.cycle(1),
            Key::Left | Key::Char('h') => ui.cycle(-1),
            Key::Char('e') => ui.type_value(),
            Key::Char('s') => {
                ui.message = match config::save(&ui.values) {
                    Ok(()) => {
                        ui.dirty = false;
                        format!("saved to {}", config::path().display())
                    }
                    Err(e) => format!("could not save: {e}"),
                };
            }
            Key::Char('d') => {
                ui.message = if daemon::ask("PING").is_ok() {
                    daemon::ask("STOP").ok();
                    "daemon stopped".into()
                } else {
                    let exe = std::env::current_exe().unwrap_or_default();
                    let _ = std::process::Command::new(exe)
                        .arg("daemon")
                        .stdout(std::process::Stdio::null())
                        .stderr(std::process::Stdio::null())
                        .status();
                    daemon::status_line()
                };
                ui.header[2] = format!("daemon: {}", daemon::status_line());
            }
            Key::Char('q') | Key::Char('\u{3}') => {
                if ui.dirty {
                    ui.message = "unsaved — press s to save, q again to discard".into();
                    ui.dirty = false; 
                    continue;
                }
                break;
            }
            _ => {}
        }
    }
    print!("{SHOW}{ALT_OFF}");
    let _ = std::io::stdout().flush();
    stty(&["sane"]);
    code
}
