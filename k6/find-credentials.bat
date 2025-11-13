@echo off
REM Helper script to find Supabase credentials in your Flutter project
REM This will search for .env files or configuration with Supabase settings

echo.
echo ========================================
echo  Buscando credenciales de Supabase
echo ========================================
echo.

REM Check if .env exists
if exist "..\\.env" (
    echo [Encontrado] Archivo .env en la raiz del proyecto
    echo.
    echo Contenido relevante:
    findstr /I "SUPABASE" "..\\.env"
    echo.
) else (
    echo [No encontrado] Archivo .env en la raiz
    echo.
)

REM Check if there are dart-define or other config files
echo Buscando configuraciones de Supabase en el codigo...
echo.

REM Search in common config locations
if exist "..\\lib\\main.dart" (
    findstr /C:"supabaseUrl" /C:"supabaseAnonKey" /C:"SUPABASE_URL" /C:"SUPABASE_ANON_KEY" "..\\lib\\main.dart" 2>nul
    if %errorlevel% equ 0 (
        echo [Encontrado] Referencias en main.dart
        echo.
    )
)

echo ----------------------------------------
echo.
echo Si no encuentras las credenciales aqui:
echo.
echo 1. Ve a: https://supabase.com/dashboard
echo 2. Selecciona tu proyecto "Manos Solidarias"
echo 3. Ve a: Settings ^(gear icon^) -^> API
echo 4. Copia:
echo    - Project URL ^(ejemplo: https://xxxxx.supabase.co^)
echo    - anon public key ^(empieza con eyJ...^)
echo.
echo Luego ejecuta:
echo   set SUPABASE_URL=https://tu-proyecto.supabase.co
echo   set SUPABASE_ANON_KEY=tu-anon-key
echo   run-test.bat
echo.
echo ========================================
echo.

pause
