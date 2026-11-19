"""Build standalone IGA v15 Zodiac Open-Book Spread & Ribbons Asset Brief Pack."""
from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPTURE_DIR = ROOT / ".godot/test-results/captures_1600x900/captures"
STAGING_DIR = ROOT / ".godot/v15_staging/pack_root"
ARCHIVE_ZIP = ROOT / "archive/IGA_Asset_Pack_Brief_v15_Zodiac_Book_Spread.zip"

COMMON_NEG = (
    "text, letters, typography, Chinese characters, English words, numbers, printed card portraits inside niche, "
    "tilted perspective view, dark shadows clipping canvas, ribbons baked into book spread, hands holding book, watermark"
)

MANIFEST_ITEMS = [
    {
        "id": "ui_zodiac_book_spread",
        "group": "Zodiac_Book_Spread",
        "target_path": "assets/ui_core/v14_ui/zodiac/ui_zodiac_book_spread.png",
        "width": 1580,
        "height": 936,
        "requires_alpha": True,
        "min_transparent_ratio": 0.02,
        "replaces_ui": "ZodiacAlbumPanel 星座典籍对开详情底板 BookSpread（替换程序绘制 _ZodiacBookCanvas）",
        "pixel_layout": "全书本 1580×936，正中书脊 x=790；左页凹槽卡位 Rect2(188, 114, 434, 651) 留空或仅作凹陷阴影盒，绝不绘人物牌；右页铜棕 L 形分隔线 (x=864, y=82)",
        "prompt_cn": (
            "严格对照参考图 06_星座典籍双页详情_左卡片右介绍.jpg 与截图 20_zodiac_book_detail.png 的复古精装对开手帐典籍整图（1580×936 RGBA）："
            "深棕皮革硬壳封皮（外缘微圆角带外阴影与透明边距）、左右多层阶梯式奶白纸页边、翻开的双页温润米白羊皮纸（#FAF6EC）、正中柔和书脊折痕阴影；"
            "左页（x: 38..790）带有靠左极细菱形侧边装订装饰轨、外圈墨线金饰卷草四角花纹边框、以及正中凹陷立体阴影卡槽框（精准对应 x: 188..622, y: 114..765 用于嵌入 422×633 星座塔罗牌，卡槽上下各留双横线夹空处放文字）；"
            "右页（x: 790..1542）顶部偏左绘铜棕色 L 型双轴横竖分割装饰条（竖线 x≈864, y: 52..396，横线 x: 842..1460, y≈82）、右上角淡淡淡金色八芒星水印、右下角铜棕 L 形角标，其余纸面保持干净空白以便程序排版文字与丝带。严禁任何文字、数字、丝带和卡片插画。"
        ),
        "prompt_en": (
            "Open antique leather-bound hardcover lore book double-page spread matching curated reference 06_星座典籍双页详情_左卡片右介绍.jpg, "
            "straight flat top-down orthographic view (1580x936 RGBA with subtle outer shadow on transparent padding), dark espresso-walnut leather "
            "cover with layered stacked ivory paper edges on left and right, smooth center spine crease shadow (x=790) dividing left and right cream "
            "paper pages (#FAF6EC). Left page features subtle far-left vertical diamond margin rail, ornate vintage sepia-ink and gold botanical scroll "
            "corner filigree dotted border, horizontal top/bottom divider rules, and a clean recessed shadow-box rectangular card niche in the middle "
            "(matching x:188..622, y:114..765, completely empty shadow-box niche with NO card artwork inside). Right page features signature warm bronze "
            "L-axis header bar on upper-left (vertical line x=864, horizontal rule y=82), faint pastel gold 8-point compass star watermark in upper-right "
            "corner, matching bronze L-corner bracket at bottom-right, and spotless wide blank cream paper for UI text. Strictly ZERO text, ZERO numbers, ZERO ribbons, ZERO characters"
        ),
        "negative_prompt": COMMON_NEG,
    },
    {
        "id": "ui_zodiac_ribbon_sage",
        "group": "Zodiac_Book_Spread",
        "target_path": "assets/ui_core/v14_ui/zodiac/ui_zodiac_ribbon_sage.png",
        "width": 256,
        "height": 56,
        "requires_alpha": True,
        "min_transparent_ratio": 0.14,
        "replaces_ui": "ZodiacAlbumPanel 右页小节标题浅豆绿丝带底图（能力说明 / 制约与代价 / 相互关系）",
        "pixel_layout": "256×56 透明底横条丝带；左侧 0..160px 保持平整颜色承托中文小标题，右侧 160..248px 绘制手绘奶白卷草涡纹",
        "prompt_cn": (
            "复古手绘淡鼠尾草/浅豆绿手帐小节丝带标签底图（256×56 RGBA）：对齐参考图 06 里「FIRST / SECOND」同款微歪手绘剪纸丝带感——柔和灰调鼠尾草绿（#DFE4C2），"
            "左平右带微微小燕尾/手剪微斜边，丝带右半段绘有柔和优雅的手绘奶白卷草涡纹小花（左侧留空平整承托中文标题「能力说明」），纯透明背景，严禁任何汉字字母。"
        ),
        "prompt_en": (
            "Cozy hand-painted sage-pistachio green watercolor paper ribbon header tag (#DFE4C2) matching reference 06 banner strip, "
            "clean flat horizontal strip with delicate organic hand-cut bevel on right end, subtle delicate cream-white hand-drawn swirl flourish "
            "gracefully tucked on right half only (leaving left half completely plain clean color for crisp title label), "
            "isolated on pure transparent RGBA background (256x56), zero text, zero letters"
        ),
        "negative_prompt": COMMON_NEG + ", folded 3D heavy drop cloth, loud neon green",
    },
    {
        "id": "ui_zodiac_ribbon_rose",
        "group": "Zodiac_Book_Spread",
        "target_path": "assets/ui_core/v14_ui/zodiac/ui_zodiac_ribbon_rose.png",
        "width": 256,
        "height": 56,
        "requires_alpha": True,
        "min_transparent_ratio": 0.14,
        "replaces_ui": "ZodiacAlbumPanel 右页「战斗共鸣」珊瑚蔷薇粉丝带标题底图",
        "pixel_layout": "与 ui_zodiac_ribbon_sage 同几何比例（256×56 RGBA）；左侧承托「战斗共鸣」，右侧饰奶白涡纹",
        "prompt_cn": (
            "与 ui_zodiac_ribbon_sage 同轮廓尺寸（256×56 RGBA）的珊瑚蔷薇粉主强调小节丝带：对齐参考图右上「固有」粉色徽章——"
            "柔和淡珊瑚蔷薇粉（#EAB4B7），左区干净平整右区带柔和奶白卷草涡纹，纯透明背景无文字。"
        ),
        "prompt_en": (
            "Cozy hand-painted dusty rose-coral watercolor paper ribbon header tag (#EAB4B7) strictly matching ui_zodiac_ribbon_sage proportion "
            "and reference 06 pink tag style, gentle hand-painted paper texture with delicate cream-white hand-drawn swirl flourish on right half "
            "only (leaving left half clean plain surface for title text), isolated on pure transparent RGBA background (256x56), zero text"
        ),
        "negative_prompt": COMMON_NEG + ", neon magenta, blood red",
    },
]

QA_SCRIPT_BODY = r'''"""Zero-dependency PNG verification tool for IGA v15 Zodiac Open-Book Spread Pack."""
from __future__ import annotations

import json
import struct
import sys
import zlib
from pathlib import Path


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def inspect_png(path: Path) -> dict:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Not a valid PNG file")
    pos = 8
    width = height = bit_depth = color_type = 0
    idat_parts = []
    while pos + 8 <= len(data):
        length, ctype = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _c, _f, interlace = struct.unpack(">IIBBBBB", chunk)
            if interlace != 0:
                raise ValueError("Interlaced PNG not supported; please export non-interlaced PNG")
        elif ctype == b"IDAT":
            idat_parts.append(chunk)
        elif ctype == b"IEND":
            break

    has_alpha = color_type in (4, 6)
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color_type, 0)
    transparent_ratio = 0.0
    if has_alpha and bit_depth == 8 and channels in (2, 4):
        raw = zlib.decompress(b"".join(idat_parts))
        bpp = channels
        stride = width * bpp
        prev = bytearray(stride)
        transparent_pixels = 0
        total_pixels = width * height
        idx = 0
        for _y in range(height):
            flt_type = raw[idx]
            idx += 1
            row = bytearray(raw[idx:idx + stride])
            idx += stride
            if flt_type == 1:
                for i in range(bpp, stride):
                    row[i] = (row[i] + row[i - bpp]) & 0xFF
            elif flt_type == 2:
                for i in range(stride):
                    row[i] = (row[i] + prev[i]) & 0xFF
            elif flt_type == 3:
                for i in range(stride):
                    left = row[i - bpp] if i >= bpp else 0
                    row[i] = (row[i] + ((left + prev[i]) >> 1)) & 0xFF
            elif flt_type == 4:
                for i in range(stride):
                    left = row[i - bpp] if i >= bpp else 0
                    up = prev[i]
                    upleft = prev[i - bpp] if i >= bpp else 0
                    row[i] = (row[i] + _paeth(left, up, upleft)) & 0xFF
            for a in row[bpp - 1::bpp]:
                if a <= 10:
                    transparent_pixels += 1
            prev = row
        transparent_ratio = transparent_pixels / max(1, total_pixels)

    return {
        "width": width,
        "height": height,
        "bit_depth": bit_depth,
        "color_type": color_type,
        "has_alpha": has_alpha,
        "transparent_ratio": round(transparent_ratio, 4),
    }


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Usage: python qa_check_v15_zodiac_book.py <project_or_delivery_root> [manifest_json]")
        return 0
    target_root = Path(sys.argv[1]).resolve()
    manifest_path = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else (Path(__file__).resolve().parents[1] / "02_asset_manifest_v15.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    passed = 0
    failed = 0
    missing = 0
    for item in manifest["items"]:
        rel = item["target_path"]
        f = target_root / rel
        if not f.exists():
            f_alt = target_root / Path(rel).name
            if f_alt.exists():
                f = f_alt
            else:
                print(f"[MISSING] {item['id']} -> {rel}")
                missing += 1
                continue
        try:
            info = inspect_png(f)
        except Exception as exc:
            print(f"[FAIL] {item['id']} ({f.name}): {exc}")
            failed += 1
            continue
        errs = []
        if info["width"] != item["width"] or info["height"] != item["height"]:
            errs.append(f"size {info['width']}x{info['height']} != {item['width']}x{item['height']}")
        if info["bit_depth"] != 8:
            errs.append(f"bit_depth {info['bit_depth']} != 8")
        if item["requires_alpha"]:
            if not info["has_alpha"]:
                errs.append("missing alpha channel (must be RGBA PNG)")
            elif info["transparent_ratio"] < float(item["min_transparent_ratio"]):
                errs.append(
                    f"transparent_ratio {info['transparent_ratio']:.1%} < {float(item['min_transparent_ratio']):.1%}"
                )
        if errs:
            print(f"[FAIL] {item['id']} -> " + "; ".join(errs))
            failed += 1
        else:
            print(
                f"[PASS] {item['id']} ({info['width']}x{info['height']}, alpha={info['has_alpha']}, transparent={info['transparent_ratio']:.1%})"
            )
            passed += 1
    print(f"Summary: {passed} passed, {failed} failed, {missing} missing / {len(manifest['items'])} total")
    return 0 if (failed == 0 and missing == 0) else 1


if __name__ == "__main__":
    raise SystemExit(main())
'''


def _readme_md() -> str:
    return """# IGA v15 星座典籍对开详情页专属素材包（共 3 项，独立增补包）

> **编制日期**：2026-11-19  
> **打包说明**：本包为**星座图鉴「左卡展示 × 右页详介」对开书本界面**的独立增补需求（不影响正在制作的 `v14` 32 项通用 UI/按钮包，按统一落库路径直接放入即可自动生效）。

---

## 一、画布坐标系与精准卡槽尺寸铁律

Godot 中 `ZodiacAlbumPanel` 的书本控件 `BookSpread` 尺寸锁定为 **`1580×936`**，关键像素区间如下（制作 `ui_zodiac_book_spread.png` 时请严格对齐截图 `20_zodiac_book_detail.png`）：

1. **中线书脊**：`x = 790`（左页 `x: 38..790`，右页 `x: 790..1542`）。
2. **左页大卡凹槽（`CardNiche`）**：`Rect2(188, 114, 434, 651)`
   - 引擎会直接在凹槽上方嵌入 `422×633` 的星座卡片与金色外框（[`zodiac_card_frame.png`](04_Style_References/zodiac_card_frame.png)）及动态共鸣光环；
   - 因此书本美术在 `188..622, 114..765` 处只需表现**略微内凹的实体影盒折边阴影**，**绝不要画任何卡片插画或字符**。
   - 凹槽上方（`y ≈ 62..96`）和下方（`y ≈ 782..852`）对称保留两处横向引导装饰线，中间文字由程序叠加。
3. **右页铜棕 L 轴与干净排版区**：
   - 顶部偏左铜棕 L 形轴线：竖线 `x ≈ 864 (y: 52..396)`，横线 `y ≈ 82 (x: 842..1460)`；
   - `y: 162..740` 区域保持纸面干净整洁（仅保留纸质微肌理），避免纹饰遮挡黑色说明正文；
   - 右上角淡金色星芒水印 & 右下角铜棕 L 角标请参照 `06_星座典籍双页详情_左卡片右介绍.jpg` 的温和淡雅浓度。
4. **两条独立手绘丝带**（`ui_zodiac_ribbon_sage.png` 与 `ui_zodiac_ribbon_rose.png`，均 `256×56`）：
   - 与书本分离导出以便后续复用和精准对齐不同高度条目；右侧绘制白色卷草涡纹，左侧保持平坦颜色让引擎渲染中文节名。

---

## 二、目录结构与零依赖验收命令

- `00_README_星座典籍对开书本交付规范.md`（本规范）
- `01_星座典籍素材需求与提示词_v15.md`（3 项详单与中英文 Prompt）
- `02_asset_manifest_v15.json`（机读验收清单）
- `03_Current_Screen_References/`（当前 Godot 实机截图：`19_zodiac_overview.png`、`20_zodiac_book_detail.png`）
- `04_Style_References/`（主创提供原参考图 `06_星座典籍双页详情_左卡片右介绍.jpg` + 现行卡牌框 `zodiac_card_frame.png` / 样例牌 `zodiac_01_aries_hero.png`）
- `06_Tools/qa_check_v15_zodiac_book.py`（零依赖 PNG 质检脚本）

验收命令：
```bash
python 06_Tools/qa_check_v15_zodiac_book.py <交付根目录或工程根目录> 02_asset_manifest_v15.json
```
全部 **3 项输出 `[PASS]`** 并合入 `res://assets/ui_core/v14_ui/zodiac/` 后，`ZodiacAlbumPanel` 将在下次启动自动加载，**无需改动一行代码**。
"""


def _prompts_md() -> str:
    lines = [
        "# IGA v15 星座典籍对开书本与丝带素材提示词（共 3 项）",
        "",
        "> 对照 `04_Style_References/06_星座典籍双页详情_左卡片右介绍.jpg` 与实机截图 `03_Current_Screen_References/20_zodiac_book_detail.png` 制作，精准匹配 `1580×936` 对开坐标。",
        "",
    ]
    for idx, item in enumerate(MANIFEST_ITEMS, 1):
        lines.append(f"### {idx:02d}. `{item['id']}`")
        lines.append(f"- **落库路径**：`{item['target_path']}`")
        lines.append(f"- **替换对象**：{item['replaces_ui']}")
        lines.append(f"- **像素坐标要点**：{item['pixel_layout']}")
        lines.append(f"- **尺寸与透明要求**：`{item['width']}×{item['height']}` · 8-bit RGBA PNG（透明像素 ≥ `{float(item['min_transparent_ratio']):.0%}`）")
        lines.append(f"- **中文制作指令**：{item['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {item['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {item['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


def build_pack() -> None:
    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_ZIP.parent.mkdir(parents=True, exist_ok=True)

    (STAGING_DIR / "00_README_星座典籍对开书本交付规范.md").write_text(_readme_md(), encoding="utf-8")
    (STAGING_DIR / "01_星座典籍素材需求与提示词_v15.md").write_text(_prompts_md(), encoding="utf-8")
    manifest_payload = {
        "version": "v15",
        "generated_date": "2026-11-19",
        "note": "Standalone pack for Zodiac Open-Book Spread; paths under assets/ui_core/v14_ui/zodiac/ match ZodiacAlbumPanel auto-load constants.",
        "items": MANIFEST_ITEMS,
    }
    (STAGING_DIR / "02_asset_manifest_v15.json").write_text(
        json.dumps(manifest_payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    screen_dest = STAGING_DIR / "03_Current_Screen_References"
    screen_dest.mkdir(parents=True, exist_ok=True)
    for name in ["19_zodiac_overview.png", "20_zodiac_book_detail.png"]:
        src = CAPTURE_DIR / name
        if not src.is_file():
            raise FileNotFoundError(f"Missing live Zodiac capture: {src}")
        shutil.copy2(src, screen_dest / name)

    ref_dest = STAGING_DIR / "04_Style_References"
    ref_dest.mkdir(parents=True, exist_ok=True)
    style_sources = [
        ROOT / "docs/references/2026-11-19-scene-ui-redesign/03_交互窗口与商店选拔赛/06_星座典籍双页详情_左卡片右介绍.jpg",
        ROOT / "assets/ui/zodiac_cards/zodiac_card_frame.png",
        ROOT / "assets/ui/zodiac_cards/zodiac_01_aries_hero.png",
    ]
    for src in style_sources:
        if not src.is_file():
            raise FileNotFoundError(f"Missing style reference: {src}")
        shutil.copy2(src, ref_dest / src.name)

    tools_dest = STAGING_DIR / "06_Tools"
    tools_dest.mkdir(parents=True, exist_ok=True)
    (tools_dest / "qa_check_v15_zodiac_book.py").write_text(QA_SCRIPT_BODY, encoding="utf-8")

    if ARCHIVE_ZIP.exists():
        ARCHIVE_ZIP.unlink()
    file_count = 0
    with zipfile.ZipFile(ARCHIVE_ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for path in sorted(STAGING_DIR.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(STAGING_DIR).as_posix())
                file_count += 1

    print(json.dumps({
        "zip_path": str(ARCHIVE_ZIP),
        "zip_bytes": ARCHIVE_ZIP.stat().st_size,
        "entries": file_count,
        "manifest_items": len(MANIFEST_ITEMS),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build_pack()
