@echo off
REM ---------------------------------------------------------------------------
REM IRONVINE - run the desktop build on Windows.
REM Double-click this file. It installs dependencies the first time (a few
REM minutes, ~200MB) and launches the game after that.
REM ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo   Node.js was not found on PATH.
  echo   Install the LTS build from https://nodejs.org then close and reopen
  echo   this window - a fresh terminal is needed to pick up the new PATH.
  echo.
  pause
  exit /b 1
)

for /f "tokens=*" %%v in ('node --version') do echo Using Node %%v

if not exist "node_modules" (
  echo.
  echo   First run - installing dependencies. This takes a few minutes.
  echo.
  call npm install --no-audit --no-fund
  if errorlevel 1 (
    echo.
    echo   npm install failed. The output above says why.
    echo.
    pause
    exit /b 1
  )
)

echo.
echo   Launching IRONVINE. Alt+F4 or the pause menu's QUIT TO TITLE to exit.
echo.
call npm start

echo.
echo   The game has closed. Anything printed above is console output from it.
echo.
pause
