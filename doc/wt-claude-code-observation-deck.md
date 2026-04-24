# Claude Code 多 Agent 觀測台：Windows Terminal 18 項配置完全指南

## 為什麼要做這套配置

當你日常使用 Claude Code CLI 進行**多專案、多 sub-agent 平行作業**時，預設的 Windows Terminal 配置會成為瓶頸。典型場景：

- 同時開 3 個 Claude Code session 跑 3 個不同專案（aihcr-daily / n8n2vps-hub / wt-settings）
- 每個 session 視窗內再拆 3-4 個 panes 觀察不同 agent 狀態：主對話、`tail -f log`、`git status`、`htop`
- Claude 任務常跑 5-30 分鐘，期間你會切到 IDE / 瀏覽器處理別的事，需要知道何時跑完
- 對話超長（一個 session 輕鬆 2 萬行 scrollback），需要回頭找早期內容
- 跨 panes 複製檔案路徑、URL、code block

這 18 項配置形成一套「**觀測台模式**」(Observatory Mode)，把 Windows Terminal 從通用終端機改造成 Claude Code 多 agent 監控台。設計原則：

1. **不丟失**（persistedWindowLayout、historySize、confirmCloseAllTabs）
2. **知道焦點**（unfocusedAppearance、cursorColor、TogglePaneZoom）
3. **知道完工**（bellStyle taskbar+window）
4. **快速切換**（Alt+方向鍵、tab title 跟 cwd）
5. **複製順手**（wordDelimiters、multiLinePasteWarning）

---

## A. 上下文管理（避免丟失過往對話）

### 1. `historySize: 100000`

**設定**：`profiles.defaults.historySize: 100000`
**預設值**：9001
**改成**：100,000 行

**這個設定做什麼**

每個 pane 在記憶體中保留多少行歷史輸出（scrollback buffer）。超過上限時，最舊的行被丟棄，無法再用滑鼠或 Ctrl+Shift+F 找回來。

**為何這對 Claude Code CLI 重要**

Claude 一個 session 的輸出**輕鬆突破 2 萬行**：每個 tool call 顯示輸入/輸出、每次 Edit 顯示完整 diff、thinking 區塊、agent 任務的子代理輸出、verbose 模式的詳細 trace。預設 9001 行根本撐不過 2 小時的密集對話 — 你回頭想找 Claude 之前產出的某段程式碼或 commit hash，會發現 buffer 已經被吃掉。

100,000 行能完整保留 6-8 小時的密集 session 對話。每 pane 約佔記憶體 200-400MB（每行平均 2-4KB），12 panes 全開最多 5GB — 對現代 16GB+ RAM 機器無感。

**怎麼觸發 / 操作**

被動，自動生效。Claude 跑完任務後在 pane 內按 `Ctrl+Shift+↑` 或 `Ctrl+Shift+End` 滾動，或直接用滑鼠滾輪往上看。

**搭配技巧**

配合 #2「Find in scrollback」(`Ctrl+Shift+F`) 才能真正發揮 — 100k 行你不可能用眼睛掃，要用搜尋。

---

### 2. Find in scrollback（`Ctrl+Shift+F`）

**設定**：WT 內建熱鍵，預設啟用，無需額外配置
**預設值**：`Ctrl+Shift+F` 開啟搜尋視窗

**這個設定做什麼**

在當前 pane 的 scrollback 內做文字搜尋，支援 regex、case-sensitive、whole-word 切換。命中項目高亮 + 跳轉。

**為何這對 Claude Code CLI 重要**

Claude 經常產出你會想回頭找的內容：
- 「剛剛 Claude 提到的那個檔案路徑」→ 搜檔名片段
- 「上一次 commit 的 SHA」→ 搜 `commit` 或 hash 前綴
- 「Claude 報的某個錯誤訊息」→ 搜 error keyword
- 「我之前回 Claude 的某個指令」→ 搜你發的關鍵字

沒有這個功能，你只能滑鼠滾上看 — 在 100k 行的 buffer 裡是地獄。

**怎麼觸發 / 操作**

在 pane 內按 `Ctrl+Shift+F` → 輸入搜尋字 → Enter → `F3` 跳下一個、`Shift+F3` 跳上一個 → `Esc` 關搜尋。

**搭配技巧**

對 Claude 的 `Tool: Bash` 區塊很好用 — 直接搜「Bash」就能跳到所有 bash 指令的位置。

---

### 3. `MarkMode`（`Ctrl+Shift+M`）

**設定**：`{ "id": "Terminal.MarkMode", "keys": "ctrl+shift+m" }`
**預設值**：未綁定
**改成**：綁 `Ctrl+Shift+M`

**這個設定做什麼**

進入鍵盤瀏覽模式 — 用方向鍵、PgUp/PgDn 移動游標 cursor 在 scrollback 中，可選取文字後 Enter 複製。完全不需要滑鼠。

**為何這對 Claude Code CLI 重要**

當 Claude 還在 streaming 輸出時，用滑鼠滾動很容易誤觸（Claude 把焦點搶回去自動往下捲）。Mark mode 暫停 stream tracking，讓你可以穩定瀏覽。

也適合**遠端 SSH** 或**鍵盤至上派**使用者 — 完全不離開鍵盤。

**怎麼觸發 / 操作**

`Ctrl+Shift+M` 進入 → 方向鍵移動游標 → `Shift+方向鍵` 選取 → `Enter` 複製到剪貼簿 → `Esc` 退出。

**搭配技巧**

Mark mode 中 `Ctrl+方向鍵` 一次跳一個字，`Home/End` 跳行首尾，`PgUp/PgDn` 翻頁 — 跟 Vim navigation 邏輯接近。

---

## B. Pane 管理（多 agent 平行觀測）

### 4. Pane 焦點導航（`Alt+方向鍵`）

**設定**：4 個 keybindings
```json
{ "id": "Terminal.MoveFocusLeft", "keys": "alt+left" }
{ "id": "Terminal.MoveFocusRight", "keys": "alt+right" }
{ "id": "Terminal.MoveFocusUp", "keys": "alt+up" }
{ "id": "Terminal.MoveFocusDown", "keys": "alt+down" }
```
**預設值**：未綁定（這是 WT 設計缺陷）

**這個設定做什麼**

把鍵盤焦點移到當前 pane 的左/右/上/下相鄰 pane。

**為何這對 Claude Code CLI 重要**

這是**多 pane 工作流的命脈**。當你拆出 4 個 panes 監控不同 agent 時，沒有快速切焦點的鍵 = 廢。預設 WT 沒綁定這 4 個鍵 — 等於要你用滑鼠點各個 pane。對重度鍵盤使用者來說無法接受。

實際場景：
- pane A 跑主 Claude session → pane B 看 git log → pane C 看 `tail -f` → pane D 跑 htop
- 你需要快速從 A 切到 B 看剛 commit 的內容 → `Alt+→`
- 從 B 切回 A 繼續跟 Claude 對話 → `Alt+←`

**怎麼觸發 / 操作**

按 `Alt+方向鍵`，焦點立即跳到對應方向的 pane。

**搭配技巧**

WT 智慧導航：如果右邊有 2 個 panes 上下排列，`Alt+→` 會優先跳到「水平上最接近當前游標位置」的那個。所以你的 mental model 是「視覺上的相鄰」，而非「拆分順序的相鄰」。

---

### 5. Pane 大小調整（`Alt+Shift+方向鍵`）

**設定**：4 個 keybindings
```json
{ "id": "Terminal.ResizePaneLeft", "keys": "alt+shift+left" }
{ "id": "Terminal.ResizePaneRight", "keys": "alt+shift+right" }
{ "id": "Terminal.ResizePaneUp", "keys": "alt+shift+up" }
{ "id": "Terminal.ResizePaneDown", "keys": "alt+shift+down" }
```
**預設值**：未綁定

**這個設定做什麼**

縮小或放大當前 pane 的尺寸（朝某個方向擴張）。

**為何這對 Claude Code CLI 重要**

不同 pane 應該有不同重要性 → 不同大小：
- 主 Claude pane：60% 寬度
- `tail -f log` pane：20%（看狀態跑就好）
- `git status` pane：20%

預設 panes 是平均分配 — 4 個 panes 就是 25% × 4，主 pane 太擠。手動拖拽 splitter 又不精準。`Alt+Shift+方向鍵`一次調整 5%，按住可連續調整。

**怎麼觸發 / 操作**

按住 `Alt+Shift` + 連按方向鍵，當前 pane 朝該方向擴張（吃掉相鄰 pane 的空間）。

**搭配技巧**

配合 #7「TogglePaneZoom」(`Alt+Z`) — 平時各 pane 維持 60/20/20，需要時 `Alt+Z` 把主 pane 全螢幕，看完再 `Alt+Z` 回去。

---

### 6. `unfocusedAppearance` 半透明非焦點 pane

**設定**：
```json
"unfocusedAppearance": {
    "opacity": 70,
    "useAcrylic": true
}
```
**位置**：`profiles.defaults`
**預設值**：無（所有 pane 不論焦點都是 100% 不透明）
**改成**：非焦點 pane 70% 透明 + acrylic 模糊

**這個設定做什麼**

當前 pane（有鍵盤焦點）保持全亮 100%，其他非焦點 panes 變半透明 70%。視覺上立刻分辨「我現在在哪」。

**為何這對 Claude Code CLI 重要**

4 panes 並列時，眼睛容易迷失「焦點在哪裡」。雖然有 `cursorColor: #FFCC00` 的黃色游標可以找，但「整個 pane 變色」比「找游標」快 3 倍。

也避免你**對著錯的 pane 打字** — 想跟 Claude 對話卻打到 `tail -f` 的 pane（雖然 tail 不會回應，但你會浪費幾秒搞清楚為什麼沒反應）。

**怎麼觸發 / 操作**

被動，自動生效。切焦點時相鄰 pane 會立即由暗變亮。

**搭配技巧**

`opacity: 70` 是個甜蜜點 — 太低（< 50）連非焦點 pane 的內容都看不清，失去監控意義；太高（> 85）跟焦點 pane 視覺差不夠，達不到提示效果。

---

### 7. `TogglePaneZoom`（`Alt+Z`）

**設定**：`{ "id": "Terminal.TogglePaneZoom", "keys": "alt+z" }`
**預設值**：未綁定
**改成**：綁 `Alt+Z`

**這個設定做什麼**

當前 pane 暫時放大到全 tab 大小（其他 panes 隱藏但仍在跑）。再按一次回到原本的 multi-pane 布局。

**為何這對 Claude Code CLI 重要**

Claude 在做大量 tool calls 或長 diff 時，主 pane 25% 寬度看不下去 — 文字被自動 wrap，diff 變雜亂。`Alt+Z` 暫時把它放大到全螢幕看清楚，看完再 `Alt+Z` 回到 monitoring 布局。

關鍵：**其他 panes 沒有死**。它們在背景繼續跑，只是不顯示 — 你看完主 pane 切回去時，`tail -f` 已經收到新行、`htop` 數字也更新了。

**怎麼觸發 / 操作**

`Alt+Z` toggle。第一次按 = zoom，第二次按 = 還原。

**搭配技巧**

跟 #5 ResizePane 互補：ResizePane 是「永久調整布局」，TogglePaneZoom 是「臨時聚焦」。前者用於穩定的 60/20/20 設定，後者用於應急閱讀長輸出。

---

## C. 視覺辨識（多 windows × 多 tabs 不混亂）

### 8. Tab title 自動跟隨 cwd

**設定**：`profiles.defaults.suppressApplicationTitle: false`（顯式設為 false，這是預設值但寫出來代表「我們依賴這個行為」）

**這個設定做什麼**

允許 shell 用 ANSI escape sequence 設定 tab 標題（如 `echo -ne "\033]0;my-title\007"`）。如果 set 為 true，這些指令被忽略，tab 標題永遠顯示 `wt new-tab --title` 指定的初始值。

**為何這對 Claude Code CLI 重要**

當你 3 windows 各 4 panes 共 12 panes、其中跨 2-3 個專案時，每個 tab 標題顯示什麼決定你能不能快速分辨。

理想：tab 標題顯示 **當前 cwd** — 一眼看出「這個 tab 在 aihcr-daily」、「那個在 wt-settings」。

要實現這個，shell 端要設定 PROMPT 自動寫 tab title：

**Git Bash** (`~/.bashrc`)：
```bash
PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/~}\007"'
```

**PowerShell** (`$PROFILE`)：
```powershell
function prompt {
    $title = (Get-Location).Path -replace [regex]::Escape($HOME), '~'
    $Host.UI.RawUI.WindowTitle = $title
    "PS $($title)> "
}
```

WT 端把 `suppressApplicationTitle: false` 才會接收這些 escape sequence。

**怎麼觸發 / 操作**

被動。每次你 `cd` 到新目錄，下次 prompt 出現時 tab 標題自動更新。

**搭配技巧**

Claude Code 自己**不更新 tab title**。要靠 shell 的 PROMPT 設定。如果你跑 Claude 後 tab 標題凍結在「啟動時的那個 cwd」，那是 Claude 不參與 prompt loop 的關係 — 等 Claude exit 後 cd 一次就會更新。

---

### 9. `SetTabColor`（手動，非熱鍵）

**設定**：WT 內建 action，可選擇性綁熱鍵。預設可從 tab 右鍵選單觸發。

**這個設定做什麼**

對當前 tab 設定底色（一條色帶顯示在 tab 列）。永久（直到關閉 tab）。

**為何這對 Claude Code CLI 重要**

一個 tab 標題太長被截斷時，**色帶比文字更快認**。建立你自己的色彩約定：
- 紅色 = production / aihcr-daily（生產關鍵）
- 藍色 = n8n2vps-hub（VPS 自動化）
- 綠色 = wt-settings（個人設定）
- 黃色 = 臨時 / 實驗

切到紅色 tab 時心裡警鐘響起 — 你在動真的東西。

**怎麼觸發 / 操作**

右鍵 tab → 「設定 tab 色彩」→ 選色。或自訂熱鍵：
```json
{ "id": "Terminal.SetTabColor", "keys": "ctrl+shift+t" }
```

**搭配技巧**

Tab 色彩**不持久**（重開 WT 會消失）。如果你想固定某個 profile 永遠是某色，在 profile 內加 `"tabColor": "#FF0000"`。但這就失去「同 profile 不同 tab 不同顏色」的彈性 — 取捨之間。

---

### 10. `tabWidthMode: titleLength`

**設定**：`tabWidthMode: "titleLength"`
**預設值**：`equal`
**改成**：`titleLength`

**這個設定做什麼**

控制 tab 寬度策略：
- `equal`（預設）：所有 tab 平分寬度，多 tab 時都被擠成同寬
- `titleLength`：每個 tab 寬度跟標題長度成正比
- `compact`：類似瀏覽器，當前 tab 顯示完整標題，其他 tab 縮成 icon

**為何這對 Claude Code CLI 重要**

預設 `equal` 在 5+ tabs 時會把所有標題截斷成「aih...」「n8n...」「wt-...」— 完全分不出誰是誰。

`titleLength` 讓「aihcr-daily」顯示完整、「wt-settings」也顯示完整，反而是空白 tab（如剛開的 cmd）變窄 — 真正提升資訊密度。

**怎麼觸發 / 操作**

被動，立即生效。你開新 tab、改名 tab、切 cwd（如果 #8 啟用）時 tab 寬度自動調整。

**搭配技巧**

跟 #8 (cwd 自動 title) 是黃金組合 — 沒 cwd title，所有 tab 標題都是「Windows PowerShell」這種廢標題，`titleLength` 也救不了。

---

## D. 完工通知（Claude 跑完知道）

### 11. `bellStyle: ["taskbar", "window"]`

**設定**：`profiles.defaults.bellStyle: ["taskbar", "window"]`
**預設值**：`["audible"]`（系統預設音）
**改成**：工作列圖示閃爍 + 視窗框閃爍，無聲音

**這個設定做什麼**

當 pane 收到 ASCII BEL 字元（`\a` / `0x07`）時，WT 觸發的反饋方式：
- `audible`：發系統 beep 音
- `visual`：閃爍視窗一次（已 deprecated）
- `taskbar`：閃爍工作列圖示（橘色，直到視窗被聚焦）
- `window`：閃爍視窗框

**為何這對 Claude Code CLI 重要**

你跑 Claude 一個長任務（5-30 分鐘），會切到 IDE / 瀏覽器處理別的事。中途 Claude 要不要繼續、跑完了沒、卡住等待你輸入、或失敗了 — 你不會知道。

`taskbar + window` 是「**靜音通知**」：圖示閃爍不打擾你（不像系統 beep 會吵到隔壁同事），但你掃一眼工作列就看到「橘色閃爍 → 該回 Claude 視窗了」。

要讓 Claude 完成任務時觸發 bell，需要在 `~/.claude/settings.json` 加 Stop hook：
```json
"Stop": [{
  "hooks": [{ "type": "command", "command": "printf '\\a'" }]
}]
```

**怎麼觸發 / 操作**

被動。Claude Stop hook 送 `\a` → WT 收到 BEL → 觸發 bellStyle 行為。

**搭配技巧**

如果你跑很多 Claude session 同時開，**每個都會閃**。可以在 hook 加判斷只有特定條件才送 BEL（例如 task 跑超過 30 秒才通知，避免每次小任務都閃）。

---

### 12. 靜音 bell（無音效）

**設定**：上面 `bellStyle` 不含 `audible` 即達成
**注意**：如果 WT bellStyle 預設值含 audible，需顯式設定上面的 `["taskbar", "window"]` 排除 audible

**這個設定做什麼**

確保 Claude 完工通知**不會發聲**。

**為何這對 Claude Code CLI 重要**

辦公室環境發 beep 等於騷擾同事。長 session 期間 Claude 可能跑 N 個 sub-agent，每個結束都 beep 你會被痛罵。視覺通知（taskbar 閃爍）達到同樣效果但社交友善。

**怎麼觸發 / 操作**

被動，bellStyle 不含 audible 即無聲。

**搭配技巧**

如果是個人環境（家裡）想要聲音，可以加回 `audible`：`bellStyle: ["taskbar", "window", "audible"]`。

---

## E. 視窗持久化（救命符）

### 13. `firstWindowPreference: "persistedWindowLayout"`

**設定**：`firstWindowPreference: "persistedWindowLayout"`
**位置**：頂層全域
**預設值**：`"defaultProfile"`（每次開 WT 都從零開始）
**改成**：`persistedWindowLayout`

**這個設定做什麼**

WT 會 atomic snapshot 整個視窗樹狀態（windows × tabs × panes × cwd）到 disk。下次啟動 WT、或當機後重開、或系統重啟後，全部還原。

**為何這對 Claude Code CLI 重要**

你的 multi-agent 觀測台辛苦設定的 3 windows × 4 panes 布局，**任何意外都不會丟**：
- WT 自己當機 → 重開還原
- Windows 強制重啟 → 重開還原
- 你不小心 `Ctrl+Shift+W` → 重開還原
- 顯示器斷電 → 重開還原

配合 Claude `--continue` 旗標，**雙重持久化**：WT 記住「我有哪些 panes」，Claude 記住「我跟你說到哪」。重開後切回去，跟沒中斷一樣。

**怎麼觸發 / 操作**

被動，自動。每隔幾秒 WT 自動寫快照到 `%LOCALAPPDATA%\...\state.json`。

**搭配技巧**

和 #14 `confirmCloseAllTabs: true` 雙保險 — 一個防意外當機、一個防誤操作。

---

### 14. `warning.confirmCloseAllTabs: true`

**設定**：`warning.confirmCloseAllTabs: true`
**預設值**：`true`（但很多人會手賤改 false）
**改成**：保持 `true`（如果你之前改過 false 要改回來）

**這個設定做什麼**

按 `Ctrl+Shift+W` 或視窗的 X 鍵時，如果 tab 數 > 1，會跳警告「確定要關閉所有 tab 嗎？」

**為何這對 Claude Code CLI 重要**

你 3 windows × 4 panes = 12 panes 內可能跑著 12 個 Claude session。誤關 = 12 個 session 全斷 + 12 個 panes 的 scrollback 全丟。雖然 `--continue` 能救對話，但 panes 布局要重新拉一次。

警告對話框那 1 秒延遲就是救命符。

**怎麼觸發 / 操作**

被動。`Ctrl+Shift+W` 時跳對話。

**搭配技巧**

**永遠不要勾「下次不再詢問」** — 那一勾就回到「沒警告，誤操作直接死亡」的狀態。

---

## F. 內容操作（複製 / 貼上 / 選取）

### 15. `wordDelimiters` 路徑/URL 雙擊全選

**設定**：`wordDelimiters: " ()\"'-,;<>~!@#$%^&*|+=[]{}~?│"`
**預設值**：`" /\\()\"'-.,:;<>~!@#$%^&*|+=[]{}~?│"`（含 `/`、`\`、`.`、`:`）
**改成**：移除 `/`、`\`、`.`、`:`

**這個設定做什麼**

定義「字界」字元 — 雙擊選取時碰到這些字元就停止。預設含 `/`、`\`、`.`、`:` 意味著雙擊 `app/auth/middleware.py` 只能選到 `middleware`，要選整個路徑必須拖選。

**為何這對 Claude Code CLI 重要**

Claude 對話經常出現你想複製的字串：
- 檔案路徑：`C:\Users\B00332\workspace\file.py`
- 模組路徑：`app/components/auth/middleware.py`
- URL：`https://docs.anthropic.com/en/api/...`
- Git SHA：`a1b2c3d4`
- Python module：`mypackage.submodule.function`

預設這些雙擊都會被拆斷，要嘛拖選（容易選漏）、要嘛手動 Ctrl+Shift+End 加 Shift+方向鍵 — 都很慢。

把 `/`、`\`、`.`、`:` 從 wordDelimiters 移除後，雙擊任何路徑/URL 整段選起。

**怎麼觸發 / 操作**

雙擊文字。被動使用，越用越爽。

**搭配技巧**

`-` 仍保留為 delimiter 是刻意 — 否則 `npm-script-name` 會被當成一個字。如果你常複製 kebab-case，可以也把 `-` 移除。`_` 永遠不是 delimiter（snake_case 友善）。

---

### 16. `multiLinePasteWarning: true`

**設定**：`multiLinePasteWarning: true`
**預設值**：`true`（可能被某些情況關閉）
**改成**：顯式 `true` 確保開啟

**這個設定做什麼**

當你貼上的內容包含換行字元時，跳警告「貼上多行內容會自動執行，確定？」

**為何這對 Claude Code CLI 重要**

你經常從 Claude 對話複製多行 bash 指令：
```bash
cd ~/workspace/foo
git pull
npm install
npm test
```

直接貼到 shell = 自動逐行執行。如果中間有 `rm -rf` 或 `npm install some-malicious-package`（如果 Claude 被 prompt injection 騙到推薦壞 package），你就完蛋了。

警告強迫你**看一眼**「你真的要執行這 4 行嗎？」

**怎麼觸發 / 操作**

被動。每次 `Ctrl+V` 貼上含換行的內容時跳對話。

**搭配技巧**

如果你**確認自己貼的東西安全**（如 100% 自寫的 script），可以在對話中勾「下次不再詢問」— 但建議**永遠不勾**。1 秒延遲就能避免一次災難。

---

## G. 啟動行為（多視窗排版一致）

### 17. `initialCols: 140` / `initialRows: 40`

**設定**：
```json
"profiles.defaults.initialCols": 140
"profiles.defaults.initialRows": 40
```
**預設值**：120 cols × 30 rows
**改成**：140 × 40

**這個設定做什麼**

新開 WT 視窗時的初始尺寸（單位是字元欄/列，不是像素）。

**為何這對 Claude Code CLI 重要**

3 windows 並排顯示在 4K / 1440p 螢幕上，三個視窗大小一致才好看。預設 120×30 在現代螢幕上偏小，Claude 的 ASCII 表格、code diff 容易換行。

140 cols 容納大多數 80-120 字元的 code line + 一些縮排空間。40 rows 比 30 多 33% 內容可視 — 看 Claude 的長 thinking 區塊或 diff 時受用。

**怎麼觸發 / 操作**

被動。新開視窗時自動套用。已開的視窗不會被改（你可以手動拖大小）。

**搭配技巧**

若你有 27 寸 4K 螢幕想 3 windows 並排，可以更激進：`initialCols: 180, initialRows: 50`。1080p 螢幕反而要保守：`120 × 30`。

---

### 18. `centerOnLaunch: true`

**設定**：`centerOnLaunch: true`
**預設值**：`false`
**改成**：`true`

**這個設定做什麼**

新開 WT 視窗時自動置中於主螢幕，而非預設的「上次關閉的位置」或「螢幕左上角」。

**為何這對 Claude Code CLI 重要**

如果你不開「persistedWindowLayout」，每次開 WT 視窗的位置會重複你上次關閉的位置 — 對 multi-monitor 使用者特別煩（可能在第二螢幕關閉後，下次第一螢幕開不出來）。

`centerOnLaunch` 確保視窗永遠在「你看得到的地方」開出來。配合 `initialCols/Rows` 固定大小 → 每次新視窗的「位置 + 大小」完全一致 → 排版可預期。

**怎麼觸發 / 操作**

被動。每個新 WT 視窗自動置中。

**搭配技巧**

如果你開了 `firstWindowPreference: persistedWindowLayout`（#13），這個設定**只對「真的全新視窗」生效** — restored window 會回到原位置。所以兩者不衝突。

---

## 觀測台模式：18 項組合起來的綜效

單獨看，每項只是個小 tweak。組合起來形成一個**「Claude Code multi-agent 觀測台」**的設計模式：

### 不丟失（4 項）
- `historySize: 100000` 防止 scrollback 截斷
- `firstWindowPreference: persistedWindowLayout` 防止視窗布局丟失
- `confirmCloseAllTabs: true` 防止誤關
- Find in scrollback (`Ctrl+Shift+F`) 救回過往對話

### 知道焦點（3 項）
- `unfocusedAppearance.opacity: 70` 視覺差異
- `cursorColor: #FFCC00` 黃色游標標記
- `Alt+Z` zoom 暫時放大焦點 pane

### 知道完工（2 項）
- `bellStyle: ["taskbar", "window"]` 閃爍通知
- 配 Claude Stop hook 送 BEL

### 快速切換（4 項）
- `Alt+方向鍵` pane 焦點導航
- `Alt+Shift+方向鍵` pane 大小調整
- `tabWidthMode: titleLength` tab 標題完整顯示
- Tab cwd 自動更新（PROMPT 設定）

### 複製順手（2 項）
- `wordDelimiters` 路徑/URL 雙擊全選
- `multiLinePasteWarning` 防誤執行

### 啟動可預期（3 項）
- `initialCols: 140, initialRows: 40`
- `centerOnLaunch: true`
- `MarkMode (Ctrl+Shift+M)` 鍵盤瀏覽

## 結語：為什麼這套設計可規模化

當你從「1 個 Claude session」成長到「3 windows × 4 panes × 多 sub-agent」，**心智負擔不是線性增長，是指數增長**。每多開 1 個 pane，需要管理的「我在哪個 context」「這個 pane 在跑什麼」「跑完了沒」變多。

這 18 項配置每一項都在減一點點認知負擔：
- `unfocusedAppearance` 把「我在哪？」從思考題變反射動作
- `bellStyle` 把「跑完了沒？」從輪詢變 push 通知
- `wordDelimiters` 把「複製這個路徑」從 5 秒手動拖選變 1 秒雙擊
- `persistedWindowLayout` 把「重啟後重新拉布局」從 5 分鐘變 0 秒

12 panes × 0.5 秒/pane × 100 次/天 = 每天節省 10 分鐘。一年 60 小時 = 一個工作週。

這不是過度工程，這是**為高密度工作流而生的工具配置**。預設值是給「偶爾打開 cmd 看 ipconfig」的使用者，不是給「每天 8 小時跟 12 個 Claude agent 平行作業」的你。
