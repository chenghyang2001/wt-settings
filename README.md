# wt-settings

Windows Terminal `settings.json` 備份與版本控制。

## 新 PC 設定

選一條路徑（看你新 PC 上有沒有 Git Bash）：

### 路徑 A — 有 Git Bash（推薦，功能最全）

```bash
# 1. clone repo
git clone https://github.com/chenghyang2001/wt-settings ~/workspace/wt-settings

# 2. bootstrap：apply.sh 自動偵測 + 部署 + 安裝 /wt-sync slash command + 字型/孤兒 profile 檢查
bash ~/workspace/wt-settings/apply.sh

# 3. （可選）重建工作列 .lnk（gitignored，每台機器需各自重建）
powershell -ExecutionPolicy Bypass -File ~/workspace/wt-settings/regen-lnk.ps1

# 4. 從 nerdfonts.com 下載 CaskaydiaCove Nerd Font 並「為所有使用者安裝」
#    apply.sh 偵測缺失時會印警告
```

### 路徑 B — 純 Windows、沒裝 Git Bash

```cmd
:: 1. clone repo（git for Windows 即可，不需要 Git Bash）
git clone https://github.com/chenghyang2001/wt-settings %USERPROFILE%\workspace\wt-settings

:: 2. 部署 WT settings（Windows native，純 cmd + 內建 PowerShell）
cd %USERPROFILE%\workspace\wt-settings
apply.bat

:: 3. （可選）安裝 CLI aliases（by / 等）
setup.bat

:: 4. （可選）重建工作列 .lnk
powershell -ExecutionPolicy Bypass -File regen-lnk.ps1
```

`apply.bat` 與 `apply.sh` 對標：同樣會做「source 檢查 → JSON 驗證 → 備份輪替 5 份 → cp → 驗證」7 步驟。差別只是 .bat 沒做字型/孤兒 profile 檢查（apply.sh 額外加分項目）。

之後在該 PC 的 Claude Code 內就能用：

```
/wt-sync                  # 自動 git pull + 套用最新設定
/wt-sync --dry-run        # 預覽會發生什麼，不動真檔
/wt-sync --regen-lnk      # 順便重建工作列 .lnk
```

設計細節（兩件式架構、孤兒 profile 偵測、5 份備份輪替等）見 [CLAUDE.md](CLAUDE.md)。

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

## 鍵盤快捷鍵 Cheatsheet

完整 19 個自訂快捷鍵的 1 頁 A4 cheatsheet（PDF + HTML 雙格式，Git 追蹤）：

- 📄 [**doc/keybindings-cheatsheet.pdf**](doc/keybindings-cheatsheet.pdf) — 列印用 / 跨 PC 攜帶
- 🌐 [**doc/keybindings-cheatsheet.html**](doc/keybindings-cheatsheet.html) — 瀏覽器開即可看

8 個分類：複製貼上 / Tab 操作 / Pane 拆分 / Pane 焦點 / Pane 大小 / Pane 縮放 / Pane 關閉 / 滾動。

### 重新生成 cheatsheet

每次 `settings.json` 的 `keybindings` 改了，跑這個重生：

```cmd
:: Windows native（cmd 雙擊或在 cmd 跑）
gen-cheatsheet.bat

:: 或 Git Bash
PYTHONUTF8=1 python gen_cheatsheet.py
```

需要 **Python 3.10+** 與 **Microsoft Edge**（用 `--headless --print-to-pdf` 渲染 PDF；Edge 是 Windows 預設瀏覽器，通常已裝好）。

### 摘要（前 6 個常用）

| 快捷鍵 | 動作 |
|--------|------|
| `Ctrl+C` / `Ctrl+V` | 複製 / 貼上 |
| `Alt+S` / `Alt+Shift+D` | 自動拆分 pane（兩個 alias 同效） |
| `Alt+H/J/K/L` | 焦點移到左/下/上/右 pane（vim 風） |
| `Alt+F` | 焦點切換到下一個 pane（建立順序） |
| `Alt+Shift+方向鍵` | 調整當前 pane 大小 |
| `Alt+Z` / `Alt+E` | 暫時放大 / 關閉當前 pane |
| `Alt+N` / `Alt+P` | 下/上一個 tab |
| `Ctrl+Shift+M` | 進入鍵盤標記模式（滾動 scrollback） |

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

## CLI Aliases（`bin/`）

跨 PC 共用的命令列 alias（cmd / PowerShell / Git Bash 通用）：

| Alias | 指令 |
|-------|------|
| `by` | `claude --continue --permission-mode bypassPermissions %*` — 接續上次對話 + 跳過權限提示 |

### 一鍵部署（推薦）

新 PC clone 完 repo 後，直接雙擊 `setup.bat` 或在 cmd 跑：

```cmd
cd %USERPROFILE%\workspace\wt-settings
setup.bat
```

`setup.bat` 會：建 `~/bin` → copy `bin\*.bat` → 冪等補 user PATH（PowerShell 而非 setx，避開 1024 字元截斷 bug）→ 警告 `claude` CLI 是否存在 → 開新 cmd 跑 `where by` 驗證部署成功。重跑兩次行為一致。

### 手動部署（若不想跑腳本）

```bash
mkdir -p "$HOME/bin"
cp ~/workspace/wt-settings/bin/*.bat "$HOME/bin/"
# 若 ~/bin 不在 PATH 上，開 PowerShell：
#   $bin = "$env:USERPROFILE\bin"
#   $up  = [Environment]::GetEnvironmentVariable("Path","User")
#   if (";$up;" -notlike "*;$bin;*") {
#       [Environment]::SetEnvironmentVariable("Path","$up;$bin","User")
#   }
```

詳細設計與新增 alias 的 SOP 見 [doc/wt-launchers-index.md 第 7 節](doc/wt-launchers-index.md#7-cli-aliasesbin)。

## 相關

- [Microsoft Docs — Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/)
- [Profiles schema](https://aka.ms/terminal-profiles-schema)
