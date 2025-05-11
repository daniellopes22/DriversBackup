@echo off
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: DriversBackup - Backup e Restauração de Drivers (GPL 3.0)
:: Copyright (C) 2025 Daniel Lopes
:: Repositório: https://github.com/daniellopes22/DriversBackup
:: 
:: Este programa é software livre: redistribua ou modifique sob os termos da GPL3.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ========================= CONFIGURAÇÕES =========================
set "versaoAtual=1.3"
set "githubUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/DriversBackup.bat"
set "logFile=DriversBackup_%date:~-4%-%date:~-7,2%-%date:~-10,2%.log"

:: ===================== VERIFICAÇÃO DE ADMIN =====================
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [%time%] Elevando para administrador... >> "!logFile!"
    powershell -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c cd /d ""%~dp0"" && ""%~nx0""'"
    exit
)

:: ========================= MENU PRINCIPAL =========================
:menu
cls
echo ===========================================
echo        BACKUP E RESTAURAđấO DE DRIVERS
echo ===========================================
echo.
echo 1 - Backup: Laboratório (Z:\Drivers)
echo 2 - Backup: Administrativo (C:\Drivers)
echo 3 - Backup: Caminho personalizado
echo.
echo 4 - Restaurađấo: Laboratório (Z:\Drivers)
echo 5 - Restaurađấo: Administrativo (C:\Drivers)
echo 6 - Restaurađấo: Caminho personalizado
echo.
echo 7 - Tutorial no YouTube
echo 8 - Verificar atualizađấes
echo 9 - Sair
echo.

:: ===================== VALIDAđấO DE ENTRADA =====================
:menuInput
set "opcao="
set /p opcao=Digite sua opđấo: 
set "opcao=!opcao: =!"
set "opcao=!opcao:~0,1!"

echo.!opcao! | findstr /r "^[1-9]$" >nul || (
    echo [%time%] Opđấo inválida: !opcao! >> "!logFile!"
    echo.
    echo Opđấo inválida. Digite 1-9.
    timeout /t 2 >nul
    goto menu
)

:: ===================== LÓGICA DAS OPđấES =====================
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
set /p pathVar=Digite o caminho para %pathType%: 
if not defined pathVar (
    echo [%time%] Caminho vazio para %pathType% >> "!logFile!"
    echo Erro: Caminho nấo pode ser vazio!
    timeout /t 2 >nul
    exit /b 1
)
if "!pathType!"=="backup" (set "backupDestino=!pathVar!") else (set "restauraOrigem=!pathVar!")
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
    echo [✗] Erro no DISM! Consulte o log
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
echo         RESTAURAđấO DOS DRIVERS
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
    if !errorlevel! equ 0 (set /a successCount+=1 && echo [✓]) else echo [✗]
)
echo.
echo Resultado: !successCount!/!driverCount! drivers instalados
echo [%time%] Restaurađấo concluída >> "!logFile!"
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
echo [%time%] Verificando atualizađấes >> "!logFile!"
powershell -Command "(Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/version.txt').Content" > temp_version.txt
set /p versaoGitHub=<temp_version.txt
del temp_version.txt

if "!versaoGitHub!" gtr "!versaoAtual!" (
    echo Nova versão !versaoGitHub! disponível!
    choice /c SN /m "Atualizar agora (S/N)?"
    if !errorlevel! equ 1 (
        echo [%time%] Iniciando atualizađấo >> "!logFile!"
        powershell -Command "Invoke-WebRequest -Uri '!githubUrl!' -OutFile 'DriversBackup_NEW.bat'"
        move /Y "DriversBackup_NEW.bat" "%~nx0" >nul
        start "" "%~nx0"
        exit
    )
) else (
    echo Você já está na versão mais recente (!versaoAtual!).
)
pause
goto menu

:exitScript
choice /c SN /m "Deseja reiniciar o computador (S/N)?"
if !errorlevel! equ 1 (
    echo [%time%] Reiniciando sistema >> "!logFile!"
    shutdown /r /t 5
)
exit

:end
endlocal
