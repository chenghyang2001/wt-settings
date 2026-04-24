# Windows Terminal 快捷鍵 Cheatsheet

> 本 repo `wt-settings` 自訂的全部快捷鍵 + 常用 WT 預設。
> 適合列印貼螢幕邊。
> 來源：`settings.json` 的 `keybindings` 陣列 + 預設 WT 行為。

---

## 🪟 Pane 操作（自訂 11 個）

| 快捷鍵 | 動作 | 用途 |
|---|---|---|
| `Alt+Shift+D` | DuplicatePaneAuto | 自動拆分當前 pane（沿上次方向） |
| `Alt+R` | ToggleSplitOrientation | 切換 pane 拆分方向（橫 ↔ 直） |
| `Alt+←` | MoveFocusLeft | 焦點移到左邊的 pane |
| `Alt+→` | MoveFocusRight | 焦點移到右邊的 pane |
| `Alt+↑` | MoveFocusUp | 焦點移到上面的 pane |
| `Alt+↓` | MoveFocusDown | 焦點移到下面的 pane |
| `Alt+Shift+←` | ResizePaneLeft | 當前 pane 朝左擴張 |
| `Alt+Shift+→` | ResizePaneRight | 當前 pane 朝右擴張 |
| `Alt+Shift+↑` | ResizePaneUp | 當前 pane 朝上擴張 |
| `Alt+Shift+↓` | ResizePaneDown | 當前 pane 朝下擴張 |
| `Alt+Z` | TogglePaneZoom | 當前 pane 暫時全螢幕 / 復原 |

---

## 📑 Tab 操作（自訂 2 個）

| 快捷鍵 | 動作 | 用途 |
|---|---|---|
| `Alt+N` | NextTab | 下一個 tab |
| `Alt+P` | PrevTab | 上一個 tab |

---

## 📋 複製貼上（自訂 2 個）

| 快捷鍵 | 動作 | 用途 |
|---|---|---|
| `Ctrl+C` | CopyToClipboard | 有選取就複製，無選取走 SIGINT |
| `Ctrl+V` | PasteFromClipboard | 貼上（多行時跳警告） |

**雙擊滑鼠技巧**：路徑 / URL / file.py 整段選起 — 已調整 `wordDelimiters` 移除 `/` `\` `.` `:`

---

## 🔍 Scrollback 操作（自訂 1 + 預設 1）

| 快捷鍵 | 動作 | 用途 |
|---|---|---|
| `Ctrl+Shift+M` | MarkMode（自訂） | 鍵盤模式瀏覽 scrollback，方向鍵移動，Shift+方向鍵選取，Enter 複製，Esc 退出 |
| `Ctrl+Shift+F` | Find（WT 預設） | 開搜尋視窗，F3 / Shift+F3 跳下/上一個 |
| `Ctrl+Shift+↑` `↓` | ScrollUp / Down（WT 預設） | 鍵盤滾動 scrollback 一行 |
| `Ctrl+Shift+PgUp` `PgDn` | 翻頁（WT 預設） | 鍵盤滾動一頁 |
| `Ctrl+Shift+Home` `End` | 跳頂尾（WT 預設） | 跳到 scrollback 最頂 / 最底 |

---

## ⚙️ Tab / Window 管理（WT 預設）

| 快捷鍵 | 動作 |
|---|---|
| `Ctrl+Shift+T` | 新 tab（用 default profile） |
| `Ctrl+Shift+數字` | 開特定 profile 的新 tab（1=第一個 profile，2=第二個…） |
| `Ctrl+Shift+W` | 關閉當前 pane（多 panes 時跳警告 — 已開 `confirmCloseAllTabs`） |
| `Ctrl+Tab` | 下一個 tab（同 Alt+N） |
| `Ctrl+Shift+Tab` | 上一個 tab（同 Alt+P） |
| `Ctrl+Shift+P` | 開啟 Command Palette（找指令） |
| `Ctrl+Shift+Space` | 開新 tab dropdown menu |
| `Alt+F4` | 關整個視窗（多 tabs 時跳警告） |

---

## 🔎 字體與外觀（WT 預設）

| 快捷鍵 | 動作 |
|---|---|
| `Ctrl++` `Ctrl+-` | 放大 / 縮小字體 |
| `Ctrl+0` | 字體還原預設 |
| `Ctrl+Scroll` | 滾輪縮放字體 |
| `Alt+Enter` / `F11` | 全螢幕切換 |

---

## 💡 Claude Code 多 agent 觀測台速查

| 場景 | 操作 |
|---|---|
| 開新 pane 監控 log | `Alt+Shift+D` 拆分 → 切到新 pane → `tail -f log.txt` |
| 主 Claude pane 太擠 | `Alt+Z` 暫時全螢幕 → 看完再 `Alt+Z` 回去 |
| 快速切到 git status pane | `Alt+→` |
| 縮小 monitoring pane 給主 pane 多空間 | 在 monitoring pane 按 `Alt+Shift+←` |
| 找 Claude 5 分鐘前說的某個檔名 | `Ctrl+Shift+F` 搜尋字串 |
| Claude 跑完通知 | 自動：bell → 工作列圖示閃爍（Stop hook 已設） |
| 不小心 Ctrl+Shift+W | 跳警告，按 Cancel 取消 |

---

## 🔗 相關檔案

- 原始 keybindings 定義：[`settings.json`](../settings.json) `keybindings` 陣列（第 9-78 行）
- 18 項配置完整解說：[`wt-claude-code-observation-deck.md`](wt-claude-code-observation-deck.md)
- 設計脈絡：[`../CLAUDE.md`](../CLAUDE.md) 「Claude Code CLI 工作流配置」段落
- 同步腳本：[`../apply.sh`](../apply.sh)
- Slash command：`/wt-sync`

---

*列印建議：A4 縱向、字體 10-11pt、無頁邊空白可塞滿一頁。*
