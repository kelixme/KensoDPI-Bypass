@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: Установка кодировки UTF-8
for /f "tokens=2 delims=:" %%a in ('chcp') do set "original_codepage=%%a"
set "original_codepage=%original_codepage: =%"
reg add "HKCU\Console" /v CodePage /t REG_DWORD /d 65001 /f >nul 2>&1

:: Переменные
set VER=v2.0 BETA
set SRVCDESC=AdGuardHome.Bypass - %VER%
set ADG_HOME=AdGuardHome
set SRVCDIR="%~dp0ADGHOME\lib\AdGuardHome.exe"
set ICON_PATH=%~dp0ADGHOME\favicon.ico
title %SRVCDESC%

:menu
@REM mode con cols=69 lines=30
cls

:: Чтение порта из YAML
set CURRENT_PORT=8080
set YAML_PATH=ADGHOME\lib\AdGuardHome.yaml
if exist "!YAML_PATH!" (
    for /f "tokens=*" %%a in ('findstr /c:"address:" "!YAML_PATH!"') do (
        set "line=%%a"
        set "line=!line:*address:=!"
        set "line=!line: =!"
        for /f "tokens=2 delims=:" %%b in ("!line!") do set CURRENT_PORT=%%b
    )
) else (
    if exist "AdGuardHome.yaml" (
        for /f "tokens=*" %%a in ('findstr /c:"address:" "AdGuardHome.yaml"') do (
            set "line=%%a"
            set "line=!line:*address:=!"
            set "line=!line: =!"
            for /f "tokens=2 delims=:" %%b in ("!line!") do set CURRENT_PORT=%%b
        )
    )
)

if "!CURRENT_PORT!"=="" set CURRENT_PORT=8080
set CURRENT_PORT=!CURRENT_PORT: =!


echo  [96mKensoDPI [90m[[94mAdGuardHome.Bypass [90m- [91m%VER%[90m][0m
echo  [90m-----------------------------------------------------------------[0m
:: Проверка прав администратора
net session >nul 2>&1
if %errorLevel% == 0 (
    echo  [93m Доступ: [92mПолный[0m[90m
) else (
    echo  [93m Доступ: [91mОграниченый[0m[90m / [93mЗапрос прав админа...[0m
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'" > nul
    exit
)






echo  [90m===================================== Управление [92m%ADG_HOME%[90m ====[0m
net session >nul 2>&1
if %errorLevel% == 0 (
    sc query %ADG_HOME% >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [96mСервис: [92mУстановлен[0m
        echo   [96mURL: [91mhttp://127.0.0.1:!CURRENT_PORT![0m
    ) else (
        echo   [96mСервис: [91mНе установлен[0m[90m
    )
) else (
    sc query %ADG_HOME% >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [96mСервис: [92mУстановлен[0m[90m
        echo   [96m[91mТРЕБУЮТСЯ ПРАВА АДМИНИСТРАТОРА[0m
    ) else (
        echo   [96mСервис: [91mНе установлен[0m[90m
    )
)
echo  [90m-----------------------------------------------------------------[0m
echo   [93m1 [90m-[0m [92mУстановить службу[0m
echo   [93m2 [90m-[0m [91mУдалить службу[0m
echo   [93m3 [90m-[0m [96mИзменить порт [90m[[91m!CURRENT_PORT![90m][0m
echo   [93m4 [90m-[0m [96mНастройка DNS [90m[[94mОбязательно после установки[90m][0m
echo  [90m=================================================================[0m
set /p choice=[96m  Выбор: [93m

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall_menu
if "%choice%"=="3" goto change_port
if "%choice%"=="4" goto dns_menu
goto menu

:dns_menu
@REM mode con cols=85 lines=25
@REM mode con cols=69 lines=25
cls
echo  [90m============================================== [94mНастройка DNS [90m====[0m
echo   [93m1 [90m-[0m [96mCloudFlare DNS [92m[РЕКОМЕНДУЕТСЯ][0m
echo       [96m│[90m[90m ─ Протокол ─ Первичный DNS ─ Вторичный DNS
echo       [96m├─[90m│ [90m[91mIPv4     [90m│ [94m127.0.0.1     [90m│ [94m1.1.1.1[0m
echo       [96m└─[90m│ [90m[91mIPv6     [90m│ [94m::1           [90m│ [94m2606:4700:4700::1111[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m2 [90m-[0m [96mGoogle DNS[0m
echo       [96m│[90m[90m ─ Протокол ─ Первичный DNS ─ Вторичный DNS
echo       [96m├─[90m│ [90m[91mIPv4     [90m│ [94m127.0.0.1     [90m│ [94m8.8.8.8[0m
echo       [96m└─[90m│ [90m[91mIPv6     [90m│ [94m::1           [90m│ [94m2001:4860:4860::8888[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m3 [90m-[0m [96mYandex DNS[0m
echo       [96m│[90m[90m ─ Протокол ─ Первичный DNS ─ Вторичный DNS
echo       [96m├─[90m│ [90m[91mIPv4     [90m│ [94m127.0.0.1     [90m│ [94m77.88.8.8[0m
echo       [96m└─[90m│ [90m[91mIPv6     [90m│ [94m::1           [90m│ [94m2a02:6b8::feed:0ff[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m4 [90m-[0m [96mAdGuard DNS[0m
echo       [96m│[90m[90m ─ Протокол ─ Первичный DNS ─ Вторичный DNS
echo       [96m├─[90m│ [90m[91mIPv4     [90m│ [94m127.0.0.1     [90m│ [94m94.140.14.14[0m
echo       [96m└─[90m│ [90m[91mIPv6     [90m│ [94m::1           [90m│ [94m2a10:50c0::ad1:ff[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m0[90m:[0m[96mУдалить DNS [90m─ [95mKey[90m:[93mEnter[90m [0m[96mНазад[0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
set /p dns_choice=[96m  Выбор: [93m

if "%dns_choice%"=="" goto menu
if "%dns_choice%"=="1" set DNS_NAME=CloudFlare DNS& set DNS4_1=127.0.0.1& set DNS4_2=1.1.1.1& set DNS6_1=::1& set DNS6_2=2606:4700:4700::1111& goto apply_dns_only
if "%dns_choice%"=="2" set DNS_NAME=Google DNS& set DNS4_1=127.0.0.1& set DNS4_2=8.8.8.8& set DNS6_1=::1& set DNS6_2=2001:4860:4860::8888& goto apply_dns_only
if "%dns_choice%"=="3" set DNS_NAME=Yandex DNS& set DNS4_1=127.0.0.1& set DNS4_2=77.88.8.8& set DNS6_1=::1& set DNS6_2=2a02:6b8::feed:0ff& goto apply_dns_only
if "%dns_choice%"=="4" set DNS_NAME=AdGuard DNS& set DNS4_1=127.0.0.1& set DNS4_2=94.140.14.14& set DNS6_1=::1& set DNS6_2=2a10:50c0::ad1:ff& goto apply_dns_only
if "%dns_choice%"=="0" goto remove_dns_only

echo [91m  [ОШИБКА] Неверный выбор![0m
pause
goto dns_menu

:apply_dns_only
@REM mode con cols=69 lines=30
cls
echo  [90m============================================= [94mПрименение DNS [90m====[0m
echo   [93m[*] Устанавливаются: [91m%DNS_NAME%[0m
echo   [96m│[90m[90m ─ Протокол ─ Первичный DNS ─ Вторичный DNS
echo   [96m├─[90m│ [90m[91mIPv4     [90m│ [94m%DNS4_1%     [90m│ [94m%DNS4_2%[0m
echo   [96m└─[90m│ [90m[91mIPv6     [90m│ [94m%DNS6_1%           [90m│ [94m%DNS6_2%[0m
call :apply_dns "%DNS4_1%" "%DNS4_2%" "%DNS6_1%" "%DNS6_2%"
echo  [90m-----------------------------------------------------------------[0m
echo   [92mНастройка DNS успешно выполнена![0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu

:remove_dns_only
@REM mode con cols=69 lines=30
cls
echo  [90m================================================== [94mСброс DNS [90m====[0m
echo   [93m[*] Сброс DNS настроек[0m
echo   [93m[*] Сброс DNS на автоматический режим (DHPC)...[0m
call :remove_dns
echo  [90m-----------------------------------------------------------------[0m
echo   [92mСброс DNS выполнен[0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu

:stop_and_delete_service
echo [93m  [*] Остановка и удаление службы...[0m
taskkill /f /im AdGuardHome.exe >nul 2>&1
net stop %ADG_HOME% > nul 2>&1
sc delete %ADG_HOME% > nul 2>&1
timeout /t 2 /nobreak >nul
exit /b

:create_service
echo [93m  [*] Создание службы...[0m
sc create "%ADG_HOME%" binPath= "cmd.exe /k start \"\" \"%SRVCDIR%\"" DisplayName= "%ADG_HOME%" start= auto type= own >nul 2>&1
if %errorlevel% neq 0 (
    echo [91m  [!] Ошибка при создании службы![0m
    exit /b 1
)

sc description %ADG_HOME% "%SRVCDESC%" >nul 2>&1
sc failure "%ADG_HOME%" reset= 30 actions= restart/1000/restart/1000/restart/1000 >nul 2>&1
echo [92m  [+] Служба создана[0m

echo [93m  [*] Запуск службы...[0m
start /B sc start %ADG_HOME% >nul 2>&1

sc query %ADG_HOME% >nul 2>&1
if %errorlevel% equ 0 (
    echo [92m  [+] Служба запущена[0m
) else (
    echo [91m  [!] Ошибка при запуске службы![0m
    echo [93m  [*] Запускаем AdGuardHome вручную...[0m
    start "" %SRVCDIR%
)
exit /b 0

:install
@REM mode con cols=69 lines=25
cls
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'" > nul
    exit
)

echo  [90m====================================== [94mУстановка %ADG_HOME% [90m====[0m
if not exist "ADGHOME\lib\AdGuardHome.yaml" (
    if exist "AdGuardHome.yaml" (
        copy "AdGuardHome.yaml" "ADGHOME\lib\AdGuardHome.yaml" >nul
        echo [94m  [i] Скопирован существующий файл в ADGHOME\lib\[0m
    )
)
sc query %ADG_HOME% >nul 2>&1
if %errorlevel% equ 0 (
    echo [93m  [*] Служба уже установлена. Переустановка...[0m
    call :stop_and_delete_service
    echo [92m  [+] Служба удалена для переустановки[0m
)

call :create_service
if %errorlevel% neq 0 (
    pause
    exit /b 1
)
echo [93m  [*] Создание ярлыков...[0m
call :create_shortcuts
echo [92m  [+] Ярлыки созданы[0m

:install_complete
echo  [90m-----------------------------------------------------------------[0m
echo   [92m Установка успешно завершена![0m
echo  [90m-----------------------------------------------------------------[0m
echo [93m  [*] Открытие веб-интерфейса...[0m
timeout /t 2 /nobreak >nul
start http://localhost:!CURRENT_PORT!
echo [92m  [+] Веб-интерфейс доступен: http://localhost:!CURRENT_PORT![0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu

:apply_dns
set DNS4_1=%~1
set DNS4_2=%~2
set DNS6_1=%~3
set DNS6_2=%~4

echo [93m  [*] Поиск активных адаптеров...[0m

set adapter_count=0

for /f "usebackq tokens=*" %%a in (`powershell -Command "& {Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | Select-Object -ExpandProperty Name}"`) do (
    set /a adapter_count+=1
    echo [93m  [*] Настройка адаптера: [91m%%a[0m
    
    netsh interface ipv4 delete dns name="%%a" all >nul 2>&1
    netsh interface ipv6 delete dns name="%%a" all >nul 2>&1
    
    netsh interface ipv4 set dns name="%%a" source=static addr=%DNS4_1% register=primary validate=no >nul
    if not "%DNS4_2%"=="" netsh interface ipv4 add dns name="%%a" addr=%DNS4_2% index=2 validate=no >nul
    
    netsh interface ipv6 set dns name="%%a" source=static addr=%DNS6_1% register=primary validate=no >nul
    if not "%DNS6_2%"=="" netsh interface ipv6 add dns name="%%a" addr=%DNS6_2% index=2 validate=no >nul
    echo   [96m│[90m[90m ─ Статус выполнения
    echo   [96m└─[90m│ [92mГОТОВО[0m
)
if %adapter_count%==0 (
    echo [91m  [ВНИМАНИЕ] Не найдено ни одного активного адаптера![0m
    echo [93m  [i] Проверьте подключение или запустите от имени администратора.[0m
) else (
    echo [92m  [+] Настройка завершена.
)
exit /b

:create_shortcuts
set WEB_URL=http://localhost:!CURRENT_PORT!
set SHORTCUT_NAME=AdGuard Home
set "ICON_ABS=%~dp0ADGHOME\favicon.ico"
set "ICON_ABS_PS=%ICON_ABS:\=\\%"
if exist "%ICON_ABS%" (
    set HAS_ICON=1
) else (
    set HAS_ICON=0
    echo [93m  [!] Внимание: файл иконки не найден: %ICON_ABS%[0m
    echo [93m  [!] Будут созданы ярлыки без иконки.[0m
)

powershell -Command ^
    "$WshShell = New-Object -ComObject WScript.Shell; " ^
    "$Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\%SHORTCUT_NAME%.lnk'); " ^
    "$Shortcut.TargetPath = '%WEB_URL%'; " ^
    "$Shortcut.Save(); " ^
    "if (%HAS_ICON%) { " ^
    "    $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\%SHORTCUT_NAME%.lnk'); " ^
    "    $Shortcut.IconLocation = '%ICON_ABS_PS%'; " ^
    "    $Shortcut.Save(); " ^
    "}"

powershell -Command ^
    "$WshShell = New-Object -ComObject WScript.Shell; " ^
    "$Shortcut = $WshShell.CreateShortcut('%~dp0%SHORTCUT_NAME%.lnk'); " ^
    "$Shortcut.TargetPath = '%WEB_URL%'; " ^
    "$Shortcut.Save(); " ^
    "if (%HAS_ICON%) { " ^
    "    $Shortcut = $WshShell.CreateShortcut('%~dp0%SHORTCUT_NAME%.lnk'); " ^
    "    $Shortcut.IconLocation = '%ICON_ABS_PS%'; " ^
    "    $Shortcut.Save(); " ^
    "}"

powershell -Command ^
    "$WshShell = New-Object -ComObject WScript.Shell; " ^
    "$Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\%SHORTCUT_NAME%.lnk'); " ^
    "$Shortcut.TargetPath = '%WEB_URL%'; " ^
    "$Shortcut.Save(); " ^
    "if (%HAS_ICON%) { " ^
    "    $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\%SHORTCUT_NAME%.lnk'); " ^
    "    $Shortcut.IconLocation = '%ICON_ABS_PS%'; " ^
    "    $Shortcut.Save(); " ^
    "}"

exit /b

:delete_shortcuts
set SHORTCUT_NAME=AdGuardHome

del /f /q "%USERPROFILE%\Desktop\%SHORTCUT_NAME%.lnk" 2>nul
del /f /q "%USERPROFILE%\Desktop\%SHORTCUT_NAME%.url" 2>nul
del /f /q "%~dp0%SHORTCUT_NAME%.lnk" 2>nul
del /f /q "%~dp0%SHORTCUT_NAME%.url" 2>nul
del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\%SHORTCUT_NAME%.lnk" 2>nul
del /f /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\%SHORTCUT_NAME%.url" 2>nul

exit /b

:uninstall_menu
@REM mode con cols=69 lines=10
cls
echo  [90m======================================= [94mУдаление %ADG_HOME% [90m====[0m
echo   [93m1 [90m- [91mУдалить DNS настройки[0m (автоматический DHCP)[0m
echo   [93m2 [90m- [92mСохранить текущие DNS настройки[0m
echo  [90m-----------------------------------------------------------------[0m
echo   [95mKey[90m:[93mEnter[90m [0m[96mНазад[0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
echo.
set /p dns_choice=[96m  Выбор: [93m

if "%dns_choice%"=="" goto menu
if "%dns_choice%"=="1" set REMOVE_DNS=1
if "%dns_choice%"=="2" set REMOVE_DNS=0
if not defined REMOVE_DNS goto uninstall_menu

goto uninstall

:uninstall
@REM mode con cols=69 lines=15
cls
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'" > nul
    exit
)
echo  [90m======================================= [94mУдаление %ADG_HOME% [90m====[0m
echo [93m  [*] Удаление ярлыков...[0m
call :delete_shortcuts
echo [92m  [+] Ярлыки удалены[0m
sc query %ADG_HOME% >nul 2>&1
if %errorlevel% equ 0 (
    call :stop_and_delete_service
    echo [92m  [+] Служба удалена[0m
) else (
    echo [91m  [-] Служба не найдена[0m
)
if "%REMOVE_DNS%"=="1" (
    echo [93m  [*] Сброс DNS настроек...[0m
    call :remove_dns
) else (
    echo [92m  [+] DNS настройки сохранены[0m
)
echo  [90m-----------------------------------------------------------------[0m
echo  [92m Удаление успешно завершено[0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu

:remove_dns
set adapter_count=0

for /f "usebackq tokens=*" %%a in (`powershell -Command "Get-NetAdapter -Physical | Where-Object {$_.Status -eq 'Up'} | Select-Object -ExpandProperty Name"`) do (
    set /a adapter_count+=1
    echo   [96m[*] Сброс DNS на адаптере: [91m%%a[0m
    netsh interface ipv4 set dns name="%%a" source=dhcp >nul 2>&1
    netsh interface ipv6 set dns name="%%a" source=dhcp >nul 2>&1
)
exit /b

:change_port
@REM mode con cols=85 lines=25
cls
echo  [90m======================================= [94mИзменение HTTP порта [90m====[0m
set YAML_FILE=ADGHOME\lib\AdGuardHome.yaml
if not exist "ADGHOME\lib\AdGuardHome.yaml" (
    if exist "AdGuardHome.yaml" (
        set YAML_FILE=AdGuardHome.yaml
    ) else (
        echo   [91m[ОШИБКА] Конфигурационный файл не найден![0m
        echo  [90m=================================================== [93mНажмите [94mENTER[0m
        pause > nul
        goto menu
    )
)
echo   Текущий порт: [91m!CURRENT_PORT![0m
echo  [90m-----------------------------------------------------------------[0m
echo   [95mKey[90m:[93mEnter[90m [0m[96mНазад[0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
set /p NEW_PORT=[96m  Введите новый порт: [93m

if "%NEW_PORT%"=="" (
    echo   [93m[i] Изменение отменено[0m
    echo  [90m=================================================== [93mНажмите [94mENTER[0m
    pause > nul
    goto menu
)

set "check="
for /f "delims=0123456789" %%i in ("%NEW_PORT%") do set check=%%i
if defined check (
    echo   [91m[ОШИБКА] Порт должен содержать только цифры![0m
    echo  [90m=================================================== [93mНажмите [94mENTER[0m
    pause > nul
    goto change_port
)

set SERVICE_WAS_INSTALLED=0
sc query %ADG_HOME% >nul 2>&1
if %errorlevel% equ 0 set SERVICE_WAS_INSTALLED=1

if !SERVICE_WAS_INSTALLED! equ 1 (
    echo   [93m[*] Служба установлена. Остановка и удаление службы...[0m
    call :stop_and_delete_service
    echo   [92m[+] Служба удалена[0m
)

set TEMP_FILE=%YAML_FILE%.tmp
(
    for /f "usebackq delims=" %%a in ("%YAML_FILE%") do (
        set "line=%%a"
        echo !line! | findstr /b /c:"  address:" >nul
        if !errorlevel! equ 0 (
            echo   address: 0.0.0.0:%NEW_PORT%
        ) else (
            echo !line!
        )
    )
) > "%TEMP_FILE%"
move /y "%TEMP_FILE%" "%YAML_FILE%" >nul

if "%YAML_FILE%"=="AdGuardHome.yaml" (
    if exist "lib" (
        copy "%YAML_FILE%" "ADGHOME\lib\AdGuardHome.yaml" >nul
    )
)
cls
echo  [90m======================================= [94mИзменение HTTP порта [90m====[0m
echo [92m  [+] Порт изменен с !CURRENT_PORT! на %NEW_PORT%[0m
set CURRENT_PORT=%NEW_PORT%

echo [93m  [*] Обновление ярлыков...[0m
call :delete_shortcuts
call :create_shortcuts
echo [92m  [+] Ярлыки обновлены с новым портом[0m

if !SERVICE_WAS_INSTALLED! equ 1 (
    echo [93m  [*] Ждем 3 секунды перед переустановкой службы...[0m
    timeout /t 3 /nobreak >nul
    echo [93m  [*] Переустановка службы...[0m
    call :create_service
    echo [92m  [+] Служба переустановлена[0m
) else (
    echo [93m  [i] Служба не была установлена, переустановка не требуется[0m
)

echo.
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu