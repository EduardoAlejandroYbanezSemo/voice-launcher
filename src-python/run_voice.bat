@echo off
cd %~dp0
call venv\Scripts\activate
set PYTHONIOENCODING=utf-8
python app.py