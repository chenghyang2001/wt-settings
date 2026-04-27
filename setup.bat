@echo off
REM ============================================================
REM wt-settings one-click setup
REM Cross-PC CLI alias deployment for Claude Code shortcuts
REM
REM Idempotent: re-running is safe (no duplicate PATH entries,
REM mkdir guarded, copy /Y overwrites stale aliases).
REM ============================================================

setlocal enabledelayedexpansion

REM Resolve repo root from this script's location (no hardcoded user path)
set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"

set "TARGET=%USERPROFILE%\bin"

echo.
echo === wt-settings setup ===
echo Repo:   %REPO_DIR%
echo Target: %TARGET%
echo.

REM --- Step 1: verify repo bin/ exists ---
if not exist "%REPO_DIR%\bin" (
    echo ERROR: bin\ folder not found in repo: %REPO_DIR%
    echo This setup.bat must be in the repo root next to bin\
    endlocal
    exit /b 1
)

REM --- Step 2: ensure target bin/ exists ---
if not exist "%TARGET%" (
    mkdir "%TARGET%"
    if errorlevel 1 (
        echo ERROR: failed to create %TARGET%
        endlocal
        exit /b 1
    )
    echo [OK] Created %TARGET%
) else (
    echo [OK] %TARGET% already exists
)

REM --- Step 3: copy bin/*.bat to target (overwrite) ---
copy /Y "%REPO_DIR%\bin\*.bat" "%TARGET%\" >nul
if errorlevel 1 (
    echo ERROR: copy failed from %REPO_DIR%\bin\ to %TARGET%\
    endlocal
    exit /b 1
)
echo [OK] Synced *.bat from repo bin\ to %TARGET%\

REM Escape single quotes in TARGET for PowerShell single-quoted string literal safety
REM (Windows account names can legally contain ').
set "TARGET_PS=%TARGET:'=''%"

REM --- Step 4: append target to user PATH if missing (idempotent) ---
REM Use PowerShell to read user PATH (not process PATH) and split by ';'
REM to avoid substring false positives like "C:\Users\X\bin2" matching "C:\Users\X\bin".
REM Compare normalized form (TrimEnd('\').ToLower()) so "C:\Users\X\bin\" vs
REM "C:\Users\X\bin" do not double-append. ErrorActionPreference=Stop + try/catch
REM ensures GPO / HKCU\Environment ACL failures surface as exit 1, not silent success.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $bin='%TARGET_PS%'; $up=[Environment]::GetEnvironmentVariable('Path','User'); $norm = { param($p) $p.TrimEnd('\').ToLower() }; $binN = & $norm $bin; $upN = $up -split ';' | ForEach-Object { & $norm $_ }; if ($upN -notcontains $binN) { exit 1 } else { exit 0 } } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [..] %TARGET% not in user PATH, appending...
    REM Avoid setx (1024 char truncation bug). Use SetEnvironmentVariable instead.
    REM Write back using original $bin (preserve account-name casing); only the
    REM membership check uses normalized form.
    powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $bin='%TARGET_PS%'; $up=[Environment]::GetEnvironmentVariable('Path','User'); $norm = { param($p) $p.TrimEnd('\').ToLower() }; $binN = & $norm $bin; $upN = $up -split ';' | ForEach-Object { & $norm $_ }; if ($upN -notcontains $binN) { [Environment]::SetEnvironmentVariable('Path', ($up.TrimEnd(';') + ';' + $bin), 'User') } } catch { Write-Error $_.Exception.Message; exit 1 }"
    if errorlevel 1 (
        echo ERROR: failed to update user PATH
        endlocal
        exit /b 1
    )
    echo [OK] Appended to user PATH ^(open a new cmd window to see effect^)
) else (
    echo [OK] %TARGET% already in user PATH
)

REM --- Step 5: warn if claude CLI is missing (non-fatal) ---
where claude >nul 2>&1
if errorlevel 1 (
    echo [WARN] 'claude' CLI not found in PATH.
    echo        Aliases like 'by' will fail until Claude Code is installed.
    echo        Install: https://docs.claude.com/claude-code
) else (
    echo [OK] 'claude' CLI detected
)

echo.
echo === Setup complete. Opening verification window... ===
echo.

REM --- Step 6: open new cmd to verify alias resolution ---
REM A new cmd inherits the freshly-updated user PATH. We use 'where by'
REM (resolves but does not execute) to prove the alias is on PATH without
REM accidentally launching a real Claude session.
start "wt-settings verify" cmd /k "echo === setup.bat verification === && echo. && where by && echo. && echo Expected: %USERPROFILE%\bin\by.bat && echo. && echo If the path above matches, setup is complete. && echo Type 'by' anytime to continue your Claude session. && echo. && pause"

endlocal
exit /b 0
