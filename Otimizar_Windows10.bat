@echo off
title Otimizador Windows 10 - Seguro
color 0A
echo ===========================================
echo   OTIMIZADOR DO WINDOWS 10 - INICIANDO...
echo ===========================================
echo.

:: Limpeza de arquivos temporarios
echo Limpando arquivos temporarios...
del /s /f /q %temp%\*.* >nul 2>&1
del /s /f /q C:\Windows\Temp\*.* >nul 2>&1
echo Limpeza concluida.
echo.

:: Desativar serviços desnecessarios
echo Desativando servicos desnecessarios...
sc stop "SysMain" >nul 2>&1
sc config "SysMain" start=disabled >nul 2>&1
sc stop "DiagTrack" >nul 2>&1
sc config "DiagTrack" start=disabled >nul 2>&1
sc stop "WSearch" >nul 2>&1
sc config "WSearch" start=disabled >nul 2>&1
echo Servicos desnecessarios desativados.
echo.

:: Desativar Windows Update automatico
echo Desativando Windows Update automatico...
sc stop wuauserv >nul 2>&1
sc config wuauserv start=disabled >nul 2>&1
echo Windows Update desativado (pode reativar manualmente).
echo.

:: Ajustar desempenho visual
echo Ajustando efeitos visuais para desempenho maximo...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
echo Efeitos visuais otimizados.
echo.

:: Ativar plano de energia de alto desempenho
echo Ativando plano de energia de alto desempenho...
powercfg -setactive SCHEME_MIN
echo Plano de energia ajustado.
echo.

:: =========================
:: DESABILITAR OTIMIZACAO DE ENTREGA
:: =========================

echo Desabilitando Otimizacao de Entrega...

sc stop DoSvc
sc config DoSvc start= disabled

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f

echo Otimizacao de Entrega desativada.

:: Conclusao
echo ===========================================
echo  Otimizacao concluida com seguranca!
echo  Reinicie o computador para aplicar tudo.
echo ===========================================
pause
