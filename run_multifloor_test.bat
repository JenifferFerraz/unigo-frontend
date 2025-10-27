@echo off
echo ========================================
echo   TESTE: Navegacao Multi-Andar
echo ========================================
echo.

cd c:\Users\ferra\unigo-frontend

echo [1/3] Verificando dependencias...
call flutter pub get
echo.

echo [2/3] Executando testes...
echo.
call flutter test test/services/location_service_multifloor_test.dart --reporter expanded
echo.

echo [3/3] Teste finalizado!
echo.
echo ========================================
echo   Verifique os resultados acima
echo ========================================
pause
