@echo off
REM Script para ejecutar pruebas de carga K6 en Manos Solidarias
REM Uso: run-test.bat

echo.
echo ========================================
echo  Manos Solidarias - Prueba de Carga K6
echo ========================================
echo.

REM Verificar si K6 está instalado
k6 version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] K6 no esta instalado.
    echo.
    echo Instala K6 con Chocolatey:
    echo   choco install k6
    echo.
    echo O descarga desde: https://k6.io/docs/getting-started/installation/
    echo.
    pause
    exit /b 1
)

echo [OK] K6 version:
k6 version
echo.

REM Verificar variables de entorno
if "%SUPABASE_URL%"=="" (
    echo [ADVERTENCIA] SUPABASE_URL no esta configurada
    echo.
    echo Configura las variables de entorno:
    echo   set SUPABASE_URL=https://tu-proyecto.supabase.co
    echo   set SUPABASE_ANON_KEY=tu-anon-key
    echo.
    echo O edita el archivo load-test.js directamente.
    echo.
    set /p continue="Continuar de todas formas? (s/n): "
    if /i not "%continue%"=="s" exit /b 1
) else (
    echo [OK] SUPABASE_URL configurada: %SUPABASE_URL%
)

if "%SUPABASE_ANON_KEY%"=="" (
    echo [ADVERTENCIA] SUPABASE_ANON_KEY no esta configurada
) else (
    echo [OK] SUPABASE_ANON_KEY configurada (oculta por seguridad)
)

echo.
echo ----------------------------------------
echo Iniciando prueba de carga...
echo ----------------------------------------
echo.
echo Duracion estimada: ~6 minutos
echo Usuarios concurrentes maximos: 20
echo.

REM Ejecutar K6
k6 run load-test.js

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] La prueba fallo con codigo de error: %errorlevel%
    echo.
    echo Posibles causas:
    echo - Credenciales de Supabase incorrectas
    echo - Problemas de conectividad
    echo - Politicas RLS bloqueando operaciones
    echo.
    echo Ejecuta con modo verbose para mas informacion:
    echo   k6 run --verbose load-test.js
    echo.
) else (
    echo.
    echo ========================================
    echo  Prueba completada exitosamente!
    echo ========================================
    echo.
)

pause
