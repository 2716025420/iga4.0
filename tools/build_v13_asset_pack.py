"""Build IGA v13 Layered Scene Reset Asset Brief Pack (archive/IGA_Asset_Pack_Brief_v13_Scene_Reset_Layered.zip)."""
from __future__ import annotations

import json
import shutil
import struct
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BLUEPRINT_DIR = ROOT / ".godot/v13_staging/03_Wireframe_Blueprints"
STAGING_DIR = ROOT / ".godot/v13_staging/pack_root"
ARCHIVE_ZIP = ROOT / "archive/IGA_Asset_Pack_Brief_v13_Scene_Reset_Layered.zip"

MANIFEST_ITEMS = [
    # Group A: Shared Sky Layers (Layer 0)
    {
        "id": "sky_arete_day_wide",
        "group": "Layer0_Sky",
        "target_path": "assets/ui/scene_reset/staged/shared/sky_arete_day_wide.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": False,
        "min_transparent_ratio": 0.0,
        "blueprint": "共用天空底图（全 7 处室内外场景共用）",
        "prompt_cn": "盛夏清透晴空，高饱和柔和蔚蓝天际渐变至淡青白地平线，几团蓬松干净的赛璐璐厚涂积云，右上保留轻微蔚蓝档案式极细白色几何光晕圆环，无任何建筑/地面/人物/文字。",
        "prompt_en": "Blue Archive style clean anime summer sky background only, crystal clear vibrant cerulean blue sky fading to pale cyan horizon, soft fluffy stylized cumulus clouds, subtle thin white concentric geometric sky rings faintly visible in upper sky, cel-shaded crisp anime background art, completely empty horizon, no buildings, no ground, no characters, no text, no watermarks, 21:9 wide composition",
        "negative_prompt": "photorealistic, gritty, noise, buildings, trees, people, text, UI, watermark, dark clouds, overcast",
    },
    {
        "id": "sky_arete_dusk_wide",
        "group": "Layer0_Sky",
        "target_path": "assets/ui/scene_reset/staged/shared/sky_arete_dusk_wide.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": False,
        "min_transparent_ratio": 0.0,
        "blueprint": "共用黄昏天空底图（旧公园黄昏之约主舞台与下午室外复用）",
        "prompt_cn": "清透温暖的夏日黄昏晚霞天空，顶部柔和靛蓝过渡到珊瑚橙红与暖琥珀金地平线，舒展洁净的晚霞云层带金边高光，无建筑无人物无文字。",
        "prompt_en": "Blue Archive style clean anime golden hour dusk sky background only, soft twilight indigo zenith blending smoothly into warm coral orange and amber gold horizon, stylized luminous sunset clouds, crisp clean cel-shaded anime illustration, no buildings, no ground, no characters, no text, 21:9 wide",
        "negative_prompt": "photorealistic, muddy brown, dark grim, buildings, trees, people, text, UI, watermark",
    },
    {
        "id": "sky_arete_redmoon_wide",
        "group": "Layer0_Sky",
        "target_path": "assets/ui/scene_reset/staged/shared/sky_arete_redmoon_wide.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": False,
        "min_transparent_ratio": 0.0,
        "blueprint": "共用夜空/红月天空底图（夜晚外出及红月预警阶段自动切换）",
        "prompt_cn": "清透深海蓝紫夜空，右上区域悬有一轮柔和却极具辨识度的暗绯红满月与细微数字光环晕染，薄雾星云清澈不浑浊，无建筑无人物无文字。",
        "prompt_en": "Blue Archive style clean anime night sky with soft crimson red moon, deep indigo midnight blue sky, subtle glowing crimson full moon positioned in upper-right sky with faint pale red atmospheric halo, clean scattered stars, crisp anime background painting, no buildings, no ground, no people, no text, 21:9 wide",
        "negative_prompt": "photorealistic, horror gore, muddy black, noisy grain, buildings, characters, text, UI",
    },

    # Group B: Layer 1 Clean Cel Midground Architecture & Paths (2340x1080 RGBA, transparent sky/window cutouts!)
    {
        "id": "rooftop_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/rooftop/rooftop_midground_wide.png",
        "blueprint": "BP_01_rooftop_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.22,
        "safe_zone_notes": "上方 y=0..418 天空区必须完全透明 (alpha=0) 以便透出 Layer 0；x=0..356（含左侧宽边）为程序左侧功能停靠栏区，仅放楼梯间背墙延伸；中区 x=860..1320 预留净地坪站位给 Slot A 同伴。",
        "prompt_cn": "严格对齐 BP_01 蓝图：蔚蓝档案清透日光赛璐璐风教学楼天台，极简洁净浅蓝白方形瓷砖地坪、通透蓝白金属网格护栏、左侧干净几何楼梯间铁门小屋与壁边白色校内饮料贩卖机、中景护栏外碧海与远处白色灯塔剪影。严禁地面脏污、锈斑、杂草和人物。",
        "prompt_en": "Blue Archive style clean anime school rooftop midground layer, transparent sky cutout above horizon (alpha 0 sky), crisp pale ice-blue and white square rooftop tiles, clean light-blue wire mesh safety railing, minimalist white stairwell cabin with metal door and tidy white beverage vending machine on left-mid, calm turquoise ocean bay with tiny white lighthouse on distant right horizon, wide open empty floor center-right for character standing, clean cel-shaded lines, bright airy summer light, zero rust, zero dirt, no characters, no text, 2340x1080",
        "negative_prompt": "sky painted opaque, rust, dirty concrete, cracks, photorealistic, weeds, foreground table, characters, people, text, UI",
    },
    {
        "id": "shop_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/shop/shop_midground_wide.png",
        "blueprint": "BP_02_shop_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.05,
        "safe_zone_notes": "严格对齐 BP_02 蓝图：右侧大采光窗 (1225..1835, 150..475) 玻璃窗格必须挖空为全透明 alpha=0；画面最下方 y=660..1080 的前景收银柜台由 Layer 3 单独制作，本层柜台后方保持干净墙面/货架底色，绝对不要画前景柜台与店员唐小满！",
        "prompt_cn": "严格对齐 BP_02 蓝图（参考 Angel 24）：正面微仰平视视角、奶油白配清透薄荷青校园小店室内后景。左中区为干净玻璃冷饮柜与文具货架；中央为原木货架与墨绿黑板菜单（不写可辨识文字）；右区为挖空透明玻璃的大采光窗与码放整齐的快递纸箱区。无前景柜台、无人物。",
        "prompt_en": "Blue Archive Angel 24 style clean bright school convenience store interior background only, straight front-facing eye-level perspective, cream white walls with pastel mint-teal ceiling trim, neat glass beverage cooler on left-center, warm light-wood display shelves and blank dark-green menu chalkboard in center, large sunlit storefront window on right with fully transparent glass pane (alpha 0 cutout), neatly stacked cardboard delivery boxes below right window, no foreground counter, no shopkeeper, no characters, no readable text, clean anime cel shading, 2340x1080",
        "negative_prompt": "foreground counter, cashier desk, shopkeeper, characters, messy cluttered shelves, photorealistic labels, readable words, angled fish-eye view, dark shadows",
    },
    {
        "id": "gym_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/gym/gym_midground_wide.png",
        "blueprint": "BP_03_gym_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.05,
        "safe_zone_notes": "严格对齐 BP_03 蓝图：顶部拱形高窗玻璃区 (y=0..165) 挖空透明；中左区域 (x=560..1150) 绘制清晰发光的蓝色护盾裁决擂台地坪圆环与上方悬浮赛事信息横幅/电子记分框（无具体字）；右侧 (x=1200..1580) 留出干净木地板承接 Slot A 柳宇龙，远右设训练战术白板。",
        "prompt_cn": "严格对齐 BP_03 蓝图：蔚蓝档案清透日光室内体育馆。顶部挑高拱形天窗玻璃区透明镂空；温暖洁净的浅枫木地板（无油腻反光）；中左区建有浅蓝发光科技感护盾裁决圆形擂台线与上方悬挂深蓝科技感电子赛事横幅（空白界面条不写字）；右墙设洁净战术白板与整齐器材架。无人物、无右下角长椅。",
        "prompt_en": "Blue Archive style bright sunlit indoor gymnasium midground, high arched clerestory windows along top (transparent alpha 0 glass cutouts), clean warm matte maple wood court floor without harsh glare, clean white and light-wood paneling walls, left-center glowing cyan circular Shield-Arbitration arena ring painted on floor with sleek dark-blue overhead digital tournament banner frame (blank glowing screen, no text), clean tactical whiteboard and tidy gym rack on far right wall, wide open floor space at right-center for character, crisp cel-shaded anime art, no foreground bench, no characters, no text, 2340x1080",
        "negative_prompt": "wet shiny floor glare, dark moody lighting, foreground bench, characters, athletes, readable text, logos, photorealistic",
    },
    {
        "id": "library_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/library/library_midground_wide.png",
        "blueprint": "BP_04_library_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.05,
        "safe_zone_notes": "严格对齐 BP_04 蓝图：彻底去除近景摊开巨书！中右大落地海景窗 (1095..1635, 130..620) 玻璃必须全透明镂空；左区后墙整齐书架承接前景林知夏 (Slot A)；中右落地窗前留空承接黄秋枫 (Slot B)；借书台与窗边书桌本身在 Layer 3 绘制。",
        "prompt_cn": "严格对齐 BP_04 蓝图：蔚蓝档案式三段开阔透视图书馆，清透原木与薄荷绿地面配色。挑高暖白木梁天花板；左区背景为整洁暖木服务区后方矮书架；中右区为一整面原木框落地大海景窗（玻璃完全透明镂空 alpha=0）；远右为挑高书架与白色期刊展示架。彻底禁止左下近景摊开大书、无前景桌子、无人物。",
        "prompt_en": "Blue Archive style bright sunlit school library interior background, spacious 3-zone perspective, soft mint-sage floor and cream walls, neat warm oak bookshelves behind left-center service wall, huge floor-to-ceiling wooden-framed window at center-right with fully transparent glass panes (alpha 0 cutout), tall bookshelves and clean white magazine rack on far right, zero foreground desks, zero giant close-up books, no librarians, no characters, no readable text, clean cel-shaded anime background, 2340x1080",
        "negative_prompt": "foreground desk, giant open book in foreground, characters, students, opaque sky in window, dark gloomy lighting, photorealistic, text",
    },
    {
        "id": "coast_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/coast/coast_midground_wide.png",
        "blueprint": "BP_05_coast_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.22,
        "safe_zone_notes": "严格对齐 BP_05 蓝图：上方天空 (y=0..480) 完全透明；右侧清透碧海与下行白色石阶通往阿瑞忒海滩；左侧开阔海滨木栈道+红枫掩映小径拱门通往旧公园；中左木栈道长椅旁留给 Slot A 站位。",
        "prompt_cn": "严格对齐 BP_05 蓝图：盛夏清透海滨沿海大道，一眼可读的 Y 字形双通道布局。上方天空全透明镂空；右侧为清澈碧蓝海面与远方青翠小岛、顺岸下行白色石阶（通海滩）；左侧为浅米色海滨大道与红枫掩映的林荫拐角石门（通旧公园）；中左设干净原木长椅与简洁双指向空白木路牌。无前景栏杆、无人物、无文字。",
        "prompt_en": "Blue Archive style bright summer coastal promenade midground, transparent sky above horizon (alpha 0), Y-junction dual path layout: on the left a stone park archway framed by clean stylized red maple trees leading off-road, on the right sparkling turquoise ocean and clean white stone stairs descending toward beach, neat pale paved promenade in center with a simple wooden bench and blank two-way directional signpost, crisp cel-shaded anime art, no foreground guardrail, no characters, no text, 2340x1080",
        "negative_prompt": "sky painted opaque, foreground railing, photorealistic gravel noise, messy power lines, characters, readable words, dark shadows",
    },
    {
        "id": "old_park_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/old_park/old_park_midground_wide.png",
        "blueprint": "BP_06_old_park_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.16,
        "safe_zone_notes": "严格对齐 BP_06 蓝图：树冠间隙上方天空镂空透明以便程序动态切黄昏/红月夜；中景正中 (x=880..1380) 留空放长椅与 Slot B 黄秋枫（长椅本身由 Layer 3 拆层遮挡）；右侧街角 (x=1520..1720, y=380..760) 必须清晰绘制一座醒目发光的橘子汽水自动贩卖机！",
        "prompt_cn": "严格对齐 BP_06 蓝图：干净赛璐璐化校外旧公园庭院，上方树影间天空全透明镂空。整洁浅米石板公园广场与柔和秋草地，上方环抱造型简化舒展的红枫与金黄银杏树冠（降低碎叶噪点），中后设复古深灰铁艺矮围栏；右侧街角立着一座清晰明亮、灯箱呈暖橙色的自动贩卖机（呼应橘子汽水剧情道具）。中央长椅位置留空交由 Layer 3 叠放、无人物、无文字。",
        "prompt_en": "Blue Archive style clean quiet autumn old park courtyard midground, transparent sky visible above and between stylized tree canopies (alpha 0 sky), neat pale stone plaza and soft sage lawn, simplified clean cel-shaded red maple and golden ginkgo trees with crisp silhouette (no noisy leaf scatter), classic low wrought-iron fence in back, prominent glowing warm-orange beverage vending machine standing at right corner (x around 75% right), empty central plaza space reserved for bench and character, no park bench, no characters, no text, 2340x1080",
        "negative_prompt": "park bench in center, sky painted opaque, photorealistic noisy leaves, muddy dark brown, characters, readable text, watermarks",
    },
    {
        "id": "beach_midground_wide",
        "group": "Layer1_Midground",
        "target_path": "assets/ui/scene_reset/staged/beach/beach_midground_wide.png",
        "blueprint": "BP_07_beach_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.22,
        "safe_zone_notes": "严格对齐 BP_07 蓝图：海平面以上天空 (y=0..470) 全透明镂空；柔和干净米白沙滩 + 透明浅蓝海浪白沫；左侧延伸木栈桥端头留出 Slot A 站位；右侧防波堤白色石阶通回沿海公路。",
        "prompt_cn": "严格对齐 BP_07 蓝图：清透盛夏蔚蓝档案风海滩。海平线以上天空完全透明镂空；透明浅蓝渐层海水与洁净白色浪花拍打暖米色细沙滩；左中区建有一段干净平直的原木栈桥端头；远右侧有返回公路的白色石阶防波堤。彻底干净留白、无垃圾杂物、无前景护栏、无人物。",
        "prompt_en": "Blue Archive style bright clean summer beach midground, transparent sky above ocean horizon (alpha 0), crystal clear turquoise ocean waves with crisp white seafoam washing onto smooth pale cream sand, neat flat wooden pier deck extending from left-center over water, white stone breakwater steps on far right side, generous clean sand foreground for characters, crisp anime cel-shaded art, no foreground railing, no characters, no trash, no text, 2340x1080",
        "negative_prompt": "sky painted opaque, foreground railing, messy footprints, dark wet sand, rocks cluttering center, characters, text, photorealistic",
    },

    # Group C: Layer 3 True-Alpha Foreground Occluders (2340x1080 RGBA, >=50-60% transparent!)
    {
        "id": "rooftop_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/rooftop/rooftop_foreground_wide.png",
        "blueprint": "BP_01_rooftop_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.60,
        "safe_zone_notes": "透明遮罩层（>80% 透明）：仅在右下角 (x=1400..1920, y=770..1080) 绘制近景干净原木遮阳桌边沿与桌面小道具（如冰镇橘子汽水罐/素描本），其余全画布保持 100% 透明 (alpha=0)。",
        "prompt_cn": "真透明 PNG 前景层（其余背景全透明）：仅在画面右下角绘制近景洁净浅色原木天台方桌桌面边沿与一只橘子汽水罐，用于自然增加场景纵深，画面其余 85% 以上区域必须完全透明。",
        "prompt_en": "Isolated foreground rooftop wooden table corner on bottom-right only, transparent background (alpha 0 everywhere else), clean light-oak table edge with a small orange soda can sitting on it, crisp Blue Archive anime cel shading matching bright daylight, over 85% pure transparent empty space, no sky, no floor, no characters, 2340x1080",
        "negative_prompt": "opaque background, white background, sky, floor, buildings, characters, text",
    },
    {
        "id": "shop_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/shop/shop_foreground_wide.png",
        "blueprint": "BP_02_shop_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.50,
        "safe_zone_notes": "最关键前景遮罩层！y=0..659 必须 100% 透明 (alpha=0)，以便透出背后货架与腰部以上的唐小满！仅在 y=660..1080 横跨全宽绘制 Angel 24 式浅暖原木/奶油白收银台面，并在 x=1000..1120 放一台干净收银小屏、x=1650..1780 放橘子汽水展示瓶/零钱托盘。",
        "prompt_cn": "严格对齐 BP_02 蓝图（参考 Angel 24 前景柜台）：真透明 PNG 前景收银台层！画面上半部 y=0..659 必须完全透明 (alpha=0)；仅在下方 y=660..1080 绘制横跨全画面的正面平视暖木+奶油白便利店收银前台，台面左侧放一台小型白色平板收银机，右侧摆两瓶亮色橘子汽水展示瓶与招财小牌。严禁出现店员或背景货架！",
        "prompt_en": "Isolated foreground convenience store checkout counter only at bottom y=660..1080, upper 61% of image completely transparent (alpha 0), straight front-facing eye-level perspective matching Angel 24 style, clean warm light-wood tabletop with cream front paneling, compact white POS tablet screen at left-center of counter and two bright orange soda display bottles on far right of counter, crisp anime cel shading, no shopkeeper, no background shelves, no readable text, 2340x1080",
        "negative_prompt": "opaque background, white backdrop, shopkeeper, Tang Xiaoman, background shelves, walls, readable text, photorealistic",
    },
    {
        "id": "gym_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/gym/gym_foreground_wide.png",
        "blueprint": "BP_03_gym_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.60,
        "safe_zone_notes": "透明前景层（>80% 透明）：仅在右下角 (x=1470..1900, y=755..1080) 绘制近景木质整备长椅与一只闭合深蓝战术卡匣手提箱，其余全透明，不遮挡中央擂台与柳宇龙。",
        "prompt_cn": "真透明 PNG 前景层：仅在右下角绘制近景暖原木整备长椅一角，上面放着一只深蓝配亮青线涂装的折叠战术卡匣手提箱；其余 85% 以上区域必须完全透明。",
        "prompt_en": "Isolated foreground wooden gym bench corner on bottom-right only with a sleek dark-blue tactical card case resting on it, completely transparent background (alpha 0 everywhere else), crisp Blue Archive anime cel shading, over 85% pure transparent space, no gym floor, no walls, no characters, 2340x1080",
        "negative_prompt": "opaque background, white background, gym floor, walls, characters, text",
    },
    {
        "id": "library_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/library/library_foreground_wide.png",
        "blueprint": "BP_04_library_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.60,
        "safe_zone_notes": "重要前景双桌遮罩层！① 左中 x=455..1005, y=670..1080 绘制低矮弧形原木借书接待台（遮住林知夏下半身）；② 右中 x=1150..1680, y=720..1080 绘制干净原木自习桌桌面与桌腿（自然遮住 Slot B 黄秋枫下半身）；其余全画布 100% 透明！",
        "prompt_cn": "严格对齐 BP_04 蓝图：真透明 PNG 前景双桌层！① 左中区 (x=455..1005, y=670..1080) 绘制低矮干净的原木弧形借书台，台面放一册精装借书登记簿；② 右中区 (x=1150..1680, y=720..1080) 绘制一张透视一致的洁净原木双人阅读自习桌。其余全部区域必须完全透明 (alpha=0)，绝不能遮住上半身立绘位！",
        "prompt_en": "Isolated foreground library wooden desks only on transparent background (alpha 0 everywhere else): on left-center (x 28%-48%, y 62%-100%) a curved warm oak library circulation desk with a small closed register book on top; on right-center (x 58%-80%, y 67%-100%) a clean warm oak student reading table. Over 65% pure transparent empty space, no bookshelves, no walls, no characters, crisp Blue Archive anime cel shading, 2340x1080",
        "negative_prompt": "opaque background, white background, walls, bookshelves, librarians, characters, giant open book, text",
    },
    {
        "id": "coast_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/coast/coast_foreground_wide.png",
        "blueprint": "BP_05_coast_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.60,
        "safe_zone_notes": "透明前景层：仅在右下缘 (x=1040..2130, y=805..1080) 绘制一段干净斜向延伸的白色海滨铁艺安全护栏（不挡中心站位）。",
        "prompt_cn": "真透明 PNG 前景层：仅在画面右下角绘制一小段清爽洁白的金属海滨安全护栏横杆与立柱，其余 85% 以上画布完全透明。",
        "prompt_en": "Isolated foreground crisp white painted coastal metal safety guardrail at bottom-right edge only, completely transparent background (alpha 0 everywhere else), clean anime cel shading in bright sunlight, over 85% transparent empty space, no ocean, no road, no characters, 2340x1080",
        "negative_prompt": "opaque background, ocean, road, sky, characters, rust, text",
    },
    {
        "id": "old_park_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/old_park/old_park_foreground_wide.png",
        "blueprint": "BP_06_old_park_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.60,
        "safe_zone_notes": "透明前景长椅层：在中央偏右 (x=885..1390, y=718..1080) 绘制面向后方/斜侧、带木质横条靠背与深灰铸铁扶手的复古公园长椅前景，可自然压住立于长椅后的黄秋枫下身！",
        "prompt_cn": "严格对齐 BP_06 蓝图：真透明 PNG 前景长椅层！仅在画面中下 x=885..1390, y=718..1080 绘制一张干净温润的复古红木条+铸铁扶手公园长椅前景（椅背高度停在 y=725，使站在椅后的少女腰部以上完整露出），其余 80% 以上画面必须完全透明。",
        "prompt_en": "Isolated foreground classic wooden slatted park bench with dark wrought-iron armrests centered around x 47%-68%, y 66%-100%, completely transparent background (alpha 0 everywhere else), clean anime cel shading, warm sunset-friendly wood tone, over 80% pure transparent empty space, no trees, no ground, no characters, 2340x1080",
        "negative_prompt": "opaque background, ground, trees, sky, characters, people, photorealistic, text",
    },
    {
        "id": "beach_foreground_wide",
        "group": "Layer3_Foreground",
        "target_path": "assets/ui/scene_reset/staged/beach/beach_foreground_wide.png",
        "blueprint": "BP_07_beach_2340x1080.png",
        "width": 2340,
        "height": 1080,
        "requires_alpha": True,
        "min_transparent_ratio": 0.60,
        "safe_zone_notes": "透明前景层：仅在左下前景 (x=380..940, y=790..1080) 绘制洁净原木栈桥低矮木护栏柱与麻绳，其余全透明。",
        "prompt_cn": "真透明 PNG 前景层：仅在左下角前景绘制一段干净的浅色原木海滨栈桥木柱与绳索护栏，其余 85% 以上区域完全透明。",
        "prompt_en": "Isolated foreground wooden pier railing posts and rope on bottom-left edge only, completely transparent background (alpha 0 everywhere else), clean Blue Archive anime cel shading, over 85% transparent empty space, no sand, no ocean, no sky, no characters, 2340x1080",
        "negative_prompt": "opaque background, ocean, sand, sky, characters, text",
    },
]

QA_SCRIPT_BODY = '''"""Zero-dependency PNG verification tool for IGA v13 Layered Scene Assets."""
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
    if data[:8] != b"\\x89PNG\\r\\n\\x1a\\n":
        raise ValueError("Not a valid PNG file")
    pos = 8
    width = height = bit_depth = color_type = 0
    idat_parts = []
    while pos + 8 <= len(data):
        length, ctype = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, comp, flt, interlace = struct.unpack(">IIBBBBB", chunk)
            if interlace != 0:
                raise ValueError("Interlaced PNG not supported for fast QA; please export non-interlaced PNG")
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
        print("Usage: python qa_check_v13_layers.py <project_or_delivery_root> [manifest_json]")
        return 0
    target_root = Path(sys.argv[1]).resolve()
    manifest_path = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else (Path(__file__).resolve().parents[1] / "02_asset_manifest_v13.json")
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
    return """# IGA v13 场景重置分层素材需求总控规范（已拍板执行版）

> **编制日期**：2026-11-19  
> **总纲依据**：主创已拍板 6 项核心决策 + Godot 实机验证通过的 5 层模块化舞台底座（`SceneStageLayers`）与 03 左侧停靠栏（`SceneHUDLayout`）  
> **交付规模**：共 **17 张** 精准分层 `2340×1080` PNG（3 张共用天空层 + 7 张干净赛璐璐中景层 + 7 张真透明前景遮挡层）

---

## 一、主创已拍板的 4 大核心视觉铁律

1. **画风定调（蔚蓝档案清透日光赛璐璐）**：
   - 彻底告别旧图灰暗、锈渍、写实木纹与高频碎叶噪点；
   - 色面干净明快、线条暖褐/冷灰柔和、留足 **35% 以上视觉留白**，与现行角色立绘（唐小满/林知夏/黄秋枫/柳宇龙/杨子英）自然融合。
2. **严禁烘焙人物、文字与 UI 按钮**：
   - 本次只需交付纯背景/前景分层 PNG，**所有角色立绘、对话气泡、行动按钮、菜单与标题栏均由 Godot 引擎实时挂载与渲染**；
   - 黑板、赛事电子横幅、路牌表面必须保持洁净空白设计感（不得生成乱码或英文单词）。
3. **2340×1080 统一画幅与严格安全区对齐**：
   - 全部 17 张 PNG **强制统一输出 `2340×1080`（8-bit sRGB，non-interlaced）**；
   - 其中居中 **`[x: 210..2130, y: 0..1080]`（宽 `1920`）为 16:9 核心安全区**，左右各 `210px` 为 20:9 宽屏无缝自然延展边；
   - **左侧 `x: 0..566`（即安全区 `0..356` + 左延展 `210px`）由程序半透行动停靠栏常驻覆盖**，严禁把主要NPC槽位或关键道具放进此区；
   - **右上安全区 `x: 1294..2102, y: 24..92`** 为程序资源与地图/菜单条，中景上方对应区域保持简洁背景或留白。
4. **严格执行 5 层透明通道规范（消除“立绘悬浮剪纸感”）**：
   - **Layer 0（3 张共用天空）**：RGB/RGBA 均可，纯天空+云彩+红月，无前景地物；
   - **Layer 1（7 张中景）**：**必须带真透明通道（RGBA PNG）**：
     - 4 处户外场景（天台/沿海/旧公园/海滩）地平线/树冠以上天空必须 **完全镂空（`alpha = 0`）**；
     - 3 处室内场景（商店大窗、图书馆海景落地窗、体育馆拱形天窗）玻璃区域必须 **完全镂空（`alpha = 0`）**，以便引擎 `Layer 0` 实时切昼/黄昏/红月夜；
   - **Layer 3（7 张前景遮挡层）**：**必须带真透明通道（RGBA PNG）**，且透明像素占比达到 **50%–85%+**（除前景柜台/借书台/长椅/护栏自身外全图 `alpha = 0`），用于在引擎 `Layer 2` 立绘前方直接遮住人物腰部以下！

---

## 二、压缩包目录结构说明

- `00_README_总控规范与交付标准.md`（本文件）
- `01_分场景详细需求与提示词_v13.md`（17 张素材的中文要点 + 英文 Prompt + Negative Prompt + 像素位置要求）
- `02_asset_manifest_v13.json`（机器可读清单：目标落库路径、分辨率、Alpha 与透明占比阈值）
- `03_Wireframe_Blueprints/`（**Godot 4.7.2 实机导出的 7 张 `2340×1080` 1:1 像素对齐蓝图**，已含 Slot A/B 实机角色比例参考与红框安全区，可直接垫在画板最底层做 ControlNet / 图生图 / 手绘线稿对齐！）
- `04_Style_References/`（主创审定采用的画风、柜台构图与 HUD 参考图）
- `05_Character_Scale_References/`（唐小满/林知夏/黄秋枫/柳宇龙/杨子英 原生立绘，供校对赛璐璐线宽、饱和度与头身透视）
- `06_Tools/qa_check_v13_layers.py`（零依赖自动质检工具：交付前运行可逐张核查分辨率与透明通道占比）

---

## 三、交付目录结构与自动质检命令

请按 `02_asset_manifest_v13.json` 中 `target_path` 原样目录落位后打包，或在本地工程根目录运行：

```bash
python 06_Tools/qa_check_v13_layers.py <交付根目录或工程根目录> 02_asset_manifest_v13.json
```

全部 17 项输出 `[PASS]` 后即可直接合入工程 `assets/ui/scene_reset/staged/`，无需修改代码即可自动生效！
"""


def _prompts_md() -> str:
    lines = [
        "# IGA v13 分场景详细素材需求与提示词清单（共 17 张）",
        "",
        "> 使用前请务必对照 `03_Wireframe_Blueprints/` 内对应 `2340×1080` 蓝图垫底对齐坐标（红色外框为 1920×1080 安全区，蓝阴影为程序 HUD 占用区，绿/红框为 NPC 槽位，橙色区为 Layer 3 前景遮挡）。",
        "",
    ]
    current_group = ""
    group_titles = {
        "Layer0_Sky": "## 一、Layer 0 共用天空层（3 张，2340×1080）",
        "Layer1_Midground": "## 二、Layer 1 干净赛璐璐中景与地坪路径层（7 张，2340×1080 RGBA 透明镂空）",
        "Layer3_Foreground": "## 三、Layer 3 真透明前景遮挡层（7 张，2340×1080 RGBA，≥50%–85% 透明）",
    }
    for idx, item in enumerate(MANIFEST_ITEMS, 1):
        grp = str(item["group"])
        if grp != current_group:
            current_group = grp
            lines.append(group_titles.get(grp, grp))
            lines.append("")
        lines.append(f"### {idx:02d}. `{item['id']}`")
        lines.append(f"- **落库路径**：`{item['target_path']}`")
        lines.append(f"- **对照蓝图**：`{item['blueprint']}`")
        alpha_desc = f"必须 RGBA 真透明（最低透明占比 ≥ {float(item['min_transparent_ratio']):.0%}）" if item["requires_alpha"] else "RGB 或 RGBA 均可（不透明整图）"
        lines.append(f"- **像素与通道**：`{item['width']}×{item['height']}` · {alpha_desc}")
        if item.get("safe_zone_notes"):
            lines.append(f"- **构图与安全区要点**：{item['safe_zone_notes']}")
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

    # 1. Docs & Manifest
    (STAGING_DIR / "00_README_总控规范与交付标准.md").write_text(_readme_md(), encoding="utf-8")
    (STAGING_DIR / "01_分场景详细需求与提示词_v13.md").write_text(_prompts_md(), encoding="utf-8")
    manifest_payload = {
        "version": "v13",
        "generated_date": "2026-11-19",
        "canvas": {"width": 2340, "height": 1080, "safe_16_9_rect": [210, 0, 1920, 1080], "left_hud_x_end": 566},
        "items": MANIFEST_ITEMS,
    }
    (STAGING_DIR / "02_asset_manifest_v13.json").write_text(
        json.dumps(manifest_payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # 2. 03_Wireframe_Blueprints (7 PNGs from Godot export)
    bp_dest = STAGING_DIR / "03_Wireframe_Blueprints"
    bp_dest.mkdir(parents=True, exist_ok=True)
    bp_files = sorted(BLUEPRINT_DIR.glob("BP_*_2340x1080.png"))
    if len(bp_files) != 7:
        raise RuntimeError(f"Expected 7 exported blueprints in {BLUEPRINT_DIR}, found {len(bp_files)}")
    for f in bp_files:
        shutil.copy2(f, bp_dest / f.name)

    # 3. 04_Style_References
    ref_root = ROOT / "docs/references/2026-11-19-scene-ui-redesign"
    ref_dest = STAGING_DIR / "04_Style_References"
    selected_refs = [
        *[f"01_场景画风与空间构图/{p.name}" for p in sorted((ref_root / "01_场景画风与空间构图").glob("*")) if p.suffix.lower() in (".jpg", ".png", ".webp")],
        "02_UI控件与HUD布局/03_时段圆盘与左侧行动停靠栏_Potionomics.jpg",
        "02_UI控件与HUD布局/04_NPC头顶极简对话泡与角落定位HUD_P3R.jpg",
        "02_UI控件与HUD布局/05_左右功能停靠与人物视觉重心_重返未来1999.jpg",
        "03_交互窗口与商店选拔赛/01_商店左货架详情与右店员同屏融合_Potionomics.jpg",
        "03_交互窗口与商店选拔赛/03_选拔赛窗口_左战绩编组与右三轮对手卡_蔚蓝档案.png",
    ]
    for rel in selected_refs:
        src = ref_root / rel
        if not src.is_file():
            raise FileNotFoundError(f"Missing style reference: {src}")
        dst = ref_dest / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)

    # 4. 05_Character_Scale_References
    char_dest = STAGING_DIR / "05_Character_Scale_References"
    char_dest.mkdir(parents=True, exist_ok=True)
    char_sources = [
        ROOT / "assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png",
        ROOT / "assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_neutral.png",
        ROOT / "assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png",
        ROOT / "assets/sprites/characters/phase_two/fullbody/liu_yu_long.png",
        ROOT / "assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png",
    ]
    for src in char_sources:
        if not src.is_file():
            raise FileNotFoundError(f"Missing character reference: {src}")
        suffix = "halfbody" if "halfbody" in str(src) else "fullbody"
        shutil.copy2(src, char_dest / f"{suffix}_{src.name}")

    # 5. 06_Tools
    tools_dest = STAGING_DIR / "06_Tools"
    tools_dest.mkdir(parents=True, exist_ok=True)
    (tools_dest / "qa_check_v13_layers.py").write_text(QA_SCRIPT_BODY, encoding="utf-8")

    # 6. Pack into ZIP cleanly
    if ARCHIVE_ZIP.exists():
        ARCHIVE_ZIP.unlink()
    file_count = 0
    with zipfile.ZipFile(ARCHIVE_ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for path in sorted(STAGING_DIR.rglob("*")):
            if path.is_file():
                arcname = path.relative_to(STAGING_DIR).as_posix()
                zf.write(path, arcname)
                file_count += 1

    print(json.dumps({
        "zip_path": str(ARCHIVE_ZIP),
        "zip_bytes": ARCHIVE_ZIP.stat().st_size,
        "entries": file_count,
        "manifest_items": len(MANIFEST_ITEMS),
        "blueprints": len(bp_files),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build_pack()
