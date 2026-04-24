# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案目的

此 repo 同時處理兩件事：

1. **Windows Terminal `settings.json` 版本控制**：把 `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` 拉進 git 做備份與跨機器同步。
2. **單 tab 快速啟動三件套**：供 Windows 工作列釘選用的 `.bat` + `.ico` + `.lnk`（+ 產 icon 的 `make_icon.py`），一鍵在本目錄開 `claude --continue -n wt-settings` 具名 session。

## 常用指令

### settings.json 同步（Git Bash）

從本機 → repo（備份）：

```bash
cp "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" ~/workspace/wt-settings/settings.json
```

從 repo → 本機（套用，WT 會 hot-reload 不需重啟）：

```bash
cp ~/workspace/wt-settings/settings.json "$LOCALAPPDATA/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
```

### 重建 icon

```bash
python make_icon.py   # 需要 Pillow；產出 wt-settings.ico
```

### 重建 .lnk（換機器時必做，`.lnk` 被 gitignore）

見 README.md 第 71-83 行 PowerShell 片段。**target 必須指向 `cmd.exe /c <bat>` 並設 `WindowStyle=7`**，否則 Windows 1903+ 無法右鍵釘工作列（`.bat` 的 pin verb 在 1903 後被拔掉）。

## 架構要點（需跨檔才能理解的部分）

### 三件套的耦合關係

```
wt-settings.lnk (gitignored)   ← 使用者右鍵釘工作列
  │  target = cmd.exe /c
  ▼
claude-wt-1-tab-wt-settings.bat  ← wt new-tab → cmd /k claude --continue -n wt-settings
  │
  ▼  icon 來源
wt-settings.ico  ← 由 make_icon.py 產生
```

- `.bat` 用 `wt new-tab --title "wt-settings" -d <path> cmd /k claude ...` 而非 `wt -d ...`，因為要保留 cmd 視窗存活（`cmd /k`）讓 Claude Code 持續跑。
- 具名 session：`claude --continue -n "wt-settings"` — 與 `.bat` 檔名、`wt new-tab --title`、repo 名稱**必須一致**（這樣使用者就能認出這是哪台專案的 session）。
- icon 設計：teal `#16a085` 底 + 白色 `{ }`，刻意避開 S189 已使用的 5 色（紅/棕/綠/藍/紫），作為第 6 色系統。

### icon 產生的非顯而易見細節

`make_icon.py` 第 60-68 行**逐尺寸用 `render_at(s)` 個別產圖**而非一次 `save(sizes=...)`，原因是 Pillow ICO 匯出有一個 bug：只會把 primary 尺寸存進去，`sizes=[...]` 參數會被忽略。workaround 是先把 256 存成 primary，再用 `append_images=[16..128]` 把其他尺寸黏上去。改 icon 時**不要動這個迴圈結構**。

### 跨機器可移植性

- `.bat` / `.py` / `.ico` 用 `%USERPROFILE%` / `Path(__file__).parent` — 可攜。
- `.lnk` **不可攜**（絕對路徑內嵌）— 已 gitignore，換機時用 README 的 PowerShell 片段重建。
- `settings.json` 本身有幾個欄位是機器特定的（profile `guid`、`CaskaydiaCove Nerd Font` 需本機已裝），拉回別台機器前要確認字型已安裝。

## 兩層權威

| 檔案 | 權威位置 |
|------|---------|
| `settings.json`（工作版本） | `%LOCALAPPDATA%\...\LocalState\settings.json`（WT 實際讀取的那份） |
| `settings.json`（備份/歷史） | 本 repo（git 歷史即變更記錄） |

修改流程：**先改 WT（GUI 或直接編 LocalState 的檔）→ WT hot-reload 驗證無誤 → 再 `cp` 進 repo commit**。不要反過來先改 repo 版本再 copy 過去（會跳過 WT 的 schema 驗證）。

## 未來擴展清單（來自 PDF《打造專屬的 Windows Terminal — JSON 設定檔視覺化完全指南》）

原始 PDF 在 `pdf/Windows_Terminal_JSON_Blueprint.pdf`（10 頁，含 cheat sheet）。下表對照 PDF 建議的屬性與本 repo 目前狀態，供未來調整參考。

| PDF 建議屬性 | 狀態 | 決策 / 值 |
|---|---|---|
| `padding`（內部留白） | ✅ 已套用 | `"25, 25, 25, 25"`（PDF 舒適型） |
| `useAcrylic` / `acrylicOpacity` | ✅ 已套用 | `true` / `0.75` |
| `defaultProfile` | ✅ 保留 cmd | `{0caa0dad-35be-5f56-a8ff-afceeeaa6101}`（與 bat `cmd /k` 工作列釘選一致） |
| `cursorColor` / `cursorShape` | ✅ 已套用 | `#FFCC00` / `filledBox`（放 `profiles.defaults`，全 profile 共用） |
| `startingDirectory`（PowerShell / cmd） | ✅ 已套用 | `%USERPROFILE%\workspace`（Git Bash 仍維持 `%USERPROFILE%`） |
| `backgroundImage` 三件組 | ❌ 互斥排除 | 已選 Acrylic，兩者不可並存 |

**關鍵互斥規則**：`useAcrylic: true` 和 `backgroundImage` 不可同時啟用 — DWM 模糊合成管線（抓桌面像素模糊）和 GPU 貼圖走不同 render path，WT 強制二選一。若未來改用背景圖，必須先把 `useAcrylic` 設 `false`，再加 `backgroundImage` / `backgroundImageOpacity` / `backgroundImageStretchMode` 三個屬性（PDF 第 9 頁）。

**屬性放置慣例**：跨所有 profile 共用的屬性（字型、padding、acrylic）放在 `profiles.defaults`；單一 profile 才需要的（startingDirectory、icon）放在該 profile 本身。

## Claude Code CLI 工作流配置（2026-04-24 套用）

主要使用情境：3 windows × 3-4 panes 同時跑多個 Claude Code 專案 / sub-agents 觀測。設計目標 = **觀測台模式**（不丟失 + 知道焦點 + 知道完工 + 快速切換）。

### 上下文管理
- `profiles.defaults.historySize: 100000` — Claude 對話超長，預設 9001 行不夠
- `keybindings: Terminal.MarkMode (ctrl+shift+m)` — 鍵盤滾動 scrollback，免用滑鼠

### Pane 操作（觀測多 agent 必備）
- `Terminal.MoveFocus{Left,Right,Up,Down}` 綁 `alt+方向鍵` — pane 焦點切換
- `Terminal.ResizePane{Left,Right,Up,Down}` 綁 `alt+shift+方向鍵` — 動態調整 pane 大小
- `Terminal.TogglePaneZoom` 綁 `alt+z` — 暫時放大單一 pane 全螢幕，再按一次回到 multi-pane

### 視覺辨識（多 windows / 多 panes 場景）
- `profiles.defaults.unfocusedAppearance.opacity: 70` — 非焦點 pane 半透明，當前 pane 一目了然
- `tabWidthMode: "titleLength"` — tab 寬度依標題伸縮，不再擠成一團

### 完工通知
- `profiles.defaults.bellStyle: ["taskbar", "window"]` — Claude 跑完長任務時工作列圖示閃爍 + 視窗閃爍，不在 WT 視窗也能注意到

### 視窗持久化（救命符）
- `firstWindowPreference: "persistedWindowLayout"` — WT 當機/重開自動還原全部 windows + tabs + panes 布局
- `warning.confirmCloseAllTabs: true` — 防止 `Ctrl+Shift+W` 誤關 12 panes

### 內容操作
- `wordDelimiters: " ()\"'-,;<>~!@#$%^&*|+=[]{}~?│"` — 移除 `/`、`\`、`.`、`:` 後雙擊路徑/URL 整段選起（Claude 對話常出現的 `app/auth/middleware.py` 一次選好）
- `multiLinePasteWarning: true` — 多行貼上會警告，避免從 Claude 對話複製 `rm -rf` 直接執行

### 啟動行為
- `profiles.defaults.initialCols: 140` / `initialRows: 40` — 視窗預設大小固定，3 windows 並排不會大小不一
- `centerOnLaunch: true` — 視窗居中啟動

### 快速參考：本 repo 已自訂的所有快捷鍵

| 鍵 | 動作 |
|---|---|
| `Ctrl+C` / `Ctrl+V` | 複製 / 貼上 |
| `Alt+Shift+D` | 自動拆分 pane |
| `Alt+R` | 切換 pane 分割方向 |
| `Alt+N` / `Alt+P` | 下/上一個 tab |
| `Alt+方向鍵` | pane 焦點移動 |
| `Alt+Shift+方向鍵` | pane 大小調整 |
| `Alt+Z` | pane 暫時全螢幕 |
| `Ctrl+Shift+M` | 進入 mark mode（鍵盤滾動 scrollback） |
