// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::Serialize;

#[derive(Default, Serialize)]
struct Channel {
    name: String,
}

#[derive(Default, Serialize)]
struct Fixture {
    name: String,
    channels: Vec<Channel>,
}

#[tauri::command]
fn get_fixtures() -> Vec<Fixture> {
    vec![
        Fixture {
            name: "SMD 132 Pro strobe".to_string(),
            channels: vec![
                Channel {
                    name: "Red".to_string(),
                },
                Channel {
                    name: "Green".to_string(),
                },
                Channel {
                    name: "Blue".to_string(),
                },
            ],
        }
    ]
}

fn main() {
    tauri::Builder::default()
        .manage(Fixture::default())
        .invoke_handler(tauri::generate_handler![
                        get_fixtures
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
