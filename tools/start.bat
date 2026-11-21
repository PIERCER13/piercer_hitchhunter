@echo off
title piercer_hitchhunter - painel web
rem Duplo clique para abrir o painel em http://localhost:8787/
rem Opcoes: start.bat -Port 8788   |   start.bat -DataFile "C:\caminho\incidents.json"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1" -Open %*
pause
