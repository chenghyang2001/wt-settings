---
description: 從 GitHub 拉最新 wt-settings 並套用到本機 Windows Terminal
argument-hint: "[--dry-run] [--force] [--regen-lnk]"
---

# /wt-sync

從 `chenghyang2001/wt-settings` GitHub repo 同步最新 Windows Terminal 設定到本機 LocalState。
適用於：(1) 新 PC 第一次設定 (2) 已有 repo 的日常更新。

## 參數解析（從 $ARGUMENTS 讀）

- `--dry-run`：只顯示會發生什麼，不實際 cp（傳給 apply.sh）
- `--force`：忽略本機 repo 工作樹的未 commit 改動，強制 git pull
- `--regen-lnk`：apply.sh 跑完後額外執行 regen-lnk.ps1

## 工作流程

### Step 1：檢查 repo 是否存在
```bash
test -d ~/workspace/wt-settings && echo "EXISTS" || echo "MISSING"
```

- **MISSING**：詢問使用者「要從 GitHub clone 嗎？(y/N)」
  - 同意：先試 `gh repo clone chenghyang2001/wt-settings ~/workspace/wt-settings`
    若 gh 失敗，fallback `git clone https://github.com/chenghyang2001/wt-settings.git ~/workspace/wt-settings`
  - 拒絕：結束
- **EXISTS**：進 Step 2

### Step 2：檢查 git 工作樹
```bash
cd ~/workspace/wt-settings && git status --porcelain
```

- 有輸出（有未 commit 改動）+ 無 `--force`：
  - 顯示變更檔案清單
  - 詢問：「[a] 暫存改動後 pull / [b] 強制覆蓋（--force）/ [c] 取消」
- 乾淨或 `--force`：執行 `git -C ~/workspace/wt-settings pull --ff-only`
  - 若 `pull --ff-only` 失敗（divergent history）：警告並要求使用者手動處理

### Step 3：跑 apply.sh
```bash
bash ~/workspace/wt-settings/apply.sh [--dry-run]
```

apply.sh 會自動：
- 偵測 WT stable / preview 路徑
- 備份舊 settings.json（保留最近 5 份，超過自動清理）
- 驗證來源 JSON 合法
- 顯示 diff
- cp 新 settings.json → LocalState
- 驗證部署結果 JSON 合法
- 檢查 CaskaydiaCove Nerd Font 是否已安裝
- 列出潛在的孤兒 profile（依賴外部 source 如 WSL/Azure）
- 安裝 /wt-sync slash command 到 `~/.claude/commands/`（首次安裝後續本機就能直接用）

### Step 4（可選）：重建 .lnk
若使用者傳了 `--regen-lnk`：
```bash
powershell -ExecutionPolicy Bypass -File ~/workspace/wt-settings/regen-lnk.ps1
```

### Step 5：回報

把 apply.sh 的關鍵輸出整理給使用者：
- WT 版本（stable / preview）
- 是否有變更（or「已同步無變更」）
- 備份路徑
- 字體狀態
- 孤兒 profile 警告（若有）
- Repo commit hash + commit message
- 提醒：WT 自動 hot-reload，切回 WT 視窗即可看到效果

## 失敗處理

| 情境 | 處理 |
|---|---|
| WT 未安裝 | apply.sh 自己會印 `winget install Microsoft.WindowsTerminal` 提示後 exit 1 |
| gh CLI 未登入 | fallback 到 `git clone`（HTTPS 公開 repo 不需要憑證） |
| `pull --ff-only` 失敗 | 不嘗試 merge，要求使用者手動 `cd ~/workspace/wt-settings && git status` |
| apply.sh exit != 0 | 顯示其 stderr，停止後續步驟 |

## 注意事項

- WT settings.json 的 hot-reload 是即時的，不需要重啟 WT
- 第一次新 PC 設定完後額外要做：
  - 從 nerdfonts.com 下載 **CaskaydiaCove Nerd Font** 並「為所有使用者安裝」
  - 若要工作列釘選：`/wt-sync --regen-lnk`
- profile GUID 跨機器可能不一致 — repo 裡的 WSL/Azure profile 在新 PC 上若 source 還沒裝，會以灰色顯示在 dropdown，apply.sh 會列出來提醒
