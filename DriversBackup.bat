@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title DriversBackup

:: ========================= CONFIGURAÇÕES =========================
set "versaoAtual=1.6"
set "githubUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/DriversBackup.bat"
set "versionUrl=https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/version.txt"
for /f "usebackq delims=" %%D in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; (Get-Date).ToString('yyyy-MM-dd')"` ) do set "dataAtual=%%D"
set "logFile=%~dp0DriversBackup_%dataAtual%.log"

:: ===================== VERIFICAÇÃO DE ADMIN =====================
net session >nul 2>&1
if errorlevel 1 (
    echo [%time%] Elevando para administrador... >> "%logFile%"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $arg='/c ""%~f0""'; try { Start-Process -Verb RunAs -FilePath '%ComSpec%' -ArgumentList $arg -WorkingDirectory '%~dp0' | Out-Null; exit 0 } catch { exit 1 }"
    if errorlevel 1 (
        echo [%time%] Elevação cancelada ou falhou >> "%logFile%"
        echo [✗] É necessário executar como administrador.
        pause
        exit /b 1
    )
    exit /b 0
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
set "opcao=!opcao: =!"
if not defined opcao (
    echo.
    echo Opção inválida. Digite 1-9.
    timeout /t 2 >nul
    goto menu
)

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
echo(!pathVar!| findstr /r "[^ ]" >nul || (
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
if not defined backupDestino (
    echo [%time%] Destino de backup vazio >> "%logFile%"
    echo [✗] Destino de backup inválido.
    pause
    goto menu
)
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
if not defined restauraOrigem (
    echo [%time%] Origem de restauração vazia >> "%logFile%"
    echo [✗] Origem de restauração inválida.
    pause
    goto menu
)
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
set "versaoGitHub="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $v=(Invoke-WebRequest -Uri '%versionUrl%' -MaximumRedirection 5 -UseBasicParsing).Content; if ($null -eq $v) { exit 2 }; $v=($v -replace '[^\d\.]','').Trim(); if ([string]::IsNullOrWhiteSpace($v)) { exit 3 }; Write-Output $v" 2^>nul`) do set "versaoGitHub=%%V"
if not defined versaoGitHub (
    echo [✗] Não foi possível verificar atualizações.
    echo [%time%] Falha ao consultar versão remota >> "%logFile%"
    pause
    goto menu
)

call :compareVersions "%versaoAtual%" "%versaoGitHub%" versionCompare
if "!versionCompare!"=="L" (
    echo Nova versão !versaoGitHub! disponível!
    choice /c SN /m "Atualizar agora (S/N)?"
    if errorlevel 2 goto menu
    if errorlevel 1 (
        echo [%time%] Iniciando atualização >> "%logFile%"
        set "updateTemp=%TEMP%\DriversBackup_New_%RANDOM%.bat"
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%githubUrl%' -MaximumRedirection 5 -OutFile '%updateTemp%' -UseBasicParsing } catch { exit 1 }"
        if errorlevel 1 (
            echo [✗] Falha ao baixar a atualização.
            echo [%time%] Falha ao baixar nova versão >> "%logFile%"
            pause
            goto menu
        )
        if not exist "%updateTemp%" (
            echo [✗] Arquivo de atualização inválido.
            echo [%time%] Download sem arquivo válido >> "%logFile%"
            pause
            goto menu
        )
        for %%I in ("%updateTemp%") do if %%~zI lss 100 (
            echo [✗] Arquivo de atualização corrompido ou incompleto.
            echo [%time%] Download incompleto: %%~zI bytes >> "%logFile%"
            del "%updateTemp%" 2>nul
            pause
            goto menu
        )
        set "updaterCmd=%TEMP%\DriversBackup_Updater_%RANDOM%.cmd"
        > "%updaterCmd%" (
            echo @echo off
            echo setlocal EnableExtensions
            echo set "target=%%~1"
            echo set "source=%%~2"
            echo set "log=%%~3"
            echo set /a attempts=0
            echo :retryCopy
            echo set /a attempts+=1
            echo copy /y "%%source%%" "%%target%%" ^>nul
            echo if not errorlevel 1 goto copied
            echo if %%attempts%% geq 10 ^(
            echo ^  echo [%%time%%] Falha na atualização: não foi possível substituir o arquivo em execução ^>^> "%%log%%"
            echo ^  exit /b 1
            echo ^)
            echo timeout /t 1 /nobreak ^>nul
            echo goto retryCopy
            echo :copied
            echo echo [%%time%%] Atualização aplicada com sucesso ^>^> "%%log%%"
            echo start "" "%%target%%"
            echo del "%%source%%" ^>nul 2^>^&1
            echo del "%%~f0" ^>nul 2^>^&1
        )
        start "" "%updaterCmd%" "%~f0" "%updateTemp%" "%logFile%"
        exit /b 0
    )
) else (
    echo Você já está na versão mais recente (!versaoAtual!).
)
pause
goto menu

:compareVersions
set "left=%~1"
set "right=%~2"
set "l1="
set "l2="
set "l3="
set "r1="
set "r2="
set "r3="
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
