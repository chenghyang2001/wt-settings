# 重建 wt-settings.lnk（gitignored，跨機器需各自重建）
# 用途：產出可右鍵釘工作列的 Windows 捷徑
# 用法：powershell -ExecutionPolicy Bypass -File regen-lnk.ps1

$ErrorActionPreference = "Stop"

$WorkspaceDir = Join-Path $env:USERPROFILE "workspace\wt-settings"
$LnkPath      = Join-Path $WorkspaceDir "wt-settings.lnk"
$BatPath      = Join-Path $WorkspaceDir "claude-wt-1-tab-wt-settings.bat"
$IconPath     = Join-Path $WorkspaceDir "wt-settings.ico"

if (-not (Test-Path $WorkspaceDir)) {
    Write-Error "找不到 $WorkspaceDir。請先 git clone repo。"
    exit 1
}
if (-not (Test-Path $BatPath)) {
    Write-Error "找不到 $BatPath。repo 不完整。"
    exit 1
}

$sh  = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut($LnkPath)
$lnk.TargetPath       = Join-Path $env:SystemRoot "System32\cmd.exe"
$lnk.Arguments        = "/c `"$BatPath`""
$lnk.WorkingDirectory = $WorkspaceDir
$lnk.IconLocation     = "$IconPath,0"
$lnk.WindowStyle      = 7  # 最小化執行 — Windows 1903+ 才有 .bat 的 pin verb 限制，cmd.exe + minimized 可繞過
$lnk.Description      = "Claude Code @ wt-settings (single tab)"
$lnk.Save()

Write-Output "OK：$LnkPath 已建立"
Write-Output ""
Write-Output "釘到工作列步驟："
Write-Output "  1. 右鍵 $LnkPath → 複製"
Write-Output "  2. 貼到桌面（或任意位置）"
Write-Output "  3. 右鍵桌面捷徑 → 釘選到工作列"
