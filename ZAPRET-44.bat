@echo off
set LOCAL_VERSION=v2.6b BETA
set SRVCDESC=Zapret.Bypass - %LOCAL_VERSION%
title %SRVCDESC%

:: ‚­¥è­¨¥ ª®¬ ­¤ë
if "%~1"=="status_zapret" (
    call :test_service zapret soft
    call :tcp_enable
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

if "%~1"=="check_updates" (
    if defined NO_UPDATE_CHECK exit /b

    if exist "%~dp0ZAPRET\utils\check_updates.enabled" (
        if not "%~2"=="soft" (
            start /b "%~f0" check_updates soft
        ) else (
            call :service_check_updates soft
        )
    )

    exit /b
)

:: Œ…ž ================================
setlocal EnableDelayedExpansion
:menu
@REM mode con cols=69 lines=30
cls
call :ipset_switch_status
call :game_switch_status
call :check_updates_switch_status
call :get_strategy_name

set "menu_choice=null"

echo  [96mKensoDPI [90m[[94mZapret.Bypass [90m- [91m%LOCAL_VERSION%[90m][0m
echo  [90m-----------------------------------------------------------------[0m
:: à®¢¥àª  ¯à ¢  ¤¬¨­¨áâà â®à 
net session >nul 2>&1
if %errorLevel% == 0 (
    echo  [93m „®áâã¯: [92m®«­ë©[0m[90m
) else (
    echo  [93m „®áâã¯: [91mŽ£à ­¨ç¥­ë©[0m[90m / [93m‡ ¯à®á ¯à ¢  ¤¬¨­ ...[0m
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'" > nul
    exit
)
echo  [90m========================================== “¯à ¢«¥­¨¥ [92mZapret[90m ====[0m
net session >nul 2>&1
if %errorLevel% == 0 (
    sc query "zapret" >nul 2>&1
    if !errorlevel!==0 (
        for /f "tokens=2*" %%A in ('reg query "HKLM\System\CurrentControlSet\Services\zapret" /v zapret-discord-youtube 2^>nul') do set SELECT_SRV=%%B
    )
    tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
    if !errorlevel! equ 0 (
        echo   [96m‘¥à¢¨á: [92m“áâ ­®¢«¥­[0m
        echo   [96m‘âà â¥£¨ï: [93m!SELECT_SRV![0m
    ) else (
        echo   [96m‘¥à¢¨á: [91m¥ ãáâ ­®¢«¥­[0m[90m
    )
) else (
    tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
    if !errorlevel! equ 0 (
        echo   [96m‘¥à¢¨á: [92m“áâ ­®¢«¥­[0m[90m
        echo   [96m[91m’…“ž’‘Ÿ €‚€ €„Œˆˆ‘’€’Ž€[0m
    ) else (
        echo   [96m‘¥à¢¨á: [91m¥ ãáâ ­®¢«¥­[0m[90m
    )
)

echo  [90m-----------------------------------------------------------------[0m
echo    [93m1[90m. [92m“áâ ­®¢¨âì á«ã¦¡ã[0m
echo    [93m2[90m. [91m“¤ «¨âì á«ã¦¡ë[0m
echo    [93m3[90m. [95mŠ®­ä¨£ãà â®à[0m   [90m[[93mlist-general.txt[90m][0m
echo    [93m4[90m. [96mà®¢¥à¨âì áâ âãá[0m
echo    [93m5[90m. [96mˆ£à®¢®© ä¨«ìâà[0m [90m[[93m!GameFilterStatus![90m][0m
echo    [93m6[90m. [96mIPSet ä¨«ìâà[0m   [90m[[93m!IPsetStatus![90m][0m
echo    [93m7[90m. [96mŽ¡­®¢¨âì á¯¨á®ª IPSet[0m
echo    [93m8[90m. [96mŽ¡­®¢¨âì ä ©« hosts[0m
echo    [93m9[90m. [96m‡ ¯ãáâ¨âì ¤¨ £­®áâ¨ªã[0m
echo   [93m10[90m. [96m‡ ¯ãáâ¨âì â¥áâë[0m
echo  [90m=================================================================[0m
set /p menu_choice=[96m  ‚ë¡®à: [93m

if "%menu_choice%"=="" goto menu
if "%menu_choice%"=="1" goto service_install
if "%menu_choice%"=="2" goto service_remove
if "%menu_choice%"=="3" goto list_editor_init
if "%menu_choice%"=="4" goto service_status
if "%menu_choice%"=="5" goto game_switch
if "%menu_choice%"=="6" goto ipset_switch
if "%menu_choice%"=="7" goto ipset_update
if "%menu_choice%"=="8" goto hosts_update
if "%menu_choice%"=="9" goto service_diagnostics
if "%menu_choice%"=="10" goto run_tests
goto menu

:: ‚Š‹ž—…ˆ… TCP ==========================
:tcp_enable
netsh interface tcp show global | findstr /i "timestamps" | findstr /i "enabled" > nul || netsh interface tcp set global timestamps=enabled > nul 2>&1
exit /b

:: ‡€ƒ“‡Š€ Ž‹œ‡Ž‚€’…‹œ‘Šˆ• ‘ˆ‘ŠŽ‚ =====================
:load_user_lists
set "LISTS_PATH=%~dp0ZAPRET\lists\"

if not exist "%LISTS_PATH%ipset-exclude-user.txt" (
    echo 203.0.113.113/32>"%LISTS_PATH%ipset-exclude-user.txt"
)
if not exist "%LISTS_PATH%list-general-user.txt" (
    echo # Never leave this file empty>"%LISTS_PATH%list-general-user.txt"
    echo domain.example.abc>>"%LISTS_PATH%list-general-user.txt"
)
if not exist "%LISTS_PATH%list-exclude-user.txt" (
    echo domain.example.abc>"%LISTS_PATH%list-exclude-user.txt"
)

exit /b

:: ‘’€’“‘ ==============================
:service_status
@REM mode con cols=69 lines=25
cls
echo  [90m============================================== [94m‘â âãá á«ã¦¡ë [90m====[0m

sc query "zapret" >nul 2>&1
if !errorlevel!==0 (
    for /f "tokens=2*" %%A in ('reg query "HKLM\System\CurrentControlSet\Services\zapret" /v zapret-discord-youtube 2^>nul') do echo   [96m‘âà â¥£¨ï ãáâ ­®¢«¥­  ¨§:[0m [93m%%B[0m
)

call :test_service zapret
call :test_service WinDivert

set "BIN_PATH=%~dp0ZAPRET\bin\"
if not exist "%BIN_PATH%\*.sys" (
    call :PrintRed "  ” ©« WinDivert64.sys … €‰„…."
)
@REM echo.

tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
if !errorlevel!==0 (
    call :PrintGreen "  Ž¡å®¤ winws.exe § ¯ãé¥­."
) else (
    call :PrintRed "  Ž¡å®¤ winws.exe ­¥ § ¯ãé¥­."
)

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:test_service
set "ServiceName=%~1"
set "ServiceStatus="

for /f "tokens=3 delims=: " %%A in ('sc query "%ServiceName%" ^| findstr /i "STATE"') do set "ServiceStatus=%%A"
set "ServiceStatus=%ServiceStatus: =%"

if "%ServiceStatus%"=="RUNNING" (
    if "%~2"=="soft" (
        echo "%ServiceName%" “†… ‡€“™… ª ª á«ã¦¡ , á­ ç «  ¨á¯®«ì§ã©â¥ "service.bat" ¨ ¢ë¡¥à¨â¥ "Remove Services", ¥á«¨ å®â¨â¥ § ¯ãáâ¨âì  ¢â®­®¬­ë© bat.
        pause
        exit /b
    ) else (
        echo   [92m‘«ã¦¡  %ServiceName% ‡ ¯ãé¥­ [0m
    )
) else if "%ServiceStatus%"=="STOP_PENDING" (
    call :PrintYellow "  %ServiceName% ¢ á®áâ®ï­¨¨ STOP_PENDING, íâ® ¬®¦¥â ¡ëâì ¢ë§¢ ­® ª®­ä«¨ªâ®¬ á ¤àã£¨¬ ®¡å®¤®¬."
) else if not "%~2"=="soft" (
    echo   [91m‘«ã¦¡  %ServiceName% ­¥ § ¯ãé¥­ [0m
)

exit /b

:: “„€‹…ˆ… ==============================
:service_remove
@REM mode con cols=69 lines=15
cls
echo  [90m============================================= [94m“¤ «¥­¨¥ á«ã¦¡ [90m====[0m

set SRVCNAME=zapret
sc query "!SRVCNAME!" >nul 2>&1
if !errorlevel!==0 (
    echo   [93m[*] Žáâ ­®¢ª  á«ã¦¡ë...[0m
    net stop %SRVCNAME% >nul 2>&1
    echo   [93m[*] “¤ «¥­¨¥ á«ã¦¡ë...[0m
    sc delete %SRVCNAME% >nul 2>&1
    echo   [92m[+] ‘«ã¦¡  ã¤ «¥­ .[0m
) else (
    echo   [91m[-] ‘«ã¦¡  "%SRVCNAME%" ­¥ ãáâ ­®¢«¥­ .[0m
)

tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
if !errorlevel!==0 (
    taskkill /IM winws.exe /F > nul
    echo   [92m[+] winws.exe § ¢¥àè¥­.[0m
)

sc query "WinDivert" >nul 2>&1
if !errorlevel!==0 (
    net stop "WinDivert" >nul 2>&1
    sc delete "WinDivert" >nul 2>&1
    echo   [92m[+] WinDivert ã¤ «¥­.[0m
)
net stop "WinDivert14" >nul 2>&1
sc delete "WinDivert14" >nul 2>&1

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: “‘’€Ž‚Š€ =============================
:service_install
@REM mode con cols=69 lines=25
cls
echo  [90m=========================================== [94m“áâ ­®¢ª  á«ã¦¡ë [90m====[0m

:: Main
cd /d "%~dp0ZAPRET\"
set "BIN_PATH=%~dp0ZAPRET\bin\"
set "LISTS_PATH=%~dp0ZAPRET\lists\"
echo   [95m‚ë¡¥à¨â¥ ®¤¨­ ¨§ ¢ à¨ ­â®¢:[0m
echo  [90m-----------------------------------------------------------------[0m

:: ‘¡®à á¯¨áª  ä ©«®¢ .bat (¨áª«îç ï service*.bat)
set "count=0"
for /f "delims=" %%F in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '.' -Filter '*.bat' | Where-Object { $_.Name -notlike 'service*' } | Sort-Object { [Regex]::Replace($_.Name, '(\d+)', { $args[0].Value.PadLeft(8, '0') }) } | ForEach-Object { $_.BaseName }"') do (
    set /a count+=1
    set "file!count!=%%F.bat"
    set "name!count!=%%F"
)

:: Žâ®¡à ¦¥­¨¥ ¢ áâ®«¡æë (¯® 20 áâà®ª ¢ áâ®«¡æ¥)
set "rows=20"
set /a "cols=(count + rows - 1) / rows"
if %cols% lss 1 set "cols=1"

:: ‚ëç¨á«ï¥¬ ¬ ªá¨¬ «ì­ãî ¤«¨­ã ¨¬¥­¨ ¤«ï Š€†„ŽƒŽ áâ®«¡æ 
for /l %%c in (1,1,%cols%) do (
    set "max_len_%%c=0"
    for /l %%r in (1,1,%rows%) do (
        set /a "idx=%%r + (%%c - 1) * rows"
        if !idx! leq !count! (
            call set "fname=%%name!idx!%%"
            call :strlen fname
            if !len! gtr !max_len_%%c! set "max_len_%%c=!len!"
        )
    )
)

for /l %%r in (1,1,%rows%) do (
    set "line="
    for /l %%c in (1,1,%cols%) do (
        set /a "idx=%%r + (%%c - 1) * rows"
        if !idx! leq !count! (
            set "num=!idx!"
            if !num! lss 10 (set "num= !num!") else (set "num=!num!")
            
            :: ®«ãç ¥¬ ¨¬ï ä ©« 
            call set "fname=%%name!idx!%%"
            
            :: ®«ãç ¥¬ ¬ ªá¨¬ «ì­ãî ¤«¨­ã ¤«ï íâ®£® áâ®«¡æ 
            call set "max_len=%%max_len_%%c%%"
            
            :: ‚ëç¨á«ï¥¬ ®âáâã¯ ¤«ï ¢ëà ¢­¨¢ ­¨ï
            call :strlen fname
            set /a "pad_len=max_len - len"
            
            set "spaces="
            for /l %%p in (1,1,!pad_len!) do set "spaces=!spaces! "
            
            :: „®¡ ¢«ï¥¬ ¢ áâà®ªã á ¤¢ã¬ï ¯à®¡¥« ¬¨ ¬¥¦¤ã áâ®«¡æ ¬¨
            if "!line!"=="" (
                set "line=  [93m!num![90m.[0m [96m!fname!!spaces![0m"
            ) else (
                set "line=!line!  [93m!num![90m.[0m [96m!fname!!spaces![0m"
            )
        )
    )
    echo !line!
)

echo  [90m-----------------------------------------------------------------[0m

:: ‚ë¡®à ä ©« 
set "choice="
set /p "choice=[96m  ‚¢¥¤¨â¥ ­®¬¥à ä ©« : [93m"
if "!choice!"=="" (
    @REM echo   [91m¥¢¥à­ë© ¢ë¡®à, ¢ëå®¤...[0m
    @REM pause
    goto menu
)

:: à®¢¥àï¥¬, çâ® choice - íâ® ç¨á«®
echo !choice! | findstr /R "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo   [91m‚¢¥¤¨â¥ ª®àà¥ªâ­ë© ­®¬¥à![0m
    pause
    goto service_install
)

:: à®¢¥àï¥¬, çâ® ­®¬¥à ­¥ ¯à¥¢ëè ¥â ª®«¨ç¥áâ¢® ä ©«®¢
if !choice! gtr !count! (
    echo   [91m®¬¥à ¯à¥¢ëè ¥â ª®«¨ç¥áâ¢® ¤®áâã¯­ëå ä ©«®¢ (!count!)[0m
    pause
    goto service_install
)

set "selectedFile=!file%choice%!"
if not defined selectedFile (
    echo   [91m” ©« á ­®¬¥à®¬ !choice! ­¥ ­ ©¤¥­[0m
    pause
    goto service_install
)

:: €à£ã¬¥­âë, §  ª®â®àë¬¨ ¤®«¦­® á«¥¤®¢ âì §­ ç¥­¨¥
set "args_with_value=sni host altorder"

::  §¡®à  à£ã¬¥­â®¢ (mergeargs: 2=­ ç «® ¯ à ¬¥âà |3= à£ã¬¥­â á® §­ ç¥­¨¥¬|1=¯ à ¬¥âàë|0=¯® ã¬®«ç ­¨î)
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
                        set "arg=\!QUOTE!@%~dp0ZAPRET\!arg:~1!\!QUOTE!"
                    ) else if "!arg:~0,5!"=="%%BIN%%" (
                        set "arg=\!QUOTE!!BIN_PATH!!arg:~5!\!QUOTE!"
                    ) else if "!arg:~0,7!"=="%%LISTS%%" (
                        set "arg=\!QUOTE!!LISTS_PATH!!arg:~7!\!QUOTE!"
                    ) else (
                        set "arg=\!QUOTE!%~dp0ZAPRET\!arg!\!QUOTE!"
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

:: ‘®§¤ ­¨¥ á«ã¦¡ë á à §®¡à ­­ë¬¨  à£ã¬¥­â ¬¨
call :tcp_enable

set ARGS=%args%
call set "ARGS=%%ARGS:EXCL_MARK=^!%%"
echo  [90m-----------------------------------------------------------------[0m
echo   [93m[*] ‚ë¡à ­ë© ¯à¥á¥â: !selectedFile![0m
@REM echo   [93m[*] ˆâ®£®¢ë¥  à£ã¬¥­âë: !ARGS![0m
set SRVCNAME=zapret

net stop %SRVCNAME% >nul 2>&1
sc delete %SRVCNAME% >nul 2>&1
echo   [93m[*] ‘®§¤ ­¨¥ á«ã¦¡ë...[0m
sc create %SRVCNAME% binPath= "\"%BIN_PATH%winws.exe\" !ARGS!" DisplayName= "zapret" start= auto >nul 2>&1
sc description %SRVCNAME% "à®£à ¬¬­®¥ ®¡¥á¯¥ç¥­¨¥ Zapret ¤«ï ®¡å®¤  DPI" >nul 2>&1
echo   [93m[*] ‡ ¯ãáª á«ã¦¡ë...[0m
sc start %SRVCNAME% >nul 2>&1
for %%F in ("!file%choice%!") do (
    set "filename=%%~nF"
)
reg add "HKLM\System\CurrentControlSet\Services\zapret" /v zapret-discord-youtube /t REG_SZ /d "!filename!" /f >nul 2>&1
echo   [92m[+] ‘«ã¦¡  ãá¯¥è­® ãáâ ­®¢«¥­ ![0m

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: ”ã­ªæ¨ï ¤«ï ¯®¤áçñâ  ¤«¨­ë áâà®ª¨
:strlen
set "len=0"
if "!%1!"=="" goto :eof
set "temp_str=!%1!"
:strlen_loop
if not "!temp_str!"=="" (
    set "temp_str=!temp_str:~1!"
    set /a len+=1
    goto strlen_loop
)
goto :eof

:: Ž‚…Š€ ŽŽ‚‹…ˆ‰ =======================
:service_check_updates
chcp 437 > nul
cls

:: Set current version and URLs
set "GITHUB_VERSION_URL=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/.service/version.txt"
set "GITHUB_RELEASE_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/tag/"
set "GITHUB_DOWNLOAD_URL=https://github.com/Flowseal/zapret-discord-youtube/releases/latest"

echo  [90m=========================================== [94mà®¢¥àª  ®¡­®¢«¥­¨© [90m====[0m

:: Get the latest version from GitHub
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Invoke-WebRequest -Uri \"%GITHUB_VERSION_URL%\" -Headers @{\"Cache-Control\"=\"no-cache\"} -UseBasicParsing -TimeoutSec 5).Content.Trim()" 2^>nul') do set "GITHUB_VERSION=%%A"

:: Error handling
if not defined GITHUB_VERSION (
    echo   [93m[!] à¥¤ã¯à¥¦¤¥­¨¥: ­¥ ã¤ «®áì ¯®«ãç¨âì ¯®á«¥¤­îî ¢¥àá¨î. â® ¯à¥¤ã¯à¥¦¤¥­¨¥ ­¥ ¢«¨ï¥â ­  à ¡®âã zapret[0m
    timeout /T 9 >nul
    if "%1"=="soft" exit 
    goto menu
)

:: Version comparison
if "%LOCAL_VERSION%"=="%GITHUB_VERSION%" (
    echo   [92m[+] “áâ ­®¢«¥­  ¯®á«¥¤­ïï ¢¥àá¨ï: %LOCAL_VERSION%[0m
    
    if "%1"=="soft" exit 
    pause
    goto menu
) 

echo   [93m[!] „®áâã¯­  ­®¢ ï ¢¥àá¨ï: %GITHUB_VERSION%[0m
echo   [96m[+] ‘âà ­¨æ  à¥«¨§ : %GITHUB_RELEASE_URL%%GITHUB_VERSION%[0m

echo   [93m[*] Žâªàëâ¨¥ áâà ­¨æë § £àã§ª¨...[0m
start "" "%GITHUB_DOWNLOAD_URL%"

if "%1"=="soft" exit 
pause
goto menu

:: ……Š‹ž—€’…‹œ Ž‚…Šˆ ŽŽ‚‹…ˆ‰ =================
:check_updates_switch_status
set "checkUpdatesFlag=%~dp0ZAPRET\utils\check_updates.enabled"

if exist "%checkUpdatesFlag%" (
    set "CheckUpdatesStatus=‚ª«îç¥­"
) else (
    set "CheckUpdatesStatus=Žâª«îç¥­"
)
exit /b

:check_updates_switch
cls
echo  [90m=========================================== [94m€¢â®-¯à®¢¥àª  ®¡­®¢«¥­¨© [90m====[0m

set "checkUpdatesFlag=%~dp0ZAPRET\utils\check_updates.enabled"

if not exist "%checkUpdatesFlag%" (
    echo   [93m[*] ‚ª«îç¥­¨¥  ¢â®-¯à®¢¥àª¨ ®¡­®¢«¥­¨©...[0m
    echo ENABLED > "%checkUpdatesFlag%"
    echo   [92m[+] €¢â®-¯à®¢¥àª  ®¡­®¢«¥­¨© ¢ª«îç¥­ [0m
) else (
    echo   [93m[*] Žâª«îç¥­¨¥  ¢â®-¯à®¢¥àª¨ ®¡­®¢«¥­¨©...[0m
    del /f /q "%checkUpdatesFlag%" >nul 2>&1
    echo   [92m[+] €¢â®-¯à®¢¥àª  ®¡­®¢«¥­¨© ®âª«îç¥­ [0m
)

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: „ˆ€ƒŽ‘’ˆŠ€ =========================
:service_diagnostics
@REM mode con cols=69 lines=30
cls
echo  [90m=================================================== [94m„¨ £­®áâ¨ª  [90m====[0m

:: Base Filtering Engine
sc query BFE | findstr /I "RUNNING" > nul
if !errorlevel!==0 (
    call :PrintGreen "  à®¢¥àª  Base Filtering Engine ¯à®©¤¥­ "
) else (
    call :PrintRed "  [X] Base Filtering Engine ­¥ § ¯ãé¥­ . â  á«ã¦¡  ­¥®¡å®¤¨¬  ¤«ï à ¡®âë zapret"
)
echo.

:: à®¢¥àª  ¯à®ªá¨
set "proxyEnabled=0"
set "proxyServer="

for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2^>nul ^| findstr /i "ProxyEnable"') do (
    if "%%B"=="0x1" set "proxyEnabled=1"
)

if !proxyEnabled!==1 (
    for /f "tokens=2*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2^>nul ^| findstr /i "ProxyServer"') do (
        set "proxyServer=%%B"
    )
    
    call :PrintYellow "  [?) ‘¨áâ¥¬­ë© ¯à®ªá¨ ¢ª«îç¥­: !proxyServer!"
    call :PrintYellow "  “¡¥¤¨â¥áì, çâ® ®­ ¤¥©áâ¢¨â¥«¥­, ¨«¨ ®âª«îç¨â¥ ¥£®, ¥á«¨ ¢ë ­¥ ¨á¯®«ì§ã¥â¥ ¯à®ªá¨"
) else (
    call :PrintGreen "  à®¢¥àª  ¯à®ªá¨ ¯à®©¤¥­ "
)
echo.

:: à®¢¥àª  ¢à¥¬¥­­ëå ¬¥â®ª TCP
netsh interface tcp show global | findstr /i "timestamps" | findstr /i "enabled" > nul
if !errorlevel!==0 (
    call :PrintGreen "  à®¢¥àª  ¢à¥¬¥­­ëå ¬¥â®ª TCP ¯à®©¤¥­ "
) else (
    call :PrintYellow "  [?) ‚à¥¬¥­­ë¥ ¬¥âª¨ TCP ®âª«îç¥­ë. ‚ª«îç¥­¨¥ ¬¥â®ª..."
    netsh interface tcp set global timestamps=enabled > nul 2>&1
    if !errorlevel!==0 (
        call :PrintGreen "  ‚à¥¬¥­­ë¥ ¬¥âª¨ TCP ãá¯¥è­® ¢ª«îç¥­ë"
    ) else (
        call :PrintRed "  [X] ¥ ã¤ «®áì ¢ª«îç¨âì ¢à¥¬¥­­ë¥ ¬¥âª¨ TCP"
    )
)
echo.

:: AdguardSvc.exe
tasklist /FI "IMAGENAME eq AdguardSvc.exe" | find /I "AdguardSvc.exe" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X]  ©¤¥­ ¯à®æ¥áá Adguard. Adguard ¬®¦¥â ¢ë§ë¢ âì ¯à®¡«¥¬ë á Discord"
    call :PrintRed "  https://github.com/Flowseal/zapret-discord-youtube/issues/417"
) else (
    call :PrintGreen "  à®¢¥àª  Adguard ¯à®©¤¥­ "
)
echo.

:: Killer
sc query | findstr /I "Killer" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X]  ©¤¥­ë á«ã¦¡ë Killer. Killer ª®­ä«¨ªâã¥â á zapret"
    call :PrintRed "  https://github.com/Flowseal/zapret-discord-youtube/issues/2512#issuecomment-2821119513"
) else (
    call :PrintGreen "  à®¢¥àª  Killer ¯à®©¤¥­ "
)
echo.

:: Intel Connectivity Network Service
sc query | findstr /I "Intel" | findstr /I "Connectivity" | findstr /I "Network" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X]  ©¤¥­  á«ã¦¡  Intel Connectivity Network Service. Ž­  ª®­ä«¨ªâã¥â á zapret"
    call :PrintRed "  https://github.com/ValdikSS/GoodbyeDPI/issues/541#issuecomment-2661670982"
) else (
    call :PrintGreen "  à®¢¥àª  Intel Connectivity ¯à®©¤¥­ "
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
    call :PrintRed "  [X]  ©¤¥­ë á«ã¦¡ë Check Point. Check Point ª®­ä«¨ªâã¥â á zapret"
    call :PrintRed "  ®¯à®¡ã©â¥ ã¤ «¨âì Check Point"
) else (
    call :PrintGreen "  à®¢¥àª  Check Point ¯à®©¤¥­ "
)
echo.

:: SmartByte
sc query | findstr /I "SmartByte" > nul
if !errorlevel!==0 (
    call :PrintRed "  [X]  ©¤¥­ë á«ã¦¡ë SmartByte. SmartByte ª®­ä«¨ªâã¥â á zapret"
    call :PrintRed "  ®¯à®¡ã©â¥ ã¤ «¨âì ¨«¨ ®âª«îç¨âì SmartByte ç¥à¥§ services.msc"
) else (
    call :PrintGreen "  à®¢¥àª  SmartByte ¯à®©¤¥­ "
)
echo.

:: WinDivert64.sys ä ©«
set "BIN_PATH=%~dp0ZAPRET\bin\"
if not exist "%BIN_PATH%\*.sys" (
    call :PrintRed "  ” ©« WinDivert64.sys … €‰„…."
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
    call :PrintYellow "  [?)  ©¤¥­ë VPN á«ã¦¡ë:!VPN_SERVICES!. ¥ª®â®àë¥ VPN ¬®£ãâ ª®­ä«¨ªâ®¢ âì á zapret"
    call :PrintYellow "  “¡¥¤¨â¥áì, çâ® ¢á¥ VPN ®âª«îç¥­ë"
) else (
    call :PrintGreen "  à®¢¥àª  VPN ¯à®©¤¥­ "
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
    call :PrintYellow "  [?) “¡¥¤¨â¥áì, çâ® ¢ë ­ áâà®¨«¨ ¡¥§®¯ á­ë© DNS ¢ ¡à ã§¥à¥ á ª ª¨¬-«¨¡® ¯à®¢ ©¤¥à®¬ DNS ­¥ ¯® ã¬®«ç ­¨î,"
    call :PrintYellow "  …á«¨ ¢ë ¨á¯®«ì§ã¥â¥ Windows 11, ¢ë ¬®¦¥â¥ ­ áâà®¨âì § è¨äà®¢ ­­ë© DNS ¢ ­ áâà®©ª å, çâ®¡ë áªàëâì íâ® ¯à¥¤ã¯à¥¦¤¥­¨¥"
) else (
    call :PrintGreen "  à®¢¥àª  ¡¥§®¯ á­®£® DNS ¯à®©¤¥­ "
)
echo.

:: à®¢¥àª  ä ©«  hosts
set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
if exist "%hostsFile%" (
    set "yt_found=0"
    >nul 2>&1 findstr /I "youtube.com" "%hostsFile%" && set "yt_found=1"
    >nul 2>&1 findstr /I "youtu.be" "%hostsFile%" && set "yt_found=1"
    if !yt_found!==1 (
        call :PrintYellow "  [?) ‚ è ä ©« hosts á®¤¥à¦¨â § ¯¨á¨ ¤«ï youtube.com ¨«¨ youtu.be. â® ¬®¦¥â ¢ë§¢ âì ¯à®¡«¥¬ë á ¤®áâã¯®¬ ª YouTube"
    )
)

:: Š®­ä«¨ªâ WinDivert
tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" > nul
set "winws_running=!errorlevel!"

sc query "WinDivert" | findstr /I "RUNNING STOP_PENDING" > nul
set "windivert_running=!errorlevel!"

if !winws_running! neq 0 if !windivert_running!==0 (
    call :PrintYellow "  [?) winws.exe ­¥ § ¯ãé¥­, ­® á«ã¦¡  WinDivert  ªâ¨¢­ . ®¯ëâª  ã¤ «¨âì WinDivert..."
    
    net stop "WinDivert" >nul 2>&1
    sc delete "WinDivert" >nul 2>&1
    sc query "WinDivert" >nul 2>&1
    if !errorlevel!==0 (
        call :PrintRed "  [X] ¥ ã¤ «®áì ã¤ «¨âì WinDivert. à®¢¥àª  ª®­ä«¨ªâãîé¨å á«ã¦¡..."
        
        set "conflicting_services=GoodbyeDPI"
        set "found_conflict=0"
        
        for %%s in (!conflicting_services!) do (
            sc query "%%s" >nul 2>&1
            if !errorlevel!==0 (
                call :PrintYellow "  [?)  ©¤¥­  ª®­ä«¨ªâãîé ï á«ã¦¡ : %%s. Žáâ ­®¢ª  ¨ ã¤ «¥­¨¥..."
                net stop "%%s" >nul 2>&1
                sc delete "%%s" >nul 2>&1
                if !errorlevel!==0 (
                    call :PrintGreen "  ‘«ã¦¡  ãá¯¥è­® ã¤ «¥­ : %%s"
                ) else (
                    call :PrintRed "  [X] ¥ ã¤ «®áì ã¤ «¨âì á«ã¦¡ã: %%s"
                )
                set "found_conflict=1"
            )
        )
        
        if !found_conflict!==0 (
            call :PrintRed "  [X] Š®­ä«¨ªâãîé¨å á«ã¦¡ ­¥ ­ ©¤¥­®. à®¢¥àìâ¥ ¢àãç­ãî, ­¥ ¨á¯®«ì§ã¥â «¨ ª ª®©-«¨¡® ¤àã£®© ®¡å®¤ WinDivert."
        ) else (
            call :PrintYellow "  [?) ®¯ëâª  á­®¢  ã¤ «¨âì WinDivert..."

            net stop "WinDivert" >nul 2>&1
            sc delete "WinDivert" >nul 2>&1
            sc query "WinDivert" >nul 2>&1
            if !errorlevel! neq 0 (
                call :PrintGreen "  WinDivert ãá¯¥è­® ã¤ «¥­ ¯®á«¥ ã¤ «¥­¨ï ª®­ä«¨ªâãîé¨å á«ã¦¡"
            ) else (
                call :PrintRed "  [X] WinDivert ¢á¥ ¥é¥ ­¥ ¬®¦¥â ¡ëâì ã¤ «¥­. à®¢¥àìâ¥ ¢àãç­ãî, ­¥ ¨á¯®«ì§ã¥â «¨ ª ª®©-«¨¡® ¤àã£®© ®¡å®¤ WinDivert."
            )
        )
    ) else (
        call :PrintGreen "  WinDivert ãá¯¥è­® ã¤ «¥­"
    )
    
    echo.
)

:: Š®­ä«¨ªâãîé¨¥ ®¡å®¤ë
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
    call :PrintRed "  [X]  ©¤¥­ë ª®­ä«¨ªâãîé¨¥ á«ã¦¡ë ®¡å®¤ : !found_conflicts!"
    
    set "CHOICE="
    set /p "CHOICE=  ‚ë å®â¨â¥ ã¤ «¨âì íâ¨ ª®­ä«¨ªâãîé¨¥ á«ã¦¡ë? (Y/N) (¯® ã¬®«ç ­¨î: N) "
    if "!CHOICE!"=="" set "CHOICE=N"
    if "!CHOICE!"=="y" set "CHOICE=Y"
    
    if /i "!CHOICE!"=="Y" (
        for %%s in (!found_conflicts!) do (
            call :PrintYellow "  Žáâ ­®¢ª  ¨ ã¤ «¥­¨¥ á«ã¦¡ë: %%s"
            net stop "%%s" >nul 2>&1
            sc delete "%%s" >nul 2>&1
            if !errorlevel!==0 (
                call :PrintGreen "  ‘«ã¦¡  ãá¯¥è­® ã¤ «¥­ : %%s"
            ) else (
                call :PrintRed "  [X] ¥ ã¤ «®áì ã¤ «¨âì á«ã¦¡ã: %%s"
            )
        )

        net stop "WinDivert" >nul 2>&1
        sc delete "WinDivert" >nul 2>&1
        net stop "WinDivert14" >nul 2>&1
        sc delete "WinDivert14" >nul 2>&1
    )
    
    echo.
)

:: Žç¨áâª  ªíè  Discord
set "CHOICE="
set /p "CHOICE=  ‚ë å®â¨â¥ ®ç¨áâ¨âì ªíè Discord? (Y/N) (¯® ã¬®«ç ­¨î: Y)  "
if "!CHOICE!"=="" set "CHOICE=Y"
if "!CHOICE!"=="y" set "CHOICE=Y"

if /i "!CHOICE!"=="Y" (
    tasklist /FI "IMAGENAME eq Discord.exe" | findstr /I "Discord.exe" > nul
    if !errorlevel!==0 (
        echo   [93m[*] Discord § ¯ãé¥­, § ªàëâ¨¥...[0m
        taskkill /IM Discord.exe /F > nul
        if !errorlevel! == 0 (
            call :PrintGreen "  Discord ãá¯¥è­® § ªàëâ"
        ) else (
            call :PrintRed "  ¥ ã¤ «®áì § ªàëâì Discord"
        )
    )

    set "discordCacheDir=%appdata%\discord"

    for %%d in ("Cache" "Code Cache" "GPUCache") do (
        set "dirPath=!discordCacheDir!\%%~d"
        if exist "!dirPath!" (
            rd /s /q "!dirPath!" 2>nul
            if !errorlevel!==0 (
                call :PrintGreen "  “á¯¥è­® ã¤ «¥­® !dirPath!"
            ) else (
                call :PrintRed "  ¥ ã¤ «®áì ã¤ «¨âì !dirPath!"
            )
        ) else (
            echo   [90m[!] !dirPath! ­¥ áãé¥áâ¢ã¥â[0m
        )
    )
)
echo.

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: ˆƒŽ‚Ž‰ ……Š‹ž—€’…‹œ ========================
:game_switch_status

set "gameFlagFile=%~dp0ZAPRET\utils\game_filter.enabled"

if not exist "%gameFlagFile%" (
    set "GameFilterStatus=Žâª«îç¥­"
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
    set "GameFilterStatus=‚ª«îç¥­ - TCP/UDP"
    set "GameFilter=1024-65535"
    set "GameFilterTCP=1024-65535"
    set "GameFilterUDP=1024-65535"
) else if /i "%GameFilterMode%"=="tcp" (
    set "GameFilterStatus=‚ª«îç¥­ - TCP"
    set "GameFilter=1024-65535"
    set "GameFilterTCP=1024-65535"
    set "GameFilterUDP=12"
) else (
    set "GameFilterStatus=‚ª«îç¥­ - UDP"
    set "GameFilter=1024-65535"
    set "GameFilterTCP=12"
    set "GameFilterUDP=1024-65535"
)
exit /b

:game_switch
@REM mode con cols=69 lines=20
cls
echo  [90m============================================= [94mˆ£à®¢®© ä¨«ìâà [90m====[0m
echo   [93m0[90m -[0m [91mŽâª«îç¨âì[0m
echo   [93m1[90m -[0m [96mTCP ¨ UDP[0m
echo   [93m2[90m -[0m [96m’®«ìª® TCP[0m
echo   [93m3[90m -[0m [96m’®«ìª® UDP[0m
echo  [90m=================================================================[0m
set "GameFilterChoice=0"
set /p "GameFilterChoice=[96m  ‚ë¡®à: [93m"
if "%GameFilterChoice%"=="" set "GameFilterChoice=0"

if "%GameFilterChoice%"=="0" (
    if exist "%gameFlagFile%" (
        del /f /q "%gameFlagFile%" >nul 2>&1
        echo   [92m[+] ˆ£à®¢®© ä¨«ìâà ®âª«îç¥­.[0m
    ) else (
        goto menu
    )
) else if "%GameFilterChoice%"=="1" (
    echo all>"%gameFlagFile%"
    echo   [92m[+] ˆ£à®¢®© ä¨«ìâà ãáâ ­®¢«¥­ ­  TCP+UDP.[0m
) else if "%GameFilterChoice%"=="2" (
    echo tcp>"%gameFlagFile%"
    echo   [92m[+] ˆ£à®¢®© ä¨«ìâà ãáâ ­®¢«¥­ ­  ’®«ìª® TCP.[0m
) else if "%GameFilterChoice%"=="3" (
    echo udp>"%gameFlagFile%"
    echo   [92m[+] ˆ£à®¢®© ä¨«ìâà ãáâ ­®¢«¥­ ­  ’®«ìª® UDP.[0m
) else (
    echo   [91m[!] ¥¢¥à­ë© ¢ë¡®à.[0m
    pause
    goto menu
)

call :PrintYellow "  ¥à¥§ ¯ãáâ¨â¥ á«ã¦¡ã zapret, çâ®¡ë ¯à¨¬¥­¨âì ¨§¬¥­¥­¨ï"
echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: ……Š‹ž—€’…‹œ IPSET =======================
:: ……Š‹ž—€’…‹œ IPSET =======================
:ipset_switch_status

set "listFile=%~dp0ZAPRET\lists\ipset-all.txt"
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
echo  [90m=============================================== [94mIPSet ä¨«ìâà [90m====[0m

set "listFile=%~dp0ZAPRET\lists\ipset-all.txt"
set "backupFile=%listFile%.backup"

if "%IPsetStatus%"=="Loaded" (
    echo   [93m[*] ¥à¥ª«îç¥­¨¥ ¢ à¥¦¨¬ none...[0m
    
    if not exist "%backupFile%" (
        ren "%listFile%" "ipset-all.txt.backup" 2>nul
    ) else (
        del /f /q "%backupFile%" 2>nul
        ren "%listFile%" "ipset-all.txt.backup" 2>nul
    )
    
    >"%listFile%" (
        echo 203.0.113.113/32
    )
    echo   [92m[+] IPSet ä¨«ìâà ãáâ ­®¢«¥­ ¢ à¥¦¨¬ NONE.[0m
    
) else if "%IPsetStatus%"=="None" (
    echo   [93m[*] ¥à¥ª«îç¥­¨¥ ¢ à¥¦¨¬ any...[0m
    
    >"%listFile%" (
        rem ‘®§¤ ­¨¥ ¯ãáâ®£® ä ©« 
    )
    echo   [92m[+] IPSet ä¨«ìâà ãáâ ­®¢«¥­ ¢ à¥¦¨¬ ANY.[0m
    
) else if "%IPsetStatus%"=="Any" (
    echo   [93m[*] ¥à¥ª«îç¥­¨¥ ¢ à¥¦¨¬ loaded...[0m
    
    if exist "%backupFile%" (
        del /f /q "%listFile%" 2>nul
        ren "%backupFile%" "ipset-all.txt" 2>nul
        echo   [92m[+] IPSet ä¨«ìâà ãáâ ­®¢«¥­ ¢ à¥¦¨¬ LOADED.[0m
    ) else (
        echo   [91m[!] Žè¨¡ª : ­¥â à¥§¥à¢­®© ª®¯¨¨ ¤«ï ¢®ááâ ­®¢«¥­¨ï. ‘­ ç «  ®¡­®¢¨â¥ á¯¨á®ª ¨§ ¬¥­î á«ã¦¡[0m
        pause
        goto menu
    )
)

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: ŽŽ‚‹…ˆ… IPSET =======================
:ipset_update
@REM mode con cols=69 lines=15
cls
echo  [90m=================================================== [94mŽ¡­®¢«¥­¨¥ á¯¨áª  IPSet [90m====[0m

set "listFile=%~dp0ZAPRET\lists\ipset-all.txt"
set "url=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt"

echo   [93m[*] Ž¡­®¢«¥­¨¥ ipset-all...[0m

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

echo   [92m[+] Ž¡­®¢«¥­¨¥ § ¢¥àè¥­®.[0m
echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: ŽŽ‚‹…ˆ… ”€‰‹€ HOSTS =======================
:hosts_update
@REM mode con cols=69 lines=20
cls
echo  [90m=================================================== [94mŽ¡­®¢«¥­¨¥ ä ©«  hosts [90m====[0m

set "hostsFile=%SystemRoot%\System32\drivers\etc\hosts"
set "hostsUrl=https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/hosts"
set "tempFile=%TEMP%\zapret_hosts.txt"
set "needsUpdate=0"

echo   [93m[*] à®¢¥àª  ä ©«  hosts...[0m

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
    call :PrintRed "  ¥ ã¤ «®áì § £àã§¨âì ä ©« hosts ¨§ à¥¯®§¨â®à¨ï"
    call :PrintYellow "  ‘ª®¯¨àã©â¥ ä ©« hosts ¢àãç­ãî ¨§ %hostsUrl%"
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
    echo   [93m[!] ¥à¢ ï áâà®ª  ¨§ à¥¯®§¨â®à¨ï ­¥ ­ ©¤¥­  ¢ ä ©«¥ hosts[0m
    set "needsUpdate=1"
)

findstr /C:"!lastLine!" "%hostsFile%" >nul 2>&1
if !errorlevel! neq 0 (
    echo   [93m[!] ®á«¥¤­ïï áâà®ª  ¨§ à¥¯®§¨â®à¨ï ­¥ ­ ©¤¥­  ¢ ä ©«¥ hosts[0m
    set "needsUpdate=1"
)

if "%needsUpdate%"=="1" (
    echo.
    call :PrintYellow "  ” ©« hosts ­¥®¡å®¤¨¬® ®¡­®¢¨âì"
    call :PrintYellow "  ®¦ «ã©áâ , ¢àãç­ãî áª®¯¨àã©â¥ á®¤¥à¦¨¬®¥ ¨§ § £àã¦¥­­®£® ä ©«  ¢ ¢ è ä ©« hosts"
    
    start notepad "%tempFile%"
    explorer /select,"%hostsFile%"
) else (
    call :PrintGreen "  ” ©« hosts  ªâã «¥­"
    if exist "%tempFile%" del /f /q "%tempFile%" 2>nul
)

echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: ‡€“‘Š ’…‘’Ž‚ =============================
:run_tests
@REM mode con cols=69 lines=15
cls
echo  [90m============================================== [94m‡ ¯ãáª â¥áâ®¢ [90m====[0m

:: ’à¥¡ã¥âáï PowerShell 3.0+
powershell -NoProfile -Command "if ($PSVersionTable -and $PSVersionTable.PSVersion -and $PSVersionTable.PSVersion.Major -ge 3) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorLevel% neq 0 (
    echo   [91m[!] ’à¥¡ã¥âáï PowerShell 3.0 ¨«¨ ­®¢¥¥.[0m
    echo   [93m[*] ®¦ «ã©áâ , ®¡­®¢¨â¥ PowerShell ¨ § ¯ãáâ¨â¥ íâ®â áªà¨¯â á­®¢ .[0m
    echo.
    pause
    goto menu
)

echo   [93m[*] ‡ ¯ãáª â¥áâ®¢ ª®­ä¨£ãà æ¨¨ ¢ ®ª­¥ PowerShell...[0m
start "" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ZAPRET\utils\test zapret.ps1"
echo  [90m=================================================== [93m ¦¬¨â¥ [94mENTER[0m
pause > nul
goto menu

:: Ž‹“—ˆ’œ ˆŒŸ ‘’€’…ƒˆˆ =============================
:get_strategy_name
set "CurrentStrategy="
for /f "tokens=2*" %%A in ('reg query "HKLM\System\CurrentControlSet\Services\zapret" /v zapret-discord-youtube 2^>nul') do set "CurrentStrategy=‘âà â¥£¨ï: %%B"
exit /b

:: ‚á¯®¬®£ â¥«ì­ë¥ äã­ªæ¨¨

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
    echo [Ž˜ˆŠ€] %1 ­¥ ­ ©¤¥­® ¢ PATH
    echo ˆá¯à ¢ìâ¥ ¢ èã ¯¥à¥¬¥­­ãî PATH á ¯®¬®éìî ¨­áâàãªæ¨© §¤¥áì https://github.com/Flowseal/zapret-discord-youtube/issues/7490
    pause
    exit /b 1
)
exit /b 0

:check_extracted
set "extracted=1"

if not exist "%~dp0ZAPRET\bin\" set "extracted=0"

if "%extracted%"=="0" (
    echo Zapret ¤®«¦¥­ ¡ëâì ¨§¢«¥ç¥­ ¨§  àå¨¢ , ¨«¨ ¯ ¯ª  bin ­¥ ­ ©¤¥­  ¯® ª ª®©-â® ¯à¨ç¨­¥
    pause
    exit
)
exit /b 0

:: ˆ’…ƒˆŽ‚€›‰ …„€Š’Ž ‘ˆ‘ŠŽ‚ (ã­ªâ 3) =============

:list_editor_init
set "EDITOR_VERSION=v1.3"
set "SELECTED_FILE=%~dp0ZAPRET\utils\selected.txt"
set "PRESETS_DIR=%~dp0ZAPRET\lists\presets"

if not exist "%PRESETS_DIR%" (
    echo[ ERROR ]  ¯ª  %PRESETS_DIR% ­¥ ­ ©¤¥­ ![0m
    pause
    goto menu
)

:load_selected
set "selected_list="
if exist "%SELECTED_FILE%" (
    for /f "usebackq delims=" %%i in ("%SELECTED_FILE%") do (
        set "found=0"
        for %%a in (!selected_list!) do (
            if "%%a"=="%%i" set "found=1"
        )
        if !found!==0 (
            if not "!selected_list!"=="" set "selected_list=!selected_list! %%i"
            if "!selected_list!"=="" set "selected_list=%%i"
        )
    )
)

:refresh_list
set "file_list="
set "file_count=0"
for %%f in ("%PRESETS_DIR%\*.txt") do (
    set /a file_count+=1
    set "file_!file_count!=%%~nxf"
    set "file_name_!file_count!=%%~nxf"
    set "file_selected_!file_count!=0"
    
    if defined selected_list (
        for %%s in (!selected_list!) do (
            if "%%s"=="%%~nxf" set "file_selected_!file_count!=1"
        )
    )
)
set "total_files=!file_count!"
set "current_pos=1"
set "current_page=1"
set "items_per_page=15"

set /a "total_pages=(total_files+items_per_page-1)/items_per_page"
if !total_pages! lss 1 set "total_pages=1"

:editor_menu
cls
echo  [90m================================================ [94m¥¤ ªâ®à á¯¨áª®¢ [90m====[0m
echo   [90m ˆá¯®«ì§ã©â¥ [93m‘’…‹Šˆ[90m ¤«ï ­ ¢¨£ æ¨¨, [93mà®¡¥«/Enter[90m ¤«ï ¢ë¡®à [0m
echo  [90m----------------------------------------------------------------------[0m

set /a "start_item=(current_page-1)*items_per_page+1"
set /a "end_item=current_page*items_per_page"
if !end_item! gtr !total_files! set "end_item=!total_files!"

for /l %%i in (!start_item!,1,!end_item!) do (
    set "selected_status= "
    if !file_selected_%%i!==1 set "selected_status=[48;2;50;50;50m[48;2;0;130;0m[38;2;100;255;100m "
    if !file_selected_%%i!==0 set "selected_status=[48;2;50;50;50m[48;2;130;0;0m[38;2;255;100;100m "

    if %%i==!current_pos! (
        echo  ^> !selected_status![48;2;50;50;50m[38;2;255;255;70m !file_name_%%i! [0m
    ) else (
        echo    !selected_status![48;2;24;24;24m !file_name_%%i! [0m
    )
)

set /a "empty_lines=items_per_page-(end_item-start_item+1)"
for /l %%i in (1,1,!empty_lines!) do echo.
echo  [90m----------------------------------------------------------------------[0m
echo                   [93m[[96m^< [0mà¥¤.[93m] [90m‘âà ­¨æ : !current_page!/!total_pages! [93m[[96m^> [0m‘«¥¤.[93m]
echo  [90m======================================================================[0m
echo   [93m[[96mA [0m‚ë¡à âì ¢á¥[93m] [93m[[96mN [0m‘­ïâì ¢á¥[93m] [93m[[96mS [0m‘®åà ­¨âì[93m] [93m[[96mR [0mŽ¡­®¢¨âì[93m] [93m[[96mESC [0m‚ëå®¤[93m]
echo  [90m======================================================================[0m

set "key="
for /f "delims=" %%a in ('powershell -Command "$key = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode; Write-Host $key"') do set "key=%%a"

:: ‘âà¥«ª  ¢¢¥àå (38)
if "%key%"=="38" (
    set /a current_pos-=1
    if !current_pos! lss !start_item! (
        if !current_page! gtr 1 (
            set /a current_page-=1
            set /a "current_pos=(current_page-1)*items_per_page+items_per_page"
            if !current_pos! gtr !total_files! set "current_pos=!total_files!"
        ) else (
            set "current_pos=1"
        )
    )
    if !current_pos! lss 1 set "current_pos=1"
    goto editor_menu
)

:: ‘âà¥«ª  ¢­¨§ (40)
if "%key%"=="40" (
    set /a current_pos+=1
    if !current_pos! gtr !end_item! (
        if !current_page! lss !total_pages! (
            set /a current_page+=1
            set /a "current_pos=(current_page-1)*items_per_page+1"
        ) else (
            set "current_pos=!total_files!"
        )
    )
    if !current_pos! gtr !total_files! set "current_pos=!total_files!"
    goto editor_menu
)

:: ‘âà¥«ª  ¢«¥¢® (37)
if "%key%"=="37" (
    if !current_page! gtr 1 (
        set /a current_page-=1
        set /a "current_pos=(current_page-1)*items_per_page+1"
    )
    goto editor_menu
)

:: ‘âà¥«ª  ¢¯à ¢® (39)
if "%key%"=="39" (
    if !current_page! lss !total_pages! (
        set /a current_page+=1
        set /a "current_pos=(current_page-1)*items_per_page+1"
    )
    goto editor_menu
)

:: Enter (13) ¨«¨ à®¡¥« (32)
if "%key%"=="13" goto toggle_select
if "%key%"=="32" goto toggle_select
goto check_other_keys

:toggle_select
if !file_selected_%current_pos%!==1 (
    set "file_selected_%current_pos%=0"
) else (
    set "file_selected_%current_pos%=1"
)
goto editor_menu

:check_other_keys
if "%key%"=="65" goto select_all
if "%key%"=="97" goto select_all
if "%key%"=="78" goto clear_all
if "%key%"=="110" goto clear_all
if "%key%"=="83" goto save_and_merge
if "%key%"=="115" goto save_and_merge
if "%key%"=="82" goto refresh_list
if "%key%"=="114" goto refresh_list
if "%key%"=="27" goto menu
if "%key%"=="81" goto menu
if "%key%"=="113" goto menu
goto editor_menu

:select_all
for /l %%i in (1,1,%total_files%) do set "file_selected_%%i=1"
goto editor_menu

:clear_all
for /l %%i in (1,1,%total_files%) do set "file_selected_%%i=0"
goto editor_menu

:save_and_merge
cls
echo  [96m======================================================================[0m
echo   [94m‘®åà ­¥­¨¥ ¨ ®¡ê¥¤¨­¥­¨¥ á¯¨áª®¢...[0m
echo  [96m======================================================================[0m

set "OUTPUT_FILE=%~dp0ZAPRET\lists\list-general.txt"
set "TEMP_FILE=%TEMP%\merged_list_temp.txt"

if exist "%TEMP_FILE%" del "%TEMP_FILE%" 2>nul
if exist "%SELECTED_FILE%" del "%SELECTED_FILE%" 2>nul

set "merged_count=0"

for /l %%i in (1,1,%total_files%) do (
    if !file_selected_%%i!==1 (
        set /a merged_count+=1
        echo !file_name_%%i!>> "%SELECTED_FILE%"
        echo   [96m[*] „®¡ ¢«¥­¨¥: !file_name_%%i![0m
        
        if exist "%PRESETS_DIR%\!file_name_%%i!" (
            type "%PRESETS_DIR%\!file_name_%%i!" >> "%TEMP_FILE%"
            echo. >> "%TEMP_FILE%"
        )
    )
)

if !merged_count!==0 (
    echo   [91m[*] ¥ ¢ë¡à ­® ­¨ ®¤­®£® ä ©« . ã¤¥â á®§¤ ­ ¯ãáâ®© á¯¨á®ª.[0m
    type nul > "%OUTPUT_FILE%" 2>nul
    echo   [92m[+] ‘®§¤ ­ ¯ãáâ®© ä ©«: %OUTPUT_FILE%[0m
    set "line_count=0"
) else (
    if exist "%TEMP_FILE%" (
        powershell -Command "Get-Content '%TEMP_FILE%' | Where-Object {$_ -ne ''} | Sort-Object | Get-Unique" > "%OUTPUT_FILE%" 2>nul
        if errorlevel 1 (
            type "%TEMP_FILE%" > "%OUTPUT_FILE%" 2>nul
        )
        del "%TEMP_FILE%" 2>nul
        
        set "line_count=0"
        for /f %%i in ('type "%OUTPUT_FILE%" ^| find /c /v ""') do set "line_count=%%i"
    )
)

echo  [90m----------------------------------------------------------------------[0m
echo   [92m[+] “á¯¥è­® ®¡ê¥¤¨­¥­® ä ©«®¢: !merged_count![0m
echo   [92m[+] ‚á¥£® ã­¨ª «ì­ëå áâà®ª § ¯¨á ­®: %line_count%[0m
echo  [90m----------------------------------------------------------------------[0m
echo   [93m ¦¬¨â¥ «î¡ãî ª« ¢¨èã ¤«ï ¢®§¢à â  ¢ à¥¤ ªâ®à...[0m
pause >nul
goto load_selected
