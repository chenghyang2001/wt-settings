@echo off
REM ============================================================
REM gen-cheatsheet.bat - Regenerate doc/keybindings-cheatsheet.{html,pdf}
REM Reads repo settings.json, outputs to doc/.
REM Requires: Python 3.10+, Microsoft Edge (for PDF rendering)
REM ============================================================

setlocal

set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"
set "PYTHONUTF8=1"

python "%REPO_DIR%\gen_cheatsheet.py"
set "RC=%ERRORLEVEL%"

endlocal & exit /b %RC%
