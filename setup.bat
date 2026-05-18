@echo off
REM ============================================================
REM wt-settings one-click setup
REM Cross-PC CLI alias deployment for Claude Code shortcuts
REM
REM Idempotent: re-running is safe (no duplicate PATH entries,
REM mkdir guarded, copy /Y overwrites stale aliases).
REM ============================================================
REM ------------------------------------------------------------
REM MANIFEST v1.1
REM COMPLEXITY: medium
REM EXPECTED_TEST_CASES: 5 (focused)
REM REVIEWER_INVOLVED: yes
REM CHANGE_LOG:
REM   Ch1 L46      bin/ empty guard (dir /b check before copy)
REM   Ch2+3 L99+   verify window: & chaining + SUCCESS/FAIL echo
REM   Ch4+6 L64-79 merge two PS calls into one; PATH len check
REM   Ch5 L10+     --dry-run flag (DRY=0/1, skip side-effects)
REM   Ch7 L13      REPO_DIR one-liner (for %%I in ("%~dp0."))
REM   Ch8 L10      setlocal (drop enabledelayedexpansion)
REM ------------------------------------------------------------

REM Ch8: dropped enabledelayedexpansion (no !var! used; avoids '!' misinterpretation in echo)
setlocal

REM Ch5: --dry-run flag
set "DRY=0"
if /I "%~1"=="--dry-run" set "DRY=1"

REM Resolve repo root from this script's location (no hardcoded user path)
REM Ch7: one-liner via for %%I (replaces two-line %~dp0 + substring strip)
for %%I in ("%~dp0.") do set "REPO_DIR=%%~fI"

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
    if "%DRY%"=="1" (
        echo [DRY] would create %TARGET%
    ) else (
        mkdir "%TARGET%"
        if errorlevel 1 (
            echo ERROR: failed to create %TARGET%
            endlocal
            exit /b 1
        )
        echo [OK] Created %TARGET%
    )
) else (
    echo [OK] %TARGET% already exists
)

REM --- Step 3: copy bin/*.bat to target (overwrite) ---
REM Ch1: guard against empty bin/ (dir /b exits 1 if no match; skip copy rather than error)
dir /b "%REPO_DIR%\bin\*.bat" >nul 2>&1
if errorlevel 1 (
    echo [OK] No *.bat in repo bin\ - nothing to copy
) else (
    if "%DRY%"=="1" (
        echo [DRY] would copy *.bat from %REPO_DIR%\bin\ to %TARGET%\
    ) else (
        copy /Y "%REPO_DIR%\bin\*.bat" "%TARGET%\" >nul
        if errorlevel 1 (
            echo ERROR: copy failed from %REPO_DIR%\bin\ to %TARGET%\
            endlocal
            exit /b 1
        )
        echo [OK] Synced *.bat from repo bin\ to %TARGET%\
    )
)

REM Escape single quotes in TARGET for PowerShell single-quoted string literal safety
REM (Windows account names can legally contain ').
set "TARGET_PS=%TARGET:'=''%"

REM --- Step 4: append target to user PATH if missing (idempotent) ---
REM Use PowerShell to read user PATH (not process PATH) and split by ';'
REM to avoid substring false positives like "C:\Users\X\bin2" matching "C:\Users\X\bin".
REM Compare normalized form (TrimEnd('\').ToLower()) so "C:\Users\X\bin\" vs
REM "C:\Users\X\bin" do not double-append. ErrorActionPreference=Stop + try/catch
REM ensures GPO / HKCU\Environment ACL failures surface as exit 1, not silent success.
REM Ch4+6: merged two PS calls into one; exit 0=already present, exit 2=appended, exit 1=error.
REM        PATH length check (>8000 chars) now included before SetEnvironmentVariable.
if "%DRY%"=="1" (
    echo [DRY] would append %TARGET% to user PATH
    goto :path_dryrun
)
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; try { $bin='%TARGET_PS%'; $up=[Environment]::GetEnvironmentVariable('Path','User'); $norm = { param($p) $p.TrimEnd('\').ToLower() }; $binN = & $norm $bin; $upN = $up -split ';' | ForEach-Object { & $norm $_ }; if ($upN -notcontains $binN) { if ($up.Length + $bin.Length + 1 -gt 8000) { Write-Error 'PATH too long, max 8191'; exit 1 }; [Environment]::SetEnvironmentVariable('Path', ($up.TrimEnd(';') + ';' + $bin), 'User'); exit 2 } else { exit 0 } } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 2 goto :path_appended
if errorlevel 1 goto :path_error
goto :path_ok

:path_error
echo ERROR: failed to update user PATH
endlocal
exit /b 1

:path_appended
echo [..] %TARGET% not in user PATH, appending...
REM Avoid setx (1024 char truncation bug). Use SetEnvironmentVariable instead.
REM Write back using original $bin (preserve account-name casing); only the
REM membership check uses normalized form.
echo [OK] Appended to user PATH ^(open a new cmd window to see effect^)
goto :path_done

:path_ok
echo [OK] %TARGET% already in user PATH
goto :path_done

:path_dryrun
:path_done

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
REM Ch2+3: & chaining (unconditional) replaces && (short-circuit); SUCCESS/FAIL echo added.
if "%DRY%"=="1" (
    echo [DRY] would open verification window
    goto :eof
)
start "wt-settings verify" cmd /k "echo === setup.bat verification === & echo. & where by & if errorlevel 1 (echo FAIL: by not found in PATH) else (echo SUCCESS: by found in PATH) & echo. & echo Expected: %USERPROFILE%\bin\by.bat & echo. & echo Type 'by' anytime to continue your Claude session. & echo. & pause"

endlocal
exit /b 0
