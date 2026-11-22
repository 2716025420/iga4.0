"""Build v20 Asset Brief Pack for Chapter 1 Library Encounter (school_affairs.md): 28 items + refs + zero-dep QA."""
from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGING_DIR = ROOT / ".godot" / "v20_staging" / "pack_root"
ARCHIVE_ZIP = ROOT / "archive" / "IGA_Asset_Pack_Brief_v20_Library_Encounter.zip"
SCRIPT_SRC = ROOT / "docs" / "story" / "user_write" / "school_affairs.md"

CHAR_STYLE_TAIL = (
    "matching IGA (Inorganic General Alien) official anime character art style: "
    "delicate crisp dark-brown linework, clean soft cel-shading with subtle warm morning rim highlights, "
    "3-5 large cohesive hair mega-clumps with closed tips and zero stray floating dots, "
    "male masculinity rule (clean angular jaw and chin, horizontal slim eyes, flat low brows, "
    "NO pink/purple lower-eyelid blush or eyeshadow, NO dense lower eyelashes, NO glossy feminine lips), "
    "isolated single waist-up character on pure transparent RGBA background with generous breathing margin, "
    "zero background scenery, zero text, zero watermarks"
)

CHAR_NEG = (
    "background scenery, solid white box, opaque background, multiple characters, text, letters, UI, "
    "feminine eyelashes, pink lower-eyelid blush, glossy lips, floating stray hair dots, extra fingers, "
    "distorted hands, stretched proportions, photorealistic, harsh muddy black shadows, watermark"
)

SILHOUETTE_STYLE_TAIL = (
    "matching IGA (Inorganic General Alien) bright coastal anime visual novel bystander silhouette style: "
    "soft cool misty slate-indigo and pale blue-grey two-tone cel-shaded faceless student figure "
    "(smooth gradient silhouette with clean crisp edge linework and subtle warm morning sunlight rim highlight, "
    "completely blank faceless head with ZERO eyes, ZERO eyebrows, ZERO nose, ZERO mouth), "
    "3-5 clean cohesive hair silhouette clumps, recognizable Arete school uniform silhouette, "
    "NOT a harsh solid pitch-black cutout, isolated single waist-up figure on pure transparent RGBA background "
    "with generous breathing margin, zero background scenery, zero text, zero watermarks"
)

SILHOUETTE_NEG = (
    "eyes, pupils, eyebrows, mouth, lips, nose, detailed facial features, harsh solid pitch-black cutout, "
    "stick figure, background scenery, solid white box, opaque background, multiple characters, text, UI, "
    "extra fingers, distorted anatomy, photorealistic, watermark"
)

SCENE_CLEAN_TAIL = (
    "matching IGA bright coastal anime campus background style (Blue Archive sunlit morning clarity blended with "
    "warm nostalgic anime film atmosphere), crisp architectural perspective, clean readable surfaces, "
    "zero characters, zero people, zero UI panels, zero dialogue boxes, zero text, zero watermarks"
)

SCENE_CLEAN_NEG = (
    "characters, people, students, anime girls, anime boys, UI buttons, dialogue box, HUD, speech bubble, "
    "text, readable letters, Chinese characters, watermarks, photorealistic photo noise, muddy grunge"
)

THUG_NEW_EMOTIONS = [
    {
        "char_id": "thug_boss",
        "name": "小混混老大",
        "appearance_cn": (
            "严格延续 `04_Character_And_Style_References/thug_boss_neutral.png` 定稿外貌："
            "17-18岁身形宽厚结实的校园混混头目，深红褐偏黑微翘飞机短背头（3-5组闭合大发束），浓粗平直眉配琥珀深眼眸；"
            "阿瑞忒男生灰蓝西装校服外套披肩（左胸校徽）、领口敞开的白衬衫、内搭深灰T恤与深棕长裤金扣皮带。"
        ),
        "appearance_en": (
            "strictly matching the finalized thug_boss_neutral.png design: broad-shouldered teenage delinquent boss boy around 18, "
            "swept-back dark reddish-black pompadour hair in 3-5 clean solid clumps, thick flat brows, sharp amber eyes, "
            "wearing Arete slate-blue school blazer draped over shoulders (crest on left chest), open-collar off-white shirt over dark charcoal tee, dark trousers with gold-buckled belt"
        ),
        "extra_neg": "holding card, playing card, trading card, poker card, glowing card, holding paper, holding object in hand",
        "emotions": [
            (
                "dazed",
                "恍惚 / 败北失神",
                "因为所有卡牌都在决斗中输光而灵魂出窍般恍惚：双眼微微失焦发直、眉毛微耷、嘴巴微张呆滞（或带一丝漫画式魂魄飘散晕眩感），披肩校服略显垮塌、双手空空垂放或无力摊开，【双手必须完全空无一物，严禁手中拿着任何卡牌或道具】。",
                "comical shell-shocked dazed blank stare after losing every single card: unfocused half-lidded eyes, slightly slack open mouth, drooping shoulders with blazer slipping slightly, BOTH HANDS COMPLETELY EMPTY hanging limply or weakly open (ZERO cards in hands)",
            ),
            (
                "rally",
                "燃志 / 输光仍挺胸宣言",
                "『哪怕输掉裤头，只要挺起胸膛，也没有什么大不了的，总有一天连你的那份我也会抢回来的欧啦！』"
                "一扫颓废、骤然燃起滑稽热血：挺起胸膛昂首挺胸、眼神重新亮起倔强斗志、咧嘴自信大喊，一手豪迈拍在自己胸口或叉腰、另一手空拳举起蓄势，【双手必须完全空无一物，严禁手中出现任何卡牌】。",
                "sudden comical hot-blooded rallying pose: chest puffed out proudly, chin raised with determined blazing amber eyes and bold shouting grin, one empty hand thumping his own chest or on hip while the other empty fist is raised forward in fiery resolve, BOTH HANDS COMPLETELY EMPTY (ZERO cards)",
            ),
        ],
    },
    {
        "char_id": "thug_grunt",
        "name": "小混混",
        "appearance_cn": (
            "严格延续 `04_Character_And_Style_References/thug_grunt_neutral.png` 定稿外貌："
            "17岁精瘦跟班男高中生，短刺微翘栗棕碎发（3-5组闭合大发束），棕褐色眼眸、左颧骨小创可贴/蹭痕；"
            "敞开的阿瑞忒男生灰蓝校服西装外套（金扣与胸徽）、松散酒红斜纹领带、略乱灰白衬衫与右手腕黑色运动电子表；双手空空如也。"
        ),
        "appearance_en": (
            "strictly matching the finalized thug_grunt_neutral.png design: slim teenage delinquent sidekick boy around 17, "
            "short spiky warm chestnut-brown hair in 3-5 clean mega-clumps, brown eyes, tiny cheek mark, "
            "wearing unbuttoned Arete slate-blue school blazer with gold buttons and crest over untucked off-white shirt with loosened burgundy striped tie, black sport wristwatch on right wrist; empty hands with ZERO cards"
        ),
        "extra_neg": "holding card, trading card, paper in hand",
        "emotions": [
            (
                "crying",
                "哭泣 / 败光卡牌崩溃",
                "『呜哇哇…辛辛苦苦半年努力的欺软怕硬，都白费了』："
                "紧皱八字眉、双眼挤出漫画式亮晶晶大颗泪水（保持硬朗少年骨骼感，勿画成少女泪眼）、张嘴哭嚎，双手抬起抓扯前襟或捂脸崩溃。",
                "comical dramatic bawling tears after losing all cards: squeezed eyebrows, big anime tears streaming down cheeks (keeping masculine jaw and face structure), wide crying mouth, empty hands clutching shirt collar or wiping face in despair",
            ),
            (
                "moved",
                "抹泪 / 崇拜老大",
                "『（抹干净眼泪）超帅的老大~，我给老大丢脸了！』："
                "用一手手背或袖口抹去眼角余泪，眼眶微红却闪烁崇拜敬仰的亮光、露出憨厚又热血的傻笑，另一手握拳竖起准备追随老大『欧呜~啦！』。",
                "wiping remaining tears from eyes with one sleeve or back of hand while looking upward in glowing comical admiration and goofy loyal grin, other empty fist raised enthusiastically",
            ),
        ],
    },
]

PASSERBY_SPECS = [
    {
        "char_id": "passerby_male",
        "name": "路人剪影男",
        "appearance_cn": (
            "阿瑞忒学院清晨路过的普通男学生背景剪影："
            "柔和雾靛青至冷灰蓝渐变赛璐璐平涂轮廓（非死黑剪纸块），清爽短发男高中生身形、身穿阿瑞忒男式西装校服与斜挎书包轮廓，头部完全无五官（零眼鼻嘴）。"
        ),
        "appearance_en": (
            "ordinary male Arete academy student background silhouette: two-tone cool misty slate-indigo to pale blue-grey cel-shaded figure, "
            "neat short-haired teenage boy outline wearing Arete male school blazer silhouette with shoulder bookbag strap, completely blank faceless head"
        ),
        "emotions": [
            (
                "neutral",
                "平静 / 通用日常路人剪影",
                "自然站立或缓步走过的通用剪影姿态，单肩背着学生包轮廓、双臂自然微摆，可反复用于校园/街道日常围观场景。",
                "calm natural standing or walking three-quarter waist-up silhouette with shoulder bag strap, reusable universal campus bystander pose",
            ),
            (
                "worried",
                "担忧 / 嫌弃避让（『好可怕…走远点…』）",
                "看到混混大喊『欧呜~啦！』时身体微向侧后方避让退缩，一手护在包带或胸前、肩背微紧缩，无五官头部微侧避开视线。",
                "slightly recoiling and leaning back sideways as if avoiding rowdy troublemakers, one hand guarding shoulder bag strap, blank faceless head turned slightly away in unease",
            ),
        ],
    },
    {
        "char_id": "passerby_female",
        "name": "路人剪影女",
        "appearance_cn": (
            "阿瑞忒学院清晨路过的普通女学生背景剪影："
            "柔和雾靛青至冷灰蓝渐变赛璐璐平涂轮廓（非死黑剪纸块），齐肩微卷或中短发女高中生身形、身穿阿瑞忒女式水手领/西装校服与手提书包轮廓，头部完全无五官（零眼鼻嘴）。"
        ),
        "appearance_en": (
            "ordinary female Arete academy student background silhouette: two-tone cool misty slate-indigo to pale blue-grey cel-shaded figure, "
            "shoulder-length or bob-cut teenage girl outline wearing Arete female sailor-collar school uniform silhouette, completely blank faceless head"
        ),
        "emotions": [
            (
                "neutral",
                "平静 / 通用日常路人剪影",
                "优雅自然的清晨通学站姿，双手轻抱课本或提包在身前，可反复用于校园各处日常背景对话场景。",
                "calm natural morning student standing waist-up silhouette lightly holding a book or tote strap, reusable universal female bystander pose",
            ),
            (
                "worried",
                "担忧 / 嫌弃远离（『好恶心…走远点…』）",
                "微微偏头向一侧后退半步，一手轻掩下颌或抱紧书本防备、肩颈微耸起，无五官剪影姿态传达『快走远点』的嫌弃避让感。",
                "taking a slight step back and tilting blank faceless head away in disgust/avoidance, hugging book close to chest or raising one hand near collar defensively",
            ),
        ],
    },
]

CONCEPT_SPECS = [
    {
        "id": "concept_ch1_01_library_path_thugs",
        "title": "分镜1整页概念母图 · 林荫小路遇败北混混（`ch1_library_path`）",
        "scene_ref": "exploration_campus.png + 26_prologue_thugs.png + story_chrome.png",
        "desc_cn": (
            "清晨海风微凉的阿瑞忒校内树荫小路（非樱花校门、非室内图书馆）：两侧绿树高大浓荫在阳光地面投下清新碎斑，"
            "远方海天一线微光与图书馆拱窗建筑若隐若现。上部70%舞台右侧立着小混混老大（燃志空手挺胸）与左侧小混混（抹泪崇拜），"
            "均不手持任何卡牌；底部25%严格参照 `story_chrome.png` 摆放暖和纸手帐对话框、左下拍立得头像框、珊瑚铭牌（`小混混老大`）与中文样本文本「不要哭！一无所有后再东山再起，这才是混混的极意欧啦。」及底部半透控制栏。"
        ),
        "desc_en": (
            "Full 1920x1080 anime visual novel whole-page concept master of Chapter 1 Act 1 'Library Path Encounter - Defeated Thugs'. "
            "Upper 70% stage shows a fresh sunlit morning tree-shaded stone walkway inside Arete coastal campus (tall lush green trees casting cool morning shadows, ocean breeze shimmer and distant library facade, NOT pink sakura gate). "
            "On stage, thug_grunt wipes tears on the left and thug_boss puffs his chest proudly with EMPTY hands (ZERO cards) on the right. "
            "Lower 30% renders the exact warm cream washi-paper StoryChrome dialogue frame with bottom-left Polaroid avatar box, coral nameplate, Chinese sample text, and translucent bottom control strip."
        ),
    },
    {
        "id": "concept_ch1_02_library_path_passersby",
        "title": "分镜2整页概念母图 · 路人让开避让槽（`ch1_library_path`）",
        "scene_ref": "exploration_campus.png + story_chrome.png",
        "desc_cn": (
            "同一条清晨海风树荫林荫小路：旁白清场后，舞台左侧立冷灰蓝雾靛青无脸『路人剪影男（担忧避让）』，"
            "右侧立『路人剪影女（担忧嫌弃）』，两人均采用柔和赛璐璐水彩平涂剪影融入晨光绿荫中；"
            "底部完整套用 `story_chrome.png` 暖和纸手帐对话框与左下剪影头像框，珊瑚铭牌显示『路人剪影女』，正文显示「好恶心。。。走远点。。。」。"
        ),
        "desc_en": (
            "Full 1920x1080 anime visual novel whole-page concept master of Chapter 1 Act 1 'Passersby Clear the Way'. "
            "Same sunlit morning coastal tree-shaded campus walkway to the library. Left slot features stylized soft slate-indigo faceless male student silhouette recoiling; right slot features female student silhouette leaning away in unease. "
            "Lower 30% follows the exact StoryChrome washi-paper dialogue UI with Polaroid avatar, coral nameplate, and Chinese sample line."
        ),
    },
    {
        "id": "concept_ch1_03_library_path_encounter",
        "title": "分镜3整页概念母图 · 偶遇黄秋枫约去图书馆（`ch1_library_path`）",
        "scene_ref": "exploration_campus.png + 07_library_npc.png + concept_prologue_01_sakura_road.png",
        "desc_cn": (
            "同一条清晨海风树荫林荫小路（前景树影斑驳、远处阿瑞忒图书馆高窗清晰可见）："
            "舞台左侧立叶舟（微笑，黑棕短发灰蓝校服），右侧立黄秋枫（微害羞怀抱棕色精装书、栗色长卷发枫叶发卡与米色麻花针织开衫），"
            "晨风轻拂发丝与树叶；底部严格套用 `story_chrome.png` 暖和纸对话框，珊瑚铭牌『黄秋枫』，正文「我也想变厉害，图书馆资料很多的，两个人一起找的话肯定比一个人成功率高喔。」。"
        ),
        "desc_en": (
            "Full 1920x1080 anime visual novel whole-page concept master of Chapter 1 Act 1 'Morning Encounter with Huang Qiufeng'. "
            "Same cool morning sea-breeze campus walkway lined with lush green trees leading toward the sunlit library building ahead. "
            "Ye Zhou stands on the left smiling warmly, and Huang Qiufeng stands on the right shyly hugging a brown book in her knit cardigan with maple hairpin. "
            "Lower 30% follows exact StoryChrome dialogue box, bottom-left Polaroid avatar, coral nameplate, Chinese sample text, and bottom translucent bar."
        ),
    },
]

CLEAN_SCENE_SPECS = [
    {
        "key": "ch1_library_path",
        "title": "第一章第1幕 · 通往图书馆的清晨海风林荫小路",
        "desc_cn": (
            "阿瑞忒海滨学园内从社团教室通往图书馆的清晨林荫石板小路："
            "雨后初晴般水润凉爽的清晨空气，高大苍翠行道树枝叶在微凉海风中轻晃（严禁粉红樱花，以清新翠绿树冠与清爽树影区分序章樱道），"
            "树影与金色晨光斑驳洒在干净微湿的石板步道上；小路尽头斜前方可见阿瑞忒图书馆标志性的米白拱窗玻璃立面，远侧天际露出一线蔚蓝海岸与白帆微光；"
            "中景视线开阔平稳以承接左右立绘站位，左右边缘留出柔和树丛/建筑延展空间。纯空镜无人物、无UI、无文字。"
        ),
        "desc_en": (
            "Fresh cool morning coastal academy walkway inside Arete campus leading from the clubroom toward the library: "
            "moist crisp dawn air after morning dew, tall lush green canopy trees swaying gently in ocean breeze (NO pink cherry blossoms, distinct from sakura gate road), "
            "dappled sunlight and cool tree shadows dancing across clean stone paving; ahead along the path stands Arete Library's sunlit cream-and-arched-glass facade with a glimpse of sparkling blue sea and distant coastal hills on the horizon; "
            "balanced open middle ground for VN character sprites"
        ),
    }
]


def _build_manifest() -> dict:
    items: list[dict] = []

    # 1. P0 Thug new emotions + avatars (2 chars x 2 emotions x 2 = 8)
    for spec in THUG_NEW_EMOTIONS:
        cid = spec["char_id"]
        cname = spec["name"]
        neg = f"{CHAR_NEG}, {spec['extra_neg']}"
        for emo_id, emo_label, emo_cn, emo_en in spec["emotions"]:
            items.append({
                "id": f"char_{cid}_{emo_id}",
                "group": "thug_emotions_p0",
                "priority": "P0",
                "character_id": cid,
                "character_name": cname,
                "emotion": emo_id,
                "label": f"{cname}（{emo_label}）半身立绘",
                "zip_delivery_path": f"characters/{cid}/emotions/{emo_id}.png",
                "godot_drop_in_path": f"assets/sprites/characters/phase_two/emotions/{cid}/{emo_id}.png",
                "also_copy_if_neutral": "",
                "width": 1054,
                "height": 1581,
                "flexible_portrait_ratio": True,
                "min_width": 512,
                "min_height": 800,
                "ratio_range": [0.48, 0.92],
                "requires_alpha": True,
                "min_transparent_ratio": 0.25,
                "prompt_cn": f"【{cname} · {emo_label}】{spec['appearance_cn']} 表情与动作：{emo_cn} 严格遵守男性去女性化与3-5组大块面闭合发丝法则，纯透明RGBA背景、胸腰近景、严禁不等比拉伸。",
                "prompt_en": f"Waist-up anime portrait of {spec['appearance_en']}; expression & pose: {emo_en}; {CHAR_STYLE_TAIL}",
                "negative_prompt": neg,
            })
        for emo_id, emo_label, _emo_cn, _emo_en in spec["emotions"]:
            items.append({
                "id": f"avatar_{cid}_{emo_id}",
                "group": "thug_emotions_p0",
                "priority": "P0",
                "character_id": cid,
                "character_name": cname,
                "emotion": emo_id,
                "label": f"{cname}（{emo_label}）方形头像",
                "zip_delivery_path": f"characters/{cid}/avatars/{cid}_{emo_id}.png",
                "godot_drop_in_path": f"assets/sprites/characters/phase_two/avatars/{cid}_{emo_id}.png",
                "width": 256,
                "height": 256,
                "allowed_sizes": [[256, 256]],
                "requires_alpha": True,
                "min_transparent_ratio": 0.08,
                "prompt_cn": f"从定稿后的 `{cid}/{emo_id}.png` 半身立绘胸上肩颈区【等比正方形裁切并缩至 256×256】RGBA 透明底头像（参考 `04_Character_And_Style_References/{cid}_avatar_neutral.png`），严禁将竖图压扁。",
                "prompt_en": f"Exact 1:1 square head-and-shoulders crop scaled to 256x256 RGBA from the approved {cid} {emo_id} half-body sprite, pure transparent background, zero aspect distortion",
                "negative_prompt": neg,
            })

    # 2. P0 Passerby silhouettes (2 chars x (2 halfbody + 2 avatars + 1 portrait) = 10)
    for spec in PASSERBY_SPECS:
        cid = spec["char_id"]
        cname = spec["name"]
        for emo_id, emo_label, emo_cn, emo_en in spec["emotions"]:
            items.append({
                "id": f"char_{cid}_{emo_id}",
                "group": "passerby_p0",
                "priority": "P0",
                "character_id": cid,
                "character_name": cname,
                "emotion": emo_id,
                "label": f"{cname}（{emo_label}）半身剪影立绘",
                "zip_delivery_path": f"characters/{cid}/emotions/{emo_id}.png",
                "godot_drop_in_path": f"assets/sprites/characters/phase_two/emotions/{cid}/{emo_id}.png",
                "also_copy_if_neutral": (f"assets/sprites/characters/phase_two/halfbody/{cid}.png" if emo_id == "neutral" else ""),
                "width": 1054,
                "height": 1581,
                "flexible_portrait_ratio": True,
                "min_width": 512,
                "min_height": 800,
                "ratio_range": [0.48, 0.92],
                "requires_alpha": True,
                "min_transparent_ratio": 0.25,
                "prompt_cn": f"【{cname} · {emo_label}】{spec['appearance_cn']} 姿态要求：{emo_cn} 严格禁止画出眼睛/眉毛/嘴巴等五官，同时避免死黑剪纸块；纯透明RGBA背景、胸腰近景、严禁不等比拉伸。",
                "prompt_en": f"Waist-up stylized silhouette portrait of {spec['appearance_en']}; pose: {emo_en}; {SILHOUETTE_STYLE_TAIL}",
                "negative_prompt": SILHOUETTE_NEG,
            })
        for emo_id, emo_label, _emo_cn, _emo_en in spec["emotions"]:
            items.append({
                "id": f"avatar_{cid}_{emo_id}",
                "group": "passerby_p0",
                "priority": "P0",
                "character_id": cid,
                "character_name": cname,
                "emotion": emo_id,
                "label": f"{cname}（{emo_label}）方形头像",
                "zip_delivery_path": f"characters/{cid}/avatars/{cid}_{emo_id}.png",
                "godot_drop_in_path": f"assets/sprites/characters/phase_two/avatars/{cid}_{emo_id}.png",
                "width": 256,
                "height": 256,
                "allowed_sizes": [[256, 256]],
                "requires_alpha": True,
                "min_transparent_ratio": 0.08,
                "prompt_cn": f"从定稿后的 `{cid}/{emo_id}.png` 半身剪影胸上肩颈区【等比正方形裁切并缩至 256×256】RGBA 透明底头像，严禁压扁变形。",
                "prompt_en": f"Exact 1:1 square head-and-shoulders crop scaled to 256x256 RGBA from approved {cid} {emo_id} silhouette sprite, transparent background",
                "negative_prompt": SILHOUETTE_NEG,
            })
        items.append({
            "id": f"portrait_{cid}",
            "group": "passerby_p0",
            "priority": "P0",
            "character_id": cid,
            "character_name": cname,
            "label": f"{cname} 档案方框肖像",
            "zip_delivery_path": f"characters/{cid}/portraits/{cid}.png",
            "godot_drop_in_path": f"assets/sprites/characters/phase_two/portraits/{cid}.png",
            "width": 512,
            "height": 512,
            "allowed_sizes": [[512, 512]],
            "requires_alpha": True,
            "min_transparent_ratio": 0.10,
            "prompt_cn": f"从定稿后的 `{cid}/neutral.png` 胸上区域【等比正方形裁切并缩至 512×512】RGBA 透明底肖像，用于记录档案与对话兜底。",
            "prompt_en": f"Exact 1:1 square upper-torso crop scaled to 512x512 RGBA from approved {cid} neutral silhouette sprite, pure transparent background",
            "negative_prompt": SILHOUETTE_NEG,
        })

    # 3. P0 Stage 1 Whole-Page Concept Masters (3)
    for cspec in CONCEPT_SPECS:
        items.append({
            "id": cspec["id"],
            "group": "concepts_p0",
            "priority": "P0",
            "label": cspec["title"],
            "zip_delivery_path": f"concepts/{cspec['id']}.png",
            "godot_drop_in_path": f"docs/concepts/v20_library_encounter/{cspec['id']}.png",
            "width": 1920,
            "height": 1080,
            "allowed_sizes": [[1920, 1080]],
            "requires_alpha": False,
            "min_transparent_ratio": 0.0,
            "prompt_cn": f"【Stage 1 整页概念母图｜参考：{cspec['scene_ref']}】1920×1080 整页实机概念设计：{cspec['desc_cn']}",
            "prompt_en": cspec["desc_en"],
            "negative_prompt": "blurry, low contrast, illegible layout, wrong aspect ratio, pink sakura blossoms, indoor library walls, cards in thug_boss hands, watermark",
        })

    # 4. P0 Stage 2 Clean Production Backgrounds (1 group x 2 aspect ratios = 2)
    for sspec in CLEAN_SCENE_SPECS:
        key = sspec["key"]
        for suffix, w, h, ratio_desc in [
            ("", 1920, 1080, "16:9 标准全高清 1920×1080"),
            ("_wide", 2340, 1080, "20:9 超宽延展 2340×1080（中心[210..2130]对位，左右各 210px 自然延展）"),
        ]:
            items.append({
                "id": f"scene_{key}{suffix}",
                "group": "scenes_p0",
                "priority": "P0",
                "scene_key": key,
                "label": f"{sspec['title']} · {ratio_desc}",
                "zip_delivery_path": f"backgrounds/{key}{suffix}.png",
                "godot_drop_in_path": f"assets/backgrounds/phase_two/{key}{suffix}.png",
                "width": w,
                "height": h,
                "allowed_sizes": [[w, h]],
                "requires_alpha": False,
                "min_transparent_ratio": 0.0,
                "prompt_cn": f"【Stage 2 洁净生产底图｜{ratio_desc}】{sspec['desc_cn']} 严禁出现人物、对话框、按钮或文字。",
                "prompt_en": f"{sspec['desc_en']}, {w}x{h} clean background plate; {SCENE_CLEAN_TAIL}",
                "negative_prompt": f"{SCENE_CLEAN_NEG}, pink cherry blossoms, indoor bookshelves",
            })

    # 5. P1 Optional Ye Zhou surprised avatar (1)
    items.append({
        "id": "avatar_ye_zhou_surprised",
        "group": "avatars_p1",
        "priority": "P1",
        "character_id": "ye_zhou",
        "character_name": "叶舟",
        "emotion": "surprised",
        "label": "叶舟（惊讶）精修方形头像 [P1可选]",
        "zip_delivery_path": "avatars_p1/ye_zhou_surprised.png",
        "godot_drop_in_path": "assets/sprites/characters/phase_two/avatars/ye_zhou_surprised.png",
        "width": 256,
        "height": 256,
        "allowed_sizes": [[256, 256]],
        "requires_alpha": True,
        "min_transparent_ratio": 0.08,
        "prompt_cn": "【P1 可选精修｜当前引擎已支持从 `ye_zhou_surprised.png` 半身图实时裁切】请基于 `04_Character_And_Style_References/ye_zhou_surprised.png` 胸上肩颈区等比正方形裁切并缩至 `256×256` RGBA 透明头像，与 `ye_zhou_avatar_neutral.png` 对齐画框比例。",
        "prompt_en": "Exact 1:1 square head-and-shoulders crop scaled to 256x256 RGBA from existing ye_zhou_surprised.png matching ye_zhou_avatar_neutral.png framing, transparent background",
        "negative_prompt": CHAR_NEG,
    })

    # 6. P1 Optional Morning Crowd Transparent Overlay (2)
    for suffix, w, h, ratio_desc in [
        ("", 1920, 1080, "16:9 标准 1920×1080"),
        ("_wide", 2340, 1080, "20:9 超宽 2340×1080"),
    ]:
        items.append({
            "id": f"overlay_ch1_library_path_crowd{suffix}",
            "group": "overlays_p1",
            "priority": "P1",
            "label": f"清晨林荫道远景通学学生透明叠加层 · {ratio_desc} [P1可选]",
            "zip_delivery_path": f"overlays/ch1_library_path_crowd{suffix}.png",
            "godot_drop_in_path": f"assets/backgrounds/phase_two/overlays/ch1_library_path_crowd{suffix}.png",
            "width": w,
            "height": h,
            "allowed_sizes": [[w, h]],
            "requires_alpha": True,
            "min_transparent_ratio": 0.55,
            "prompt_cn": f"【P1 可选氛围叠加层｜{ratio_desc} RGBA】纯透明背景叠加层（透明占比 ≥55%），仅在步道中远景左右边缘点缀三五成群朝气蓬勃赶早课的阿瑞忒学生小远景，严禁遮挡中心主舞台（x=80..800 与 x=1120..1840 立绘槽）与底部 `711..1080` 对话区，参考 `05_Current_Game_Scene_References/ui_ref_duel_crowd_overlay.png`。",
            "prompt_en": f"{w}x{h} pure transparent RGBA overlay layer (at least 55% empty transparent canvas) depicting a few small distant energetic Arete morning students walking along the sides of the sunlit path far in the midground, keeping center foreground and bottom 711..1080 completely clear, zero text, zero UI",
            "negative_prompt": "opaque background, solid sky, large foreground faces blocking center, dialogue box, text, watermark",
        })

    # 7. P1 Optional Walk-to-Library Parallax Cutscene (2)
    items.append({
        "id": "cutscene_ch1_library_walk_bg",
        "group": "cutscene_p1",
        "priority": "P1",
        "label": "叶舟与黄秋枫结伴前往图书馆过场背景层 [P1可选]",
        "zip_delivery_path": "cutscenes/cutscene_ch1_library_walk_bg.png",
        "godot_drop_in_path": "assets/backgrounds/cutscenes/cutscene_ch1_library_walk_bg.png",
        "width": 2340,
        "height": 1080,
        "allowed_sizes": [[2340, 1080]],
        "requires_alpha": False,
        "min_transparent_ratio": 0.0,
        "prompt_cn": "【P1 可选收尾过场 BG｜2340×1080】通往阿瑞忒图书馆高窗入口的清晨林荫斜光纵深长廊背景，微风吹动树影与飘落零星绿叶光斑，无人物无UI无文字。",
        "prompt_en": "2340x1080 sunlit morning academy walkway approaching the tall arched glass entrance of Arete Library, gentle ocean breeze leaves and warm dawn light beams, zero characters, zero UI, zero text",
        "negative_prompt": f"{SCENE_CLEAN_NEG}, pink cherry blossoms",
    })
    items.append({
        "id": "cutscene_ch1_library_walk_fg",
        "group": "cutscene_p1",
        "priority": "P1",
        "label": "叶舟与黄秋枫结伴前往图书馆过场前景层 [P1可选]",
        "zip_delivery_path": "cutscenes/cutscene_ch1_library_walk_fg.png",
        "godot_drop_in_path": "assets/backgrounds/cutscenes/cutscene_ch1_library_walk_fg.png",
        "width": 1920,
        "height": 1080,
        "allowed_sizes": [[1920, 1080]],
        "requires_alpha": True,
        "min_transparent_ratio": 0.35,
        "prompt_cn": "【P1 可选收尾过场 FG｜1920×1080 RGBA】透明背景动态前景层：构图偏上部安全区（避让底部 `y=710..1080` 对话框），呈现叶舟与怀抱书本的黄秋枫并肩走向图书馆阳光入口的背影/侧背影轮廓剪影与微风衣摆光感。",
        "prompt_en": "1920x1080 pure transparent RGBA foreground parallax layer keeping bottom y=710..1080 clear for UI, showing Ye Zhou and Huang Qiufeng (holding brown book in cream knit cardigan) walking side by side in peaceful morning breeze seen from a warm three-quarter back-side angle",
        "negative_prompt": "opaque background, solid sky, white box, text, watermark, UI",
    })

    return {
        "pack_version": "v20_library_encounter",
        "generated_date": "2026-11-22",
        "script_source": "docs/story/user_write/school_affairs.md",
        "counts": {
            "thug_emotions_p0": sum(1 for x in items if x["group"] == "thug_emotions_p0"),
            "passerby_p0": sum(1 for x in items if x["group"] == "passerby_p0"),
            "concepts_p0": sum(1 for x in items if x["group"] == "concepts_p0"),
            "scenes_p0": sum(1 for x in items if x["group"] == "scenes_p0"),
            "avatars_p1": sum(1 for x in items if x["group"] == "avatars_p1"),
            "overlays_p1": sum(1 for x in items if x["group"] == "overlays_p1"),
            "cutscene_p1": sum(1 for x in items if x["group"] == "cutscene_p1"),
            "p0_total": sum(1 for x in items if x["priority"] == "P0"),
            "p1_total": sum(1 for x in items if x["priority"] == "P1"),
            "total": len(items),
        },
        "items": items,
    }


def _readme_md(counts: dict) -> str:
    return f"""# IGA 美术需求包 v20：第一章第 1 幕「图书馆的偶遇」（`school_affairs.md`）

> **编制日期**：2026-11-22  
> **剧本来源**：`docs/story/user_write/school_affairs.md`（从社团前往图书馆时触发：叶舟晨行独白 → 败光卡牌的小混混与老大 → 路人剪影避让 → 偶遇黄秋枫约同去图书馆）  
> **交付结构**：遵循项目 `AGENTS.md` 中的 **「1920×1080 整页概念母图（Stage 1） → 洁净生产底图与透明立绘（Stage 2）」** 标准流程。

---

## 一、压缩包内容清单

- `00_README_图书馆偶遇人物与场景素材需求总控指南.md` — 本总控指南与零改代码合入指引
- `01_人物新增表情与路人剪影需求清单.md` — **P0 混混缺漏表情（8 件）** + **P0 男女路人剪影（10 件）** + **P1 叶舟惊讶头像（1 件）**
- `02_清晨林荫小路场景与演出分镜需求清单.md` — **P0 Stage 1 整页概念母图（3 张）** + **P0 Stage 2 洁净生产底图（2 张）** + **P1 可选远景人群/收尾过场（4 件）**
- `03_asset_manifest_v20_library_encounter.json` — 全量 **{counts['total']} 项**（P0 {counts['p0_total']} + P1 {counts['p1_total']}）机读清单（含 `godot_drop_in_path` 与中英文 Prompt）
- `04_Character_And_Style_References/` — 15 份人物一致性参考图（`thug_boss`、`thug_grunt`、`ye_zhou`、`yang_zi_ying`、`huang_qiufeng` 现行定稿立绘与头像）
- `05_Current_Game_Scene_References/` — 8 份场景/UI/实机参考图（樱道对比图、绿荫校园步道、`07_library_npc`、`12_coast`、`26_prologue_thugs`、`concept_prologue_01`、`story_chrome`、透明人群叠加参考）
- `06_Tools/qa_check_v20_library_encounter.py` — 零第三方依赖 PNG 自检脚本
- `07_Script_Reference/school_affairs.md` — 原样剧本参考副本

---

## 二、重点设计纠偏与优先级说明

| 优先级 | 分组 | 数量 | 关键需求与防错提示 |
| :---: | :--- | :---: | :--- |
| **P0** | `thug_emotions_p0` | {counts['thug_emotions_p0']} | **⚠️ 连续性纠偏**：v19 的 `thug_boss` 多张立绘手中有卡，但本幕混混已「所有卡牌都败出去了」。本批 `dazed`（恍惚）与 `rally`（燃志挺胸）**严禁手中持卡**；`thug_grunt` 补齐 `crying`（哭泣）与 `moved`（抹泪崇拜）。 |
| **P0** | `passerby_p0` | {counts['passerby_p0']} | `路人剪影男 (passerby_male)` 与 `路人剪影女 (passerby_female)` 各 2 表情（`neutral` 通用复用 + `worried` 嫌弃避让）+ 2 头像 + 1 肖像；采用**柔和雾靛青/冷灰蓝无脸学生剪影**，避免生硬死黑剪纸块。 |
| **P0** | `concepts_p0` | {counts['concepts_p0']} | Stage 1 审定用 3 张 `1920×1080` 整页概念母图（含 `StoryChrome` 手帐对话条、左下头像与人物融入比例）。 |
| **P0** | `scenes_p0` | {counts['scenes_p0']} | **⚠️ 场景纠偏**：虽原稿沿用 `默认背景: library` 占位头，但正文发生于「从社团去图书馆的清晨海风绿荫小路」，须独立制作 `ch1_library_path{{,_wide}}.png`，严禁画成粉红樱花道或室内书架厅。 |
| **P1** | `avatars_p1` | {counts['avatars_p1']} | `ye_zhou_surprised.png`（`256×256` RGBA 同源精修头像，引擎当前已能从立绘自动裁切兜底）。 |
| **P1** | `overlays_p1` | {counts['overlays_p1']} | `ch1_library_path_crowd{{,_wide}}.png` 清晨远景通学学生透明叠加层（≥55% 透明，可随 `school_affairs` 自动挂载）。 |
| **P1** | `cutscene_p1` | {counts['cutscene_p1']} | 「两人去图书馆」收尾双层视差过场（`cutscene_ch1_library_walk_{{bg,fg}}.png`）。 |

> **零改代码预埋已就绪**：工程现已预埋 `passerby_male` / `passerby_female` 角色定义、`dazed` / `rally` / `crying` / `moved` 四种新表情白名单（包括 Story Studio 的 `(恍惚)`/`(燃志)`/`(哭泣)`/`(抹泪)`），以及 `ch1_library_path` 背景与可选 `overlays/ch1_library_path_crowd` 挂载槽（交图前自动安全回退，零报错）。

---

## 三、自检命令（无需任何第三方库）

```bash
# 检查全部 P0 必交资源（23 项）
python 06_Tools/qa_check_v20_library_encounter.py <产图输出根目录> --group p0

# 按分组或全量（28 项）检查
python 06_Tools/qa_check_v20_library_encounter.py <产图输出根目录> --group thug_emotions_p0
python 06_Tools/qa_check_v20_library_encounter.py <产图输出根目录> --group passerby_p0
python 06_Tools/qa_check_v20_library_encounter.py <产图输出根目录> --group scenes_p0
python 06_Tools/qa_check_v20_library_encounter.py <产图输出根目录> --group all
```

---

## 四、素材审定后导入替换现行临时剧情指引

1. **素材落位与导入**：将验收通过的图片按 `03_asset_manifest_v20_library_encounter.json` 中的 `godot_drop_in_path` 放回工程（`passerby_{{male,female}}/emotions/neutral.png` 同时复制一份至 `halfbody/passerby_{{male,female}}.png`），运行 `Godot --headless --import --quit`。
2. **替换为正式剧情（`school_affairs`）**：在 Story Studio（或 `PhaseTwoContent.SCRIPTS["school_affairs"]`）导入 `07_Script_Reference/school_affairs.md`：
   - 混混退场时 `旁白: 小混混/路人让开了路` 会自动清场并从左→右重置槽位，故 `路人剪影男` 自动站左、`路人剪影女` 自动站右；
   - `小混混老大(恍惚)` / `小混混老大(燃志)`、`小混混(哭泣)` / `小混混(抹泪)` 与背景 `ch1_library_path` 均已预埋中文标签与背景枚举，直接可用。
3. **社团→图书馆触发接线（`[备注: 这里要从社团去图书馆时触发]`）**：在后续替换临时剧情时，于 `CampusLife.travel_to("library")` 检测「从 `club` 出发且 `n_affairs` 待触发」，先播放本幕剧情再进入图书馆（`GameState.complete_phase_two_step("n_affairs")` 现已自动 `travel_to("library")`）；同时注意把原临时版中前往旧公园前夕的限幅器告警过渡提示并入图书馆后续节点。
"""


def _chars_md(items: list[dict]) -> str:
    lines = [
        "# 01 · 人物新增表情与路人剪影需求清单",
        "",
        "## 一、已齐备可直接复用的资产（无需重绘）",
        "",
        "- **黄秋枫 (`huang_qiufeng`)**：`neutral` / `happy` / `shy` / `surprised` / `worried` 半身立绘与 8 枚同源 `256×256` 头像**全量齐备**。",
        "- **叶舟 (`ye_zhou`)**：`neutral` / `happy` / `surprised` / `worried` 半身立绘全齐备；头像已有 `neutral/happy/worried`，仅将 `ye_zhou_surprised.png` 列为 **P1 可选精修**。",
        "- **小混混老大 (`thug_boss`) & 小混混 (`thug_grunt`)**：v19 已交付 `neutral` / `happy` / `surprised` / `angry`；本幕新增的 4 个表情（`dazed`/`rally`/`crying`/`moved`）须严格保持同人设、同服装、同线条色阶。",
        "",
        "> **核心红线（必读）**：",
        "> 1. **连续性红线**：本幕混混二人组刚把「所有卡牌都败出去了」，`thug_boss` 的 `dazed`（恍惚）与 `rally`（燃志）**双手必须空空如也（严禁拿任何卡牌）**。",
        "> 2. **v9.1 防拉伸 & 男性去女性化**：竖图推荐 `1054×1581`（容许 `0.48 ≤ 宽/高 ≤ 0.92`，`≥512×800`）RGBA PNG；禁止下眼影/湿润唇/少女泪眼。",
        "> 3. **剪影柔化规范**：`passerby_male` / `passerby_female` 采用**雾靛青/冷灰蓝双色赛璐璐无脸剪影**（保留衣纹轮廓与晨光边缘高光），禁止死黑剪纸块与任何五官。",
        "> 4. **同源方形头像**：`256×256` 头像与 `512×512` 肖像必须从同角色定稿半身图胸上区域**等比正方形裁切**。",
        "",
        "## 二、P0 混混二人组新增表情与头像（8 件）",
        "",
    ]
    for spec in THUG_NEW_EMOTIONS:
        cid = spec["char_id"]
        lines.append(f"### {spec['name']} (`{cid}`)")
        lines.append(f"- **一致性基线**：{spec['appearance_cn']}")
        lines.append("")
        for it in [x for x in items if x["group"] == "thug_emotions_p0" and x["character_id"] == cid]:
            lines.append(f"#### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}` RGBA）")
            lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
            lines.append(f"- **引擎投放路径**：`{it['godot_drop_in_path']}`")
            lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
            lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
            lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
            lines.append("")

    lines.extend([
        "## 三、P0 新增通用校园路人剪影（10 件：`passerby_male` + `passerby_female`）",
        "",
    ])
    for spec in PASSERBY_SPECS:
        cid = spec["char_id"]
        lines.append(f"### {spec['name']} (`{cid}`)")
        lines.append(f"- **造型定位**：{spec['appearance_cn']}")
        lines.append("")
        for it in [x for x in items if x["group"] == "passerby_p0" and x["character_id"] == cid]:
            extra = f"（同时复制一份至 `{it['also_copy_if_neutral']}`）" if it.get("also_copy_if_neutral") else ""
            lines.append(f"#### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}` RGBA）")
            lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
            lines.append(f"- **引擎投放路径**：`{it['godot_drop_in_path']}`{extra}")
            lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
            lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
            lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
            lines.append("")

    lines.extend([
        "## 四、P1 可选精修：叶舟惊讶头像（1 件）",
        "",
    ])
    for it in [x for x in items if x["group"] == "avatars_p1"]:
        lines.append(f"- **`{it['id']}`**（`{it['godot_drop_in_path']}`）：{it['prompt_cn']}")
    lines.append("")
    return "\n".join(lines)


def _scenes_md(items: list[dict]) -> str:
    lines = [
        "# 02 · 清晨林荫小路场景与演出分镜需求清单（两阶段流程）",
        "",
        "> **安全区坐标约定（`1920×1080` 主设计画布）**：",
        "> - **顶部场记条**：`0..65`；",
        "> - **人物与主视觉舞台**：`65..757`（左侧槽 `Left x=80..800`，右侧槽 `Right x=1120..1840`）；",
        "> - **`StoryChrome` 手帐对话框与左下拍立得头像**：`711..987`；",
        "> - **底部操作控制栏**：`987..1080`。",
        "",
        "---",
        "",
        "## 一、Stage 1（P0 必先出）：1920×1080 整页概念母图（3 张）",
        "",
        "先审定「清晨海风绿荫步道」气质、无脸路人剪影与混混空手状态的画面融入度，再进 Stage 2 洁净生产：",
        "",
    ]
    for it in [x for x in items if x["group"] == "concepts_p0"]:
        lines.append(f"### `{it['id']}` · {it['label']}（`1920×1080`）")
        lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
        lines.append(f"- **中文设计提示**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")

    lines.extend([
        "---",
        "",
        "## 二、Stage 2（P0 生产交付）：洁净无 UI / 无字 / 无人物背景底图（2 张）",
        "",
        "> **红线**：严禁出现粉樱树海、室内图书馆书架或烘焙任何 UI/文字/路人。`2340×1080` 须保证中心 `[210..2130]` 与 `1920×1080` 完全对位、左右各 `210px` 自然场景延展。",
        "",
    ])
    for it in [x for x in items if x["group"] == "scenes_p0"]:
        lines.append(f"### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}`）")
        lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
        lines.append(f"- **引擎投放路径**：`{it['godot_drop_in_path']}`")
        lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")

    lines.extend([
        "---",
        "",
        "## 三、P1 可选增强：清晨学生远景透明叠加层 & 同行去图书馆视差过场（4 件）",
        "",
    ])
    for it in [x for x in items if x["group"] in ("overlays_p1", "cutscene_p1")]:
        lines.append(f"### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}`）")
        lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
        lines.append(f"- **引擎投放路径**：`{it['godot_drop_in_path']}`")
        lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


QA_SCRIPT_BODY = r'''"""Zero-dependency PNG verification tool for IGA v20 Library Encounter Asset Pack."""
from __future__ import annotations

import argparse
import json
import struct
import zlib
from pathlib import Path


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)


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
                raise ValueError("Interlaced PNG not supported; export non-interlaced PNG")
        elif ctype == b"IDAT":
            idat_parts.append(chunk)
        elif ctype == b"IEND":
            break
    has_alpha = color_type in (4, 6)
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color_type, 0)
    transparent_ratio = 0.0
    if has_alpha and bit_depth == 8 and channels in (2, 4):
        raw = zlib.decompress(b"".join(idat_parts))
        stride = width * channels
        prev = bytearray(stride)
        tp = idx = 0
        for _y in range(height):
            flt = raw[idx]
            idx += 1
            row = bytearray(raw[idx:idx + stride])
            idx += stride
            if flt == 1:
                for i in range(channels, stride):
                    row[i] = (row[i] + row[i - channels]) & 0xFF
            elif flt == 2:
                for i in range(stride):
                    row[i] = (row[i] + prev[i]) & 0xFF
            elif flt == 3:
                for i in range(stride):
                    left = row[i - channels] if i >= channels else 0
                    row[i] = (row[i] + ((left + prev[i]) >> 1)) & 0xFF
            elif flt == 4:
                for i in range(stride):
                    left = row[i - channels] if i >= channels else 0
                    upleft = prev[i - channels] if i >= channels else 0
                    row[i] = (row[i] + _paeth(left, prev[i], upleft)) & 0xFF
            for a in row[channels - 1::channels]:
                if a <= 10:
                    tp += 1
            prev = row
        transparent_ratio = tp / max(1, width * height)
    return {
        "width": width,
        "height": height,
        "bit_depth": bit_depth,
        "has_alpha": has_alpha,
        "transparent_ratio": round(transparent_ratio, 4),
    }


def _resolve_candidate(target_root: Path, item: dict) -> Path | None:
    for rel in [item["zip_delivery_path"], item["godot_drop_in_path"], f"{item['id']}.png"]:
        p = target_root / rel
        if p.is_file():
            return p
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_root", help="Directory holding generated assets (or project root)")
    parser.add_argument(
        "--group",
        choices=[
            "p0",
            "thug_emotions_p0",
            "passerby_p0",
            "concepts_p0",
            "scenes_p0",
            "avatars_p1",
            "overlays_p1",
            "cutscene_p1",
            "all",
        ],
        default="p0",
    )
    parser.add_argument("--manifest", help="Optional path to 03_asset_manifest_v20_library_encounter.json")
    args = parser.parse_args()

    target_root = Path(args.target_root).resolve()
    manifest_path = (
        Path(args.manifest).resolve()
        if args.manifest
        else (Path(__file__).resolve().parents[1] / "03_asset_manifest_v20_library_encounter.json")
    )
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    if args.group == "p0":
        items = [it for it in manifest["items"] if it["priority"] == "P0"]
    elif args.group == "all":
        items = list(manifest["items"])
    else:
        items = [it for it in manifest["items"] if it["group"] == args.group]

    passed = failed = missing = 0
    for item in items:
        f = _resolve_candidate(target_root, item)
        if f is None:
            print(f"[MISSING] {item['id']} -> {item['zip_delivery_path']}")
            missing += 1
            continue
        info = inspect_png(f)
        errs = []
        w, h = info["width"], info["height"]
        if item.get("flexible_portrait_ratio"):
            min_w = int(item.get("min_width", 512))
            min_h = int(item.get("min_height", 800))
            lo, hi = item.get("ratio_range", [0.48, 0.92])
            ratio = w / max(1, h)
            if w < min_w or h < min_h:
                errs.append(f"size {w}x{h} below min {min_w}x{min_h}")
            if ratio < lo or ratio > hi:
                errs.append(f"aspect ratio {ratio:.3f} outside [{lo}, {hi}] (anti-stretch rule)")
        else:
            allowed = item.get("allowed_sizes", [[item["width"], item["height"]]])
            if [w, h] not in allowed:
                errs.append(f"size {w}x{h} not in {allowed}")
        if info["bit_depth"] != 8:
            errs.append(f"bit_depth {info['bit_depth']} != 8")
        if item["requires_alpha"]:
            if not info["has_alpha"]:
                errs.append("missing alpha channel (must be RGBA PNG)")
            elif info["transparent_ratio"] < float(item.get("min_transparent_ratio", 0.01)):
                errs.append(f"transparent {info['transparent_ratio']:.1%} < {float(item['min_transparent_ratio']):.1%}")
        if errs:
            print(f"[FAIL] {item['id']} -> " + "; ".join(errs))
            failed += 1
        else:
            print(f"[PASS] {item['id']} ({w}x{h}, alpha={info['has_alpha']}, transparent={info['transparent_ratio']:.1%})")
            passed += 1
    print(f"Summary ({args.group}): {passed} passed, {failed} failed, {missing} missing / {len(items)} total")
    return 0 if (failed == 0 and missing == 0) else 1


if __name__ == "__main__":
    raise SystemExit(main())
'''


CHAR_REFS = [
    ("thug_boss_neutral.png", "assets/sprites/characters/phase_two/emotions/thug_boss/neutral.png"),
    ("thug_boss_happy.png", "assets/sprites/characters/phase_two/emotions/thug_boss/happy.png"),
    ("thug_boss_surprised.png", "assets/sprites/characters/phase_two/emotions/thug_boss/surprised.png"),
    ("thug_boss_avatar_neutral.png", "assets/sprites/characters/phase_two/avatars/thug_boss_neutral.png"),
    ("thug_grunt_neutral.png", "assets/sprites/characters/phase_two/emotions/thug_grunt/neutral.png"),
    ("thug_grunt_surprised.png", "assets/sprites/characters/phase_two/emotions/thug_grunt/surprised.png"),
    ("thug_grunt_happy.png", "assets/sprites/characters/phase_two/emotions/thug_grunt/happy.png"),
    ("thug_grunt_avatar_neutral.png", "assets/sprites/characters/phase_two/avatars/thug_grunt_neutral.png"),
    ("ye_zhou_neutral.png", "assets/sprites/characters/phase_two/emotions/ye_zhou/neutral.png"),
    ("ye_zhou_surprised.png", "assets/sprites/characters/phase_two/emotions/ye_zhou/surprised.png"),
    ("ye_zhou_avatar_neutral.png", "assets/sprites/characters/phase_two/avatars/ye_zhou_neutral.png"),
    ("yang_zi_ying_neutral.png", "assets/sprites/characters/phase_two/emotions/yang_zi_ying/neutral.png"),
    ("huang_qiufeng_happy.png", "assets/sprites/characters/phase_two/emotions/huang_qiufeng/happy.png"),
    ("huang_qiufeng_shy.png", "assets/sprites/characters/phase_two/emotions/huang_qiufeng/shy.png"),
    ("huang_qiufeng_avatar_happy.png", "assets/sprites/characters/phase_two/avatars/huang_qiufeng_happy.png"),
]

SCENE_REFS = [
    ("bg_contrast_prologue_sakura_road.png", "assets/backgrounds/phase_two/prologue_sakura_road.png"),
    ("bg_ref_exploration_campus.png", "assets/backgrounds/phase_three/exploration_campus.png"),
    ("capture_07_library_npc.png", "test_artifacts/captures_1600x900/captures/07_library_npc.png"),
    ("capture_12_coast.png", "test_artifacts/captures_1600x900/captures/12_coast.png"),
    ("capture_26_prologue_thugs.png", "test_artifacts/captures_1600x900/captures/26_prologue_thugs.png"),
    ("concept_ref_v19_01_sakura_road.png", "docs/concepts/v19_prologue/concepts/concept_prologue_01_sakura_road.png"),
    ("ui_ref_story_chrome.png", "assets/ui/school_objects/story_chrome.png"),
    ("ui_ref_duel_crowd_overlay.png", "assets/backgrounds/phase_two/overlays/prologue_sports_field_duel_crowd.png"),
]


def build_pack() -> None:
    missing_refs = [src for _dst, src in CHAR_REFS + SCENE_REFS if not (ROOT / src).is_file()]
    if missing_refs:
        raise FileNotFoundError(f"Missing reference files: {missing_refs}")
    if not SCRIPT_SRC.is_file():
        raise FileNotFoundError(f"Missing script source: {SCRIPT_SRC}")

    manifest = _build_manifest()
    items = manifest["items"]

    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_ZIP.parent.mkdir(parents=True, exist_ok=True)

    (STAGING_DIR / "00_README_图书馆偶遇人物与场景素材需求总控指南.md").write_text(
        _readme_md(manifest["counts"]), encoding="utf-8"
    )
    (STAGING_DIR / "01_人物新增表情与路人剪影需求清单.md").write_text(_chars_md(items), encoding="utf-8")
    (STAGING_DIR / "02_清晨林荫小路场景与演出分镜需求清单.md").write_text(_scenes_md(items), encoding="utf-8")
    (STAGING_DIR / "03_asset_manifest_v20_library_encounter.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    char_dir = STAGING_DIR / "04_Character_And_Style_References"
    char_dir.mkdir(parents=True, exist_ok=True)
    for dst_name, rel_src in CHAR_REFS:
        shutil.copy2(ROOT / rel_src, char_dir / dst_name)

    scene_dir = STAGING_DIR / "05_Current_Game_Scene_References"
    scene_dir.mkdir(parents=True, exist_ok=True)
    for dst_name, rel_src in SCENE_REFS:
        shutil.copy2(ROOT / rel_src, scene_dir / dst_name)

    tools_dir = STAGING_DIR / "06_Tools"
    tools_dir.mkdir(parents=True, exist_ok=True)
    (tools_dir / "qa_check_v20_library_encounter.py").write_text(QA_SCRIPT_BODY, encoding="utf-8")

    script_dir = STAGING_DIR / "07_Script_Reference"
    script_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SCRIPT_SRC, script_dir / "school_affairs.md")

    if ARCHIVE_ZIP.exists():
        ARCHIVE_ZIP.unlink()
    file_count = 0
    with zipfile.ZipFile(ARCHIVE_ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for path in sorted(STAGING_DIR.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(STAGING_DIR).as_posix())
                file_count += 1

    print(
        json.dumps(
            {
                "ok": True,
                "zip_path": str(ARCHIVE_ZIP),
                "zip_bytes": ARCHIVE_ZIP.stat().st_size,
                "entries": file_count,
                "counts": manifest["counts"],
                "char_refs": len(CHAR_REFS),
                "scene_refs": len(SCENE_REFS),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    build_pack()
