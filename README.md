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

## 相關

- [Microsoft Docs — Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/)
- [Profiles schema](https://aka.ms/terminal-profiles-schema)
