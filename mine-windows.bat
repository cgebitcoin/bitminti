@echo off
REM BitMinti One-Click Miner for Windows
REM This script will automatically start mining BitMinti

echo ========================================
echo    BitMinti One-Click Miner
echo    CPU Mining for Everyone
echo ========================================
echo.

REM Set variables
set DATADIR=%USERPROFILE%\.bitminti
set WALLET_NAME=miner

REM Check if bitmintid.exe exists
if not exist "bitmintid.exe" (
    echo ERROR: bitmintid.exe not found in current directory!
    echo.
    echo Please download the Windows binaries from:
    echo https://github.com/cgebitcoin/bitminti/releases
    echo.
    pause
    exit /b 1
)

REM Create data directory if it doesn't exist
if not exist "%DATADIR%" mkdir "%DATADIR%"

echo Starting BitMinti daemon...
echo Data directory: %DATADIR%
echo.

REM Start daemon in background
start /b bitmintid.exe -datadir="%DATADIR%" -daemon -miningfastmode=1

REM Wait for daemon to start
echo Waiting for daemon to initialize...
timeout /t 10 /nobreak >nul

REM Create/load wallet
echo Setting up mining wallet...
bitminti-cli.exe -datadir="%DATADIR%" createwallet "%WALLET_NAME%" >nul 2>&1
if errorlevel 1 (
    bitminti-cli.exe -datadir="%DATADIR%" loadwallet "%WALLET_NAME%" >nul 2>&1
)

REM Get mining address
for /f "delims=" %%a in ('bitminti-cli.exe -datadir^="%DATADIR%" -rpcwallet^="%WALLET_NAME%" getnewaddress') do set MINING_ADDR=%%a

if "%MINING_ADDR%"=="" (
    echo ERROR: Could not generate mining address!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Mining address: %MINING_ADDR%
echo ========================================
echo.
echo Mining will start now. This window will show your progress.
echo Press Ctrl+C to stop mining.
echo.

REM Start continuous mining loop
:MINE_LOOP
bitminti-cli.exe -datadir="%DATADIR%" -rpcwallet="%WALLET_NAME%" generatetoaddress 1 %MINING_ADDR% 1000000
if errorlevel 1 (
    echo Mining command failed. Retrying in 5 seconds...
    timeout /t 5 /nobreak >nul
)
goto MINE_LOOP
