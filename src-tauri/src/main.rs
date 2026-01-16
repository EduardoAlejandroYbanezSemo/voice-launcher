#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

use serde::{Deserialize, Serialize};
use serde_json::json;
use std::fs;
use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use std::sync::{Arc, Mutex};
use std::thread;
use tauri::{Emitter, Listener};
use tauri_plugin_shell::process::CommandEvent;
use tauri_plugin_shell::ShellExt;
use chrono::{Local, Timelike};

#[derive(Debug, Deserialize, Serialize, Clone)]
struct VoiceMessage {
    #[serde(rename = "type")]
    msg_type: String,
    text: Option<String>,
    message: Option<String>,
}

#[derive(Debug, Deserialize, Clone)]
struct CommandAction {
    name: String,
    keywords: Vec<String>,
    response: String,
    emit: String,
}

#[derive(Debug, Deserialize, Clone)]
struct CommandsConfig {
    actions: Vec<CommandAction>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct Game {
    id: String,
    name: String,
    keywords: Option<Vec<String>>,
    cmd: String,
    image: Option<String>,
}

#[derive(Debug, Clone)]
struct AppConfig {
    commands: CommandsConfig,
    games: Vec<Game>,
}

type SenderHandle = Arc<Mutex<Option<std::sync::mpsc::Sender<String>>>>;

fn main() {
    let (tx_main, rx_main) = std::sync::mpsc::channel::<String>();
    let sidecar_handle: SenderHandle = Arc::new(Mutex::new(Some(tx_main)));
    let handle_for_setup = sidecar_handle.clone();

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .setup(move |app| {
            let app_handle = app.handle().clone();
            let commands_cfg = load_commands();
            let games_list = load_games();

            let config = AppConfig {
                commands: commands_cfg,
                games: games_list.clone(),
            };

            let app_handle_clone = app_handle.clone();
            let games_clone = games_list.clone();
            app.listen("request-games", move |_| {
                let _ = app_handle_clone.emit("games-list", &games_clone);
            });

            let handle_for_thread = handle_for_setup.clone();
            let app_handle_for_shell = app_handle.clone();

            thread::spawn(move || {
                if cfg!(debug_assertions) {
                    println!("🛠️ MODO DESARROLLO");
                    
                    #[cfg(target_os = "windows")]
                    let script_name = "run_voice.bat";
                    #[cfg(not(target_os = "windows"))]
                    let script_name = "run_voice.sh";

                    let mut script_path = std::path::PathBuf::from(format!("src-python/{}", script_name));
                    if !script_path.exists() {
                        script_path = std::path::PathBuf::from(format!("../src-python/{}", script_name));
                    }

                    // Forzar ruta absoluta
                    let abs_script_path = std::fs::canonicalize(&script_path).expect("No se pudo encontrar el script de voz");
                    println!("🚀 Lanzando script: {:?}", abs_script_path);

                    #[cfg(target_os = "windows")]
                    let mut child = {
                        use std::os::windows::process::CommandExt;
                        const CREATE_NO_WINDOW: u32 = 0x08000000;
                        Command::new(abs_script_path.to_str().unwrap())
                            .stdout(Stdio::piped())
                            .stderr(Stdio::piped())
                            .stdin(Stdio::piped())
                            .creation_flags(CREATE_NO_WINDOW)
                            .spawn()
                            .expect("Fallo al spawnear proceso de voz")
                    };

                    #[cfg(not(target_os = "windows"))]
                    let mut child = Command::new(abs_script_path.to_str().unwrap())
                        .stdout(Stdio::piped())
                        .stderr(Stdio::piped())
                        .stdin(Stdio::piped())
                        .spawn()
                        .expect("Fallo al spawnear proceso de voz");
                    
                    let mut stdin = child.stdin.take().expect("Fallo al abrir stdin");
                    thread::spawn(move || {
                        while let Ok(msg) = rx_main.recv() {
                            let _ = writeln!(stdin, "{}", msg);
                            let _ = stdin.flush();
                        }
                    });

                    let stdout = child.stdout.take().unwrap();
                    let reader = BufReader::new(stdout);
                    for line in reader.lines() {
                        if let Ok(l) = line {
                            if let Ok(json_msg) = serde_json::from_str::<VoiceMessage>(&l) {
                                handle_voice_message(&app_handle, json_msg, &config, &handle_for_thread);
                            } else {
                                println!("[PYTHON]: {}", l);
                            }
                        }
                    }
                } else {
                    println!("🚀 MODO RELEASE");
                    let shell = app_handle_for_shell.shell();
                    let command = shell.sidecar("voice-engine").expect("Fallo sidecar");
                    let (mut rx, mut child) = command.spawn().expect("Fallo spawn sidecar");

                    thread::spawn(move || {
                        while let Ok(msg) = rx_main.recv() {
                            let _ = child.write(format!("{}\n", msg).as_bytes());
                        }
                    });

                    while let Some(event) = rx.blocking_recv() {
                        match event {
                            CommandEvent::Stdout(line_bytes) => {
                                let line = String::from_utf8_lossy(&line_bytes);
                                for single_line in line.lines() {
                                    if let Ok(json_msg) = serde_json::from_str::<VoiceMessage>(single_line) {
                                        handle_voice_message(&app_handle, json_msg, &config, &handle_for_thread);
                                    }
                                }
                            }
                            _ => {}
                        }
                    }
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error running tauri application");
}

fn load_commands() -> CommandsConfig {
    // Construir ruta de usuario
    let home_dir = std::env::var("HOME").unwrap_or_default();
    let user_config = format!("{}/.config/voice-launcher/commands.json", home_dir);
    
    // Buscar en múltiples ubicaciones
    let paths = vec![
        "commands.json",                                    // Directorio actual (dev)
        "../commands.json",                                 // Directorio padre (dev)
        "/etc/voice-launcher/commands.json",                // Sistema (producción)
        user_config.as_str(),                               // Usuario (producción)
    ];
    
    for path in paths {
        if let Ok(content) = fs::read_to_string(path) {
            if let Ok(config) = serde_json::from_str::<CommandsConfig>(&content) { 
                println!("✓ Cargado commands.json desde: {}", path);
                return config; 
            }
        }
    }
    
    println!("⚠ No se encontró commands.json, usando configuración vacía");
    CommandsConfig { actions: vec![] }
}

fn load_games() -> Vec<Game> {
    // Construir ruta de usuario
    let home_dir = std::env::var("HOME").unwrap_or_default();
    let user_config = format!("{}/.config/voice-launcher/games.json", home_dir);
    
    // Buscar en múltiples ubicaciones
    let paths = vec![
        "games.json",                                    // Directorio actual (dev)
        "../games.json",                                 // Directorio padre (dev)
        "/etc/voice-launcher/games.json",                // Sistema (producción)
        user_config.as_str(),                            // Usuario (producción)
    ];
    
    for path in paths {
        if let Ok(content) = fs::read_to_string(path) {
            if let Ok(games) = serde_json::from_str::<Vec<Game>>(&content) { 
                println!("✓ Cargado games.json desde: {}", path);
                return games; 
            }
        }
    }
    
    println!("⚠ No se encontró games.json, usando lista vacía");
    vec![]
}

fn handle_voice_message(app: &tauri::AppHandle, msg: VoiceMessage, config: &AppConfig, handle: &SenderHandle) {
    match msg.msg_type.as_str() {
        "ready" => { let _ = app.emit("voice-status", "ready"); },
        "wake_word" => { let _ = app.emit("voice-status", "listening"); },
        "command" => {
            if let Some(cmd_text) = msg.text {
                process_dynamic_command(app, &cmd_text, config, handle);
            }
        },
        _ => (),
    }
}

fn process_dynamic_command(app: &tauri::AppHandle, text: &str, config: &AppConfig, handle: &SenderHandle) {
    let text_lower = text.to_lowercase();
    for action in &config.commands.actions {
        for keyword in &action.keywords {
            if text_lower.contains(keyword) {
                let mut response = action.response.clone();
                let mut target_name = String::new();
                let mut target_game: Option<&Game> = None;

                if action.name == "launch" {
                    for game in &config.games {
                        if text_lower.contains(&game.id) || text_lower.contains(&game.name.to_lowercase()) {
                            target_game = Some(game);
                            break;
                        }
                        if let Some(keywords) = &game.keywords {
                            for k in keywords {
                                if text_lower.contains(&k.to_lowercase()) { target_game = Some(game); break; }
                            }
                        }
                        if target_game.is_some() { break; }
                    }
                    if let Some(game) = target_game {
                         response = response.replace("{target}", &game.name);
                         target_name = game.name.clone();
                         println!("🚀 EJECUTANDO: {}", game.cmd);
                         
                         // Lanzar el comando
                         #[cfg(target_os = "windows")]
                         {
                             let _ = Command::new("cmd")
                                 .args(["/C", &game.cmd])
                                 .spawn();
                         }
                         
                         #[cfg(not(target_os = "windows"))]
                         {
                             let _ = Command::new("sh")
                                 .args(["-c", &game.cmd])
                                 .spawn();
                         }
                    } else {
                        let raw_target = text_lower.replace(keyword, "").trim().to_string();
                        response = format!("No encuentro el juego {} en tu biblioteca.", raw_target);
                    }
                } else if action.name == "shutdown" {
                    #[cfg(target_os = "windows")]
                    let _ = Command::new("shutdown").args(["/s", "/t", "0"]).spawn();
                    #[cfg(not(target_os = "windows"))]
                    let _ = Command::new("sudo").args(["shutdown", "now"]).spawn();
                } else if action.name == "time" {
                    let now = Local::now();
                    let time_str = format!("Son las {} horas y {} minutos", now.hour(), now.minute());
                    response = response.replace("{time}", &time_str);
                }

                speak_through_python(handle, &response);
                let _ = app.emit(&action.emit, target_name);
                let _ = app.emit("command-executed", response);
                if action.name == "list" { let _ = app.emit("games-list", &config.games); }
                return;
            }
        }
    }
    let error_msg = "No he entendido esa orden";
    speak_through_python(handle, error_msg);
    let _ = app.emit("command-error", error_msg);
}

fn speak_through_python(handle: &SenderHandle, text: &str) {
    let msg = json!({ "type": "speak", "text": text });
    if let Ok(json_str) = serde_json::to_string(&msg) {
        if let Ok(guard) = handle.lock() {
            if let Some(tx) = &*guard { let _ = tx.send(json_str); }
        }
    }
}
