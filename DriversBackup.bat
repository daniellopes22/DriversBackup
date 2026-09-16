@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title DriversBackup

:: ========================= CONFIGURAÇÕES =========================
set "versaoAtual=1.5"
set "githubUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/DriversBackup.bat"
set "versionUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/version.txt"
for /f %%D in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd')"') do set "dataAtual=%%D"
set "logFile=%~dp0DriversBackup_%dataAtual%.log"

:: ===================== VERIFICAÇÃO DE ADMIN =====================
net session >nul 2>&1
if errorlevel 1 (
    echo [%time%] Elevando para administrador... >> "%logFile%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c cd /d \"%~dp0\" && \"%~nx0\"'"
    exit /b
)

if not exist "%logFile%" (
    echo [%time%] Inicializando log >> "%logFile%"
)

:: ========================= MENU PRINCIPAL =========================
:menu
cls
echo ===========================================
echo         BACKUP E RESTAURAÇÃO DE DRIVERS
echo ===========================================
echo.
echo 1 - Backup: Laboratório (Z:\Drivers)
echo 2 - Backup: Administrativo (C:\Drivers)
echo 3 - Backup: Caminho personalizado
echo.
echo 4 - Restauração: Laboratório (Z:\Drivers)
echo 5 - Restauração: Administrativo (C:\Drivers)
echo 6 - Restauração: Caminho personalizado
echo.
echo 7 - Tutorial no YouTube
echo 8 - Verificar atualizações
echo 9 - Sair
echo.

:: ===================== VALIDAÇÃO DE ENTRADA =====================
:menuInput
set "opcao="
set /p "opcao=Digite sua opção: "
if not defined opcao (
    echo.
    echo Opção inválida. Digite 1-9.
    timeout /t 2 >nul
    goto menu
)
set "opcao=!opcao: =!"
set "opcao=!opcao:~0,1!"

echo(!opcao!| findstr /r "^[1-9]$" >nul || (
    echo [%time%] Opção inválida: !opcao! >> "%logFile%"
    echo.
    echo Opção inválida. Digite 1-9.
    timeout /t 2 >nul
    goto menu
)

:: ===================== LÓGICA DAS OPÇÕES =====================
if "!opcao!"=="1" (
    set "backupDestino=Z:\Drivers"
    goto backup
)
if "!opcao!"=="2" (
    set "backupDestino=C:\Drivers"
    goto backup
)
if "!opcao!"=="3" (
    call :inputPath "backup"
    if errorlevel 1 goto menu
    goto backup
)
if "!opcao!"=="4" (
    set "restauraOrigem=Z:\Drivers"
    goto restore
)
if "!opcao!"=="5" (
    set "restauraOrigem=C:\Drivers"
    goto restore
)
if "!opcao!"=="6" (
    call :inputPath "restore"
    if errorlevel 1 goto menu
    goto restore
)
if "!opcao!"=="7" goto tutorial
if "!opcao!"=="8" goto checkUpdates
if "!opcao!"=="9" goto exitScript

goto menu

:: ========================= SUB-ROTINAS =========================
:inputPath
set "pathType=%~1"
set "pathVar="
set /p "pathVar=Digite o caminho para %pathType%: "
if not defined pathVar (
    echo [%time%] Caminho vazio para %pathType% >> "%logFile%"
    echo Erro: Caminho não pode ser vazio!
    timeout /t 2 >nul
    exit /b 1
)
if /i "%pathType%"=="backup" (
    set "backupDestino=!pathVar!"
) else (
    set "restauraOrigem=!pathVar!"
)
exit /b 0

:backup
cls
echo [%time%] Iniciando backup em: !backupDestino! >> "%logFile%"
echo ===========================================
echo            BACKUP DOS DRIVERS
echo ===========================================
echo.

if not exist "!backupDestino!\" (
    echo Criando diretório...
    mkdir "!backupDestino!" >nul 2>&1 || (
        echo [✗] Erro ao criar diretório
        echo [%time%] Falha ao criar: !backupDestino! >> "%logFile%"
        pause
        goto menu
    )
)

dism /online /export-driver /destination:"!backupDestino!" >> "%logFile%" 2>&1
if errorlevel 1 (
    echo [✗] Erro no DISM! Consulte o log.
    echo [%time%] Erro durante backup >> "%logFile%"
) else (
    echo [✓] Backup concluído em: !backupDestino!
    echo [%time%] Backup finalizado >> "%logFile%"
)

echo.
echo Arquivo de log: %logFile%
pause
goto menu

:restore
cls
echo ===========================================
echo         RESTAURAÇÃO DOS DRIVERS
echo ===========================================
echo.

if not exist "!restauraOrigem!\" (
    echo [✗] Caminho inválido: !restauraOrigem!
    echo [%time%] Caminho inválido: !restauraOrigem! >> "%logFile%"
    pause
    goto menu
)

set "driverCount=0"
set "successCount=0"
for /r "!restauraOrigem!" %%F in (*.inf) do (
    set /a driverCount+=1
    echo Instalando: %%~nxf
    pnputil /add-driver "%%F" /install >> "%logFile%" 2>&1
    if errorlevel 1 (
        echo [✗] Falha ao instalar %%~nxf
    ) else (
        set /a successCount+=1
        echo [✓] %%~nxf instalado
    )
)

if !driverCount! equ 0 (
    echo Nenhum driver encontrado em !restauraOrigem!.
) else (
    echo.
    echo Resultado: !successCount!/!driverCount! drivers instalados
)

echo [%time%] Restauração concluída >> "%logFile%"
pause
goto menu

:tutorial
cls
ping -n 1 youtube.com >nul || (
    echo [✗] Sem conexão com a internet!
    pause
    goto menu
)
start "" "https://youtu.be/ymOwOXdzHGQ"
echo [%time%] Tutorial acessado >> "%logFile%"
timeout /t 3 >nul
goto menu

:checkUpdates
echo [%time%] Verificando atualizações >> "%logFile%"
set "tempVersionFile=%TEMP%\DriversBackup_version.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { (Invoke-WebRequest -Uri '%versionUrl%' -UseBasicParsing).Content.Trim() } catch { exit 1 }" > "%tempVersionFile%"
if errorlevel 1 (
    echo [✗] Não foi possível verificar atualizações.
    echo [%time%] Falha ao consultar versão remota >> "%logFile%"
    del "%tempVersionFile%" 2>nul
    pause
    goto menu
)
set /p "versaoGitHub=<%tempVersionFile%"
del "%tempVersionFile%" 2>nul

call :compareVersions "%versaoAtual%" "%versaoGitHub%" versionCompare
if "!versionCompare!"=="L" (
    echo Nova versão !versaoGitHub! disponível!
    choice /c SN /m "Atualizar agora (S/N)?"
    if errorlevel 2 goto menu
    if errorlevel 1 (
        echo [%time%] Iniciando atualização >> "%logFile%"
        set "updateTemp=%~dp0DriversBackup_Update.bat"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '%githubUrl%' -OutFile '%updateTemp%' -UseBasicParsing } catch { exit 1 }"
        if errorlevel 1 (
            echo [✗] Falha ao baixar a atualização.
            echo [%time%] Falha ao baixar nova versão >> "%logFile%"
            pause
            goto menu
        )
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds 2; Move-Item -Force '%updateTemp%' '%~f0'; Start-Process '%~f0'"
        exit /b
    )
) else (
    echo Você já está na versão mais recente (!versaoAtual!).
)
pause
goto menu

:compareVersions
set "left=%~1"
set "right=%~2"
for /f "tokens=1,2,3 delims=." %%A in ("%left%") do (
    set "l1=%%A"
    set "l2=%%B"
    set "l3=%%C"
)
for /f "tokens=1,2,3 delims=." %%A in ("%right%") do (
    set "r1=%%A"
    set "r2=%%B"
    set "r3=%%C"
)
if not defined l2 set "l2=0"
if not defined l3 set "l3=0"
if not defined r2 set "r2=0"
if not defined r3 set "r3=0"
if !l1! gtr !r1! (set "%~3=G" & exit /b 0)
if !l1! lss !r1! (set "%~3=L" & exit /b 0)
if !l2! gtr !r2! (set "%~3=G" & exit /b 0)
if !l2! lss !r2! (set "%~3=L" & exit /b 0)
if !l3! gtr !r3! (set "%~3=G" & exit /b 0)
if !l3! lss !r3! (set "%~3=L" & exit /b 0)
set "%~3=E"
exit /b 0

:exitScript
choice /c SN /m "Deseja reiniciar o computador (S/N)?"
if errorlevel 2 goto exitFinal
if errorlevel 1 (
    echo [%time%] Reiniciando sistema >> "%logFile%"
    shutdown /r /t 5
)
:exitFinal
exit /b

:end
endlocal
