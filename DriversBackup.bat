@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title DriversBackup

:: ========================= CONFIGURAÇÕES =========================
set "versaoAtual=1.4"
set "githubUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/DriversBackup.bat"
set "versionUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/version.txt"
for /f %%d in ('powershell -NoProfile -Command "(Get-Date).ToString(\"yyyy-MM-dd\")"') do set "dataAtual=%%d"
set "logFile=%~dp0DriversBackup_%dataAtual%.log"

:: ===================== VERIFICAÇÃO DE ADMIN =====================
NET SESSION >nul 2>&1
if errorlevel 1 (
    echo [%time%] Elevando para administrador... >> "!logFile!"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c cd /d \"\"%~dp0\"\" && \"\"%~nx0\"\"'"
    exit /b
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
set "opcao=!opcao: =!"
set "opcao=!opcao:~0,1!"

echo(!opcao!| findstr /r "^[1-9]$" >nul || (
    echo [%time%] Opção inválida: !opcao! >> "!logFile!"
    echo.
    echo Opção inválida. Digite 1-9.
    timeout /t 2 >nul
    goto menu
)

:: ===================== LÓGICA DAS OPÇÕES =====================
if "!opcao!"=="1" set "backupDestino=Z:\Drivers" && goto backup
if "!opcao!"=="2" set "backupDestino=C:\Drivers" && goto backup
if "!opcao!"=="3" call :inputPath "backup" && goto backup
if "!opcao!"=="4" set "restauraOrigem=Z:\Drivers" && goto restore
if "!opcao!"=="5" set "restauraOrigem=C:\Drivers" && goto restore
if "!opcao!"=="6" call :inputPath "restore" && goto restore
if "!opcao!"=="7" goto tutorial
if "!opcao!"=="8" goto checkUpdates
if "!opcao!"=="9" goto exitScript

:: ========================= SUB-ROTINAS =========================
:inputPath
set "pathType=%~1"
set "pathVar="
set /p "pathVar=Digite o caminho para %pathType%: "
if not defined pathVar (
    echo [%time%] Caminho vazio para %pathType% >> "!logFile!"
    echo Erro: Caminho não pode ser vazio!
    timeout /t 2 >nul
    exit /b 1
)
if "!pathType!"=="backup" (
    set "backupDestino=!pathVar!"
) else (
    set "restauraOrigem=!pathVar!"
)
exit /b 0

:backup
cls
echo [%time%] Iniciando backup em: !backupDestino! >> "!logFile!"
echo ===========================================
echo            BACKUP DOS DRIVERS
echo ===========================================
echo.

if not exist "!backupDestino!\" (
    echo Criando diretório...
    mkdir "!backupDestino!" >nul 2>&1 || (
        echo [✗] Erro ao criar diretório
        echo [%time%] Falha ao criar: !backupDestino! >> "!logFile!"
        pause
        goto menu
    )
)

dism /online /export-driver /destination:"!backupDestino!" >> "!logFile!" 2>&1
if errorlevel 1 (
    echo [✗] Erro no DISM! Consulte o log.
    echo [%time%] Erro durante backup >> "!logFile!"
) else (
    echo [✓] Backup concluído em: !backupDestino!
    echo [%time%] Backup finalizado >> "!logFile!"
)
echo.
echo Arquivo de log: !logFile!
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
    echo [%time%] Caminho inválido: !restauraOrigem! >> "!logFile!"
    pause
    goto menu
)

set "driverCount=0"
set "successCount=0"
for /r "!restauraOrigem!" %%f in (*.inf) do (
    set /a driverCount+=1
    echo Instalando: %%~nxf
    pnputil /add-driver "%%f" /install >> "!logFile!" 2>&1
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

echo [%time%] Restauração concluída >> "!logFile!"
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
echo [%time%] Tutorial acessado >> "!logFile!"
timeout /t 3 >nul
goto menu

:checkUpdates
echo [%time%] Verificando atualizações >> "!logFile!"
set "tempVersionFile=%TEMP%\DriversBackup_version.txt"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { (Invoke-WebRequest -Uri '%versionUrl%' -UseBasicParsing).Content } catch { exit 1 }" > "%tempVersionFile%"
if errorlevel 1 (
    echo [✗] Não foi possível verificar atualizações.
    echo [%time%] Falha ao consultar versão remota >> "!logFile!"
    pause
    goto menu
)
set /p "versaoGitHub=<%tempVersionFile%"
del "%tempVersionFile%" 2>nul

call :compareVersions "!versaoAtual!" "!versaoGitHub!" versionCompare
if "!versionCompare!"=="L" (
    echo Nova versão !versaoGitHub! disponível!
    choice /c SN /m "Atualizar agora (S/N)?"
    if errorlevel 1 (
        echo [%time%] Iniciando atualização >> "!logFile!"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%githubUrl%' -OutFile '%~dp0DriversBackup_NEW.bat' -UseBasicParsing"
        move /Y "%~dp0DriversBackup_NEW.bat" "%~f0" >nul
        start "" "%~f0"
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
for /f "tokens=1,2,3 delims=." %%a in ("%left%") do (
    set "l1=%%a"
    set "l2=%%b"
    set "l3=%%c"
)
for /f "tokens=1,2,3 delims=." %%a in ("%right%") do (
    set "r1=%%a"
    set "r2=%%b"
    set "r3=%%c"
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
if errorlevel 1 (
    echo [%time%] Reiniciando sistema >> "!logFile!"
    shutdown /r /t 5
)
exit /b

:end
endlocal
