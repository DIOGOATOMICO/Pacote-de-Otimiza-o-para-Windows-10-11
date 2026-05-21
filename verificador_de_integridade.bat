@echo off

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

:: =====================================================
:: 1️⃣ Verificar integridade do sistema
echo.
echo [1/7] Verificando integridade do sistema...
sfc /scannow
echo.

:: =====================================================
:: 2️⃣ Ativar comando TRIM (mantem SSD rapido)
echo [2/7] Ativando otimizacao TRIM para SSD...
fsutil behavior set DisableDeleteNotify 0
echo TRIM ativado (mantem SSD em alta performance).
echo.

:: =====================================================
:: 3️⃣ Otimizar discos (SSD e HDD)
echo [3/7] Otimizando unidades...
defrag C: /L
defrag D: /O
echo Otimizacao de discos concluida.
echo.

:: =====================================================
:: 4️⃣ Ajustar memoria virtual automaticamente
echo [4/7] Ajustando memoria virtual (arquivo de paginacao)...
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True
echo Memoria virtual configurada automaticamente.
echo.

:: =====================================================
:: 5️⃣ Ativar modo de energia "Desempenho Maximo"
echo [5/7] Ativando plano de energia de alto desempenho...
powercfg -setactive SCHEME_MIN
echo Plano de energia ajustado para maximo desempenho.
echo.

:: =====================================================
:: 6️⃣ Limpar arquivos temporarios e cache
echo [6/6] Limpando arquivos temporarios e cache do sistema...
del /s /f /q %temp%\*.* >nul 2>&1
del /s /f /q C:\Windows\Temp\*.* >nul 2>&1
del /s /f /q C:\Windows\Prefetch\*.* >nul 2>&1
echo Limpeza concluida.

title Relatorio de Performance

set "arquivo=%~dp0logs\Relatorio_%time%.txt"

echo ===================================================== > "%arquivo%"
echo RELATORIO DE PERFORMANCE >> "%arquivo%"
echo DATA: %date% %time% >> "%arquivo%"
echo ===================================================== >> "%arquivo%"
echo. >> "%arquivo%"

:: =========================
:: DISCO
:: =========================

echo [DISCOS] >> "%arquivo%"

powershell -Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,@{Name='Livre(GB)';Expression={[math]::Round($_.FreeSpace/1GB,2)}},@{Name='Total(GB)';Expression={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize" >> "%arquivo%"

echo. >> "%arquivo%"

:: =========================
:: ALERTA DE ESPACO
:: =========================

powershell -Command "$livre=((Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\").FreeSpace/1GB); if($livre -lt 10){Write-Output 'ALERTA: Menos de 10 GB livres na unidade C:'} else {Write-Output 'Espaco em disco OK.'}" >> "%arquivo%"

echo. >> "%arquivo%"

:: =========================
:: RAM
:: =========================

echo [MEMORIA RAM] >> "%arquivo%"

powershell -Command "$os = Get-CimInstance Win32_OperatingSystem; $total = [math]::Round($os.TotalVisibleMemorySize/1MB,2); $livre = [math]::Round($os.FreePhysicalMemory/1MB,2); $usado = [math]::Round($total-$livre,2); Write-Output ('Total RAM: ' + $total + ' GB'); Write-Output ('RAM Usada: ' + $usado + ' GB'); Write-Output ('RAM Livre: ' + $livre + ' GB')" >> "%arquivo%"

echo. >> "%arquivo%"

:: =========================
:: CPU
:: =========================

echo [PROCESSADOR] >> "%arquivo%"

powershell -Command "Get-CimInstance Win32_Processor | Select-Object Name,CurrentClockSpeed,MaxClockSpeed | Format-Table -AutoSize" >> "%arquivo%"

echo. >> "%arquivo%"

:: =========================
:: TEMPERATURA
:: =========================

echo [TEMPERATURA CPU] >> "%arquivo%"

powershell -Command "Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace root/wmi | Select-Object @{Name='Temp(C)';Expression={[math]::Round(($_.CurrentTemperature/10)-273.15,1)}}" >> "%arquivo%"

echo. >> "%arquivo%"

:: =========================
:: PROCESSOS
:: =========================

echo [TOP PROCESSOS] >> "%arquivo%"

powershell -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 ProcessName,CPU,@{Name='RAM_MB';Expression={[math]::Round($_.WorkingSet/1MB,2)}} | Format-Table -AutoSize" >> "%arquivo%"

echo. >> "%arquivo%"

echo RELATORIO FINALIZADO!
pause