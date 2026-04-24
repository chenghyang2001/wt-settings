#!/bin/bash
# 把本 repo 的 settings.json 部署到 Windows Terminal LocalState。
# 用法：bash apply.sh [--dry-run] [--force] [--no-cmd]
#   --dry-run  只顯示會做什麼，不實際 cp
#   --force    略過工作樹乾淨檢查（外部呼叫者用，本腳本不檢查）
#   --no-cmd   不安裝 /wt-sync slash command 到 ~/.claude/commands/

set -euo pipefail

# ---- 參數 ----
DRY_RUN=0
INSTALL_CMD=1
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --force)   ;;  # 由外部呼叫者解讀，本腳本不用
        --no-cmd)  INSTALL_CMD=0 ;;
        -h|--help)
            grep -E '^#( |!)' "$0" | sed 's/^# \?//' | head -8
            exit 0
            ;;
        *) echo "未知參數：$arg" >&2; exit 2 ;;
    esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/settings.json"

# ---- 1. 偵測 WT 版本路徑 ----
LAD="${LOCALAPPDATA:-$HOME/AppData/Local}"
STABLE="$LAD/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
PREVIEW="$LAD/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState"

if [ -d "$STABLE" ]; then
    WT_DIR="$STABLE"; WT_VER="stable"
elif [ -d "$PREVIEW" ]; then
    WT_DIR="$PREVIEW"; WT_VER="preview"
else
    echo "錯誤：找不到 Windows Terminal LocalState 目錄" >&2
    echo "  請先安裝：winget install Microsoft.WindowsTerminal" >&2
    exit 1
fi
DST="$WT_DIR/settings.json"
echo "WT 版本：$WT_VER"
echo "目標：$DST"

# ---- 2. 驗證來源 JSON ----
if ! python -m json.tool < "$SRC" > /dev/null 2>&1; then
    echo "錯誤：來源 $SRC 不是合法 JSON" >&2
    exit 1
fi

# ---- 3. Diff ----
NEED_APPLY=1
if [ -f "$DST" ]; then
    if diff -q "$SRC" "$DST" > /dev/null 2>&1; then
        echo "無變更（已同步）"
        NEED_APPLY=0
    else
        echo ""
        echo "變更（dst → src）："
        diff -u "$DST" "$SRC" 2>/dev/null | head -40 || true
    fi
else
    echo "首次部署（LocalState settings.json 不存在）"
fi

# ---- 4. Dry-run 早退 ----
if [ "$DRY_RUN" = "1" ]; then
    echo ""
    echo "=== DRY RUN — 沒有任何檔案被修改 ==="
    exit 0
fi

# ---- 5. 套用 ----
if [ "$NEED_APPLY" = "1" ]; then
    if [ -f "$DST" ]; then
        BAK="$DST.bak-$(date +%Y%m%d-%H%M%S)"
        cp "$DST" "$BAK"
        echo "備份：$BAK"
    fi

    cp "$SRC" "$DST"
    echo "已套用：$SRC → $DST"

    # 清理舊備份（保留最近 5 份）
    find "$WT_DIR" -maxdepth 1 -name 'settings.json.bak-*' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn \
        | tail -n +6 \
        | cut -d' ' -f2- \
        | while read -r f; do
            rm -f "$f"
            echo "清理舊備份：$(basename "$f")"
        done
fi

# ---- 6. 驗證部署結果 ----
if ! python -m json.tool < "$DST" > /dev/null 2>&1; then
    echo "錯誤：部署後的 $DST 是壞 JSON！請從 $BAK 還原" >&2
    exit 1
fi

# ---- 7. 字體檢查（HKLM 為所有使用者 + HKCU 為當前使用者）----
echo ""
if {
    reg query "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" 2>/dev/null
    reg query "HKCU\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" 2>/dev/null
} | grep -qi caskaydia; then
    echo "字體：CaskaydiaCove Nerd Font 已安裝"
else
    echo "警告：CaskaydiaCove Nerd Font 未安裝"
    echo "  下載：https://www.nerdfonts.com/font-downloads"
    echo "  挑：CascadiaCode Nerd Font → 為所有使用者安裝"
    echo "  WT 在裝好前會用 fallback 字體"
fi

# ---- 8. 孤兒 profile 偵測（精準版：實際查 WSL distro 與 Azure CLI）----
echo ""
WSL_DISTROS=""
if command -v wsl >/dev/null 2>&1; then
    # wsl -l -q 在 Windows 是 UTF-16LE 輸出，需要 iconv 轉，否則 Git Bash 會看到亂碼
    WSL_DISTROS=$(wsl -l -q 2>/dev/null \
        | iconv -f UTF-16LE -t UTF-8 2>/dev/null \
        | tr -d '\r' \
        | grep -v '^$' || true)
fi

ORPHANS=$(
    DST_PATH="$(cygpath -w "$DST" 2>/dev/null || echo "$DST")" \
    WSL_INSTALLED="$WSL_DISTROS" \
    python <<'PYEOF'
import json, os
with open(os.environ["DST_PATH"], encoding="utf-8") as f:
    d = json.load(f)
wsl_installed = set(os.environ.get("WSL_INSTALLED", "").splitlines())
for p in d.get("profiles", {}).get("list", []):
    src = p.get("source", "")
    name = p.get("name", "(無名)")
    # WSL profiles：name 應對應 wsl -l -q 的某個 distro
    if src.startswith("Windows.Terminal.Wsl") or src.startswith("CanonicalGroupLimited."):
        if wsl_installed and name not in wsl_installed:
            print(f"  - {name}  source={src}  (WSL distro '{name}' 未安裝)")
    # Azure：無法可靠偵測，只在無 az CLI 時提示
    elif src.startswith("Windows.Terminal.Azure"):
        if not any(os.path.exists(os.path.join(p, "az.cmd"))
                   for p in os.environ.get("PATH", "").split(os.pathsep)):
            print(f"  - {name}  source={src}  (Azure CLI 未安裝，profile 可能無作用)")
PYEOF
)
if [ -n "$ORPHANS" ]; then
    echo "孤兒 profile（依賴的外部 source 未安裝）："
    echo "$ORPHANS"
    echo "  WT dropdown 中這些 profile 會無作用或顯示錯誤。"
    echo "  裝完對應 source 後 re-run apply.sh 可消除此訊息。"
else
    echo "Profile 檢查：所有依賴外部 source 的 profile 均可用"
fi

# ---- 9. 安裝 slash command ----
if [ "$INSTALL_CMD" = "1" ]; then
    CMD_SRC="$REPO_DIR/.claude/commands/wt-sync.md"
    CMD_DST="$HOME/.claude/commands/wt-sync.md"
    if [ -f "$CMD_SRC" ]; then
        mkdir -p "$(dirname "$CMD_DST")"
        cp "$CMD_SRC" "$CMD_DST"
        echo ""
        echo "Slash command 已安裝：/wt-sync → $CMD_DST"
    fi
fi

# ---- 10. 最終回報（用 cd subshell 避開 git -C 對 MSYS 路徑的不認識）----
COMMIT=$(cd "$REPO_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
COMMIT_MSG=$(cd "$REPO_DIR" && git log -1 --pretty=%s 2>/dev/null || echo "unknown")
echo ""
echo "=== 完成 ==="
echo "Repo @ $COMMIT：$COMMIT_MSG"
echo "WT 會自動 hot-reload，無需重啟"
