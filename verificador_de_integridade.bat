@echo off
setlocal enabledelayedexpansion

:: Verifica se está sendo executado como administrador
net session >nul 2>&1
if errorlevel 1 (
    echo Necessario executar como administrador.
    echo Reexecutando com elevacao...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo =====================================================
echo        🔧 OTIMIZADOR DE SISTEMA WINDOWS 10/11
echo =====================================================
echo.
echo  Este script ira:
echo   * Otimizar SSD e HDD
echo   * Ajustar memoria virtual (paginacao)
echo   * Ativar modo de energia de desempenho maximo
echo   * Limpar arquivos temporarios
echo   * Gerar relatorio final de performance
echo =====================================================
echo.

:: Cria pasta de logs se necessario
set "logdir=%~dp0logs"
if not exist "%logdir%" mkdir "%logdir%"

for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'"`) do set "datetime=%%I"
set "arquivo=%logdir%\Relatorio_%datetime%.txt"

:: =====================================================
:: 1️⃣ Verificar integridade do sistema
echo [1/7] Verificando integridade do sistema...
sfc /scannow
echo.

:: =====================================================
:: 2️⃣ Ativar comando TRIM (mantem SSD rapido)
echo [2/7] Ativando otimizacao TRIM para SSD...
fsutil behavior set DisableDeleteNotify 0 >nul 2>&1
if errorlevel 1 (
    echo Nao foi possivel ativar TRIM.
) else (
    echo TRIM ativado (mantem SSD em alta performance).
)
echo.

:: =====================================================
:: 3️⃣ Otimizar discos (SSD e HDD)
echo [3/7] Otimizando unidades...
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%D:\ (
        echo Otimizando %%D::
        defrag %%D: /O /U
    )
)
echo Otimizacao de discos concluida.
echo.

:: =====================================================
:: 4️⃣ Ajustar memoria virtual automaticamente
echo [4/7] Ajustando memoria virtual (arquivo de paginacao)...
powershell -NoProfile -Command "try { $cs = Get-CimInstance Win32_ComputerSystem; $cs.AutomaticManagedPagefile = $true; Set-CimInstance -InputObject $cs; Write-Output 'OK' } catch { Write-Error 'ERRO' }" >nul 2>&1
if errorlevel 1 (
    echo Falha ao ajustar memoria virtual automaticamente.
) else (
    echo Memoria virtual configurada automaticamente.
)
echo.

:: =====================================================
:: 5️⃣ Ativar modo de energia "Desempenho Maximo"
echo [5/7] Ativando plano de energia de alto desempenho...
powercfg -setactive SCHEME_MIN >nul 2>&1
if errorlevel 1 (
    echo Plano padrao nao encontrado. Tentando localizar plano de alto desempenho...
    powershell -NoProfile -Command "try { $plan = powercfg -L | Select-String -Pattern 'High performance|Alto desempenho'; if($plan){ $guid = [regex]::Match($plan, '[A-F0-9-]{36}').Value; if($guid){ powercfg -setactive $guid; exit $LASTEXITCODE } } exit 1 } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        echo Falha ao ativar plano de alto desempenho.
    ) else (
        echo Plano de alto desempenho ativado.
    )
) else (
    echo Plano de alto desempenho ativado.
)
echo.

:: =====================================================
:: 6️⃣ Limpar arquivos temporarios e cache
echo [6/6] Limpando arquivos temporarios e cache do sistema...

:: TEMP do usuario
if defined TEMP del /s /f /q "%TEMP%\*" >nul 2>&1

:: TEMP do Windows
if exist "%SystemRoot%\Temp" del /s /f /q "%SystemRoot%\Temp\*" >nul 2>&1

:: Remove pastas vazias
for /d %%x in ("%TEMP%\*") do rd /s /q "%%x" >nul 2>&1
for /d %%x in ("%SystemRoot%\Temp\*") do rd /s /q "%%x" >nul 2>&1

echo Limpeza concluida.
echo.

title Relatorio de Performance

set "arquivo=%~dp0logs\Relatorio_%datetime%.txt"

echo ===================================================== > "%arquivo%"
echo RELATORIO DE PERFORMANCE >> "%arquivo%"
echo DATA: %date% %time% >> "%arquivo%"
echo ===================================================== >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: DISCO
:: =========================

echo [DISCOS] >> "%arquivo%"
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,@{Name='Livre(GB)';Expression={[math]::Round($_.FreeSpace/1GB,2)}},@{Name='Total(GB)';Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize" >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: ALERTA DE ESPACO
:: =========================

powershell -NoProfile -Command "$disk = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\"; if($disk){ $livre = [math]::Round($disk.FreeSpace/1GB,2); if($livre -lt 10){ Write-Output 'ALERTA: Menos de 10 GB livres na unidade C:' } else { Write-Output 'Espaco em disco OK.' } } else { Write-Output 'Unidade C: nao encontrada.' }" >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: RAM
:: =========================

echo [MEMORIA RAM] >> "%arquivo%"
powershell -NoProfile -Command "$os = Get-CimInstance Win32_OperatingSystem; $total = [math]::Round($os.TotalVisibleMemorySize/1MB,2); $livre = [math]::Round($os.FreePhysicalMemory/1MB,2); $usado = [math]::Round($total-$livre,2); Write-Output ('Total RAM: ' + $total + ' GB'); Write-Output ('RAM Usada: ' + $usado + ' GB'); Write-Output ('RAM Livre: ' + $livre + ' GB')" >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: CPU
:: =========================

echo [PROCESSADOR] >> "%arquivo%"
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Select-Object Name,CurrentClockSpeed,MaxClockSpeed | Format-Table -AutoSize" >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: TEMPERATURA
:: =========================

echo [TEMPERATURA CPU] >> "%arquivo%"
powershell -NoProfile -Command "$temp = Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace root/wmi; if($temp){ $temp | Select-Object @{Name='Temp(C)';Expression={[math]::Round(($_.CurrentTemperature/10)-273.15,1)}} } else { Write-Output 'Temperatura nao disponivel no hardware.' }" >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: PROCESSOS
:: =========================

echo [TOP PROCESSOS] >> "%arquivo%"
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 ProcessName,CPU,@{Name='RAM_MB';Expression={[math]::Round($_.WorkingSet/1MB,2)}} | Format-Table -AutoSize" >> "%arquivo%"
echo. >> "%arquivo%"

echo RELATORIO FINALIZADO!
pause