@echo off
REM ============================================================
REM wt-sync.bat - 1-click pull + apply
REM Mirror of /wt-sync slash command (cmd surface)
REM ============================================================

setlocal
set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"

cd /d "%REPO_DIR%" || (
    echo ERROR: cannot cd to %REPO_DIR%
    endlocal & exit /b 1
)

echo === git pull ===
git pull
if errorlevel 1 (
    echo ERROR: git pull failed - check network / merge conflicts
    endlocal & exit /b 1
)

echo.
echo === apply.bat ===
call "%REPO_DIR%\apply.bat"
set "RC=%ERRORLEVEL%"

endlocal & exit /b %RC%
