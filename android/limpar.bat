@echo off
echo [1/5] Fechando processos que podem travar o cache...
taskkill /F /IM dark.exe /T >nul 2>&1
taskkill /F /IM java.exe /T >nul 2>&1
taskkill /F /IM flutter_tester.exe /T >nul 2>&1

echo [2/5] Removendo pastas de build locais...
rd /s /q .dart_tool
rd /s /q build
rd /s /q .flutter-plugins
rd /s /q .flutter-plugins-dependencies

echo [3/5] APAGANDO CACHE FÍSICO (PUB CACHE)...
:: Atenção: Removendo a pasta específica do pdf que está corrompida
rd /s /q "C:\Users\Abreu\AppData\Local\Pub\Cache\hosted\pub.dev\pdf-3.11.3"
:: Se quiser limpar TUDO, desente a linha abaixo (recomendado):
:: rd /s /q "C:\Users\Abreu\AppData\Local\Pub\Cache"

echo [4/5] Executando limpeza do Flutter...
call flutter clean

echo [5/5] Reinstalando pacotes (Download limpo)...
call flutter pub get

echo.
echo ####################################################
echo # LIMPEZA CONCLUÍDA. TENTE RODAR O APP NOVAMENTE.  #
echo ####################################################
pause