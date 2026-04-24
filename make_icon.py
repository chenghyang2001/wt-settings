"""產生 wt-settings 的 multi-res ICO 檔案（16/32/48/64/128/256）。

設計：深青綠底（#16a085）+ 白色 `{ }` 字樣，代表 JSON 設定檔。
顏色刻意避開 S189 已用的 5 色（紅/棕/綠/藍/紫），選 cyan-teal 當第 6 色。
"""
import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def load_font(size_px: int) -> ImageFont.FreeTypeFont:
    """依序嘗試幾個 Windows 常駐字型，找不到就回傳 default。"""
    candidates = [
        "seguisb.ttf",      # Segoe UI Semibold
        "segoeuib.ttf",     # Segoe UI Bold
        "arialbd.ttf",      # Arial Bold
        "arial.ttf",
    ]
    for name in candidates:
        try:
            return ImageFont.truetype(name, size_px)
        except OSError:
            continue
    return ImageFont.load_default()


def render_at(size: int) -> Image.Image:
    """在指定尺寸畫出 teal 圓角方塊 + 白色 `{ }`。"""
    bg = (22, 160, 133, 255)      # #16a085 teal
    fg = (255, 255, 255, 255)     # white
    text = "{ }"

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 圓角矩形底
    radius = max(2, size // 8)
    draw.rounded_rectangle(
        [0, 0, size - 1, size - 1],
        radius=radius,
        fill=bg,
    )

    # 文字置中
    font_size = int(size * 0.55)
    font = load_font(font_size)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] - size * 0.04
    draw.text((x, y), text, fill=fg, font=font)

    return img


def make_icon(out_path: Path) -> None:
    # 用最大尺寸當 primary，其餘用 render_at 個別產生（避免 Pillow 只存 primary 的 bug）
    sizes = [16, 32, 48, 64, 128, 256]
    images = [render_at(s) for s in sizes]
    primary = images[-1]                   # 256×256
    appended = images[:-1]                 # 16..128
    primary.save(
        out_path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=appended,
    )


def main() -> None:
    try:
        out = Path(__file__).parent / "wt-settings.ico"
        make_icon(out)
        print(f"OK: {out} ({out.stat().st_size} bytes)")
    except Exception as e:  # noqa: BLE001
        print(f"錯誤：{e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
