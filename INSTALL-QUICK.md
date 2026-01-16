# 🎮 Voice Launcher - Instalación Rápida

Lanzador de juegos controlado por voz para Raspberry Pi OS.

## 🚀 Instalación en 3 Pasos

### 1️⃣ Descargar el modelo de voz
```bash
chmod +x download-vosk-model.sh
./download-vosk-model.sh
```

### 2️⃣ Compilar e instalar
```bash
chmod +x install-raspberry.sh
./install-raspberry.sh
```
⏱️ *Esto tardará entre 15-30 minutos dependiendo del modelo de Raspberry Pi*

### 3️⃣ Instalar el paquete
```bash
chmod +x post-install.sh
./post-install.sh
```

## ✅ ¡Listo!

Ejecuta desde el menú de aplicaciones o desde terminal:
```bash
voice-launcher
```

---

## 🎙️ Cómo usar

1. **Palabra de activación:** Di **"Carrito"**
2. El micrófono se pondrá rojo 🔴
3. **Comandos disponibles:**
   - *"Listar juegos"* - Muestra tu biblioteca de aplicaciones
   - *"Abrir [nombre]"* - Lanza una app o juego
   - *"Qué hora es"* - Te dice la hora actual
   - *"Apagar consola"* - Apaga el sistema

**Ejemplos:**
- "Carrito... Abrir terminal"
- "Carrito... Abrir Chrome"
- "Carrito... Listar juegos"

---

## ⚙️ Configuración

Edita los archivos JSON para personalizar:

### 📋 `commands.json` - Comandos de voz
```json
{
  "actions": [
    {
      "name": "launch",
      "keywords": ["abrir", "jugar", "ejecutar"],
      "response": "Abriendo {target}...",
      "emit": "game-launch"
    }
  ]
}
```

### 🎮 `games.json` - Tu biblioteca
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
    "id": "pokemon",
    "name": "Pokemon Esmeralda",
    "keywords": ["pokemon", "esmeralda"],
    "cmd": "/usr/games/mgba-qt /home/pi/roms/pokemon.gba",
    "image": "/home/pi/.local/share/voice-launcher/images/pokemon.png"
  }
]
```

**Puedes agregar cualquier aplicación:** juegos, navegadores, editores, etc.

**Ubicación de archivos:**
- Configuración: `~/.config/voice-launcher/commands.json` y `~/.config/voice-launcher/games.json`
- Imágenes: `~/.local/share/voice-launcher/images/`

**Para editar tu biblioteca:**
```bash
nano ~/.config/voice-launcher/games.json
```

---

## 🛠️ Solución de Problemas

### El micrófono no funciona
```bash
# Verificar dispositivos de audio
arecord -l

# Configurar dispositivo por defecto
alsamixer
```

### No reconoce mi voz
- Habla claro y cerca del micrófono
- El modelo es optimizado, puede tener limitaciones
- Descarga un modelo más grande desde: https://alphacephei.com/vosk/models

### La aplicación no se abre
```bash
# Ejecutar desde terminal para ver errores
voice-launcher
```

---

## 📁 Estructura del Proyecto

```
voice-launcher/
├── src/                    # Frontend (React + Vite)
├── src-tauri/              # Backend (Rust + Tauri)
├── src-python/             # Motor de voz (Python + Vosk)
│   └── model/              # Modelo de reconocimiento de voz
├── commands.json           # Configuración de comandos
├── games.json              # Biblioteca de juegos
├── download-vosk-model.sh  # Descarga el modelo
├── install-raspberry.sh    # Script de compilación
└── post-install.sh         # Script de instalación
```

---

## 📝 Notas

- **Arquitectura soportada:** ARM64 (aarch64) y ARM32 (armv7l)
- **Sistema operativo:** Raspberry Pi OS (Debian Bullseye o superior)
- **Requisitos de hardware:** 
  - Raspberry Pi 3B+ o superior
  - Micrófono USB o micrófono integrado
  - 2GB RAM mínimo recomendado

---

## 🔗 Enlaces Útiles

- **Modelos de Vosk:** https://alphacephei.com/vosk/models
- **Documentación Tauri:** https://tauri.app/
- **Reportar problemas:** [GitHub Issues]

---

**Desarrollado con ❤️ para Raspberry Pi**
