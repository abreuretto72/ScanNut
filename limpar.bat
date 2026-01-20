@echo off
:: Forçar o script a reconhecer a pasta onde ele está gravado
cd /d "%~dp0"

echo [1/5] Verificando integridade da pasta...
if not exist "pubspec.yaml" (
    echo ERRO: pubspec.yaml nao encontrado em: %cd%
    echo Certifique-se de que este script esta na RAIZ do projeto ScanNut.
    pause
    exit /b
)

echo [2/5] Fechando processos Dart/Java...
taskkill /F /IM dart.exe /T >nul 2>&1
taskkill /F /IM java.exe /T >nul 2>&1

echo [3/5] REMOVENDO CACHE CORROMPIDO DO PDF...
:: Removendo a pasta específica que causou o "garbage error"
if exist "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\pdf-3.11.3" (
    rd /s /q "%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\pdf-3.11.3"
    echo Cache do PDF removido com sucesso.
) else (
    echo Pasta de cache do PDF nao encontrada, prosseguindo...
)

echo [4/5] Limpando pastas locais (.dart_tool e build)...
if exist ".dart_tool" rd /s /q ".dart_tool"
if exist "build" rd /s /q "build"

echo [5/5] Reconstruindo dependencias...
call flutter clean
call flutter pub get

echo.
echo ####################################################
echo # SCRIPT FINALIZADO. TENTE RODAR O APP AGORA.      #
echo ####################################################
pause