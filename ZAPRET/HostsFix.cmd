:: ======================================================
:: ОБНОВЛЕНИЕ HOSTS-ФАЙЛА
:: ======================================================
@echo off
chcp 866 > nul
cls

:: Проверка прав администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Запуск с повышенными привилегиями...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
set "hostsUrl=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/hosts"
set "tempFile=%TEMP%\zapret_hosts.txt"
set "backupFile=%TEMP%\hosts_backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%.bak"
set "needsUpdate=0"

echo Проверка файла hosts...

:: Скачивание нового hosts-файла
if exist "%SystemRoot%\System32\curl.exe" (
    curl -L -s -o "%tempFile%" "%hostsUrl%"
) else (
    powershell -Command ^
        "$url = '%hostsUrl%';" ^
        "$out = '%tempFile%';" ^
        "try {" ^
        "    Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing -OutFile $out;" ^
        "    exit 0;" ^
        "} catch {" ^
        "    exit 1;" ^
        "}"
)

if not exist "%tempFile%" (
    echo ОШИБКА: Не удалось скачать файл hosts из репозитория
    pause
    goto menu
)

:: Проверка, что файл не пустой
for %%F in ("%tempFile%") do set "tempSize=%%~zF"
if "%tempSize%"=="0" (
    echo ОШИБКА: Скачанный файл пуст
    del "%tempFile%" 2>nul
    pause
    goto menu
)

:: Проверка необходимости обновления
if not exist "%hostsFile%" (
    echo Файл hosts не найден, будет создан новый
    set "needsUpdate=1"
) else (
    :: Создание резервной копии
    copy "%hostsFile%" "%backupFile%" >nul 2>&1
    if exist "%backupFile%" (
        echo Создана резервная копия: %backupFile%
    )
    
    :: Проверка содержимого
    set "firstLine="
    set "lastLine="
    
    for /f "usebackq delims=" %%a in ("%tempFile%") do (
        if not defined firstLine (
            set "firstLine=%%a"
        )
        set "lastLine=%%a"
    )
    
    findstr /C:"!firstLine!" "%hostsFile%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo Первая строка из репозитория не найдена в текущем файле
        set "needsUpdate=1"
    )
    
    findstr /C:"!lastLine!" "%hostsFile%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo Последняя строка из репозитория не найдена в текущем файле
        set "needsUpdate=1"
    )
)

if "%needsUpdate%"=="1" (
    echo.
    echo ОБНОВЛЕНИЕ HOSTS-ФАЙЛА...
    echo ===========================
    
    :: Блокировка файла для записи
    takeown /f "%hostsFile%" >nul 2>&1
    icacls "%hostsFile%" /grant Administrators:F >nul 2>&1
    
    :: Замена файла
    copy "%tempFile%" "%hostsFile%" >nul 2>&1
    
    if errorlevel 1 (
        echo ОШИБКА: Не удалось обновить файл hosts
        echo Попытка использовать PowerShell...
        
        powershell -Command ^
            "$temp = '%tempFile%';" ^
            "$hosts = '%hostsFile%';" ^
            "Copy-Item -Path $temp -Destination $hosts -Force"
        
        if errorlevel 1 (
            echo ОШИБКА: Требуется ручное обновление
            echo.
            notepad "%tempFile%"
            explorer /select,"%hostsFile%"
        ) else (
            echo Файл hosts успешно обновлён!
        )
    ) else (
        echo Файл hosts успешно обновлён!
    )
    
    :: Очистка DNS кэша
    echo.
    echo Очистка DNS кэша...
    ipconfig /flushdns >nul 2>&1
    echo DNS кэш очищен
    
) else (
    echo Файл hosts уже актуален
)

:: Очистка временных файлов
if exist "%tempFile%" del /f /q "%tempFile%"
echo.
echo Нажмите любую клавишу для продолжения...
pause >nul
goto menu

:menu
:: Ваше меню продолжается здесь