@echo off
:: This part auto-detects the current folder path
set "BASE_DIR=%~dp0"
set "APP_DIR=%BASE_DIR%app\win"
set "DATA_DIR=%BASE_DIR%data\profile"

:: Start Zen using the local relative path to the profile
start "" "%APP_DIR%\zen.exe" -profile "%DATA_DIR%"