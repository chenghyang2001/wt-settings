"""WT 快捷鍵 PDF 產生器（繁體中文）

讀 ~/workspace/wt-settings/settings.json 的 keybindings，按 8 大類分組，
輸出 A4 直式 PDF 到 ~/workspace/wt-settings/pdf/wt-keybindings-2026-04-27.pdf。
"""
import json
import sys
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle

# 8 大類顯示順序 + 色塊 hex（同 id 但不同 keys 的 MoveFocus 必須拆方向鍵 / hjkl 兩組）
CATEGORY_ORDER = [
    "Tab 切換", "Pane 焦點 — 方向鍵", "Pane 焦點 — Vim hjkl", "Pane 焦點循環",
    "Pane 大小調整", "Pane 操作", "剪貼簿", "其他",
]
CATEGORY_COLOR = {
    "Tab 切換": "#3498DB", "Pane 焦點 — 方向鍵": "#27AE60",
    "Pane 焦點 — Vim hjkl": "#27AE60", "Pane 焦點循環": "#27AE60",
    "Pane 大小調整": "#E67E22", "Pane 操作": "#9B59B6",
    "剪貼簿": "#F39C12", "其他": "#7F8C8D",
}
DIRECTION_LABEL = {
    "Terminal.MoveFocusLeft": "左", "Terminal.MoveFocusRight": "右",
    "Terminal.MoveFocusUp": "上", "Terminal.MoveFocusDown": "下",
    "Terminal.ResizePaneLeft": "縮小左邊", "Terminal.ResizePaneRight": "放大右邊",
    "Terminal.ResizePaneUp": "縮小上邊", "Terminal.ResizePaneDown": "放大下邊",
}


def format_keys(keys: str) -> str:
    """alt+shift+d → Alt+Shift+D（每段首字大寫）。"""
    return "+".join(part.capitalize() for part in keys.split("+"))


def categorize(binding: dict) -> tuple[str, str]:
    """回傳 (類別, 功能描述)。MoveFocus 同 id 在方向鍵/hjkl 兩組各出現一次，靠 keys 字串區分。"""
    keys = binding.get("keys", "")
    bid = binding.get("id", "")
    cmd = binding.get("command", {})
    if isinstance(cmd, dict) and cmd.get("action") == "moveFocus":
        return ("Pane 焦點循環", f"循環下一個 pane（{cmd.get('direction', '')}）")
    if bid == "Terminal.PrevTab":
        return ("Tab 切換", "上一個 Tab")
    if bid == "Terminal.NextTab":
        return ("Tab 切換", "下一個 Tab")
    if bid.startswith("Terminal.MoveFocus"):
        direction = DIRECTION_LABEL.get(bid, "?")
        if any(k in keys for k in ("left", "right", "up", "down")):
            return ("Pane 焦點 — 方向鍵", f"焦點移到{direction}邊 pane")
        last = keys.split("+")[-1] if "+" in keys else keys
        if last in ("h", "j", "k", "l"):
            return ("Pane 焦點 — Vim hjkl", f"焦點移到{direction}邊 pane（vim）")
        return ("Pane 焦點 — 方向鍵", f"焦點移到{direction}邊 pane")
    if bid.startswith("Terminal.ResizePane"):
        return ("Pane 大小調整", DIRECTION_LABEL.get(bid, "調整 pane 大小"))
    if bid == "Terminal.ToggleSplitOrientation":
        return ("Pane 操作", "切換 split 方向（橫/直）")
    if bid == "Terminal.DuplicatePaneAuto":
        return ("Pane 操作", "複製當前 pane")
    if bid == "Terminal.TogglePaneZoom":
        return ("Pane 操作", "Pane 全螢幕縮放")
    if bid == "Terminal.CopyToClipboard":
        return ("剪貼簿", "複製到剪貼簿")
    if bid == "Terminal.PasteFromClipboard":
        return ("剪貼簿", "從剪貼簿貼上")
    if bid == "Terminal.MarkMode":
        return ("其他", "進入 Mark Mode（鍵盤選文字）")
    return ("其他", bid or "(未知)")


def build_pdf(grouped: dict, total: int, out_path: Path) -> None:
    """用 reportlab platypus 組 PDF；STSong-Light CID 內建字型支援繁中無需檔案。"""
    pdfmetrics.registerFont(UnicodeCIDFont("STSong-Light"))
    fn = "STSong-Light"

    doc = SimpleDocTemplate(
        str(out_path), pagesize=A4,
        leftMargin=1 * inch, rightMargin=1 * inch,
        topMargin=1 * inch, bottomMargin=1 * inch,
        title="Windows Terminal 自訂快捷鍵",
    )
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "TitleZH", parent=styles["Title"], fontName=fn,
        fontSize=22, leading=28, alignment=TA_CENTER, spaceAfter=6,
    )
    subtitle_style = ParagraphStyle(
        "SubtitleZH", parent=styles["Normal"], fontName=fn,
        fontSize=12, leading=16, alignment=TA_CENTER,
        textColor=colors.HexColor("#555555"), spaceAfter=18,
    )

    story = [
        Paragraph("Windows Terminal 自訂快捷鍵 — 2026-04-27", title_style),
        Paragraph(f"PC：B00332 ｜ 共 {total} 個快捷鍵", subtitle_style),
    ]

    for category in CATEGORY_ORDER:
        rows = grouped.get(category, [])
        if not rows:
            continue
        # 類別色塊標題（單格 Table 載背景色 + 白字）
        header_tbl = Table([[category]], colWidths=[6.5 * inch])
        header_tbl.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor(CATEGORY_COLOR[category])),
            ("TEXTCOLOR", (0, 0), (-1, -1), colors.white),
            ("FONTNAME", (0, 0), (-1, -1), fn),
            ("FONTSIZE", (0, 0), (-1, -1), 14),
            ("LEFTPADDING", (0, 0), (-1, -1), 10),
            ("TOPPADDING", (0, 0), (-1, -1), 6),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ]))
        story.append(header_tbl)
        # 內容表格：兩欄（按鍵 / 功能）
        data = [["按鍵", "功能"]] + [[k, d] for k, d in rows]
        body_tbl = Table(data, colWidths=[2.2 * inch, 4.3 * inch])
        body_tbl.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (-1, -1), fn),
            ("FONTSIZE", (0, 0), (-1, -1), 11),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#ECECEC")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#222222")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#BBBBBB")),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ]))
        story.append(body_tbl)
        story.append(Spacer(1, 14))

    doc.build(story)


def main():
    try:
        base = Path.home() / "workspace" / "wt-settings"
        settings_path = base / "settings.json"
        out_dir = base / "pdf"
        out_path = out_dir / "wt-keybindings-2026-04-27.pdf"

        try:
            with settings_path.open("r", encoding="utf-8") as f:
                settings = json.load(f)
        except FileNotFoundError:
            print(f"錯誤：找不到 {settings_path}", file=sys.stderr)
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"錯誤：settings.json 解析失敗 — {e}", file=sys.stderr)
            sys.exit(1)

        keybindings = settings.get("keybindings", [])
        if not isinstance(keybindings, list):
            print("錯誤：settings.json 的 keybindings 不是 array", file=sys.stderr)
            sys.exit(1)

        grouped: dict[str, list[tuple[str, str]]] = {c: [] for c in CATEGORY_ORDER}
        total = 0
        for binding in keybindings:
            if not isinstance(binding, dict):
                continue
            category, desc = categorize(binding)
            grouped.setdefault(category, []).append((format_keys(binding.get("keys", "")), desc))
            total += 1

        out_dir.mkdir(parents=True, exist_ok=True)
        build_pdf(grouped, total, out_path)
        print(f"PDF 已產出：{out_path}")
    except Exception as e:
        print(f"錯誤：{e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
