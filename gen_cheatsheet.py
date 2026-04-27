"""Regenerate doc/keybindings-cheatsheet.{html,pdf} from repo settings.json.

讀 repo 內的 settings.json（不是 LocalState — 跨 PC 一致），產出 1 頁 A4 cheatsheet。
HTML 寫到 doc/keybindings-cheatsheet.html，PDF 用 Edge headless 渲染。
"""
import json
import os
import subprocess
import sys
import html as htmlmod
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent
SRC = REPO / "settings.json"
OUT_DIR = REPO / "doc"
HTML_PATH = OUT_DIR / "keybindings-cheatsheet.html"
PDF_PATH = OUT_DIR / "keybindings-cheatsheet.pdf"

ACTION_MAP = {
    "Terminal.CopyToClipboard":       ("複製到剪貼簿",                    "clipboard"),
    "Terminal.PasteFromClipboard":    ("從剪貼簿貼上",                    "clipboard"),
    "Terminal.NextTab":               ("下一個 tab",                      "tab"),
    "Terminal.PrevTab":               ("上一個 tab",                      "tab"),
    "Terminal.DuplicatePaneAuto":     ("自動拆分當前 pane",               "split"),
    "User.SplitPaneDupAlt":           ("自動拆分當前 pane",               "split"),
    "Terminal.ToggleSplitOrientation":("切換 pane 拆分方向",              "split"),
    "Terminal.MoveFocusLeft":         ("焦點移到左邊 pane",               "focus"),
    "Terminal.MoveFocusRight":        ("焦點移到右邊 pane",               "focus"),
    "Terminal.MoveFocusUp":           ("焦點移到上面 pane",               "focus"),
    "Terminal.MoveFocusDown":         ("焦點移到下面 pane",               "focus"),
    "Terminal.MoveFocusNextInOrder":  ("焦點切換到下一個 pane",           "focus"),
    "Terminal.ResizePaneLeft":        ("pane 朝左擴張",                    "resize"),
    "Terminal.ResizePaneRight":       ("pane 朝右擴張",                    "resize"),
    "Terminal.ResizePaneUp":          ("pane 朝上擴張",                    "resize"),
    "Terminal.ResizePaneDown":        ("pane 朝下擴張",                    "resize"),
    "Terminal.TogglePaneZoom":        ("暫時放大當前 pane",               "zoom"),
    "Terminal.ClosePane":             ("關閉當前 pane",                   "close"),
    "Terminal.MarkMode":              ("鍵盤標記/捲動 scrollback",         "scroll"),
}

CATEGORIES = [
    ("clipboard", "📋 複製貼上"),
    ("tab",       "📑 Tab 操作"),
    ("split",     "🔲 Pane 拆分"),
    ("focus",     "🎯 Pane 焦點"),
    ("resize",    "↔️ Pane 大小"),
    ("zoom",      "🔍 Pane 縮放"),
    ("close",     "❌ Pane 關閉"),
    ("scroll",    "📜 滾動"),
]


def fmt_keys(k: str) -> str:
    return "+".join(p[0].upper() + p[1:] for p in k.split("+"))


def get_label(b: dict) -> tuple[str, str]:
    if "id" in b:
        return ACTION_MAP.get(b["id"], (b["id"], "other"))
    cmd = b.get("command", {})
    if isinstance(cmd, dict) and cmd.get("action") == "moveFocus" and cmd.get("direction") == "nextInOrder":
        return ACTION_MAP["Terminal.MoveFocusNextInOrder"]
    return (str(cmd), "other")


def find_edge() -> Path | None:
    for p in [
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    ]:
        if Path(p).exists():
            return Path(p)
    return None


def main() -> int:
    try:
        data = json.loads(SRC.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"錯誤：找不到 {SRC}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as e:
        print(f"錯誤：{SRC} 不是合法 JSON：{e}", file=sys.stderr)
        return 1

    kbs = data.get("keybindings", [])
    if not kbs:
        print(f"錯誤：{SRC} 沒有 keybindings 欄位", file=sys.stderr)
        return 1

    by_cat: dict[str, list[tuple[str, str]]] = {c[0]: [] for c in CATEGORIES}
    by_cat["other"] = []
    for b in kbs:
        label, cat = get_label(b)
        by_cat.setdefault(cat, []).append((fmt_keys(b["keys"]), label))

    sections = []
    for cat_id, cat_name in CATEGORIES:
        rows = by_cat.get(cat_id, [])
        if not rows:
            continue
        body = "".join(
            f'<tr><td class="k">{htmlmod.escape(k)}</td><td>{htmlmod.escape(d)}</td></tr>'
            for k, d in rows
        )
        sections.append(f"<section><h2>{cat_name}</h2><table>{body}</table></section>")

    ts = datetime.now().strftime("%Y-%m-%d %H:%M")
    html_content = f"""<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>WT Cheatsheet</title>
<style>
  @page {{ size: A4; margin: 10mm 10mm; }}
  * {{ -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
  html, body {{ margin: 0; padding: 0; }}
  body {{ font-family: "Segoe UI", "Microsoft JhengHei", sans-serif; color: #222; line-height: 1.3; font-size: 10pt; }}
  h1 {{ font-size: 14pt; color: #2d6a4f; border-bottom: 2px solid #2d6a4f; padding-bottom: 3px; margin: 0 0 4px 0; }}
  .meta {{ font-size: 8pt; color: #666; margin-bottom: 8px; }}
  .grid {{ column-count: 2; column-gap: 10mm; }}
  section {{ break-inside: avoid; margin-bottom: 6px; }}
  h2 {{ font-size: 9.5pt; color: white; background: #2d6a4f; padding: 3px 8px; margin: 0; border-radius: 3px 3px 0 0; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 8.5pt; }}
  td {{ padding: 2px 8px; border-bottom: 1px solid #e5e5e5; }}
  td.k {{ font-family: "Cascadia Code", "Consolas", monospace; font-weight: 600; color: #2d6a4f; white-space: nowrap; width: 40%; }}
  .footer {{ margin-top: 6px; font-size: 7pt; color: #888; text-align: center; column-span: all; }}
</style>
</head>
<body>
<h1>Windows Terminal 快捷鍵 Cheatsheet</h1>
<div class="meta">由 settings.json 即時生成 · {ts} · {len(kbs)} 個自訂快捷鍵</div>
<div class="grid">
{''.join(sections)}
</div>
<div class="footer">wt-settings repo · ~/workspace/wt-settings</div>
</body>
</html>"""

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    HTML_PATH.write_text(html_content, encoding="utf-8")
    print(f"HTML: {HTML_PATH} ({HTML_PATH.stat().st_size}B)")

    edge = find_edge()
    if not edge:
        print("錯誤：找不到 msedge.exe（需要 Microsoft Edge 來產 PDF）", file=sys.stderr)
        return 1

    cmd = [
        str(edge),
        "--headless=new",
        "--disable-gpu",
        f"--print-to-pdf={PDF_PATH}",
        "--no-pdf-header-footer",
        HTML_PATH.as_uri(),
    ]
    try:
        subprocess.run(cmd, capture_output=True, text=True, timeout=60, check=False)
    except subprocess.TimeoutExpired:
        print("錯誤：Edge headless 渲染超時 60 秒", file=sys.stderr)
        return 1

    if not PDF_PATH.exists():
        print(f"錯誤：PDF 未生成：{PDF_PATH}", file=sys.stderr)
        return 1

    print(f"PDF:  {PDF_PATH} ({PDF_PATH.stat().st_size}B)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
