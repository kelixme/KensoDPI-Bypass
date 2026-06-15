@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: Установка кодировки UTF-8
for /f "tokens=2 delims=:" %%a in ('chcp') do set "original_codepage=%%a"
set "original_codepage=%original_codepage: =%"
reg add "HKCU\Console" /v CodePage /t REG_DWORD /d 65001 /f >nul 2>&1

:: Переменные
set VER=v1.1 BETA
set SRVCDESC=KR.Corp - TgWsProxy Bypass [%VER%]
set PROG_NAME=TgWsProxy
set PROG_PATH=C:\KensoDPI-Bypass\TGWSPROXY\TgWsProxy.exe
set REG_RUN=HKLM\Software\Microsoft\Windows\CurrentVersion\Run
set VALUE_NAME=TgWsProxy
title %SRVCDESC%

:menu
@REM mode con cols=69 lines=30
cls

:: Получение статуса
set AUTORUN_STATUS=Не установлен
reg query "%REG_RUN%" /v "%VALUE_NAME%" 2>nul >nul
if %errorlevel% equ 0 set AUTORUN_STATUS=Установлен

tasklist /FI "IMAGENAME eq TgWsProxy.exe" 2>nul | find /I "TgWsProxy.exe" >nul
if %errorlevel% equ 0 (set PROCESS_STATUS=[92mЗапущен) else (set PROCESS_STATUS=[91mНе запущен)

echo  [96mKensoDPI [90m[[94mTgWsProxy.Bypass [90m- [91m%VER%[90m][0m
echo  [90m-----------------------------------------------------------------[0m
:: Проверка прав администратора
net session >nul 2>&1
if %errorLevel% == 0 (
    echo  [93mДоступ: [92mПолный[0m[90m
) else (
    echo  [93mДоступ: [91mОграничен[0m[90m / [93mЗапрос прав...[0m
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'" > nul
    exit
)

echo  [90m======================================= Управление [92mTgWsProxy [90m====[0m
echo   [96mСервис: [92m!AUTORUN_STATUS![0m
echo   [96mПроцесс: [92m!PROCESS_STATUS![0m
echo  [90m-----------------------------------------------------------------[0m
echo   [93m1 [90m-[0m [92mУстановить сервис[0m
echo   [93m2 [90m-[0m [91mУдалить сервис[0m
echo  [90m=================================================================[0m
set /p choice=[96m  Выбор: [93m

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
goto menu

:install
@REM mode con cols=69 lines=25
cls
echo  [90m======================================== [94mУстановка TgWsProxy [90m====[0m

if not exist "%PROG_PATH%" (
    echo   [91m[ОШИБКА] Файл не найден: %PROG_PATH%[0m
    echo  [90m=================================================== [93mНажмите [94mENTER[0m
    pause > nul
    goto menu
)

echo [93m  [*] Установка автозапуска...[0m
reg add "%REG_RUN%" /v "%VALUE_NAME%" /d "\"%PROG_PATH%\"" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [92m  [+] Автозапуск успешно установлен[0m
) else (
    echo [91m  [-] Не удалось установить автозапуск[0m
)

echo [93m  [*] Запуск TgWsProxy...[0m
start "" "%PROG_PATH%"
if %errorLevel% equ 0 (
    echo [92m  [+] Программа запущена[0m
) else (
    echo [91m  [-] Не удалось запустить программу[0m
)

echo  [90m-----------------------------------------------------------------[0m
echo   [92mУстановка успешно завершена![0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu

:uninstall
@REM mode con cols=69 lines=25
cls
echo  [90m-----------------------------------------------------------------[0m
echo   [94mУдаление автозапуска TgWsProxy[0m
echo  [90m-----------------------------------------------------------------[0m

echo [93m  [*] Удаление автозапуска...[0m
reg delete "%REG_RUN%" /v "%VALUE_NAME%" /f >nul 2>&1
if %errorLevel% equ 0 (
    echo [92m  [+] Автозапуск удален[0m
) else (
    echo [91m  [-] Запись в автозапуске не найдена[0m
)

echo [93m  [*] Завершение процесса TgWsProxy...[0m
taskkill /IM TgWsProxy.exe /F >nul 2>&1
if %errorLevel% equ 0 (
    echo [92m  [+] Процесс завершен[0m
) else (
    echo [91m  [-] Процесс не был запущен[0m
)

echo  [90m-----------------------------------------------------------------[0m
echo   [92mУдаление успешно завершено![0m
echo  [90m=================================================== [93mНажмите [94mENTER[0m
pause > nul
goto menu