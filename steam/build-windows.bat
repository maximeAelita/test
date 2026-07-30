@echo off
REM ---------------------------------------------------------------------------
REM IRONVINE - build the Windows .exe. Double-click this file.
REM Output: dist\win-unpacked\IRONVINE.exe  (that folder is the Steam depot)
REM ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

REM Double-clicking this file from inside Explorer's ZIP preview copies ONLY this
REM file to a temp folder and runs it there, so nothing it needs is present.
if not exist "package.json" (
  echo.
  echo   This script is not running from the extracted project folder.
  echo.
  echo   It is running here:
  echo     %~dp0
  echo   and package.json is not next to it.
  echo.
  echo   That usually means the ZIP was opened rather than extracted. Double-
  echo   clicking a file inside a ZIP window copies out only that one file.
  echo.
  echo   Fix: right-click the downloaded .zip in File Explorer, choose
  echo   "Extract All...", extract it somewhere simple such as D:\ironvine,
  echo   then run this file from the extracted contra\steam folder.
  echo.
  echo   You are in the right place when package.json, main.js and copy-game.js
  echo   sit next to this .bat file.
  echo.
  pause
  exit /b 1
)

where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo   Node.js was not found on PATH.
  echo   Install the LTS build from https://nodejs.org then reopen this window.
  echo.
  pause
  exit /b 1
)

if not exist "node_modules" (
  echo.
  echo   Installing dependencies first. This takes a few minutes.
  echo.
  call npm install --no-audit --no-fund
  if errorlevel 1 ( echo npm install failed. & pause & exit /b 1 )
)

echo.
echo   Building. Two to three minutes.
echo.
call npm run dist
if errorlevel 1 (
  echo.
  echo   Build failed. If it stopped on a signing step you can skip it -
  echo   Steam does not require a signed executable:
  echo.
  echo     set CSC_IDENTITY_AUTO_DISCOVERY=false
  echo     npx electron-builder --win --x64
  echo.
  pause
  exit /b 1
)

echo.
if exist "dist\win-unpacked\IRONVINE.exe" (
  echo   Built: dist\win-unpacked\IRONVINE.exe
  echo   Opening the folder...
  start "" "dist\win-unpacked"
) else (
  echo   Build reported success but IRONVINE.exe is not where expected.
  echo   Check the dist\ folder.
)
echo.
pause
