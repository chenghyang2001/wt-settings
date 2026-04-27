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

## 7. CLI Aliases（`bin/`）

跨 PC 共用的命令列 alias 集中在 `bin/`，每個 PC 部署一次到 `~/bin/`（已在 PATH 上）後就能在 cmd / PowerShell / Git Bash 通用。

| Alias | 對應指令 | 用途 |
|-------|---------|------|
| `by` | `claude --continue --permission-mode bypassPermissions %*` | 一鍵接續上次對話且跳過權限提示，最常用於日常 hacking |

### 部署到新 PC（一鍵）

clone repo 後，雙擊 `setup.bat` 或 cmd 跑：

```cmd
cd %USERPROFILE%\workspace\wt-settings
setup.bat
```

`setup.bat`（102 行）做 6 件事：

1. 解析 `%~dp0` 取得 repo 根目錄（不寫死路徑）
2. 確保 `bin\` 子目錄存在（缺則 hard fail，避免靜默部署空檔）
3. `mkdir %USERPROFILE%\bin` 若不存在
4. `copy /Y bin\*.bat → %USERPROFILE%\bin\`（冪等）
5. **冪等補 user PATH**：用 PowerShell `[Environment]::SetEnvironmentVariable(...,'User')`（避開 `setx` 的 1024 字元截斷 bug），比對前先正規化（`TrimEnd('\').ToLower()`）防止尾斜線變體與大小寫變體誤判
6. 警告 `claude` CLI 是否在 PATH（不致命）
7. 開新 cmd 視窗跑 `where by` 驗證 alias 真的可解析

技術防呆（reviewer-approved 後上線）：
- PowerShell 包 `$ErrorActionPreference='Stop' + try/catch + exit 1`：GPO 鎖、HKCU\Environment ACL 異常時不會靜默假成功
- `set "TARGET_PS=%TARGET:'=''%"`：對 PowerShell 單引號字串做 escape，防範帳號名含 `'` 的 injection vector
- `echo ... ^(...^)`：跳脫括號，避免 IF block 內訊息被 cmd parser 誤截斷
- `start "" cmd /k "where by ... pause"`：開新 cmd（讀新 PATH）跑 `where`（不啟動真實 claude session）讓使用者眼見為憑

### 手動部署（不跑腳本）

```bash
mkdir -p "$HOME/bin"
cp ~/workspace/wt-settings/bin/*.bat "$HOME/bin/"
# 若 ~/bin 不在 PATH 上，開 PowerShell：
#   $bin = "$env:USERPROFILE\bin"
#   $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
#   if (";$userPath;" -notlike "*;$bin;*") {
#       [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User")
#   }
```

> 💡 設計選擇：`setup.bat` 放 repo root（meta tool）而非 `bin/`（payload）— 跟 `Makefile` 不放 `src/` 一樣的分層慣例。沒整合進 `apply.sh` 是刻意：(1) 避免 `.sh` 改動觸發 writer-qa-reviewer 鐵律；(2) `apply.sh` 跑在 Git Bash 內，要呼叫 PowerShell SetEnvironmentVariable 還是得走 subshell，等於雙重複雜度。

### 為什麼放 repo 而不只放 `~/bin/`

| 比較 | 只放 `~/bin/` | 放 repo `bin/` |
|------|--------------|---------------|
| 跨 PC 同步 | 手動 cp 三次 | `git pull` 自動 |
| 版本歷史 | 無 | git log 完整紀錄 |
| 修改溯源 | 不知道是誰改的 | commit message 留證 |
| 衝突風險 | 各機器各自分歧 | merge 逼你面對 |

### 新增 alias 的 SOP

1. 在 repo `bin/` 新建 `<name>.bat`（純 ASCII + CRLF + `@echo off` 開頭）
2. 因為 `.bat` 在鐵律清單，要走 **code-writer → code-qa**（看 `~/.claude/instructions/writer-qa-iron-rule.md`）
3. 更新本文件第 7 節的 alias 表格
4. 各 PC 跑 `cp ~/workspace/wt-settings/bin/*.bat "$HOME/bin/"` 同步

## 參考

- [WT command-line arguments](https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments)
- [Claude Code CLI — `-n` 具名 session](https://docs.anthropic.com/en/docs/claude-code) （`--continue` + `-n` 是跨次續接的 key combo）
- 本 repo `make_icon.py` — Pillow 多解析度 ICO 產生器（避開 `images[0].save(primary=16×16)` 的 downscale bug）
