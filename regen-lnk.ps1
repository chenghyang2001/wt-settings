# 重建 wt-settings 桌面 .lnk（gitignored，跨機器需各自重建）
# 用途：產出可右鍵釘工作列的 Windows 捷徑（兩個：wt-settings.lnk + wt-sync.lnk）
# 用法：powershell -ExecutionPolicy Bypass -File regen-lnk.ps1

$ErrorActionPreference = "Stop"

$WorkspaceDir = Join-Path $env:USERPROFILE "workspace\wt-settings"
$DesktopDir   = Join-Path $env:USERPROFILE "Desktop"

if (-not (Test-Path $WorkspaceDir)) {
    Write-Error "找不到 $WorkspaceDir。請先 git clone repo。"
    exit 1
}
if (-not (Test-Path $DesktopDir)) {
    Write-Error "找不到 $DesktopDir。"
    exit 1
}

# Helper: 建立單一 .lnk
function New-DesktopShortcut {
    param(
        [Parameter(Mandatory=$true)] [string] $LnkName,
        [Parameter(Mandatory=$true)] [string] $BatRel,
        [Parameter(Mandatory=$true)] [string] $IconRel,
        [Parameter(Mandatory=$true)] [string] $Description
    )
    $LnkPath  = Join-Path $DesktopDir   $LnkName
    $BatPath  = Join-Path $WorkspaceDir $BatRel
    $IconPath = Join-Path $WorkspaceDir $IconRel
    if (-not (Test-Path $BatPath))  { Write-Error "找不到 $BatPath。repo 不完整。"; exit 1 }
    if (-not (Test-Path $IconPath)) { Write-Error "找不到 $IconPath。repo 不完整。"; exit 1 }
    $sh  = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($LnkPath)
    $lnk.TargetPath       = Join-Path $env:SystemRoot "System32\cmd.exe"
    $lnk.Arguments        = "/c `"$BatPath`""
    $lnk.WorkingDirectory = $WorkspaceDir
    $lnk.IconLocation     = "$IconPath,0"
    $lnk.WindowStyle      = 7  # 最小化執行 — Windows 1903+ 才有 .bat 的 pin verb 限制，cmd.exe + minimized 可繞過
    $lnk.Description      = $Description
    $lnk.Save()
    Write-Output "OK: $LnkPath"
}

# 重建兩個桌面 .lnk
New-DesktopShortcut -LnkName "wt-settings.lnk"  -BatRel "claude-wt-1-tab-wt-settings.bat" -IconRel "wt-settings.ico" -Description "Claude Code @ wt-settings (single tab)"
New-DesktopShortcut -LnkName "wt-sync.lnk"       -BatRel "wt-sync.bat"                     -IconRel "wt-sync.ico"     -Description "wt-settings sync (git pull + apply.bat)"

Write-Output ""
Write-Output "釘到工作列步驟："
Write-Output "  1. 桌面右鍵 wt-settings.lnk 或 wt-sync.lnk"
Write-Output "  2. 釘選到工作列 / 釘選到開始畫面"
