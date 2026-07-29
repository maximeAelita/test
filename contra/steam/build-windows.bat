@echo off
REM ---------------------------------------------------------------------------
REM IRONVINE - build the Windows .exe. Double-click this file.
REM Output: dist\win-unpacked\IRONVINE.exe  (that folder is the Steam depot)
REM ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

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
