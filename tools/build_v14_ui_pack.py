"""Build IGA v14 UI Controls, 9-Slice Buttons & Hand-Painted Icons Asset Brief Pack."""
from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPTURE_DIR = ROOT / ".godot/test-results/captures_1600x900/captures"
STAGING_DIR = ROOT / ".godot/v14_staging/pack_root"
ARCHIVE_ZIP = ROOT / "archive/IGA_Asset_Pack_Brief_v14_UI_Controls_Buttons.zip"

COMMON_UI_NEG = (
    "text, letters, typography, Chinese characters, English words, numbers, icons baked in center, "
    "photorealistic, 3D bevel plastic, neon cyberpunk glow, heavy drop shadow clipping canvas edge, "
    "dirty grunge texture, dark gothic metal, asymmetrical border pattern inside 9-slice stretch zone, watermark"
)

COMMON_ICON_NEG = (
    "text, letters, numbers, white rectangular background box, drop shadow cut off at border, "
    "photorealistic 3D render, flat vector clip art, blurry low-res, multiple objects collage, watermark"
)

MANIFEST_ITEMS = [
    # =========================================================================
    # Group 1: PeriodDial & Top/Left/Bottom HUD Chrome (7 items)
    # =========================================================================
    {
        "id": "ui_dial_morning",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/dials/ui_dial_morning.png",
        "width": 256,
        "height": 256,
        "requires_alpha": True,
        "min_transparent_ratio": 0.18,
        "replaces_ui": "SceneHUDLayout.PeriodDial / HomeScreen HomePeriodDial（早晨/昼间程序画圆盘）",
        "prompt_cn": "Potionomics 风格圆形怀表式时段徽章（早晨晴昼状态）：外圈洁净奶白与浅金细边框、内部清透天蓝昼空配柔和暖金色太阳圆轮与少许软白云朵微景观、正面平视居中构图、四周留透明边距，绝无文字数字或指针遮挡读数。",
        "prompt_en": (
            "Anime cozy watercolor-cel circular pocket-watch time-of-day badge icon, daytime morning sky edition, "
            "clean cream-ivory and soft gold metallic circular rim, glowing cerulean blue sky inside with warm radiant golden sun disc "
            "and subtle wispy clouds, crisp Potionomics inspired hand-painted UI craft, front view centered circle, generous transparent "
            "padding outside circle, pure RGBA transparent background, no text, no numbers, no clock hands"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", dark night, moon, thick messy outlines",
    },
    {
        "id": "ui_dial_afternoon",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/dials/ui_dial_afternoon.png",
        "width": 256,
        "height": 256,
        "requires_alpha": True,
        "min_transparent_ratio": 0.18,
        "replaces_ui": "PeriodDial 下午/黄昏状态圆形仪表徽章",
        "prompt_cn": "同系列圆形怀表时段徽章（下午/黄昏状态）：一致尺寸外框与透视，盘面内部变为渐变桃粉橙至暖琥珀金的晚霞云层与低垂金太阳，色彩柔和清透，透明背景。",
        "prompt_en": (
            "Anime cozy watercolor-cel circular pocket-watch time-of-day badge icon matching daytime rim proportion, "
            "warm golden-hour afternoon dusk edition, cream-ivory and soft bronze-gold outer ring, twilight peach-coral to "
            "warm amber sunset gradient sky inside with glowing descending sun and soft pink clouds, clean cel-shaded UI badge, "
            "centered circle on pure transparent RGBA background, no text, no numbers, no clock hands"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", pitch black night, heavy brown grunge",
    },
    {
        "id": "ui_dial_night",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/dials/ui_dial_night.png",
        "width": 256,
        "height": 256,
        "requires_alpha": True,
        "min_transparent_ratio": 0.18,
        "replaces_ui": "PeriodDial 常规夜晚状态圆形仪表徽章",
        "prompt_cn": "同系列圆形怀表时段徽章（常规夜晚状态）：银蓝偏暖铜细外环，内部深靛蓝透明夜空悬有柔和弯银月与点点浅金微星，清透优雅不晦暗，透明背景。",
        "prompt_en": (
            "Anime cozy watercolor-cel circular pocket-watch time-of-day badge icon matching morning rim proportion, "
            "serene clear night edition, pale silver-blue and muted brass circular rim, deep indigo-blue clear night sky inside "
            "with luminous silver crescent moon and delicate twinkling tiny stars, Potionomics UI elegance, centered circle "
            "on pure transparent RGBA background, no text, no numbers, no clock hands"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", crimson red moon, horror, muddy black",
    },
    {
        "id": "ui_dial_redmoon",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/dials/ui_dial_redmoon.png",
        "width": 256,
        "height": 256,
        "requires_alpha": True,
        "min_transparent_ratio": 0.18,
        "replaces_ui": "PeriodDial 红月预警 / Overclock 相位状态圆形徽章",
        "prompt_cn": "同系列圆形怀表时段徽章（红月预警状态）：深靛蓝外圈配细暗金与微弱绯红环光，盘内深紫蓝夜空悬有一轮醒目的温柔绯红满月与细微白色轨道细环（呼应蔚蓝档案/红月学园都市），透明背景。",
        "prompt_en": (
            "Anime cozy watercolor-cel circular pocket-watch time-of-day badge icon matching morning rim proportion, "
            "crimson red-moon alert edition, deep twilight slate-navy rim with subtle pale-crimson hairline accent, "
            "midnight violet-navy sky inside featuring a luminous crimson-red full moon with faint thin white geometric orbital ring, "
            "stylish anime UI badge, centered circle on pure transparent RGBA background, no text, no numbers"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", blood gore, messy splatter, skull",
    },
    {
        "id": "ui_hud_dock_strip_9slice",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/panels/ui_hud_dock_strip_9slice.png",
        "width": 512,
        "height": 1024,
        "requires_alpha": True,
        "min_transparent_ratio": 0.02,
        "nine_slice_margins": {"left": 24, "right": 44, "top": 48, "bottom": 48},
        "replaces_ui": "SceneHUDLayout 左侧操作停靠栏 DockBacking（当前 07_library_npc 等场景左栏纯色半透明 ColorRect）",
        "prompt_cn": "高竖条 9-Slice 手帐磨砂左侧停靠底板（512×1024）：左缘与上下缘保持平整柔和渐隐、右缘距画布右边界留约 16px 透明柔光阴影与极细薄荷青（#359686）+ 浅金双线边框，板面为温暖透亮微肌理象牙米白水彩纸质感（约 92% 不透明度，中央完全均匀无花纹），严禁文字与按钮。",
        "prompt_en": (
            "9-slice UI vertical side dock panel plate, translucent warm ivory cream watercolor paper glass texture (#FFFDF8), "
            "clean straight left edge, right edge with delicate vertical mint-teal (#359686) hairline accent, fine warm gold inner rule, "
            "and soft 14px translucent drop shadow fading into transparent margin on far right, completely uniform plain smooth interior "
            "for seamless vertical stretching, anime school journal style, RGBA PNG, zero text, zero icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", busy floral pattern across center, dark heavy border",
    },
    {
        "id": "ui_hud_resource_capsule_9slice",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/panels/ui_hud_resource_capsule_9slice.png",
        "width": 640,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.12,
        "nine_slice_margins": {"left": 64, "right": 64, "top": 28, "bottom": 28},
        "replaces_ui": "HomeScreen 与 SceneHUDLayout 右上角体力/练习点/零用钱资源胶囊 ResourceCapsule",
        "prompt_cn": "横条全圆角胶囊型 HUD 状态条底板（640×128，9-Slice 水平居中拉伸）：洁净清透的奶白温润玻璃釉质胶囊，细腻薄荷青（#359686）双层极细边线、顶部微亮反光带与底部柔和自然落影，四周圆角外全透明，中央内部保持纯洁均匀留白，严禁分割线与文字图标。",
        "prompt_en": (
            "9-slice horizontal pill capsule UI plate, crisp rounded stadium pill shape centered on transparent RGBA canvas, "
            "clean warm ivory milk-glass surface (#FFFDF8) with delicate pastel mint-teal (#359686) fine outer rim, subtle top gloss "
            "highlight, and soft translucent drop shadow outside capsule, uniform smooth center stretch area with no vertical dividers, "
            "Blue Archive & Potionomics cozy UI craft, no text, no icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", vertical divider bars inside capsule, sharp square corners",
    },
    {
        "id": "ui_status_bar_9slice",
        "group": "PeriodDial_HUD",
        "target_path": "assets/ui_core/v14_ui/panels/ui_status_bar_9slice.png",
        "width": 1024,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.08,
        "nine_slice_margins": {"left": 48, "right": 48, "top": 24, "bottom": 24},
        "replaces_ui": "SceneHUDLayout / RegionMapView / RegionAtlasView 底部悬浮说明深灰条 StatusBar / PreviewCard",
        "prompt_cn": "底部提示条 9-Slice 深海青灰毛玻璃底板（1024×128）：替换现在偏枯燥的纯深灰矩形提示条，改为温润深海军靛灰半透明质地（#212F47 约 90% 不透明）、极细暖金/米白手帐内细线、小圆角边缘加柔和微阴影，两端左端可点缀极小精致四叶/星菱角标，中央严格均匀平坦。",
        "prompt_en": (
            "9-slice horizontal HUD tooltip bar panel, translucent deep slate-navy frosted glass ink card (#212F47), "
            "delicate thin champagne-gold inner border hairline, crisp small rounded corners fading softly into transparent margin, "
            "tiny minimalist diamond sparkle accent near top-left inner frame corner, completely uniform center area for crisp CJK text legibility, "
            "Blue Archive cozy anime UI, RGBA PNG, no text, no icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", bright white background, noisy texture overlapping center text zone",
    },
    # =========================================================================
    # Group 2: Core Cel-Shaded 9-Slice Buttons & Stamp (7 items)
    # =========================================================================
    {
        "id": "ui_btn_cel_normal_9slice",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_btn_cel_normal_9slice.png",
        "width": 512,
        "height": 144,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 32, "bottom": 36},
        "replaces_ui": "左侧停靠栏日常行动卡、HomeScreen 快捷白按钮、商店次要按钮、地图白按钮（常规态）",
        "prompt_cn": "清透学园赛璐璐常规按钮 9-Slice 底图（512×144）：温润象牙白手帐卡片（#FFFDF8）略带极淡纸张呼吸感，外圈清晰淡蓝灰细描边（#D6DADF），顶部 2px 纯白高光边，底部略厚 4px 立体厚度边与 10px 轻柔阴影，边缘透明，中间严格干净平整便于文字居中排版。",
        "prompt_en": (
            "9-slice anime UI button plate normal state, clean warm ivory cream card (#FFFDF8) with gentle subtle paper smoothness, "
            "delicate cool slate-silver outline, crisp thin white top highlight edge, clean 3px soft tinted bottom lip giving tactile "
            "button depth, gentle soft drop shadow into transparent outer padding, rounded rectangular corners (radius ~14px), "
            "completely flat clean middle stretch area, Potionomics & Blue Archive style, RGBA PNG, zero text, zero icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", heavy gradient, neon, corner ornaments stretching awkwardly",
    },
    {
        "id": "ui_btn_cel_hover_9slice",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_btn_cel_hover_9slice.png",
        "width": 512,
        "height": 144,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 32, "bottom": 36},
        "replaces_ui": "对应 ui_btn_cel_normal_9slice 的鼠标悬浮与键盘焦点高亮态",
        "prompt_cn": "与 ui_btn_cel_normal_9slice 同比例尺寸的悬浮高亮态（512×144）：通透暖日奶白微泛极淡薄荷青高光边框（#359686），外缘轻微柔和晨光晕染，干净清亮的手帐质感，无文字无图案。",
        "prompt_en": (
            "9-slice anime UI button plate hover/highlighted state matching ui_btn_cel_normal_9slice exact geometry, "
            "luminous sunlit cream-white interior with crisp pastel mint-teal (#359686) glowing border rim, gentle luminous outer aura "
            "fading softly into transparent margin, clean uniform center for readable dark navy text, Potionomics & Blue Archive style, "
            "RGBA PNG, zero text, zero icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", dark shadow center, harsh neon glow",
    },
    {
        "id": "ui_btn_cel_primary_9slice",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_btn_cel_primary_9slice.png",
        "width": 512,
        "height": 144,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 32, "bottom": 36},
        "replaces_ui": "全游主强调珊瑚红按钮：前往体育馆、登台挑战、练习90点、前往校园地图、商店确认结算",
        "prompt_cn": "高光感暖珊瑚杏红主操作按钮 9-Slice 底图（512×144）：上亮珊瑚杏橘渐变到下暖珊瑚朱红（#E26A56 -> #D45B49），极细奶油米金双内框线与右上角落极细微星光高光，微厚底边与柔影，清晰突出核心点击欲又与手帐背景和谐。",
        "prompt_en": (
            "9-slice anime primary CTA button plate, warm coral-terracotta to apricot sunset cel gradient (#E26A56 to #D45B49), "
            "delicate cream-gold thin double inner hairline border, subtle crisp top bevel highlight and tactile slightly darker coral "
            "bottom lip, gentle soft shadow into transparent outer padding, rounded rectangular corners, clean uniform center so white text "
            "pops effortlessly, Blue Archive & Reverse:1999 cozy UI mix, RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", crimson blood red, flat unshaded solid rectangle, neon orange",
    },
    {
        "id": "ui_btn_cel_teal_9slice",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_btn_cel_teal_9slice.png",
        "width": 512,
        "height": 144,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 32, "bottom": 36},
        "replaces_ui": "青碧选中态与功能切页按钮：商店选中分类页签（行动卡/购买）、随行中、已通关可再战",
        "prompt_cn": "清新薄荷青碧功能选中态按钮 9-Slice 底图（512×144）：同结构圆润手感，柔和海风薄荷青渐变（#44AB99 -> #359686），极细象牙白内线框与温和顶缘高光，适合反白文字阅读。",
        "prompt_en": (
            "9-slice anime active-tab & teal action button plate matching ui_btn_cel_primary_9slice geometry, "
            "fresh soothing mint-teal cel gradient (#44AB99 to #359686), crisp thin cream-white inner border hairline, subtle top gloss, "
            "tactile soft teal bottom edge fading cleanly to transparent margin, smooth uniform center for white text, RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", muddy dark green, fluorescent cyan",
    },
    {
        "id": "ui_btn_cel_back_9slice",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_btn_cel_back_9slice.png",
        "width": 448,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 28, "bottom": 32},
        "replaces_ui": "导航与返回胶囊按钮：← 返回校园地图、地区地图(M)、菜单、弹窗返回 ×、战台顶栏按钮",
        "prompt_cn": "清冷晴空冰白二级导航胶囊按钮 9-Slice 底图（448×128）：浅晴空冷白（#F4F8FC）底面配柔和海军钢蓝细边线（#B8C6D8），简约现代赛璐璐导航条质感，透明留边，中央干净均匀。",
        "prompt_en": (
            "9-slice anime navigation & back button plate, cool cloud-ice white surface (#F4F8FC) with crisp steel slate-blue hairline rim "
            "(#B8C6D8), clean subtle top inner sheen and soft bottom edge depth, gentle drop shadow into transparent margin, rounded stadium/pill "
            "corners, clean uniform stretchable center for dark navy text, Blue Archive UI aesthetic, RGBA PNG, zero text, zero arrows"
        ),
        "negative_prompt": COMMON_UI_NEG + ", heavy yellow cream, dark background, arrow icons baked in",
    },
    {
        "id": "ui_btn_stamp_claim",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_btn_stamp_claim.png",
        "width": 320,
        "height": 112,
        "requires_alpha": True,
        "min_transparent_ratio": 0.08,
        "nine_slice_margins": {"left": 32, "right": 32, "top": 24, "bottom": 24},
        "replaces_ui": "03_projection_records 放映档案室「盖章领奖」按钮（当前为纯红褐矩形，缺盖章手帐手感）",
        "prompt_cn": "手帐朱红社团印章风格按钮 9-Slice 底图（320×112）：暖朱红赤陶印泥质感（#C45746）带轻微纸纤维透底、双层方圆角线框外框与轻微手盖压边质感，透明外留边，中间平滑以清晰承托白色「盖章领奖」文字。",
        "prompt_en": (
            "9-slice Japanese school-club rubber stamp button plate, warm vermilion-terracotta ink-pad color (#C45746) with delicate subtle "
            "washi paper grain, double stamped rectangle-rounded frame lines inside edge, slight organic ink border warmth fading into "
            "transparent outer edge, clean even central tone for crisp white CJK label, cozy scrapbook UI aesthetic, RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", blurred illegible smudge in center, heavy grunge holes",
    },
    {
        "id": "ui_seal_claimed_badge",
        "group": "Buttons_9Slice",
        "target_path": "assets/ui_core/v14_ui/buttons/ui_seal_claimed_badge.png",
        "width": 192,
        "height": 192,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "放映档案室已领取委托、选拔赛已通关印章 Decorative Seal 装饰盖章叠层",
        "prompt_cn": "透明背景社团完成认证红色圆章（192×192）：朱红印泥盖印效果（半透明微破损纸感），双层同心细圆环配四颗四角星与小橄榄/银杏叶微饰，中间留空可配打勾或斜盖展示，绝不写任何中文英文汉字或乱码字母。",
        "prompt_en": (
            "Transparent ink-stamp round club completion seal emblem, warm vermilion red ink (#C94E3E) slightly textured on invisible "
            "transparent RGBA background, concentric hand-stamped circular double rings adorned with subtle tiny four-point stars and "
            "minimalist school leaf sprigs around rim, open clean center with simple checkmark flourish, strictly ZERO letters and ZERO text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", pseudo-kanji, fake English characters, solid opaque white circle background",
    },
    # =========================================================================
    # Group 3: Dialogue Bubbles & Card / List Item Plates (5 items)
    # =========================================================================
    {
        "id": "ui_npc_bubble_9slice",
        "group": "Bubbles_Cards",
        "target_path": "assets/ui_core/v14_ui/panels/ui_npc_bubble_9slice.png",
        "width": 384,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.16,
        "nine_slice_margins": {"left": 48, "right": 48, "top": 28, "bottom": 32},
        "replaces_ui": "全场景头顶极简 NPC 浮泡（💬 林知夏 / 唐小满 / 杨子英 / 柳宇龙 / 姜梓）胶囊框",
        "prompt_cn": "头顶极简 NPC 名字浮泡 9-Slice 外框（384×128，不带底部小三角尖刺——尖刺由引擎动态定位）：圆润纯净奶白微透糖果胶质胶囊（#FFFFFF 96%），外圈极细浅青绿（#359686）与柔美浅阴影，视觉精致清爽，无文字无图标。",
        "prompt_en": (
            "9-slice floating NPC speech pill frame without tail pointer, pure luminous soft milk-white lozenge (#FFFFFF) with subtle "
            "clean mint-aqua outline hairline (#359686) and delicate soft ambient shadow into generous transparent outer margin, "
            "crisp P3R & Blue Archive minimal floating world bubble aesthetic, uniform smooth center, RGBA PNG, no tail, no text, no icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", speech triangle tail attached, gray dirty shading",
    },
    {
        "id": "ui_clerk_speech_bubble_9slice",
        "group": "Bubbles_Cards",
        "target_path": "assets/ui_core/v14_ui/panels/ui_clerk_speech_bubble_9slice.png",
        "width": 640,
        "height": 192,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 48, "right": 48, "top": 36, "bottom": 40},
        "replaces_ui": "09_shop_counter 商店分栏右侧唐小满实时互动对话卡片 ClerkSpeechBubble",
        "prompt_cn": "店员互动气泡 9-Slice 暖纸手帐框（640×192）：温暖牛奶象牙底色（#FFFDF6）配精细海绿细边框（#359686）与内侧淡淡虚线手帐边、小胶带/页签装饰只在左上角安全区边缘内且不进入中心拉伸区，柔和投影，纯透明外留白，无任何文字。",
        "prompt_en": (
            "9-slice shopkeeper dialogue card frame inspired by Potionomics & cozy anime journals, warm cream milk-paper surface (#FFFDF6), "
            "crisp mint-teal fine outer outline (#359686), delicate inner fine dotted line inset cleanly inside margins, subtle corner drop shadow "
            "into transparent background, completely uniform central reading space, RGBA PNG, zero text, zero nameplate"
        ),
        "negative_prompt": COMMON_UI_NEG + ", speech tail, dark mud color, busy center texture",
    },
    {
        "id": "ui_item_card_normal_9slice",
        "group": "Bubbles_Cards",
        "target_path": "assets/ui_core/v14_ui/panels/ui_item_card_normal_9slice.png",
        "width": 384,
        "height": 384,
        "requires_alpha": True,
        "min_transparent_ratio": 0.06,
        "nine_slice_margins": {"left": 36, "right": 36, "top": 36, "bottom": 36},
        "replaces_ui": "商店货架商品卡、选拔赛三轮对手行卡片、工坊行动卡槽位卡片、同行切换行（未选中态）",
        "prompt_cn": "通用手帐商品/对战卡片 9-Slice 底板（384×384）：浅米杏温润厚卡纸（#FFFBF3），外圈精致浅沙金褐色细边线（#DCCEB7）、极细内描线与轻微立体阴影，干净精致不抢卡片中央插画与文字焦点，边缘透明。",
        "prompt_en": (
            "9-slice anime store item & roster card plate normal state, clean warm cream cardstock (#FFFBF3) with fine warm sand-taupe "
            "outline (#DCCEB7) and delicate ultra-thin inset frame border, soft tactile bottom paper thickness edge and gentle drop shadow "
            "into transparent margin, rounded corners, uniform smooth plain interior, RGBA PNG, zero text, zero icons"
        ),
        "negative_prompt": COMMON_UI_NEG + ", heavy brown parchment burns, loud patterns",
    },
    {
        "id": "ui_item_card_selected_9slice",
        "group": "Bubbles_Cards",
        "target_path": "assets/ui_core/v14_ui/panels/ui_item_card_selected_9slice.png",
        "width": 384,
        "height": 384,
        "requires_alpha": True,
        "min_transparent_ratio": 0.06,
        "nine_slice_margins": {"left": 36, "right": 36, "top": 36, "bottom": 36},
        "replaces_ui": "商店选中商品卡、选拔赛当前可挑战/高亮轮次卡、工坊当前选中卡与切换随行当前同伴卡",
        "prompt_cn": "与 ui_item_card_normal_9slice 同结构的选中高亮卡片 9-Slice 底板（384×384）：清亮暖白内芯外围升级为精致珊瑚金边框（#D96B52 / #E6B566）与微弱暖金外辉光，优雅点明当前激活状态。",
        "prompt_en": (
            "9-slice anime store & tactical card plate selected state matching ui_item_card_normal_9slice exact geometry, "
            "bright luminous warm white center with crisp coral-gold accent outline (#D96B52) and fine golden inner trim hairline, "
            "soft warm golden glow fading into transparent outer padding, completely uniform central reading space, RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", harsh red alarm glare, dark center",
    },
    {
        "id": "ui_map_title_plate_9slice",
        "group": "Bubbles_Cards",
        "target_path": "assets/ui_core/v14_ui/maps/ui_map_title_plate_9slice.png",
        "width": 512,
        "height": 160,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 32, "bottom": 36},
        "replaces_ui": "05_campus_map 阿瑞忒地图 & 06_world_atlas 六地区总图 左上角当前单纯矩形标题铭牌",
        "prompt_cn": "地图左上角水彩手绘铭牌底板 9-Slice（512×160）：呼应游戏现行 ui_map_pin_plates.png 绘本质感——温暖柔光象牙卡纸面、清新松石青边框（#488B80）、极其内敛的双片浅青水彩小叶点缀于左上角安全缘边，中间干净留白承托地名与日期。",
        "prompt_en": (
            "9-slice watercolor storybook map header title plate matching IGA ui_map_pin_plates watercolor aesthetic, "
            "warm sunlit cream paper interior with crisp turquoise-sage hand-painted border (#488B80) and subtle delicate pair of watercolor "
            "leaves nestled gracefully at top-left border only, soft drop shadow into transparent margin, wide uniform plain center for map title, "
            "RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", leaves extending into center text area, heavy wood frame",
    },
    # =========================================================================
    # Group 4: Campus Map & World Atlas Cards / Ribbon Badges (3 items)
    # =========================================================================
    {
        "id": "ui_atlas_region_card_9slice",
        "group": "Map_Atlas_Badges",
        "target_path": "assets/ui_core/v14_ui/maps/ui_atlas_region_card_9slice.png",
        "width": 448,
        "height": 144,
        "requires_alpha": True,
        "min_transparent_ratio": 0.10,
        "nine_slice_margins": {"left": 44, "right": 44, "top": 28, "bottom": 32},
        "replaces_ui": "06_world_atlas 六地区巡回总图上的 6 张白色纯代码地区铭牌卡片（阿瑞忒/诺莫斯/忒克捏/阿戈拉/同盟/教团）",
        "prompt_cn": "六地区巡回地图车票/明信片风节点铭牌 9-Slice 底板（448×144）：通透暖米白晴空旅游手帐卡，柔和天蓝/青灰细双线外框、微弱角落纸质投影，清晰轻巧漂浮在手绘水彩大地图上，不遮挡过多地图风光。",
        "prompt_en": (
            "9-slice travel-ticket / anime map node plaque for world atlas over hand-painted watercolor map, "
            "clean warm cream translucent ivory card with fine sky-blue & slate hairline border, crisp small rounded corners, "
            "gentle soft drop shadow into transparent outer padding, uniform clean interior for region name and number badge, RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", heavy brown leather, opaque black block, jagged stamp perforations overlapping center",
    },
    {
        "id": "ui_badge_current_loc",
        "group": "Map_Atlas_Badges",
        "target_path": "assets/ui_core/v14_ui/maps/ui_badge_current_loc.png",
        "width": 256,
        "height": 64,
        "requires_alpha": True,
        "min_transparent_ratio": 0.14,
        "nine_slice_margins": {"left": 32, "right": 32, "top": 16, "bottom": 16},
        "replaces_ui": "05_campus_map「当前所在」青色胶囊角标及各界面青色小状态标签",
        "prompt_cn": "小巧青绿小标签丝带底图 9-Slice（256×64）：饱满柔润的松石绿胶囊（#359686）配极细微亮内高光与微影，纯透明边缘，无字无图标。",
        "prompt_en": (
            "9-slice compact UI ribbon pill badge, calm emerald-teal gradient (#3BA492 to #2B8273), delicate top subtle gloss and fine cream "
            "inner hairline, crisp stadium rounded ends fading cleanly to transparent outer border, RGBA PNG, zero text, zero dots"
        ),
        "negative_prompt": COMMON_UI_NEG + ", square sharp corners, neon glow",
    },
    {
        "id": "ui_badge_event_alert",
        "group": "Map_Atlas_Badges",
        "target_path": "assets/ui_core/v14_ui/maps/ui_badge_event_alert.png",
        "width": 256,
        "height": 64,
        "requires_alpha": True,
        "min_transparent_ratio": 0.14,
        "nine_slice_margins": {"left": 32, "right": 32, "top": 16, "bottom": 16},
        "replaces_ui": "05_campus_map「✦ 代表选拔赛」、02_home_club「★ 8项可盖章」及左栏「赛事/1活动」醒目微标",
        "prompt_cn": "与 ui_badge_current_loc 成对的醒目珊瑚金红活动微标 9-Slice 底图（256×64）：柔和明快的暖珊瑚朱红（#DF6551 -> #CC513F）配细金白高光边线，小巧精悍，无字无图标。",
        "prompt_en": (
            "9-slice compact UI event-alert ribbon pill badge matching ui_badge_current_loc geometry, vibrant yet warm coral-crimson "
            "gradient (#DF6551 to #CC513F), delicate thin cream-gold inner rim, soft subtle shadow into transparent border, RGBA PNG, zero text"
        ),
        "negative_prompt": COMMON_UI_NEG + ", harsh flashing siren orange, square borders",
    },
    # =========================================================================
    # Group 5: Cozy Hand-Painted Icons Matching icon_allowance & icon_practice_points (10 items)
    # =========================================================================
    {
        "id": "icon_stamina_heart",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_stamina_heart.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "资源胶囊最左侧体力爱心（替换目前扁平单色 SVG icon_heart.svg，对齐旁边零用钱与练习点的手绘厚度）",
        "prompt_cn": "手绘水彩赛璐璐体力小红心图标（128×128）：对齐现行 icon_allowance.png 与 icon_practice_points.png 的饱满温润手绘水彩描边感——温柔樱桃珊瑚粉红宝石/珐琅质感心形徽章，细暖棕金包边与左上方柔和白高光，居中孤立于纯透明背景。",
        "prompt_en": (
            "Single hand-painted anime watercolor-cel UI stamina heart icon strictly matching cozy painted thickness of IGA coin & brush icons, "
            "plump warm coral-rose enamel heart charm with fine warm bronze-gold trim and soft glossy highlight at top-left, gentle hand-painted "
            "linework, centered isolated object with generous margin on pure transparent RGBA background, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", flat minimalist monochrome vector icon",
    },
    {
        "id": "icon_activity_pip_full",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_activity_pip_full.png",
        "width": 64,
        "height": 64,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "SceneHUDLayout「剩余活动 3/3」当前实心圆点（替换代码绘制的绿圆点）",
        "prompt_cn": "小尺寸点亮态「剩余活动点」发光菱星/水滴宝石徽记（64×64）：清透薄荷翠青配淡金细边，中间泛微暖光晕的小巧精致校徽星点，64px 下依旧锐利清晰，纯透明背景。",
        "prompt_en": (
            "Tiny radiant lit daily action-point gem star icon, crisp four-point star/seed crystal in glowing mint-emerald teal (#3BB09B) "
            "framed by delicate pale-gold rim, high silhouette clarity readable at small UI size, centered isolated on pure transparent "
            "RGBA background, hand-painted anime UI polish, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", tiny noisy details invisible when scaled down",
    },
    {
        "id": "icon_activity_pip_empty",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_activity_pip_empty.png",
        "width": 64,
        "height": 64,
        "requires_alpha": True,
        "min_transparent_ratio": 0.30,
        "replaces_ui": "SceneHUDLayout「剩余活动」已消耗空槽位",
        "prompt_cn": "与 icon_activity_pip_full 同轮廓的未点亮空槽位（64×64）：柔和淡雾蓝灰浅凹槽框（#C6D1DB），温润内凹小星形底座，纯透明背景。",
        "prompt_en": (
            "Tiny unlit spent daily action-point socket icon strictly matching icon_activity_pip_full four-point star silhouette, "
            "soft muted cloud-silver/slate recessed matte enamel groove (#C6D1DB), clean low-contrast unlit state, centered isolated on "
            "pure transparent RGBA background, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", glowing highlights, bright green",
    },
    {
        "id": "icon_act_chat",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_act_chat.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "全游浮泡与按钮里的系统 emoji「💬」（和林知夏聊聊 / 唐小满 / 姜梓 气泡头图标，替换各平台字体不一致的黑白气泡）",
        "prompt_cn": "清透小巧手绘水彩风圆角对话小气泡图标（128×128）：纯净天蓝描边暖奶白小气泡，内有三颗整齐可爱的薄荷青或天蓝小圆点，轮廓凝练在 24px 缩小时也极清楚，纯透明背景。",
        "prompt_en": (
            "Single crisp hand-painted anime UI chat speech bubble icon, clean rounded ivory-white speech bubble with soft sky-teal outline "
            "and three neat pastel teal ellipsis dots inside, clean readable silhouette even at 24px badge scale, cozy watercolor-cel finish, "
            "centered isolated on pure transparent RGBA background, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", realistic Android/Apple glossy 3D emoji, faces",
    },
    {
        "id": "icon_act_activity",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_act_activity.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "左栏需要消耗 1 活动点的主活动行前置符号「◆」（如 牌理研习 / 店务兼职 / 午后复盘）",
        "prompt_cn": "消耗 1 活动点日程图标（128×128）：温暖琥珀金配薄荷丝带的手绘菱形校园笔记本书签与微闪星芒，传达「投入时段日程」的明快视觉提示，纯透明背景。",
        "prompt_en": (
            "Single hand-painted anime UI daily schedule activity icon, warm golden-amber notebook diamond emblem with small sunlit sparkle "
            "and delicate mint ribbon tab, cozy school-life icon readability at small 28px size, centered isolated on pure transparent RGBA "
            "background, watercolor-cel craft, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", skull, dark clock, cluttered scene",
    },
    {
        "id": "icon_act_duel",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_act_duel.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "体育馆「阿瑞忒代表选拔赛」与地图赛事标签的符号「✦」及切磋行动图标",
        "prompt_cn": "非致命学园护盾裁决对决图标（128×128）：蔚蓝银框护盾徽章叠加珊瑚朱红荣誉勋带或双交叉练习卡片轮廓，体现学园战术刻印赛与护盾裁决特色（不画血腥兵器），纯透明背景。",
        "prompt_en": (
            "Single hand-painted anime UI school tactical shield-duel crest icon, gleaming silver-blue protective kite shield badge accented with "
            "coral-vermilion victory ribbon and crossed glowing card silhouettes, friendly non-lethal academy tournament feel matching IGA world, "
            "centered isolated on pure transparent RGBA background, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", bloody sword, gore, dark demon skull",
    },
    {
        "id": "icon_act_shop",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_act_shop.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "校园商店「查看商品采购」与商店导购按钮前缀图标",
        "prompt_cn": "精致小巧日系校园小店手提纸袋徽章图标（128×128）：温暖牛皮米白购物纸袋配清新薄荷绿顶边与小巧橙色蝴蝶结吊牌，纯透明背景。",
        "prompt_en": (
            "Single hand-painted anime UI cozy school-shop paper tote bag icon, warm cream-kraft shopping bag with pastel mint-teal cuff accent "
            "and tiny apricot price tag charm, crisp readable silhouette at small UI scale, centered isolated on pure transparent RGBA "
            "background, watercolor-cel style, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", barcode, store logo letters, metal shopping cart",
    },
    {
        "id": "icon_act_travel",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_act_travel.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "地区跳转行动按钮与右上「地区地图(M)」前置图标（替代纯文本箭头 →）",
        "prompt_cn": "清透水彩折页校园导览地图+小指南针图标（128×128）：天蓝海洋边微缩折页小地图配小巧金边定位针，清爽明快呼应阿瑞忒海滨地图，纯透明背景，不出现汉字或 N/E/W/S 字母。",
        "prompt_en": (
            "Single hand-painted anime UI folded watercolor campus guide-map icon with tiny coral location pin on top, soft cream paper folds "
            "showing clean abstract teal sea & green park color blocks, matching IGA world watercolor feel, centered isolated on pure transparent "
            "RGBA background, strictly NO letters (no N/E/S/W)"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", compass letters N S E W, text labels",
    },
    {
        "id": "icon_act_companion",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_act_companion.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "天台「切换随行同伴」与同伴协战羁绊入口徽标",
        "prompt_cn": "同伴协战双星丝带校徽图标（128×128）：两颗相互依偎的珊瑚粉与天蓝暖金双星微章缠绕柔和白色丝带，象征同伴默契连协，纯透明背景。",
        "prompt_en": (
            "Single hand-painted anime UI companion-bond emblem icon, twin harmonious coral-rose and cerulean-blue enamel stars linked by a "
            "graceful warm ivory ribbon swirl, cozy academy teamwork charm, crisp readable icon on pure transparent RGBA background, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", full human portraits inside 128px icon, cluttered collage",
    },
    {
        "id": "icon_hud_menu",
        "group": "HandPainted_Icons",
        "target_path": "assets/ui_core/v14_ui/icons/icon_hud_menu.png",
        "width": 128,
        "height": 128,
        "requires_alpha": True,
        "min_transparent_ratio": 0.25,
        "replaces_ui": "右上角「≡ 菜单」与全屏工具按钮文字三横符号 ≡",
        "prompt_cn": "温和海军蓝+浅金圆角三线菜单/小手帐本标识图标（128×128）：精致简约的手绘圆头三横菜单符号（可选略微衬底浅圆角小手帐轮廓），清晰稳定替换字符 ≡，纯透明背景。",
        "prompt_en": (
            "Single clean hand-painted anime UI menu icon, three neat rounded horizontal cream-gold bars over a subtle soft navy-slate rounded "
            "journal badge silhouette (or crisp slate-navy triple bars with delicate watercolor highlight), high legibility at 24-32px HUD scale, "
            "centered isolated on pure transparent RGBA background, zero text"
        ),
        "negative_prompt": COMMON_ICON_NEG + ", distorted wavy lines, unreadable thin hairlines",
    },
]

QA_SCRIPT_BODY = r'''"""Zero-dependency PNG verification tool for IGA v14 UI Controls, 9-Slice Plates & Icons."""
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


def inspect_png(path: Path, nine_slice: dict | None = None) -> dict:
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
                raise ValueError("Interlaced PNG not supported for fast QA; please export non-interlaced PNG")
        elif ctype == b"IDAT":
            idat_parts.append(chunk)
        elif ctype == b"IEND":
            break

    has_alpha = color_type in (4, 6)
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color_type, 0)
    transparent_ratio = 0.0
    center_opaque_ratio = 1.0
    if has_alpha and bit_depth == 8 and channels in (2, 4):
        raw = zlib.decompress(b"".join(idat_parts))
        bpp = channels
        stride = width * bpp
        prev = bytearray(stride)
        transparent_pixels = 0
        total_pixels = width * height
        center_total = 0
        center_visible = 0
        use_ns = False
        ns_l = ns_r = ns_t = ns_b = 0
        if nine_slice:
            ns_l = int(nine_slice.get("left", 0))
            ns_r = int(nine_slice.get("right", 0))
            ns_t = int(nine_slice.get("top", 0))
            ns_b = int(nine_slice.get("bottom", 0))
            use_ns = (ns_l + ns_r < width) and (ns_t + ns_b < height)
        idx = 0
        for y in range(height):
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
            alphas = row[bpp - 1::bpp]
            for x, a in enumerate(alphas):
                if a <= 10:
                    transparent_pixels += 1
                if use_ns and ns_l <= x < (width - ns_r) and ns_t <= y < (height - ns_b):
                    center_total += 1
                    if a >= 20:
                        center_visible += 1
            prev = row
        transparent_ratio = transparent_pixels / max(1, total_pixels)
        if use_ns and center_total > 0:
            center_opaque_ratio = center_visible / center_total

    return {
        "width": width,
        "height": height,
        "bit_depth": bit_depth,
        "color_type": color_type,
        "has_alpha": has_alpha,
        "transparent_ratio": round(transparent_ratio, 4),
        "center_opaque_ratio": round(center_opaque_ratio, 4),
    }


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Usage: python qa_check_v14_ui.py <project_or_delivery_root> [manifest_json]")
        return 0
    target_root = Path(sys.argv[1]).resolve()
    manifest_path = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else (Path(__file__).resolve().parents[1] / "02_asset_manifest_v14.json")
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
        ns = item.get("nine_slice_margins")
        try:
            info = inspect_png(f, ns)
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
        if ns:
            if int(ns["left"]) + int(ns["right"]) >= item["width"] or int(ns["top"]) + int(ns["bottom"]) >= item["height"]:
                errs.append("invalid nine_slice_margins larger than texture dimensions")
            elif info["center_opaque_ratio"] < 0.80:
                errs.append(f"9-slice center interior appears too hollow ({info['center_opaque_ratio']:.1%} visible)")
        if errs:
            print(f"[FAIL] {item['id']} -> " + "; ".join(errs))
            failed += 1
        else:
            ns_note = f", center={info['center_opaque_ratio']:.0%}" if ns else ""
            print(
                f"[PASS] {item['id']} ({info['width']}x{info['height']}, alpha={info['has_alpha']}, transparent={info['transparent_ratio']:.1%}{ns_note})"
            )
            passed += 1
    print(f"Summary: {passed} passed, {failed} failed, {missing} missing / {len(manifest['items'])} total")
    return 0 if (failed == 0 and missing == 0) else 1


if __name__ == "__main__":
    raise SystemExit(main())
'''


def _readme_md() -> str:
    return """# IGA v14 UI 控件、9-Slice 按钮与手绘图标美化需求规范

> **编制日期**：2026-11-19  
> **制作定位**：在刚完成 `v13` 蔚蓝档案清透赛璐璐 7 处场景换新之后，把全游依然停留在**纯代码 `StyleBoxFlat` 矩形、程序几何 `draw_circle` 圆盘与系统 `💬 / ♦ / ≡` 字符符号**的交互控件升级为统一的**暖调青春赛璐璐 × 温润水彩手帐 UI**。  
> **交付总量**：共 **32 张 RGBA 透明通道 PNG**（4 张怀表时段圆盘 + 3 张 HUD 面板 9-Slice + 7 张按钮与盖章 9-Slice + 5 张气泡/卡片 9-Slice + 3 张地图与角标 9-Slice + 10 张与现有金币/画笔同画风手绘小图标）。

---

## 一、画风基准与色板约定

请参考压缩包内 `04_Style_Anchors/` 中随附的项目已有成熟成品与参考图：
1. **暖纸手帐锚点**：[`paper_modal_9slice.png`](04_Style_Anchors/paper_modal_9slice.png) 与 [`dialogue_choice_9slice.png`](04_Style_Anchors/dialogue_choice_9slice.png) —— 干净温和的象牙奶白手帐纸感、清晰不过噪的边线、极简胶带/标签点缀。
2. **地图绘本锚点**：[`ui_map_pin_plates.png`](04_Style_Anchors/ui_map_pin_plates.png) —— 松石青/晴空蓝水彩细框配双片叶子手绘质感。
3. **手绘图标锚点**：[`icon_allowance.png`](04_Style_Anchors/icon_allowance.png) 与 [`icon_practice_points.png`](04_Style_Anchors/icon_practice_points.png) —— 饱和清澈、带柔和暖色轮廓的厚涂水彩赛璐璐小物件图标。
4. **标准色板**：
   - 主奶白纸面：`#FFFDF8` / `#FFFBF3`
   - 主题薄荷青：`#359686`（选中/确认/边线点缀）
   - 主强调珊瑚红：`#D45B49` -> `#E26A56`（赛事挑战/训练强化/地图引导）
   - 导航冰白蓝：`#F4F8FC` / 边框 `#B8C6D8`
   - 墨色正文：`#1E314D`（所有浅底按钮中间需足够均匀亮堂以承托深海军蓝文字）

---

## 二、五大铁律（避免返工）

1. **严禁烘焙任何文字、数字或图标进按钮/底板内**：
   - 所有中文标签、数字、角标与小图标全部由 Godot 在运行时动态叠加；所有 9-Slice 底板中间区域必须是**纯粹干净文字底面**。
2. **9-Slice 中心拉伸区严格保持水平与垂直均匀平滑**：
   - 凡 `02_asset_manifest_v14.json` 中标有 `nine_slice_margins`（如 `L=44 R=44 T=32 B=36`）的图片，位于中心 `[L .. W-R, T .. H-B]` 的像素会被引擎双向平铺/拉伸以适配任意宽高的按钮（如宽 `316px` 行动栏条、`188px` 小按钮、不同长度对话气泡）。
   - **因此严禁在中心区域画斜向光泽、大块不均匀水彩斑点或延伸跨过安全边界的小叶子/小胶带**；细小装饰只能落在固定不变的四角/侧缘 margin 之内。
3. **外轮廓投影不要被画布边缘截断**：
   - 按钮和胶囊四角外请留足 `8–16px` 透明柔影缓冲区（已计入目标画幅与 9-Slice margin）。
4. **必须输出非交错 8-bit RGBA PNG**：
   - 全部 32 项均须含真透明背景（`alpha = 0`），图标本体居中、占画布宽高约 `72%–82%`。
5. **不重复绘制已经表现很好的美术资源（已排除在本次需求之外）**：
   - `assets/ui_core/theme/paper_modal_9slice.png`（选拔赛、切换同伴弹窗暖纸底板 — 已定稿，后续也可直接复用到设置/休息确认弹窗）
   - `assets/ui/school_objects/story_chrome.png`（全游统一手帐对话条）
   - `assets/ui/school_objects/menu.png`（笔袋风系统菜单）
   - `assets/ui/player_experience/` 下的放映室幕布/手提卡匣工坊插画、16 张行动卡面与 12 张星座母卡

---

## 三、交付目录与零依赖验收命令

成品图请按 `02_asset_manifest_v14.json` 的 `target_path` 存放（如 `assets/ui_core/v14_ui/buttons/ui_btn_cel_primary_9slice.png`），交付前运行随包零依赖质检脚本：

```bash
python 06_Tools/qa_check_v14_ui.py <交付根目录或工程根目录> 02_asset_manifest_v14.json
```

全部 **32 项输出 `[PASS]`** 后合入工程，我们将通过 Godot `StyleBoxTexture` 统一切换接入全游控件并做 `1600×900` / `1600×720` 真机截图复验。
"""


def _prompts_md() -> str:
    lines = [
        "# IGA v14 全量 UI 控件、9-Slice 按钮与手绘图标提示词清单（共 32 项）",
        "",
        "> 制作时可随时对照 `03_Current_Screen_References/` 中的当前 Godot 实机截图（了解待替换控件实际排版位置）与 `04_Style_Anchors/` 中的现有锚点素材（对齐笔触与色彩浓度）。",
        "",
    ]
    group_titles = {
        "PeriodDial_HUD": "## 一、时段圆形仪表与主 HUD 框架底板（7 项）",
        "Buttons_9Slice": "## 二、核心赛璐璐 9-Slice 按钮与社团盖章（7 项）",
        "Bubbles_Cards": "## 三、对话气泡、商品/赛事列表卡与地图标题牌（5 项）",
        "Map_Atlas_Badges": "## 四、地区地图 / 巡回总图卡片与状态丝带微标（3 项）",
        "HandPainted_Icons": "## 五、水彩赛璐璐手绘系统与行动图标（10 项，对齐金币/画笔风格）",
    }
    current_group = ""
    for idx, item in enumerate(MANIFEST_ITEMS, 1):
        grp = str(item["group"])
        if grp != current_group:
            current_group = grp
            lines.append(group_titles.get(grp, grp))
            lines.append("")
        lines.append(f"### {idx:02d}. `{item['id']}`")
        lines.append(f"- **落库路径**：`{item['target_path']}`")
        lines.append(f"- **替换对象**：{item['replaces_ui']}")
        ns = item.get("nine_slice_margins")
        ns_text = (
            f" · **9-Slice 固定边距**：`left={ns['left']}, right={ns['right']}, top={ns['top']}, bottom={ns['bottom']}`（中心区域需严格均匀以支持拉伸）"
            if ns
            else " · 独立整图（无 9-Slice 拉伸）"
        )
        lines.append(
            f"- **尺寸与透明要求**：`{item['width']}×{item['height']}` · 8-bit RGBA PNG（透明像素 ≥ `{float(item['min_transparent_ratio']):.0%}`）{ns_text}"
        )
        lines.append(f"- **中文设计要求**：{item['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {item['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {item['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


def build_pack() -> None:
    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_ZIP.parent.mkdir(parents=True, exist_ok=True)

    # 1. Docs & Manifest
    (STAGING_DIR / "00_README_总控规范与9Slice交付标准.md").write_text(_readme_md(), encoding="utf-8")
    (STAGING_DIR / "01_全量UI与按钮需求清单及提示词_v14.md").write_text(_prompts_md(), encoding="utf-8")
    manifest_payload = {
        "version": "v14",
        "generated_date": "2026-11-19",
        "palette": {
            "ivory": "#FFFDF8",
            "card": "#FFFBF3",
            "teal": "#359686",
            "coral": "#D45B49",
            "ice": "#F4F8FC",
            "navy_ink": "#1E314D",
        },
        "items": MANIFEST_ITEMS,
    }
    (STAGING_DIR / "02_asset_manifest_v14.json").write_text(
        json.dumps(manifest_payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # 2. 03_Current_Screen_References (10 live captures showing flat code UI/buttons)
    screen_dest = STAGING_DIR / "03_Current_Screen_References"
    screen_dest.mkdir(parents=True, exist_ok=True)
    screen_names = [
        "02_home_club.png",
        "03_projection_records.png",
        "04_workshop.png",
        "05_campus_map.png",
        "06_world_atlas.png",
        "07_library_npc.png",
        "08_shop_npc.png",
        "09_shop_counter.png",
        "10_gym_qualifier.png",
        "13_rooftop.png",
    ]
    for name in screen_names:
        src = CAPTURE_DIR / name
        if not src.is_file():
            raise FileNotFoundError(f"Missing live screen reference: {src}")
        shutil.copy2(src, screen_dest / name)

    # 3. 04_Style_Anchors (existing game art + curator-approved UI references)
    anchor_dest = STAGING_DIR / "04_Style_Anchors"
    anchor_dest.mkdir(parents=True, exist_ok=True)
    existing_anchors = [
        ROOT / "assets/ui_core/theme/paper_modal_9slice.png",
        ROOT / "assets/ui_core/theme/dialogue_choice_9slice.png",
        ROOT / "assets/ui/region_maps/ui_map_pin_plates.png",
        ROOT / "assets/ui_core/icons/economy/icon_allowance.png",
        ROOT / "assets/ui_core/icons/economy/icon_practice_points.png",
    ]
    for src in existing_anchors:
        if not src.is_file():
            raise FileNotFoundError(f"Missing project style anchor: {src}")
        shutil.copy2(src, anchor_dest / src.name)

    ref_root = ROOT / "docs/references/2026-11-19-scene-ui-redesign"
    ref_files = [
        "02_UI控件与HUD布局/03_时段圆盘与左侧行动停靠栏_Potionomics.jpg",
        "02_UI控件与HUD布局/04_NPC头顶极简对话泡与角落定位HUD_P3R.jpg",
        "02_UI控件与HUD布局/05_左右功能停靠与人物视觉重心_重返未来1999.jpg",
        "03_交互窗口与商店选拔赛/01_商店左货架详情与右店员同屏融合_Potionomics.jpg",
        "03_交互窗口与商店选拔赛/03_选拔赛窗口_左战绩编组与右三轮对手卡_蔚蓝档案.png",
        "03_交互窗口与商店选拔赛/05_暖纸双栏功能弹窗排版_火山的女儿.jpg",
        "04_地图画风与导航/01_地区日程选点_左同伴与右横幅地标_蔚蓝档案.jpg",
        "04_地图画风与导航/03_清透水彩绘本世界质感_哆啦A梦牧场物语.jpg",
    ]
    for rel in ref_files:
        src = ref_root / rel
        if not src.is_file():
            raise FileNotFoundError(f"Missing curated UI reference: {src}")
        dst = anchor_dest / "curated_references" / src.name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)

    # 4. 06_Tools
    tools_dest = STAGING_DIR / "06_Tools"
    tools_dest.mkdir(parents=True, exist_ok=True)
    (tools_dest / "qa_check_v14_ui.py").write_text(QA_SCRIPT_BODY, encoding="utf-8")

    # 5. Zip archive
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
        "screen_refs": len(screen_names),
        "style_anchors": len(existing_anchors) + len(ref_files),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build_pack()
