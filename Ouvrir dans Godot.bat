@echo off
rem Double-clique sur ce fichier pour ouvrir le projet dans l'editeur Godot.
set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
  echo Godot est introuvable ici :
  echo %GODOT%
  echo Si tu as deplace Godot, dis-le a Claude pour qu'il corrige ce fichier.
  pause
  exit /b 1
)
start "" "%GODOT%" --editor --path "%~dp0."
