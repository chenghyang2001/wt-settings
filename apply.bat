@echo off
REM ============================================================
REM apply.bat - Windows native WT settings deployment
REM Mirror of apply.sh for Git-Bash-less environments
REM ============================================================

setlocal enabledelayedexpansion

set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"
set "SRC=%REPO_DIR%\settings.json"
set "WT_DIR=%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
set "DST=%WT_DIR%\settings.json"

echo.
echo === wt-settings apply (Windows native) ===
echo Source: %SRC%
echo Target: %DST%
echo.

REM --- 1. Verify source ---
if not exist "%SRC%" (
    echo ERROR: source not found: %SRC%
    endlocal & exit /b 1
)

REM --- 2. Verify WT installed ---
if not exist "%WT_DIR%" (
    echo ERROR: Windows Terminal LocalState not found: %WT_DIR%
    echo Install: winget install Microsoft.WindowsTerminal
    endlocal & exit /b 1
)

REM --- 3. Validate source is valid JSON ---
powershell -NoProfile -Command "try { $null = Get-Content -Raw '%SRC%' | ConvertFrom-Json; exit 0 } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo ERROR: source is not valid JSON
    endlocal & exit /b 1
)
echo [OK] source JSON valid

REM --- 4. Backup current LocalState (timestamped) ---
if exist "%DST%" (
    for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value 2^>nul') do set "DT=%%a"
    set "BAK=%WT_DIR%\settings.json.bak-!DT:~0,8!-!DT:~8,6!"
    copy /Y "%DST%" "!BAK!" >nul
    echo [OK] backed up current to !BAK!
)

REM --- 5. Copy source to LocalState ---
copy /Y "%SRC%" "%DST%" >nul
if errorlevel 1 (
    echo ERROR: copy failed
    endlocal & exit /b 1
)
echo [OK] deployed to %DST%

REM --- 6. Verify deployed file is valid JSON ---
powershell -NoProfile -Command "try { $null = Get-Content -Raw '%DST%' | ConvertFrom-Json; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo ERROR: deployed file failed JSON validation
    endlocal & exit /b 1
)
echo [OK] deployed JSON valid

REM --- 7. Cleanup old backups (keep newest 5) ---
powershell -NoProfile -Command "Get-ChildItem '%WT_DIR%\settings.json.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -Skip 5 | Remove-Item -Force -ErrorAction SilentlyContinue"

echo.
echo === Apply complete. WT will hot-reload settings automatically. ===
echo If WT is not running, settings take effect on next launch.
echo.

endlocal
exit /b 0
