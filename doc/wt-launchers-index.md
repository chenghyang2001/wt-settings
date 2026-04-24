# WT Launchers Master Index

彼得的 Windows Terminal 單 tab / combo 啟動器總表。所有 launcher 都遵循同一個 pattern：

```bat
wt new-tab --title "<title>" -d "<cwd>" cmd /k claude --permission-mode bypassPermissions --continue -n "<session>"
```

`-n <session>` 搭配 `--continue` → 具名 session 可跨次續接（關 tab 再開仍是同一個對話歷史）。

## 1. 單 tab 啟動器（6 個）

每組都是「.bat + .ico（multi-res 6 解析度） + Desktop .lnk」三件套。顏色編碼讓工作列看一眼知道在哪個 context。

| # | 色 | Title / Session | 工作目錄 | 角色 | .bat | ICO | Desktop .lnk |
|---|----|---|---|---|---|---|---|
| 1 | 🟥 | `youtube-demo` | `~/Downloads/AutoRead-GoogleBook` | YouTube 摘要 / 演練 | `~/ubuntu/claude-wt-1-tab-youtube-demo.bat` | `~/ubuntu/claude-wt-1-tab-youtube-demo.ico` | `claude-wt-1-tab-youtube-demo.lnk` |
| 2 | 🟫 | `kindle-demo` | `~/Downloads/AutoRead-GoogleBook` | Kindle 書摘 / EPUB | `~/ubuntu/claude-wt-1-tab-kindle-demo.bat` | `~/ubuntu/claude-wt-1-tab-kindle-demo.ico` | `claude-wt-1-tab-kindle-demo.lnk` |
| 3 | 🟩 | `AutoRead` | `~/Downloads/AutoRead-GoogleBook` | Session 主工作（內容加工 / 發布 / sessions_index） | `~/ubuntu/claude-wt-1-tab-AutoRead.bat` | `~/ubuntu/claude-wt-1-tab-AutoRead.ico` | `claude-wt-1-tab-AutoRead.lnk` |
| 4 | 🟦 | `NUC` | `~/workspace/aihcr-daily` | AIHCR 開發源頭（部署主層在 NUC 192.168.51.33） | `~/ubuntu/claude-wt-1-tab-NUC.bat` | `~/ubuntu/claude-wt-1-tab-NUC.ico` | `claude-wt-1-tab-NUC.lnk` |
| 5 | 🟪 | `VPS` | `~/workspace/n8n2vps-hub` | n8n2vps-hub 開發源頭（部署層在 VPS 187.127.109.145） | `~/ubuntu/claude-wt-1-tab-VPS.bat` | `~/ubuntu/claude-wt-1-tab-VPS.ico` | `claude-wt-1-tab-VPS.lnk` |
| 6 | 🟢 | `wt-settings` | `~/workspace/wt-settings` | WT settings.json 備份 repo（本 repo 自身） | `~/workspace/wt-settings/claude-wt-1-tab-wt-settings.bat` | `~/workspace/wt-settings/wt-settings.ico` | `wt-settings.lnk` |

> ⚠️ **前 5 個在 `~/ubuntu/`，第 6 個故意放在本 repo 根目錄** — 因為本 repo 就是 wt-settings 自己，launcher 跟 repo 綁在一起才不會漏 commit。

### Context 邊界（CLAUDE.md 硬規定）

進 tab 時 CLAUDE.md 會重新載入，每個 context 有自己的職責邊界：

- **YT / KD / AR**：內容加工、摘要、發布、Session HTML — 不碰 AIHCR / n8n2vps 程式碼
- **NUC**：AIHCR `~/workspace/aihcr-daily/` 開發源頭 — push 到 GitHub → NUC pull
- **VPS**：n8n2vps-hub 開發源頭 — push 到 GitHub → VPS pull + systemctl restart
- **wt-settings**：本 repo 自身；settings.json 同步

## 2. Combo 啟動器（多 tab 同時開）

| 檔案 | 開幾 tab | 附加功能 |
|------|---|---|
| `~/ubuntu/claude-wt-5-tabs-YT-Kindle-AutoRead-NUC-VPS.bat` | 5（純 5 個 Claude tab） | — |
| `~/ubuntu/claude-wt-5-tabs-monitor.bat` | 5 + SSH split-pane | NUC / VPS tab 各自水平分割（上：claude / 下：`ssh` 到該主機），開盤監控用 |
| `~/ubuntu/claude-wt-6-tabs-all.bat` | 6（5 + wt-settings） | 包含本 repo 第 6 個 tab |

### combo 語法重點

- **`wt -w -1 new-tab ...`**：`-w -1` 強制開**新視窗**，避免吸附到既有 WT window（`windowingBehavior` 預設 sticky 陷阱）
- **`; new-tab ...`**：分號串連下一個 tab（注意分號前後要空格，否則會被 cmd 當成自己的 separator）
- **`; split-pane -H ...`**：水平切當前 tab 成上下 pane（`-H` = horizontal divider）
- **`; focus-tab -t 0`**：最後回到第 0 個 tab（看起來整潔）

## 3. 釘到工作列 SOP（Windows 1903+ 限制）

Windows 1903 之後從 shell verb 拔掉「釘選到工作列」for `.bat`，所以不能直接釘 bat。解法（S189 定案）：

1. **.lnk 的 TargetPath 必須是 `cmd.exe`**（不是 bat 本身）
2. **Arguments = `/c "<bat 絕對路徑>"`**
3. **WindowStyle = 7**（最小化啟動，不閃黑 console）
4. 在桌面上右鍵該 .lnk → **釘選到工作列** / **釘選到開始畫面**

```powershell
# 重建任意 .lnk 的範本
$sh = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut("$env:USERPROFILE\Desktop\<name>.lnk")
$lnk.TargetPath       = "$env:SystemRoot\System32\cmd.exe"
$lnk.Arguments        = "/c `"<bat 絕對路徑>`""
$lnk.WorkingDirectory = "<cwd>"
$lnk.IconLocation     = "<ico 絕對路徑>,0"
$lnk.WindowStyle      = 7
$lnk.Description      = "Claude Code @ <session>"
$lnk.Save()
```

## 4. 新增第 N 個 tab 的 checklist

加 tab（例如未來要再開一個 `club-3p` 或 `rd2-bot`）時：

1. **建 .bat**（1 行 pattern，上面格式照抄）
2. **建 .ico**（選一個還沒用過的顏色 → Pillow 產 multi-res 6 解析度；可以直接 clone `~/workspace/wt-settings/make_icon.py` 改色和字樣）
3. **建 Desktop .lnk**（cmd.exe target + WindowStyle=7，按上面 PowerShell 範本）
4. **更新本文件的第 1 節表格**（加一列）
5. **（可選）如果要加進 combo**：改 `claude-wt-*-tabs*.bat`，加一段 `; new-tab --title ... -d ... cmd /k claude ...`
6. **commit + push**（若檔案在被 git 管的 repo 裡）

## 5. 已用顏色清單（避免撞色）

| 色碼 | 使用方 | 備註 |
|------|--------|------|
| 🟥 紅 | youtube-demo | YouTube 品牌紅 |
| 🟫 棕 | kindle-demo | Amazon Kindle 棕 |
| 🟩 綠 | AutoRead | 閱讀綠 |
| 🟦 深藍 | NUC | 家用主機藍 |
| 🟪 紫 | VPS | 遠端伺服器紫 |
| 🟢 teal `#16a085` | wt-settings | JSON 設定青綠（第 6 個才出現） |

剩餘可用色：🟧 橘 / 🟡 黃 / 🟥→桃紅 / 🔶 amber / ⚫ 純黑（低調款）。

## 6. Hot-reload 與 settings.json 互動

`settings.json` 改動 → WT 自動 reload（不用重啟）；但已開著的 tab **不會**追溯套用新 profile 設定，要關 tab 再開才生效。

如果改了 keybindings，記得：
1. 關所有既有 tab（或整個 WT 視窗）
2. 雙擊 .lnk 重啟 → 新 keybindings 生效

## 參考

- [WT command-line arguments](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments)
- [Claude Code CLI — `-n` 具名 session](https://docs.anthropic.com/en/docs/claude-code) （`--continue` + `-n` 是跨次續接的 key combo）
- 本 repo `make_icon.py` — Pillow 多解析度 ICO 產生器（避開 `images[0].save(primary=16×16)` 的 downscale bug）
