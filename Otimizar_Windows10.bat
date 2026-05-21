@echo off
setlocal enabledelayedexpansion
title Otimizador Windows 10 - Seguro
color 0A

:: Verifica execução como administrador
net session >nul 2>&1
if errorlevel 1 (
    echo Necessario executar como administrador.
    echo Reexecutando com elevacao...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ===========================================
echo   OTIMIZADOR DO WINDOWS 10 - INICIANDO...
echo ===========================================
echo.

:: Limpeza de arquivos temporarios
echo Limpando arquivos temporarios...
if defined TEMP (
    del /s /f /q "%TEMP%\*" >nul 2>&1
) else (
    echo Variavel TEMP nao definida.
)

if defined SystemRoot (
    if exist "%SystemRoot%\Temp" (
        del /s /f /q "%SystemRoot%\Temp\*" >nul 2>&1
    ) else (
        echo Pasta de temp do Windows nao encontrada.
    )
) else (
    echo Variavel SystemRoot nao definida.
)
echo Limpeza concluida.
echo.

:: Desativar serviços desnecessarios
echo Desativando servicos desnecessarios...
call :SafeService "SysMain"
call :SafeService "DiagTrack"
call :SafeService "WSearch"
echo Servicos desnecessarios processados.
echo.

:: Desativar Windows Update automatico
echo Desativando Windows Update automatico...
call :SafeService "wuauserv"
echo Windows Update desativado (pode reativar manualmente).
echo.

:: Ajustar desempenho visual
echo Ajustando efeitos visuais para desempenho maximo...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
if errorlevel 1 (
    echo Falha ao ajustar efeitos visuais.
) else (
    echo Efeitos visuais otimizados.
)
echo.

:: Ativar plano de energia de alto desempenho
echo Ativando plano de energia de alto desempenho...
powercfg -setactive SCHEME_MIN >nul 2>&1
if errorlevel 1 (
    echo Plano padrao nao encontrado. Tentando localizar plano de alto desempenho...
    powershell -NoProfile -Command "try { $plan = powercfg -L | Select-String -Pattern 'High performance|Alto desempenho' | Select-Object -First 1; if($plan){ $m = [regex]::Match($plan.Line, '[A-F0-9-]{36}'); if($m.Success){ powercfg -setactive $m.Value; exit $LASTEXITCODE } } exit 1 } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        echo Falha ao ativar plano de alto desempenho.
    ) else (
        echo Plano de alto desempenho ativado.
    )
) else (
    echo Plano de energia ajustado.
)
echo.

:: =========================
:: DESABILITAR OTIMIZACAO DE ENTREGA
:: =========================

echo Desabilitando Otimizacao de Entrega...
call :SafeService "DoSvc"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo Falha ao ajustar Delivery Optimization.
) else (
    echo Otimizacao de Entrega desativada.
)
echo.

:: Conclusao
echo ===========================================
echo  Otimizacao concluida com seguranca!
echo  Reinicie o computador para aplicar tudo.
echo ===========================================
pause

goto :eof

:SafeService
set "svcname=%~1"
sc query "%svcname%" >nul 2>&1
if errorlevel 1 (
    echo Servico %svcname% nao encontrado.
    goto :eof
)
sc stop "%svcname%" >nul 2>&1
sc config "%svcname%" start=disabled >nul 2>&1
if errorlevel 1 (
    echo Falha ao processar servico %svcname%.
) else (
    echo Servico %svcname% desativado.
)
goto :eof
