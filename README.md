# wt-settings

Windows Terminal `settings.json` 備份與版本控制。

## 來源路徑

Windows Terminal 穩定版會讀取：

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

等同於：

```
C:\Users\<你的帳號>\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

## 同步方式

### 從本機推到 repo（備份）

```bash
cp "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" ~/workspace/wt-settings/settings.json
cd ~/workspace/wt-settings
git add settings.json
git commit -m "更新 WT settings"
git push
```

### 從 repo 拉回本機（套用）

```bash
cd ~/workspace/wt-settings
git pull
cp settings.json "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
```

修改後 Windows Terminal 會自動偵測並 hot-reload，不需重啟。

## 目前 keybindings 摘要

| 快捷鍵 | 動作 |
|--------|------|
| `Ctrl+C` | 複製 |
| `Ctrl+V` | 貼上 |
| `Alt+Shift+D` | 自動拆分 pane |
| `Alt+N` | 下一個 tab |
| `Alt+P` | 上一個 tab |
| `Alt+R` | 切換 pane 分割方向 |

## Profiles

- Git Bash（預設外）
- Windows PowerShell
- 命令提示字元（預設）
- Ubuntu (WSL)
- Azure Cloud Shell

## 單 tab 快速啟動三件套

仿 S189 的 5-tab 配色系統，本專案額外提供一個 teal-cyan 🟦🟢 配色的單 tab 啟動器。

| 檔案 | 用途 |
|------|------|
| `claude-wt-1-tab-wt-settings.bat` | 開一個 WT tab，cd 到本目錄，`claude --continue -n wt-settings`（具名 session） |
| `wt-settings.ico` | 6 解析度 multi-res icon（16/32/48/64/128/256），teal `{ }` 代表 JSON 設定 |
| `make_icon.py` | 重新生成 ICO（改色或字樣時用） |
| `wt-settings.lnk`（未 commit） | Windows 捷徑；target 指 `cmd.exe` + `WindowStyle=7` 才可右鍵釘工作列（Windows 1903+ 拔 `.bat` 的 pin verb） |

### 重建 .lnk（換機時）

```powershell
$sh = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut("$env:USERPROFILE\workspace\wt-settings\wt-settings.lnk")
$lnk.TargetPath       = "$env:SystemRoot\System32\cmd.exe"
$lnk.Arguments        = "/c `"$env:USERPROFILE\workspace\wt-settings\claude-wt-1-tab-wt-settings.bat`""
$lnk.WorkingDirectory = "$env:USERPROFILE\workspace\wt-settings"
$lnk.IconLocation     = "$env:USERPROFILE\workspace\wt-settings\wt-settings.ico,0"
$lnk.WindowStyle      = 7
$lnk.Description      = "Claude Code @ wt-settings (single tab)"
$lnk.Save()
```

### 釘到工作列

1. 右鍵 `wt-settings.lnk` → 複製 → 貼到桌面（或任意位置）
2. 右鍵桌面捷徑 → **釘選到工作列** / **釘選到開始畫面**

## 相關

- [Microsoft Docs — Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/)
- [Profiles schema](https://aka.ms/terminal-profiles-schema)
