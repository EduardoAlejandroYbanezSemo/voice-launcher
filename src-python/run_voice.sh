#!/bin/bash
cd "$(dirname "$0")"

# Intentar activar venv (Linux style)
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    # Por si acaso alguien copió el venv de windows (malla idea, pero bueno)
    source venv/Scripts/activate
fi

export PYTHONIOENCODING=utf-8
python3 app.py
