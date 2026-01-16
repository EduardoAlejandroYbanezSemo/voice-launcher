#!/bin/bash
# 🚀 Voice Launcher - Script de Instalación para Raspberry Pi OS
# Este script automatiza todo el proceso de compilación e instalación

set -e  # Detener en caso de error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🎮 Voice Launcher - Instalación para Raspberry Pi       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Detectar arquitectura
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    TARGET_ARCH="aarch64-unknown-linux-gnu"
    echo -e "${GREEN}✓${NC} Arquitectura detectada: ARM64 (aarch64)"
elif [ "$ARCH" = "armv7l" ]; then
    TARGET_ARCH="armv7-unknown-linux-gnueabihf"
    echo -e "${GREEN}✓${NC} Arquitectura detectada: ARM32 (armv7l)"
else
    echo -e "${RED}✗${NC} Arquitectura no soportada: $ARCH"
    exit 1
fi

# Función para verificar comandos
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗${NC} $1 no encontrado"
        return 1
    else
        echo -e "${GREEN}✓${NC} $1 encontrado"
        return 0
    fi
}

# ==============================================================================
# PASO 1: Verificar e instalar dependencias del sistema
# ==============================================================================
echo ""
echo -e "${BLUE}[1/5]${NC} Instalando dependencias del sistema..."

sudo apt update
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-pyaudio \
    libespeak1 \
    portaudio19-dev \
    libasound2-dev \
    libgtk-3-dev \
    libsoup2.4-dev \
    libwebkit2gtk-4.0-dev \
    build-essential \
    curl \
    wget \
    libssl-dev \
    file \
    libglib2.0-dev \
    libjavascriptcoregtk-4.0-dev \
    libayatana-appindicator3-dev

echo -e "${GREEN}✓${NC} Dependencias del sistema instaladas"

# ==============================================================================
# PASO 2: Instalar Node.js y npm (si no están)
# ==============================================================================
echo ""
echo -e "${BLUE}[2/5]${NC} Verificando Node.js y npm..."

if ! check_command node || ! check_command npm; then
    echo -e "${YELLOW}→${NC} Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    echo -e "${GREEN}✓${NC} Node.js instalado"
fi

# ==============================================================================
# PASO 3: Instalar Rust y Cargo
# ==============================================================================
echo ""
echo -e "${BLUE}[3/5]${NC} Verificando Rust..."

if ! check_command cargo; then
    echo -e "${YELLOW}→${NC} Instalando Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo -e "${GREEN}✓${NC} Rust instalado"
fi

# ==============================================================================
# PASO 4: Compilar el motor de voz (sidecar)
# ==============================================================================
echo ""
echo -e "${BLUE}[4/5]${NC} Compilando motor de voz..."

cd src-python

# Verificar que existe el modelo de Vosk
if [ ! -d "model" ]; then
    echo -e "${RED}✗${NC} No se encontró el modelo de Vosk en src-python/model/"
    echo -e "${YELLOW}→${NC} Descarga un modelo desde: https://alphacephei.com/vosk/models"
    echo -e "${YELLOW}→${NC} Modelo recomendado: vosk-model-small-es-0.42"
    echo -e "${YELLOW}→${NC} Descomprime y renombra la carpeta a 'model'"
    exit 1
fi

# Crear entorno virtual
echo -e "${YELLOW}→${NC} Creando entorno virtual de Python..."
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
echo -e "${YELLOW}→${NC} Instalando dependencias de Python..."
pip install --upgrade pip
pip install -r requirements.txt
pip install pyinstaller

# Compilar con PyInstaller
echo -e "${YELLOW}→${NC} Compilando binario con PyInstaller..."
pyinstaller --clean --name voice-engine --add-data "model:model" --collect-all vosk --onefile app.py

# Mover el binario
mkdir -p ../src-tauri/binaries
mv dist/voice-engine "../src-tauri/binaries/voice-engine-${TARGET_ARCH}"
chmod +x "../src-tauri/binaries/voice-engine-${TARGET_ARCH}"

deactivate
cd ..

echo -e "${GREEN}✓${NC} Motor de voz compilado: voice-engine-${TARGET_ARCH}"

# ==============================================================================
# PASO 5: Compilar la aplicación Tauri
# ==============================================================================
echo ""
echo -e "${BLUE}[5/5]${NC} Compilando aplicación Tauri..."

# Instalar dependencias de npm
echo -e "${YELLOW}→${NC} Instalando dependencias de Node.js..."
npm install

# Compilar aplicación
echo -e "${YELLOW}→${NC} Compilando aplicación (esto puede tardar varios minutos)..."
npm run build
cd src-tauri
cargo tauri build
cd ..

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ COMPILACIÓN COMPLETADA                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📦 Paquete .DEB generado en:${NC}"

if [ "$ARCH" = "aarch64" ]; then
    DEB_PATH="src-tauri/target/release/bundle/deb/voice-launcher_0.1.0_arm64.deb"
else
    DEB_PATH="src-tauri/target/release/bundle/deb/voice-launcher_0.1.0_armhf.deb"
fi

echo -e "   ${BLUE}${DEB_PATH}${NC}"
echo ""
echo -e "${YELLOW}Para instalarlo:${NC}"
echo -e "   ${GREEN}sudo dpkg -i ${DEB_PATH}${NC}"
echo ""
echo -e "${YELLOW}O ejecuta el script de post-instalación:${NC}"
echo -e "   ${GREEN}./post-install.sh${NC}"
echo ""
