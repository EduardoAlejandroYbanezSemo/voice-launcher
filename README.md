# 🎮 Voice Launcher

**Lanzador de juegos controlado por voz para Raspberry Pi** con reconocimiento de voz offline.

[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-A22846?style=for-the-badge&logo=raspberry-pi&logoColor=white)](https://www.raspberrypi.org/)
[![Tauri](https://img.shields.io/badge/Tauri-FFC131?style=for-the-badge&logo=tauri&logoColor=black)](https://tauri.app/)
[![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://www.rust-lang.org/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)

## ✨ Características

- 🎙️ **Reconocimiento de voz offline** usando [Vosk](https://alphacephei.com/vosk/)
- 🚀 **Interfaz rápida y ligera** con Tauri (React + Rust)
- 🎮 **Biblioteca de juegos personalizable** mediante JSON
- 🔊 **Síntesis de voz** para respuestas del sistema
- ⚙️ **Configuración dinámica** sin recompilar
- 🖼️ **Carátulas de juegos** personalizables
- 📱 **Diseño moderno** con iconos SVG

## 🎬 Demo

![Voice Launcher Demo](https://via.placeholder.com/800x450/1a1a1a/00ff00?text=Voice+Launcher+Demo)

## 🚀 Instalación Rápida

### Requisitos
- Raspberry Pi 3B+ o superior
- Raspberry Pi OS (Bullseye o superior)
- Micrófono USB o integrado
- 2GB RAM mínimo

### Scripts Automáticos

```bash
# 1. Descargar modelo de voz
chmod +x download-vosk-model.sh
./download-vosk-model.sh

# 2. Compilar aplicación (~15-30 min)
chmod +x install-raspberry.sh
./install-raspberry.sh

# 3. Instalar paquete
chmod +x post-install.sh
./post-install.sh
```

Ver guía detallada: **[INSTALL-QUICK.md](INSTALL-QUICK.md)**

## 🎙️ Uso

### Palabra de Activación
Di **"Carrito"** para activar el sistema. El micrófono se pondrá rojo 🔴

### Comandos Disponibles

| Comando | Acción |
|---------|--------|
| `"Listar juegos"` | Muestra tu biblioteca de aplicaciones |
| `"Abrir [nombre]"` | Lanza una aplicación o juego |
| `"Qué hora es"` | Te dice la hora actual |
| `"Apagar consola"` | Apaga el sistema |

### Ejemplos de Uso

- **"Carrito... Abrir Chrome"** - Abre el navegador
- **"Carrito... Abrir terminal"** - Abre la terminal
- **"Carrito... Abrir calculadora"** - Abre la calculadora
- **"Carrito... Listar juegos"** - Muestra todas las apps disponibles
- **"Carrito... Qué hora es"** - Te dice la hora

## ⚙️ Configuración

### 📋 Comandos (`commands.json`)

Define las palabras clave que el sistema reconocerá:

```json
{
  "actions": [
    {
      "name": "launch",
      "keywords": ["abrir", "jugar", "ejecutar", "pon", "lanza"],
      "response": "Abriendo {target}...",
      "emit": "game-launch"
    },
    {
      "name": "time",
      "keywords": ["qué hora es", "hora", "dime la hora"],
      "response": "{time}",
      "emit": "time-info"
    }
  ]
}
```

### 🎮 Biblioteca (`games.json`)

Define tus aplicaciones, juegos, rutas y carátulas:

```json
[
  {
    "id": "chrome",
    "name": "Google Chrome",
    "keywords": ["chrome", "navegador", "internet"],
    "cmd": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "image": ""
  },
  {
    "id": "terminal",
    "name": "Terminal",
    "keywords": ["terminal", "consola", "powershell"],
    "cmd": "wt.exe",
    "image": ""
  },
  {
    "id": "pokemon",
    "name": "Pokemon Luna",
    "keywords": ["pokemon", "luna"],
    "cmd": "/usr/games/citra-qt /home/pi/roms/pokemon_moon.3ds",
    "image": "/home/pi/.local/share/voice-launcher/images/pokemon.png"
  }
]
```

**Nota:** Puedes agregar cualquier aplicación, no solo juegos. El archivo se llama `games.json` por tradición, pero acepta cualquier ejecutable.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────┐
│           Frontend (React + TypeScript)         │
│  - Interfaz de usuario                          │
│  - Visualización de biblioteca                  │
│  - Historial de comandos con iconos SVG        │
└─────────────────┬───────────────────────────────┘
                  │ IPC Events
┌─────────────────▼───────────────────────────────┐
│              Backend (Rust + Tauri)             │
│  - Gestión de comandos                          │
│  - Lanzamiento de procesos                      │
│  - Comunicación con motor de voz                │
└─────────────────┬───────────────────────────────┘
                  │ Stdin/Stdout
┌─────────────────▼───────────────────────────────┐
│          Motor de Voz (Python + Vosk)           │
│  - Reconocimiento de voz offline                │
│  - Síntesis de voz (pyttsx3)                    │
│  - Detección de palabra de activación          │
└─────────────────────────────────────────────────┘
```

## 🛠️ Tecnologías

### Frontend
- **React 19** - UI Library
- **TypeScript** - Type Safety
- **Vite** - Build Tool

### Backend
- **Rust** - Sistema backend
- **Tauri 2** - Framework de aplicaciones
- **Chrono** - Gestión de fechas/hora

### Motor de Voz
- **Python 3** - Scripting
- **Vosk** - Reconocimiento de voz offline
- **PyAudio** - Captura de audio
- **pyttsx3** - Síntesis de voz

## 📁 Estructura del Proyecto

```
voice-launcher/
├── src/                        # Frontend React
│   ├── components/
│   │   └── Icons.tsx          # Iconos SVG
│   ├── App.tsx                # Componente principal
│   └── App.css                # Estilos
├── src-tauri/                 # Backend Rust
│   ├── src/
│   │   └── main.rs           # Lógica principal
│   └── tauri.conf.json       # Configuración Tauri
├── src-python/                # Motor de voz Python
│   ├── app.py                # Script principal
│   ├── model/                # Modelo Vosk (descargar)
│   └── requirements.txt      # Dependencias Python
├── commands.json              # Configuración de comandos
├── games.json                 # Biblioteca de juegos
├── download-vosk-model.sh     # Descarga modelo de voz
├── install-raspberry.sh       # Script de compilación
└── post-install.sh            # Script de instalación
```

## 🐛 Solución de Problemas

### El micrófono no funciona
```bash
# Listar dispositivos de audio
arecord -l

# Ajustar configuración
alsamixer
```

### No reconoce mi voz
- Habla claro y cerca del micrófono
- Descarga un modelo Vosk más grande si es necesario
- Verifica el nivel de volumen del micrófono

### Error al compilar
```bash
# Verificar dependencias
sudo apt install -y libwebkit2gtk-4.0-dev build-essential

# Limpiar y recompilar
cd src-tauri
cargo clean
cargo build
```

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Si encuentras un bug o tienes una idea:

1. Abre un **Issue** describiendo el problema o feature
2. Haz un **Fork** del proyecto
3. Crea una **rama** para tu feature (`git checkout -b feature/AmazingFeature`)
4. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
5. **Push** a la rama (`git push origin feature/AmazingFeature`)
6. Abre un **Pull Request**

## 📝 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 🙏 Créditos

- **[Vosk](https://alphacephei.com/vosk/)** - Motor de reconocimiento de voz
- **[Tauri](https://tauri.app/)** - Framework de aplicaciones
- **[React](https://react.dev/)** - Biblioteca UI

## 📧 Contacto

¿Preguntas? Abre un [Issue](https://github.com/EduardoAlejandroYbanezSemo/voice-launcher/issues)

---

**Hecho con ❤️ para la comunidad Raspberry Pi**
