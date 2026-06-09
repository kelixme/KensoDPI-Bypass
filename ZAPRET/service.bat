@echo off
set "LOCAL_VERSION=1.9.10b"

:: Внешние команды
if "%~1"=="status_zapret" (
    call :test_service zapret soft
    call :tcp_enable
    exit /b
)

if "%~1"=="check_updates" (
    if defined NO_UPDATE_CHECK exit /b

    if exist "%~dp0utils\check_updates.enabled" (
        if not "%~2"=="soft" (
            start /b service check_updates soft
        ) else (
            call :service_check_updates soft
        )
    )

    exit /b
)

if "%~1"=="load_game_filter" (
    call :game_switch_status
    exit /b
)

if "%~1"=="load_user_lists" (
    call :load_user_lists
    exit /b
)

if "%1"=="admin" (
    call :check_command find
    call :check_command findstr
    call :check_command netsh
    
    call :load_user_lists

    echo Запущено с правами администратора
) else (
    call :check_extracted
    call :check_command powershell

    echo Запрос прав администратора...
    powershell -NoProfile -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
    exit
)


:: МЕНЮ ================================
setlocal EnableDelayedExpansion
:menu
mode con cols=69 lines=40
cls
call :ipset_switch_status
call :game_switch_status
call :check_updates_switch_status

set "menu_choice=null"

echo.
echo  [95mМЕНЕДЖЕР СЛУЖБ ZAPRET[0m [90m[[91mv!LOCAL_VERSION![90m][0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m1 [90m-[0m [92mУстановить службу[0m
echo   [93m2 [90m-[0m [91mУдалить службы[0m
echo   [93m3 [90m-[0m [96mПроверить статус[0m
echo.
echo   [93m4 [90m-[0m [96mИгровой фильтр[0m          [90m[[93m!GameFilterStatus![90m][0m
echo   [93m5 [90m-[0m [96mIPSet фильтр[0m            [90m[[93m!IPsetStatus![90m][0m
echo   [93m6 [90m-[0m [96mАвтопроверка обновлений[0m [90m[[93m!CheckUpdatesStatus![90m][0m
echo.
echo   [93m7 [90m-[0m [96mОбновить список IPSet[0m
echo   [93m8 [90m-[0m [96mОбновить файл hosts[0m
echo   [93m9 [90m-[0m [96mПроверить обновления[0m
echo.
echo   [93m10[90m -[0m [96mЗапустить диагностику[0m
echo   [93m11[90m -[0m [96mЗапустить тесты[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m0[90m -[0m [91mВыход[0m
echo  [90m═════════════════════════════════════════════════════════════════[0m
echo  [90m═══════════════════════════════════════════════════ [93mНажмите [94mENTER[0m
set /p menu_choice=[96m  Выберите действие (0-11): [93m

if "%menu_choice%"=="" goto menu
if "%menu_choice%"=="1" goto service_install
if "%menu_choice%"=="2" goto service_remove
if "%menu_choice%"=="3" goto service_status
if "%menu_choice%"=="4" goto game_switch
if "%menu_choice%"=="5" goto ipset_switch
if "%menu_choice%"=="6" goto check_updates_switch
if "%menu_choice%"=="7" goto ipset_update
if "%menu_choice%"=="8" goto hosts_update
if "%menu_choice%"=="9" goto service_check_updates
if "%menu_choice%"=="10" goto service_diagnostics
if "%menu_choice%"=="11" goto run_tests
if "%menu_choice%"=="0" exit /b
goto menu


:: ЗАГРУЗКА ПОЛЬЗОВАТЕЛЬСКИХ СПИСКОВ =====================
:load_user_lists
set "LISTS_PATH=%~dp0lists\"

if not exist "%LISTS_PATH%ipset-exclude-user.txt" (
    echo 203.0.113.113/32>"%LISTS_PATH%ipset-exclude-user.txt"
)
if not exist "%LISTS_PATH%list-general-user.txt" (
    echo domain.example.abc>"%LISTS_PATH%list-general-user.txt"
)
if not exist "%LISTS_PATH%list-exclude-user.txt" (
    echo domain.example.abc>"%LISTS_PATH%list-exclude-user.txt"
)

exit /b


:: ВКЛЮЧЕНИЕ TCP ==========================
:tcp_enable
netsh interface tcp show global | findstr /i "timestamps" | findstr /i "enabled" > nul || netsh interface tcp set global timestamps=enabled > nul 2>&1
exit /b


:: СТАТУС ==============================
:service_status
@REM mode con cols=69 lines=25
cls
echo  [90m═══════════════════════════════════════════════════ [94mСтатус [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

sc query "zapret" >nul 2>&1
if !errorlevel!==0 (
    for /f "tokens=2*" %%A in ('reg query "HKLM\System\CurrentControlSet\Services\zapret" /v zapret-discord-youtube 2^>nul') do echo   [96mСтратегия установлена из:[0m [93m%%B[0m
)

call :test_service zapret
call :test_service WinDivert

set "BIN_PATH=%~dp0bin\"
if not exist "%BIN_PATH%\*.sys" (
    call :PrintRed "  Файл WinDivert64.sys НЕ НАЙДЕН."
)
echo.

tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
if !errorlevel!==0 (
    call :PrintGreen "  Обход (winws.exe) ЗАПУЩЕН."
) else (
    call :PrintRed "  Обход (winws.exe) НЕ ЗАПУЩЕН."
)

echo  [90m-----------------------------------------------------------------[0m
echo  [90m═══════════════════════════════════════════════════ [93mНажмите [94mENTER[0m
pause > nul
goto menu

:test_service
set "ServiceName=%~1"
set "ServiceStatus="

for /f "tokens=3 delims=: " %%A in ('sc query "%ServiceName%" ^| findstr /i "STATE"') do set "ServiceStatus=%%A"
set "ServiceStatus=%ServiceStatus: =%"

if "%ServiceStatus%"=="RUNNING" (
    if "%~2"=="soft" (
        echo "%ServiceName%" УЖЕ ЗАПУЩЕН как служба, сначала используйте "service.bat" и выберите "Remove Services", если хотите запустить автономный bat.
        pause
        exit /b
    ) else (
        echo   [92mСлужба %ServiceName% ЗАПУЩЕНА.[0m
    )
) else if "%ServiceStatus%"=="STOP_PENDING" (
    call :PrintYellow "  %ServiceName% в состоянии STOP_PENDING, это может быть вызвано конфликтом с другим обходом."
) else if not "%~2"=="soft" (
    echo   [91mСлужба %ServiceName% НЕ ЗАПУЩЕНА.[0m
)

exit /b


:: УДАЛЕНИЕ ==============================
:service_remove
@REM mode con cols=69 lines=15
cls
echo  [90m═══════════════════════════════════════════════════ [94mУдаление служб [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

set SRVCNAME=zapret
sc query "!SRVCNAME!" >nul 2>&1
if !errorlevel!==0 (
    echo   [93m[*] Остановка службы...[0m
    net stop %SRVCNAME% >nul 2>&1
    echo   [93m[*] Удаление службы...[0m
    sc delete %SRVCNAME% >nul 2>&1
    echo   [92m[+] Служба удалена.[0m
) else (
    echo   [91m[-] Служба "%SRVCNAME%" не установлена.[0m
)

tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
if !errorlevel!==0 (
    taskkill /IM winws.exe /F > nul
    echo   [92m[+] winws.exe завершен.[0m
)

sc query "WinDivert" >nul 2>&1
if !errorlevel!==0 (
    net stop "WinDivert" >nul 2>&1
    sc delete "WinDivert" >nul 2>&1
    echo   [92m[+] WinDivert удален.[0m
)
net stop "WinDivert14" >nul 2>&1
sc delete "WinDivert14" >nul 2>&1

echo  [90m-----------------------------------------------------------------[0m
echo  [90m═══════════════════════════════════════════════════ [93mНажмите [94mENTER[0m
pause > nul
goto menu


:: УСТАНОВКА =============================
:service_install
@REM mode con cols=69 lines=25
cls
echo  [90m═══════════════════════════════════════════ [94mУстановка службы [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

:: Main
cd /d "%~dp0"
set "BIN_PATH=%~dp0bin\"
set "LISTS_PATH=%~dp0lists\"

echo   [96mВыберите один из вариантов:[0m
echo.
set "count=0"
for /f "delims=" %%F in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '.' -Filter '*.bat' | Where-Object { $_.Name -notlike 'service*' } | Sort-Object { [Regex]::Replace($_.Name, '(\d+)', { $args[0].Value.PadLeft(8, '0') }) } | ForEach-Object { $_.BaseName }"') do (
    set /a count+=1
    echo   [93m!count![90m.[0m [96m%%F[0m
    set "file!count!=%%F.bat"
)

:: Выбор файла
set "choice="
echo.
set /p "choice=[96m  Введите номер файла: [93m"
if "!choice!"=="" (
    echo   [91m[!] Неверный выбор, выход...[0m
    pause
    goto menu
)

set "selectedFile=!file%choice%!"
if not defined selectedFile (
    echo   [91m[!] Неверный выбор, выход...[0m
    pause
    goto menu
)

:: Аргументы, за которыми должно следовать значение
set "args_with_value=sni host altorder"

:: Разбор аргументов (mergeargs: 2=начало параметра|3=аргумент со значением|1=параметры|0=по умолчанию)
set "args="
set "capture=0"
set "mergeargs=0"
set QUOTE="

for /f "tokens=*" %%a in ('type "!selectedFile!"') do (
    set "line=%%a"
    call set "line=%%line:^!=EXCL_MARK%%"

    echo !line! | findstr /i "%BIN%winws.exe" >nul
    if not errorlevel 1 (
        set "capture=1"
    )

    if !capture!==1 (
        if not defined args (
            set "line=!line:*%BIN%winws.exe"=!"
        )

        set "temp_args="
        for %%i in (!line!) do (
            set "arg=%%i"

            if not "!arg!"=="^" (
                if "!arg:~0,2!" EQU "--" if not !mergeargs!==0 (
                    set "mergeargs=0"
                )

                if "!arg:~0,1!" EQU "!QUOTE!" (
                    set "arg=!arg:~1,-1!"

                    echo !arg! | findstr ":" >nul
                    if !errorlevel!==0 (
                        set "arg=\!QUOTE!!arg!\!QUOTE!"
                    ) else if "!arg:~0,1!"=="@" (
                        set "arg=\!QUOTE!@%~dp0!arg:~1!\!QUOTE!"
                    ) else if "!arg:~0,5!"=="%%BIN%%" (
                        set "arg=\!QUOTE!!BIN_PATH!!arg:~5!\!QUOTE!"
                    ) else if "!arg:~0,7!"=="%%LISTS%%" (
                        set "arg=\!QUOTE!!LISTS_PATH!!arg:~7!\!QUOTE!"
                    ) else (
                        set "arg=\!QUOTE!%~dp0!arg!\!QUOTE!"
                    )
                ) else if "!arg:~0,12!" EQU "%%GameFilter%%" (
                    set "arg=%GameFilter%"
                ) else if "!arg:~0,15!" EQU "%%GameFilterTCP%%" (
                    set "arg=%GameFilterTCP%"
                ) else if "!arg:~0,15!" EQU "%%GameFilterUDP%%" (
                    set "arg=%GameFilterUDP%"
                )

                if !mergeargs!==1 (
                    set "temp_args=!temp_args!,!arg!"
                ) else if !mergeargs!==3 (
                    set "temp_args=!temp_args!=!arg!"
                    set "mergeargs=1"
                ) else (
                    set "temp_args=!temp_args! !arg!"
                )

                if "!arg:~0,2!" EQU "--" (
                    set "mergeargs=2"
                ) else if !mergeargs! GEQ 1 (
                    if !mergeargs!==2 set "mergeargs=1"

                    for %%x in (!args_with_value!) do (
                        if /i "%%x"=="!arg!" (
                            set "mergeargs=3"
                        )
                    )
                )
            )
        )

        if not "!temp_args!"=="" (
            set "args=!args! !temp_args!"
        )
    )
)

:: Создание службы с разобранными аргументами
call :tcp_enable

set ARGS=%args%
call set "ARGS=%%ARGS:EXCL_MARK=^!%%"
echo  [90m-----------------------------------------------------------------[0m
echo   [93m[*] Выбраный пресет: !selectedFile![0m
@REM echo   [93m[*] Итоговые аргументы: !ARGS![0m
set SRVCNAME=zapret

net stop %SRVCNAME% >nul 2>&1
sc delete %SRVCNAME% >nul 2>&1
echo   [93m[*] Создание службы...[0m
sc create %SRVCNAME% binPath= "\"%BIN_PATH%winws.exe\" !ARGS!" DisplayName= "zapret" start= auto >nul 2>&1
sc description %SRVCNAME% "Программное обеспечение Zapret для обхода DPI" >nul 2>&1
echo   [93m[*] Запуск службы...[0m
sc start %SRVCNAME% >nul 2>&1
for %%F in ("!file%choice%!") do (
    set "filename=%%~nF"
)
reg add "HKLM\System\CurrentControlSet\Services\zapret" /v zapret-discord-youtube /t REG_SZ /d "!filename!" /f >nul 2>&1
echo   [92m[+] Служба успешно установлена![0m

echo  [90m-----------------------------------------------------------------[0m
echo  [90m═══════════════════════════════════════════════════ [93mНажмите [94mENTER[0m
pause > nul
goto menu


:: ПРОВЕРКА ОБНОВЛЕНИЙ =======================
:service_check_updates
@REM mode con cols=69 lines=20
cls
echo  [90m═══════════════════════════════════════════════════ [94mПроверка обновлений [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

:: Установка текущей версии и URL-адресов
set "GITHUB_VERSION_URL=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/.service/version.txt"
set "GITHUB_RELEASE_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/tag/"
set "GITHUB_DOWNLOAD_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/latest"

:: Получение последней версии с GitHub
echo   [93m[*] Проверка обновлений...[0m
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Invoke-WebRequest -Uri \"%GITHUB_VERSION_URL%\" -Headers @{\"Cache-Control\"=\"no-cache\"} -UseBasicParsing -TimeoutSec 5).Content.Trim()" 2^>nul') do set "GITHUB_VERSION=%%A"

:: Обработка ошибок
if not defined GITHUB_VERSION (
    echo   [91m[!] Предупреждение: не удалось получить последнюю версию.[0m
    timeout /T 5 >nul
    if "%1"=="soft" exit 
    pause
    goto menu
)

:: Сравнение версий
if "%LOCAL_VERSION%"=="%GITHUB_VERSION%" (
    echo   [92m[+] Установлена последняя версия: %LOCAL_VERSION%[0m
    
    if "%1"=="soft" exit 
    pause
    goto menu
) 

echo   [93m[!] Доступна новая версия: %GITHUB_VERSION%[0m
echo   [96m[*] Страница релиза: %GITHUB_RELEASE_URL%%GITHUB_VERSION%[0m

echo   [93m[*] Открытие страницы загрузки...[0m
start "" "%GITHUB_DOWNLOAD_URL%"

echo  [90m-----------------------------------------------------------------[0m
if "%1"=="soft" exit 
pause
goto menu


:: ДИАГНОСТИКА =========================
:service_diagnostics
@REM mode con cols=69 lines=30
cls
echo  [90m═══════════════════════════════════════════════════ [94mДиагностика [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

:: Base Filtering Engine
sc query BFE | findstr /I "RUNNING" > nul
if !errorlevel!==0 (
    call :PrintGreen "  Проверка Base Filtering Engine пройдена"
) else (
    call :PrintRed "  [X] Base Filtering Engine не запущена. Эта служба необходима для работы zapret"
)
echo.

:: Проверка прокси
set "proxyEnabled=0"
set "proxyServer="

for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2^>nul ^| findstr /i "ProxyEnable"') do (
    if "%%B"=="0x1" set "proxyEnabled=1"
)

if !proxyEnabled!==1 (
    for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2^>nul ^| findstr /i "ProxyServer"') do (
        set "proxyServer=%%B"
    )
    
    call :PrintYellow "  [?) Системный прокси включен: !proxyServer!"
    call :PrintYellow "  Убедитесь, что он действителен, или отключите его, если вы не используете прокси"
) else (
    call :PrintGreen "  Проверка прокси пройдена"
)
echo.

:: Проверка временных меток TCP
netsh interface tcp show global | findstr /i "timestamps" | findstr /i "enabled" > nul
if !errorlevel!==0 (
    call :PrintGreen "  Проверка временных меток TCP пройдена"
) else (
    call :PrintYellow "  [?) Временные метки TCP отключены. Включение меток..."
    netsh interface tcp set global timestamps=enabled > nul 2>&1
    if !errorlevel!==0 (
        call :PrintGreen "  Временные метки TCP успешно включены"
    ) else (
        call :PrintRed "  [X] Не удалось включить временные метки TCP"
    )
)
echo.

:: AdguardSvc.exe
tasklist /FI "IMAGENAME eq AdguardSvc.exe" | find /I "AdguardSvc.exe" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X] Найден процесс Adguard. Adguard может вызывать проблемы с Discord"
    call :PrintRed "  https://github.com/Flowseal/zapret-discord-youtube/issues/417"
) else (
    call :PrintGreen "  Проверка Adguard пройдена"
)
echo.

:: Killer
sc query | findstr /I "Killer" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X] Найдены службы Killer. Killer конфликтует с zapret"
    call :PrintRed "  https://github.com/Flowseal/zapret-discord-youtube/issues/2512#issuecomment-2821119513"
) else (
    call :PrintGreen "  Проверка Killer пройдена"
)
echo.

:: Intel Connectivity Network Service
sc query | findstr /I "Intel" | findstr /I "Connectivity" | findstr /I "Network" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X] Найдена служба Intel Connectivity Network Service. Она конфликтует с zapret"
    call :PrintRed "  https://github.com/ValdikSS/GoodbyeDPI/issues/541#issuecomment-2661670982"
) else (
    call :PrintGreen "  Проверка Intel Connectivity пройдена"
)
echo.

:: Check Point
set "checkpointFound=0"
sc query | findstr /I "TracSrvWrapper" > nul
if !errorlevel!==0 (
    set "checkpointFound=1"
)

sc query | findstr /I "EPWD" > nul
if !errorlevel!==0 (
    set "checkpointFound=1"
)

if !checkpointFound!==1 (
    call :PrintRed "  [X] Найдены службы Check Point. Check Point конфликтует с zapret"
    call :PrintRed "  Попробуйте удалить Check Point"
) else (
    call :PrintGreen "  Проверка Check Point пройдена"
)
echo.

:: SmartByte
sc query | findstr /I "SmartByte" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X] Найдены службы SmartByte. SmartByte конфликтует с zapret"
    call :PrintRed "  Попробуйте удалить или отключить SmartByte через services.msc"
) else (
    call :PrintGreen "  Проверка SmartByte пройдена"
)
echo.

:: WinDivert64.sys файл
set "BIN_PATH=%~dp0bin\"
if not exist "%BIN_PATH%\*.sys" (
    call :PrintRed "  Файл WinDivert64.sys НЕ НАЙДЕН."
    echo.
)

:: VPN
set "VPN_SERVICES="
sc query | findstr /I "VPN" > nul
if !errorlevel!==0 (
    for /f "tokens=2 delims=:" %%A in ('sc query ^| findstr /I "VPN"') do (
        if not defined VPN_SERVICES (
            set "VPN_SERVICES=!VPN_SERVICES!%%A"
        ) else (
            set "VPN_SERVICES=!VPN_SERVICES!,%%A"
        )
    )
    call :PrintYellow "  [?) Найдены VPN службы:!VPN_SERVICES!. Некоторые VPN могут конфликтовать с zapret"
    call :PrintYellow "  Убедитесь, что все VPN отключены"
) else (
    call :PrintGreen "  Проверка VPN пройдена"
)
echo.

:: DNS
set "dohfound=0"
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-ChildItem -Recurse -Path 'HKLM:System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\' | Get-ItemProperty | Where-Object { $_.DohFlags -gt 0 } | Measure-Object | Select-Object -ExpandProperty Count"') do (
    if %%a gtr 0 (
        set "dohfound=1"
    )
)
if !dohfound!==0 (
    call :PrintYellow "  [?) Убедитесь, что вы настроили безопасный DNS в браузере с каким-либо провайдером DNS не по умолчанию,"
    call :PrintYellow "  Если вы используете Windows 11, вы можете настроить зашифрованный DNS в настройках, чтобы скрыть это предупреждение"
) else (
    call :PrintGreen "  Проверка безопасного DNS пройдена"
)
echo.

:: Проверка файла hosts
set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
if exist "%hostsFile%" (
    set "yt_found=0"
    >nul 2>&1 findstr /I "youtube.com" "%hostsFile%" && set "yt_found=1"
    >nul 2>&1 findstr /I "youtu.be" "%hostsFile%" && set "yt_found=1"
    if !yt_found!==1 (
        call :PrintYellow "  [?) Ваш файл hosts содержит записи для youtube.com или youtu.be. Это может вызвать проблемы с доступом к YouTube"
    )
)

:: Конфликт WinDivert
tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
set "winws_running=!errorlevel!"

sc query "WinDivert" | findstr /I "RUNNING STOP_PENDING" > nul
set "windivert_running=!errorlevel!"

if !winws_running! neq 0 if !windivert_running!==0 (
    call :PrintYellow "  [?) winws.exe не запущен, но служба WinDivert активна. Попытка удалить WinDivert..."
    
    net stop "WinDivert" >nul 2>&1
    sc delete "WinDivert" >nul 2>&1
    sc query "WinDivert" >nul 2>&1
    if !errorlevel!==0 (
        call :PrintRed "  [X] Не удалось удалить WinDivert. Проверка конфликтующих служб..."
        
        set "conflicting_services=GoodbyeDPI"
        set "found_conflict=0"
        
        for %%s in (!conflicting_services!) do (
            sc query "%%s" >nul 2>&1
            if !errorlevel!==0 (
                call :PrintYellow "  [?) Найдена конфликтующая служба: %%s. Остановка и удаление..."
                net stop "%%s" >nul 2>&1
                sc delete "%%s" >nul 2>&1
                if !errorlevel!==0 (
                    call :PrintGreen "  Служба успешно удалена: %%s"
                ) else (
                    call :PrintRed "  [X] Не удалось удалить службу: %%s"
                )
                set "found_conflict=1"
            )
        )
        
        if !found_conflict!==0 (
            call :PrintRed "  [X] Конфликтующих служб не найдено. Проверьте вручную, не использует ли какой-либо другой обход WinDivert."
        ) else (
            call :PrintYellow "  [?) Попытка снова удалить WinDivert..."

            net stop "WinDivert" >nul 2>&1
            sc delete "WinDivert" >nul 2>&1
            sc query "WinDivert" >nul 2>&1
            if !errorlevel! neq 0 (
                call :PrintGreen "  WinDivert успешно удален после удаления конфликтующих служб"
            ) else (
                call :PrintRed "  [X] WinDivert все еще не может быть удален. Проверьте вручную, не использует ли какой-либо другой обход WinDivert."
            )
        )
    ) else (
        call :PrintGreen "  WinDivert успешно удален"
    )
    
    echo.
)

:: Конфликтующие обходы
set "conflicting_services=GoodbyeDPI discordfix_zapret winws1 winws2"
set "found_any_conflict=0"
set "found_conflicts="

for %%s in (!conflicting_services!) do (
    sc query "%%s" >nul 2>&1
    if !errorlevel!==0 (
        if "!found_conflicts!"=="" (
            set "found_conflicts=%%s"
        ) else (
            set "found_conflicts=!found_conflicts! %%s"
        )
        set "found_any_conflict=1"
    )
)

if !found_any_conflict!==1 (
    call :PrintRed "  [X] Найдены конфликтующие службы обхода: !found_conflicts!"
    
    set "CHOICE="
    set /p "CHOICE=  Вы хотите удалить эти конфликтующие службы? (Y/N) (по умолчанию: N) "
    if "!CHOICE!"=="" set "CHOICE=N"
    if "!CHOICE!"=="y" set "CHOICE=Y"
    
    if /i "!CHOICE!"=="Y" (
        for %%s in (!found_conflicts!) do (
            call :PrintYellow "  Остановка и удаление службы: %%s"
            net stop "%%s" >nul 2>&1
            sc delete "%%s" >nul 2>&1
            if !errorlevel!==0 (
                call :PrintGreen "  Служба успешно удалена: %%s"
            ) else (
                call :PrintRed "  [X] Не удалось удалить службу: %%s"
            )
        )

        net stop "WinDivert" >nul 2>&1
        sc delete "WinDivert" >nul 2>&1
        net stop "WinDivert14" >nul 2>&1
        sc delete "WinDivert14" >nul 2>&1
    )
    
    echo.
)

:: Очистка кэша Discord
set "CHOICE="
set /p "CHOICE=  Вы хотите очистить кэш Discord? (Y/N) (по умолчанию: Y)  "
if "!CHOICE!"=="" set "CHOICE=Y"
if "!CHOICE!"=="y" set "CHOICE=Y"

if /i "!CHOICE!"=="Y" (
    tasklist /FI "IMAGENAME eq Discord.exe" | findstr /I "Discord.exe" > nul
    if !errorlevel!==0 (
        echo   [93m[*] Discord запущен, закрытие...[0m
        taskkill /IM Discord.exe /F > nul
        if !errorlevel! == 0 (
            call :PrintGreen "  Discord успешно закрыт"
        ) else (
            call :PrintRed "  Не удалось закрыть Discord"
        )
    )

    set "discordCacheDir=%appdata%\discord"

    for %%d in ("Cache" "Code Cache" "GPUCache") do (
        set "dirPath=!discordCacheDir!\%%~d"
        if exist "!dirPath!" (
            rd /s /q "!dirPath!" 2>nul
            if !errorlevel!==0 (
                call :PrintGreen "  Успешно удалено !dirPath!"
            ) else (
                call :PrintRed "  Не удалось удалить !dirPath!"
            )
        ) else (
            echo   [90m[!] !dirPath! не существует[0m
        )
    )
)
echo.

echo  [90m-----------------------------------------------------------------[0m
echo  [90m═══════════════════════════════════════════════════ [93mНажмите [94mENTER[0m
pause > nul
goto menu


:: ИГРОВОЙ ПЕРЕКЛЮЧАТЕЛЬ ========================
:game_switch_status

set "gameFlagFile=%~dp0utils\game_filter.enabled"

if not exist "%gameFlagFile%" (
    set "GameFilterStatus=Выкл"
    set "GameFilter=12"
    set "GameFilterTCP=12"
    set "GameFilterUDP=12"
    exit /b
)

set "GameFilterMode="
for /f "usebackq delims=" %%A in ("%gameFlagFile%") do (
    if not defined GameFilterMode set "GameFilterMode=%%A"
)

if /i "%GameFilterMode%"=="all" (
    set "GameFilterStatus=включен (TCP+UDP)"
    set "GameFilter=1024-65535"
    set "GameFilterTCP=1024-65535"
    set "GameFilterUDP=1024-65535"
) else if /i "%GameFilterMode%"=="tcp" (
    set "GameFilterStatus=включен (TCP)"
    set "GameFilter=1024-65535"
    set "GameFilterTCP=1024-65535"
    set "GameFilterUDP=12"
) else (
    set "GameFilterStatus=включен (UDP)"
    set "GameFilter=1024-65535"
    set "GameFilterTCP=12"
    set "GameFilterUDP=1024-65535"
)
exit /b


:game_switch
@REM mode con cols=69 lines=20
cls
echo  [90m═══════════════════════════════════════════════════ [94mИгровой фильтр [90m════[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m0[90m -[0m [91mОтключить[0m
echo   [93m1[90m -[0m [96mTCP и UDP[0m
echo   [93m2[90m -[0m [96mТолько TCP[0m
echo   [93m3[90m -[0m [96mТолько UDP[0m
echo  [90m-----------------------------------------------------------------[0m
echo.
set "GameFilterChoice=0"
set /p "GameFilterChoice=[96m  Выберите вариант (0-3): [93m"
if "%GameFilterChoice%"=="" set "GameFilterChoice=0"

if "%GameFilterChoice%"=="0" (
    if exist "%gameFlagFile%" (
        del /f /q "%gameFlagFile%" >nul 2>&1
        echo   [92m[+] Игровой фильтр отключен.[0m
    ) else (
        goto menu
    )
) else if "%GameFilterChoice%"=="1" (
    echo all>"%gameFlagFile%"
    echo   [92m[+] Игровой фильтр установлен на TCP+UDP.[0m
) else if "%GameFilterChoice%"=="2" (
    echo tcp>"%gameFlagFile%"
    echo   [92m[+] Игровой фильтр установлен на Только TCP.[0m
) else if "%GameFilterChoice%"=="3" (
    echo udp>"%gameFlagFile%"
    echo   [92m[+] Игровой фильтр установлен на Только UDP.[0m
) else (
    echo   [91m[!] Неверный выбор.[0m
    pause
    goto menu
)

call :PrintYellow "  Перезапустите службу zapret, чтобы применить изменения"
echo  [90m-----------------------------------------------------------------[0m
pause > nul
goto menu


:: ПЕРЕКЛЮЧАТЕЛЬ ПРОВЕРКИ ОБНОВЛЕНИЙ =================
:check_updates_switch_status

set "checkUpdatesFlag=%~dp0utils\check_updates.enabled"

if exist "%checkUpdatesFlag%" (
    set "CheckUpdatesStatus=Вкл"
) else (
    set "CheckUpdatesStatus=Выкл"
)
exit /b


:check_updates_switch
@REM mode con cols=69 lines=15
cls
echo  [90m═══════════════════════════════════════════════════ [94mАвтопроверка обновлений [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

if not exist "%checkUpdatesFlag%" (
    echo   [93m[*] Включение проверки обновлений...[0m
    echo ENABLED > "%checkUpdatesFlag%"
    echo   [92m[+] Автоматическая проверка обновлений включена.[0m
) else (
    echo   [93m[*] Отключение проверки обновлений...[0m
    del /f /q "%checkUpdatesFlag%" >nul 2>&1
    echo   [92m[+] Автоматическая проверка обновлений отключена.[0m
)

echo  [90m-----------------------------------------------------------------[0m
pause > nul
goto menu


:: ПЕРЕКЛЮЧАТЕЛЬ IPSET =======================
:ipset_switch_status

set "listFile=%~dp0lists\ipset-all.txt"
if not exist "%listFile%" (
    set "IPsetStatus=Any"
    exit /b
)

for /f %%i in ('type "%listFile%" 2^>nul ^| find /c /v ""') do set "lineCount=%%i"

if !lineCount!==0 (
    set "IPsetStatus=Any"
) else (
    findstr /R "^203\.0\.113\.113/32$" "%listFile%" >nul
    if !errorlevel!==0 (
        set "IPsetStatus=None"
    ) else (
        set "IPsetStatus=Loaded"
    )
)
exit /b


:ipset_switch
@REM mode con cols=69 lines=15
cls
echo  [90m═══════════════════════════════════════════════════ [94mIPSet фильтр [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

set "listFile=%~dp0lists\ipset-all.txt"
set "backupFile=%listFile%.backup"

if "%IPsetStatus%"=="Loaded" (
    echo   [93m[*] Переключение в режим none...[0m
    
    if not exist "%backupFile%" (
        ren "%listFile%" "ipset-all.txt.backup" 2>nul
    ) else (
        del /f /q "%backupFile%" 2>nul
        ren "%listFile%" "ipset-all.txt.backup" 2>nul
    )
    
    >"%listFile%" (
        echo 203.0.113.113/32
    )
    echo   [92m[+] IPSet фильтр установлен в режим NONE.[0m
    
) else if "%IPsetStatus%"=="None" (
    echo   [93m[*] Переключение в режим any...[0m
    
    >"%listFile%" (
        rem Создание пустого файла
    )
    echo   [92m[+] IPSet фильтр установлен в режим ANY.[0m
    
) else if "%IPsetStatus%"=="Any" (
    echo   [93m[*] Переключение в режим loaded...[0m
    
    if exist "%backupFile%" (
        del /f /q "%listFile%" 2>nul
        ren "%backupFile%" "ipset-all.txt" 2>nul
        echo   [92m[+] IPSet фильтр установлен в режим LOADED.[0m
    ) else (
        echo   [91m[!] Ошибка: нет резервной копии для восстановления. Сначала обновите список из меню служб[0m
        pause
        goto menu
    )
)

echo  [90m-----------------------------------------------------------------[0m
pause > nul
goto menu


:: ОБНОВЛЕНИЕ IPSET =======================
:ipset_update
@REM mode con cols=69 lines=15
cls
echo  [90m═══════════════════════════════════════════════════ [94mОбновление списка IPSet [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

set "listFile=%~dp0lists\ipset-all.txt"
set "url=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt"

echo   [93m[*] Обновление ipset-all...[0m

if exist "%SystemRoot%\System32\curl.exe" (
    curl --version | find "libcurl/7" >nul 2>&1
    if !errorlevel!==0 (
        curl --ssl-no-revoke -L -o "%listFile%" "%url%" 2>nul
    ) else (
        curl --ssl-revoke-best-effort -L -o "%listFile%" "%url%" 2>nul
    )
) else (
    powershell -NoProfile -Command ^
        "$url = '%url%';" ^
        "$out = '%listFile%';" ^
        "$dir = Split-Path -Parent $out;" ^
        "if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null };" ^
        "$res = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing;" ^
        "if ($res.StatusCode -eq 200) { $res.Content | Out-File -FilePath $out -Encoding UTF8 } else { exit 1 }" 2>nul
)

echo   [92m[+] Обновление завершено.[0m
echo  [90m-----------------------------------------------------------------[0m
pause > nul
goto menu


:: ОБНОВЛЕНИЕ ФАЙЛА HOSTS =======================
:hosts_update
@REM mode con cols=69 lines=20
cls
echo  [90m═══════════════════════════════════════════════════ [94mОбновление файла hosts [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
set "hostsUrl=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/hosts"
set "tempFile=%TEMP%\zapret_hosts.txt"
set "needsUpdate=0"

echo   [93m[*] Проверка файла hosts...[0m

if exist "%SystemRoot%\System32\curl.exe" (
    curl -L -s -o "%tempFile%" "%hostsUrl%" 2>nul
) else (
    powershell -NoProfile -Command ^
        "$url = '%hostsUrl%';" ^
        "$out = '%tempFile%';" ^
        "$res = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing;" ^
        "if ($res.StatusCode -eq 200) { $res.Content | Out-File -FilePath $out -Encoding UTF8 } else { exit 1 }" 2>nul
)

if not exist "%tempFile%" (
    call :PrintRed "  Не удалось загрузить файл hosts из репозитория"
    call :PrintYellow "  Скопируйте файл hosts вручную из %hostsUrl%"
    pause
    goto menu
)

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
    echo   [93m[!] Первая строка из репозитория не найдена в файле hosts[0m
    set "needsUpdate=1"
)

findstr /C:"!lastLine!" "%hostsFile%" >nul 2>&1
if !errorlevel! neq 0 (
    echo   [93m[!] Последняя строка из репозитория не найдена в файле hosts[0m
    set "needsUpdate=1"
)

if "%needsUpdate%"=="1" (
    echo.
    call :PrintYellow "  Файл hosts необходимо обновить"
    call :PrintYellow "  Пожалуйста, вручную скопируйте содержимое из загруженного файла в ваш файл hosts"
    
    start notepad "%tempFile%"
    explorer /select,"%hostsFile%"
) else (
    call :PrintGreen "  Файл hosts актуален"
    if exist "%tempFile%" del /f /q "%tempFile%" 2>nul
)

echo  [90m-----------------------------------------------------------------[0m
pause > nul
goto menu


:: ЗАПУСК ТЕСТОВ =============================
:run_tests
@REM mode con cols=69 lines=15
cls
echo  [90m═══════════════════════════════════════════════════ [94mЗапуск тестов [90m════[0m
echo  [90m-----------------------------------------------------------------[0m

:: Требуется PowerShell 3.0+
powershell -NoProfile -Command "if ($PSVersionTable -and $PSVersionTable.PSVersion -and $PSVersionTable.PSVersion.Major -ge 3) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorLevel% neq 0 (
    echo   [91m[!] Требуется PowerShell 3.0 или новее.[0m
    echo   [93m[*] Пожалуйста, обновите PowerShell и запустите этот скрипт снова.[0m
    echo.
    pause
    goto menu
)

echo   [93m[*] Запуск тестов конфигурации в окне PowerShell...[0m
start "" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0utils\test zapret.ps1"
echo  [90m-----------------------------------------------------------------[0m
pause > nul
goto menu


:: Вспомогательные функции

:PrintGreen
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Green" 2>nul
exit /b

:PrintRed
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Red" 2>nul
exit /b

:PrintYellow
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Yellow" 2>nul
exit /b

:check_command
where %1 >nul 2>&1
if %errorLevel% neq 0 (
    echo [ОШИБКА] %1 не найдено в PATH
    echo Исправьте вашу переменную PATH с помощью инструкций здесь https://github.com/Flowseal/zapret-discord-youtube/issues/7490
    pause
    exit /b 1
)
exit /b 0

:check_extracted
set "extracted=1"

if not exist "%~dp0bin\" set "extracted=0"

if "%extracted%"=="0" (
    echo Zapret должен быть извлечен из архива, или папка bin не найдена по какой-то причине
    pause
    exit
)
exit /b 0