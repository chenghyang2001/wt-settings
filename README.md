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

### 推薦：用 `apply.sh`（一條指令搞定備份 + 部署 + 驗證）

```bash
bash ~/workspace/wt-settings/apply.sh           # 套用最新 settings.json
bash ~/workspace/wt-settings/apply.sh --dry-run # 只看會發生什麼
```

`apply.sh` 自動做：偵測 WT 路徑 → 驗證 JSON → 備份舊檔（保留 5 份）→ cp → 驗證 → 檢查 Nerd Font + 孤兒 profile → 安裝 `/wt-sync` slash command。

### 在 Claude Code 內：用 `/wt-sync`

```
/wt-sync              # 自動 git pull + apply.sh
/wt-sync --dry-run    # 預覽
/wt-sync --regen-lnk  # 順便重建工作列 .lnk
```

詳細工作流見 `.claude/commands/wt-sync.md` 或 [CLAUDE.md](CLAUDE.md) 的「跨 PC 同步」段落。

### 手動同步（傳統方式）

從本機推到 repo（備份）：
```bash
cp "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" ~/workspace/wt-settings/settings.json
cd ~/workspace/wt-settings && git add settings.json && git commit -m "更新 WT settings" && git push
```

從 repo 拉回本機（套用）：
```bash
cd ~/workspace/wt-settings && git pull
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
| `regen-lnk.ps1` | 一鍵重建上面的 `.lnk`（換機器時用） |

### 重建 .lnk（換機時）

```powershell
powershell -ExecutionPolicy Bypass -File ~/workspace/wt-settings/regen-lnk.ps1
```

或在 Claude Code 內：`/wt-sync --regen-lnk`

### 釘到工作列

1. 右鍵 `wt-settings.lnk` → 複製 → 貼到桌面（或任意位置）
2. 右鍵桌面捷徑 → **釘選到工作列** / **釘選到開始畫面**

## 相關

- [Microsoft Docs — Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/)
- [Profiles schema](https://aka.ms/terminal-profiles-schema)
