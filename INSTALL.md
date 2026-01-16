# 🚀 Voice Launcher - Guía de Instalación y Despliegue

Este es un lanzador de juegos controlado por voz diseñado para Raspberry Pi (OS de 64 o 32 bits). Utiliza **Tauri (Rust)** para la interfaz y un **Sidecar (Python)** para el procesamiento de voz offline.

---

## ⚡ Instalación Rápida (Recomendado)

**Si estás en Raspberry Pi OS**, usa los scripts automatizados:

```bash
# 1. Descargar modelo de voz
./download-vosk-model.sh

# 2. Compilar aplicación
./install-raspberry.sh

# 3. Instalar paquete
./post-install.sh
```

Ver más detalles en: **[INSTALL-QUICK.md](INSTALL-QUICK.md)**

---

## 📖 Instalación Manual

Si prefieres hacerlo paso a paso o entender el proceso:

---

## 🛠️ Requisitos en la Raspberry Pi

Antes de compilar, instala las dependencias de sistema necesarias para el audio y la interfaz gráfica:

```bash
sudo apt update
sudo apt install -y python3-pyaudio libespeak1 portaudio19-dev libasound2-dev libgtk-3-dev libsoup2.4-dev libwebkit2gtk-4.0-dev build-essential curl wget libssl-dev
```

---

## 🏗️ Paso 1: Compilar el Motor de Voz (Sidecar)

Para que el launcher sea un único instalador sin dependencias, "congelamos" el script de Python:

1. Entra en `src-python/`.
2. Prepara el entorno:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   pip install pyinstaller
   ```
3. Genera el binario (incluye el modelo Vosk y las librerías):
   ```bash
   pyinstaller --clean --name voice-engine --add-data "model:model" --collect-all vosk --onefile app.py
   ```
4. Muévelo a la carpeta de binarios de Tauri con el nombre de arquitectura correcto:
   ```bash
   mkdir -p ../src-tauri/binaries
   # Para Raspberry Pi 64 bits:
   mv dist/voice-engine ../src-tauri/binaries/voice-engine-aarch64-unknown-linux-gnu
   ```

---

## 📦 Paso 2: Crear el Instalador .DEB

Desde la raíz del proyecto:

```bash
npm install
npm run tauri build
```
El instalador se generará en: `src-tauri/target/release/bundle/deb/voice-launcher_0.1.0_arm64.deb`.

---

## ⚙️ Configuración Dinámica (FTP Friendly)

El lanzador lee dos archivos JSON que puedes modificar sin tocar el código. Para que sean fáciles de editar por FTP, asegúrate de que estén en la misma carpeta que el ejecutable:

### 1. `commands.json` (Voz y Acciones)
Define las palabras clave y qué debe responder el lanzador.
- **Acciones soportadas:** `launch` (abrir juegos), `list` (ver catálogo), `shutdown` (apaga la consola con `shutdown now`).
- **Emit:** El evento que se envía al frontend.

### 2. `games.json` (Tu Biblioteca)
Define tus juegos, sus comandos de ejecución y sus imágenes.
- **Keywords:** Palabras alternativas para que te entienda mejor (ej: "mario", "fontanero").
- **Image:** Ruta a la imagen (en `public/` o ruta absoluta).

---

## 🎙️ Uso del Lanzador

1. **Palabra de activación:** Di **"Carrito"**.
2. **Estado:** El icono del micrófono se pondrá en rojo y el sistema dirá "¿Dime?".
3. **Comandos:**
   - *"Listar juegos"* -> Muestra el catálogo (se cierra a los 15s de inactividad).
   - *"Abrir [Nombre/Keyword]"* -> Lanza el ejecutable configurado.
   - *"Apagar consola"* -> Ejecuta el apagado del sistema.

---

## 🛡️ Notas de Seguridad
El archivo `tauri.conf.json` tiene configurada una política de seguridad (CSP) que permite cargar imágenes locales desde el disco. Esto es vital para que las carátulas de los juegos que subas por FTP se vean correctamente.