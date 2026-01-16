import os
import sys
import json
import pyaudio
import pyttsx3
import threading
from vosk import Model, KaldiRecognizer

# Configuración de Logs y Rutas
class DevNull:
    def write(self, msg): pass
    def flush(self): pass

sys.stderr = DevNull()
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(SCRIPT_DIR, "model")

# Inicializar TTS
tts_engine = pyttsx3.init()
voices = tts_engine.getProperty('voices')
for voice in voices:
    if "spanish" in voice.name.lower() or "es-es" in voice.id.lower():
        tts_engine.setProperty('voice', voice.id)
        break
tts_engine.setProperty('rate', 180) # Velocidad un poco más natural

def speak(text):
    """Habla y bloquea hasta terminar"""
    if not text: return
    try:
        tts_engine.say(text)
        tts_engine.runAndWait()
    except Exception as e:
        pass

def stdin_listener():
    """Hilo que escucha mensajes de Rust para hablar"""
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        try:
            msg = json.loads(line)
            if msg.get("type") == "speak":
                speak(msg.get("text", ""))
        except:
            continue

def main():
    if not os.path.exists(MODEL_PATH):
        print(json.dumps({"type": "error", "message": "Modelo no encontrado"}), flush=True)
        return

    # Iniciar hilo de escucha de comandos de voz (salida)
    threading.Thread(target=stdin_listener, daemon=True).start()

    p = pyaudio.PyAudio()
    model = Model(MODEL_PATH)
    rec = KaldiRecognizer(model, 16000)
    
    stream = p.open(format=pyaudio.paInt16, channels=1, rate=16000, input=True, frames_per_buffer=8000)
    stream.start_stream()
    
    print(json.dumps({"type": "ready"}), flush=True) 

    state = "IDLE"

    while True:
        data = stream.read(4000, exception_on_overflow=False)
        if len(data) == 0: break
        
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            text = result.get("text", "")
            
            if not text: continue

            if state == "IDLE":
                if "carrito" in text or "cacharrito" in text:
                    print(json.dumps({"type": "wake_word"}), flush=True)
                    state = "LISTENING"
            
            elif state == "LISTENING":
                print(json.dumps({"type": "command", "text": text}), flush=True)
                state = "IDLE"

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(json.dumps({"type": "error", "message": str(e)}), flush=True)