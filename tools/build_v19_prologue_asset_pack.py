"""Build v19 Asset Brief Pack for New Prologue Characters & Scenes (44 items + references + zero-dep QA)."""
from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGING_DIR = ROOT / ".godot" / "v19_staging" / "pack_root"
ARCHIVE_ZIP = ROOT / "archive" / "IGA_Asset_Pack_Brief_v19_Prologue_Characters_And_Scenes.zip"

CHAR_STYLE_TAIL = (
    "matching IGA (Inorganic General Alien) official anime character art style: "
    "delicate crisp dark-brown linework, clean soft cel-shading with subtle warm sunlit rim highlights, "
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

SCENE_CLEAN_TAIL = (
    "matching IGA bright coastal anime campus background style (Blue Archive sunlit clarity blended with "
    "warm nostalgic anime film atmosphere), crisp architectural perspective, clean readable surfaces, "
    "zero characters, zero people, zero UI panels, zero dialogue boxes, zero text, zero watermarks"
)

SCENE_CLEAN_NEG = (
    "characters, people, students, anime girls, anime boys, UI buttons, dialogue box, HUD, speech bubble, "
    "text, readable letters, Chinese characters, watermarks, photorealistic photo noise, muddy grunge"
)

THUG_SPECS = [
    {
        "char_id": "thug_grunt",
        "name": "小混混",
        "role": "樱林堵路跟班（喜剧欺软怕硬型）",
        "recommended_note": "以下外貌服装为结合阿瑞忒校园日常感与喜剧小跟班气质的【推荐参考方向】，主创可按审美微调发型/肤色/细节；确认后按相同命名投放即可生效。",
        "appearance_cn": "17岁左右精瘦跟班男高中生，短刺微翘栗棕碎发（归纳为3-5个干净闭合大发束），机灵轻挑的棕褐色平眼；身穿略显随意的阿瑞忒男生深灰蓝西装校服（敞开外套、内搭浅灰白衬衫与松散酒红斜纹领带，手腕随意戴一只运动电子表），整体略带搞笑浮夸的校园小跟班神气。",
        "appearance_en": "slim teenage high-school delinquent sidekick boy around 17, short spiky warm chestnut-brown hair grouped into 3-5 clean mega-clumps, sharp mischievous brown eyes, wearing slightly unbuttoned Arete slate-blue school blazer over off-white shirt with loosened burgundy tie and casual sport wristwatch, comical cocky sidekick vibe",
        "emotions": [
            ("neutral", "平静 / 得意堵路", "单手插兜、嘴角挑起一点得意弧度斜眼看人，神态轻佻又带点虚张声势。", "standing three-quarter waist-up with one hand in pocket, slight smug smirk glancing sideways"),
            ("happy", "微笑 / 吹捧老大", "满脸谄笑竖起大拇指或比出『稳了』手势，拍马屁时一副捡到大便宜的夸张得意样。", "grinning broadly while giving a cheeky thumbs-up gesture, flattering overconfident expression"),
            ("surprised", "惊讶 / 见势不妙", "听到叶舟中二宣言并看到对方人多时双眼圆睁、冷汗直冒、双手略微抬起准备随时开溜。", "wide-eyed panicked comedic shock with tiny sweat drop, shoulders raised ready to run away"),
            ("angry", "愤怒 / 虚张声势", "咬牙皱眉、手指前方虚张声势放狠话，但站姿略微后仰显得底气不足。", "scowling fiercely while pointing ahead defensively, slightly leaning back lacking real courage"),
        ],
    },
    {
        "char_id": "thug_boss",
        "name": "小混混老大",
        "role": "樱林混混头目（口头禅『欧啦』· 讲究欺软怕硬原则的喜剧反派）",
        "recommended_note": "以下外貌服装为结合『欧啦』口头禅与喜剧校霸反差感的【推荐参考方向】，主创可自由调整发型（如飞机头/蓬松背头）或配饰细节。",
        "appearance_cn": "17-18岁身形稍宽厚结实的校园混混头目，微翘夸张的深红褐偏黑飞机感短背头（大块面闭合发束、干净利落），浓粗平直眉配琥珀深眼眸；将阿瑞忒男生校服外套披在肩上或袖口卷起半截、白衬衫领口微敞、内搭暗色T恤与暗金皮带扣，单手常夹着一张亮面刻印卡，自带喜感『原则型小反派』气场。",
        "appearance_en": "broad-shouldered teenage delinquent boss boy around 18, stylish swept-back dark reddish-black pompadour hair in 3-5 clean solid clumps, thick flat brows, sharp amber eyes, wearing Arete slate-blue school blazer draped coolly over shoulders or sleeves rolled up over open-collar white shirt and dark undershirt, holding a tactical card casually between two fingers, comical 'principled bully' aura",
        "emotions": [
            ("neutral", "平静 / 抱臂耍帅", "抱臂而立、抬下巴从容俯视，嘴角挂着自以为很有派头的哼笑。", "standing with arms crossed and chin slightly raised in a pompous smug smirk"),
            ("happy", "微笑 / 讲原则撤退", "一手叉腰另一手竖指比划『我们可是有原则的欧啦』，大笑得理直气壮又滑稽。", "laughing proudly with one hand on hip and the other pointing upward in a dramatic comical 'rule of retreat' pose"),
            ("surprised", "惊讶 / 发现不对", "挑眉侧头、瞪大眼盯着突然冒出来的叶舟和杨子英，嘴角抽动『谁？什么声音』。", "eyebrows shot up staring sideways in stunned disbelief at unexpected intruders"),
            ("angry", "愤怒 / 放话施压", "压低眉毛双手握拳或亮出卡牌威吓，摆出恶人架势但保留轻喜剧动画质感。", "furrowed heavy brows clenching fist forward while flashing a card to intimidate"),
        ],
    },
]

P1_MISSING_AVATARS = [
    ("ye_zhou", "叶舟", "angry", "愤怒 · 紧锁平眉锐利眼神指向恶徒"),
    ("ye_zhou", "叶舟", "shy", "害羞 · 略带腼腆微红脸颊轻撇视线"),
    ("ye_zhou", "叶舟", "surprised", "惊讶 · 双眸微睁愕然反应"),
    ("yang_zi_ying", "杨子英", "angry", "愤怒 · 鼓起腮帮气呼呼吐槽叶舟"),
    ("yang_zi_ying", "杨子英", "shy", "害羞 · 略微羞赧扭头『别看我』"),
    ("yang_zi_ying", "杨子英", "surprised", "惊讶 · 瞪大眼惊讶吐槽"),
    ("liu_yu_long", "柳宇龙", "shy", "害羞 · 被捧『校长之子』时略微别扭移开视线"),
    ("liu_yu_long", "柳宇龙", "surprised", "惊讶 · 挑眉饶有兴致看向走来的叶舟"),
    ("liu_yu_long", "柳宇龙", "worried", "担忧 / 认真沉思 · 收起轻佻认可叶舟的战术直觉"),
    ("jiang_zi", "姜梓", "angry", "愤怒 · 镜片反光严肃声明『这同样是我的名声』"),
    ("jiang_zi", "姜梓", "shy", "害羞 · 被说中或提出邀请时轻微敛目微赧"),
    ("jiang_zi", "姜梓", "surprised", "惊讶 · 扶住圆框眼镜略感意外"),
]

CONCEPT_SPECS = [
    {
        "id": "concept_prologue_01_sakura_road",
        "title": "第1幕整页概念母图 · 樱林解围（`campus_morning`）",
        "scene_ref": "morning_road.png + 22_prologue_sakura.png",
        "desc_cn": "清晨粉白樱花盛开、阳光斑驳洒在阿瑞忒学园通学道上。画面上部70%为舞台：左侧立叶舟（深棕短发灰蓝西装），右侧立杨子英（高马尾水手服+相机）或小混混与黄秋枫解围站位；底部25%严格参照 `story_chrome.png` 摆放暖和纸手帐对话框、左下拍立得头像框、珊瑚铭牌与底部半透操作条。",
        "desc_en": "Full 1920x1080 anime visual novel whole-page concept master of Act 1 'Sakura Road Morning Rescue'. Upper 70% stage shows sunlit cherry-blossom lined anime academy morning avenue with dappled petal shadows, Ye Zhou on the left and Yang Ziying (or delinquent thugs / Huang Qiufeng) on the right in crisp 2D cel anime style. Lower 30% renders the exact warm cream washi-paper StoryChrome dialogue frame with bottom-left Polaroid avatar box, coral nameplate, crisp Chinese sample dialogue, and translucent bottom control strip.",
    },
    {
        "id": "concept_prologue_02_sports_field",
        "title": "第2幕整页概念母图 · 操场自由决斗海选赛（`school_gate`）",
        "scene_ref": "school_gate.png + 23_prologue_sports_field.png",
        "desc_cn": "次日阳光明媚的阿瑞忒露天操场跑道与绿茵草坪，远处可见观众看台与半透明战术电子晋级榜（隐约提示榜首名字）。上部舞台为柳宇龙（左）与姜梓（右）或四人正对而立的张力站位；下部完整套用 `story_chrome.png` 对话框与头像排版。",
        "desc_en": "Full 1920x1080 anime visual novel concept master of Act 2 'Sports Field Open Qualifier'. Sunny daytime academy athletic track, green turf field, bleachers, and distant translucent qualifier ranking board under bright coastal sky. Stage shows Liu Yulong (left) and Jiang Zi (right) facing off in tension; lower area follows the warm washi-paper StoryChrome dialogue HUD and portrait card layout.",
    },
    {
        "id": "concept_prologue_03_duel_2v2",
        "title": "第2幕战斗整页概念母图 · 操场 2v2 决斗战台（`n_gate`）",
        "scene_ref": "battle_campus.png + 24_prologue_duel_2v2.png",
        "desc_cn": "晴昼操场绿茵战台：严格按我方战斗 v8 定尺布局——顶栏深蓝锻带『逃跑·判负 / 操场海选赛·2v2 / 叶舟行动 / 第1回合 / 回合记录』；上方 HUD 带与头顶纸质血条状态芯片；统一战台地坪 `y=634` 上左侧站杨子英（后卫）+ 叶舟（主战），右侧站柳宇龙 + 姜梓（均朝左迎战）；底部 `654..1080` 为手账行动手册与 3 张初始刻印卡（破隙突刺/便携偏转盾/冰镇补给印）及右侧当前目标便利贴。",
        "desc_en": "Full 1920x1080 turn-based card battle UI concept master set on a sunlit academy sports field duel stage. Follows exact IGA v8 combat HUD layout: top indigo header bar, upper HP/status plaque band, flat stage horizon platform (y=634) with Yang Ziying + Ye Zhou on left facing Liu Yulong + Jiang Zi on right, and lower cream handbook hand tray displaying 3 tactical cards on left and target sticky-note panel with coral 'End Turn' button on right.",
    },
    {
        "id": "concept_prologue_04_club_meeting",
        "title": "第3幕整页概念母图 · 决斗社团第一次会议（`club_welcome`）",
        "scene_ref": "home_room_morning_v1.png + 25_prologue_club_meeting.png",
        "desc_cn": "申请下来的全新阿瑞忒决斗社团教室清晨全景：宽大玻璃窗外是海滨学园晴空绿树，室内黑板洁净（无空白UI按钮占位）、长木会议桌与木椅整齐温暖、阳光在地板拉出明亮光影。左侧站姜梓（抱书、黑双麻花辫眼镜），右侧站叶舟（或杨子英），底部套用 `story_chrome.png` 对话框展示社团会议台词。",
        "desc_en": "Full 1920x1080 anime visual novel concept master of Act 3 'First Duel Club Meeting'. Freshly assigned bright morning clubroom with wide sunlit windows overlooking seaside campus trees, clean green chalkboard (NO empty UI pill placeholders), wooden meeting table and chairs bathed in warm morning sunbeams. Jiang Zi stands on the left as club president and Ye Zhou on the right above the warm washi-paper StoryChrome dialogue HUD.",
    },
]

CLEAN_SCENE_SPECS = [
    {
        "key": "prologue_sakura_road",
        "title": "第1幕 · 樱林上学路（清晨）",
        "desc_cn": "阿瑞忒学园樱花夹道通学路，清晨澄澈蔚蓝晴空、粉白樱树落英缤纷，阳光透过树冠在干净路面洒下温柔光斑，远处见浅色校门与教学楼；构图居中留白，左右边缘做柔和延展以便 20:9 宽屏适配。纯空镜无人物、无UI、无文字。",
        "desc_en": "Bright sunlit morning academy cherry-blossom avenue in Arete coastal campus, soft pink-white sakura trees lining clean paved walkway with dappled sunlight and drifting petals, school gate and light buildings in clear distance, gentle wide composition ready for 1920x1080 and 2340x1080 ultrawide framing",
    },
    {
        "key": "prologue_sports_field",
        "title": "第2幕 · 操场自由决斗海选赛（昼景）",
        "desc_cn": "晴朗上午的阿瑞忒露天运动操场：红白/赤陶色标准田径跑道与翠绿草坪、侧面阶梯观众看台、远方校园立面与海岸线微风感，可含干净无字/极简几何装饰的电子晋级屏远景（严禁出现可读汉字或乱码英文）；地面与视平线开阔平稳适配左右立绘站位。纯空镜无人物、无UI。",
        "desc_en": "Crisp sunny daytime academy outdoor sports field and track-and-field arena, terracotta running track framing fresh green lawn, stepped bleachers, coastal school buildings under radiant blue sky with fluffy clouds, clean open middle horizon for VN character sprites",
    },
    {
        "key": "battle_sports_field",
        "title": "第2幕战斗 · 操场 2v2 决斗战台",
        "desc_cn": "专为回合制卡牌对战构图的操场绿茵战台：正对视角、地平线稳定落在画面中部偏下（配合 `y=566..658` 战台区与顶部 `0..206` HUD 留白），背景为日光下的看台、绿树与微泛浅青蓝光晕的学园非致命护盾裁决场边界标记；上方天空留出足够干净空间不抢血条可读性。纯空镜无人物、无UI。",
        "desc_en": "Front-facing symmetrical anime card-duel arena set on a bright academy sports field turf court; open clean upper sky for HP plaques and status chips, level horizontal turf foreground aligning cleanly with y=566..658 stage platform zone, subtle glowing cyan non-lethal duel court boundary lines, sunlit bleachers and campus trees behind",
    },
    {
        "key": "prologue_club_meeting",
        "title": "第3幕 · 决斗社团第一次会议（清晨洁净教室）",
        "desc_cn": "温暖通透的清晨阿瑞忒社团教室：左侧整排高窗透入湛蓝晨光与窗外绿植街景，室内木地板光影斑驳，靠墙放置木书架、干净黑板（只画正常黑板粉笔槽与零星树叶，严禁画白色空白胶囊/按钮占位框）与会议木桌椅；画面中下部适合立绘自然叠加。纯空镜无人物、无UI。",
        "desc_en": "Warm sunlit morning anime school clubroom interior, tall left windows streaming crisp blue-gold morning sunbeams and swaying white curtains, clean wooden floor, neat bookshelves, clean dark-green chalkboard (NO blank paper button shapes or UI placeholders), and warm oak meeting desk and chairs",
    },
]


def _build_manifest() -> dict:
    items: list[dict] = []

    # 1. P0 Characters (thug_grunt, thug_boss -> 4 emotions + 4 avatars + 1 portrait each = 18)
    for char_spec in THUG_SPECS:
        cid = char_spec["char_id"]
        cname = char_spec["name"]
        for emo_id, emo_label, emo_cn, emo_en in char_spec["emotions"]:
            items.append({
                "id": f"char_{cid}_{emo_id}",
                "group": "characters_p0",
                "priority": "P0",
                "character_id": cid,
                "character_name": cname,
                "emotion": emo_id,
                "label": f"{cname}（{emo_label}）半身立绘",
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
                "prompt_cn": f"【{cname} · {emo_label}（推荐参考设定）】{char_spec['appearance_cn']} 表情与动作：{emo_cn} 严格遵守男性去女性化（硬朗下颌折角、平直眉、禁用下眼影与湿润唇）与3-5组大块面闭合发丝法则，纯透明RGBA背景、胸腰近景、严禁不等比拉伸。",
                "prompt_en": f"Waist-up anime portrait of {char_spec['appearance_en']}; expression & pose: {emo_en}; {CHAR_STYLE_TAIL}",
                "negative_prompt": CHAR_NEG,
            })
        for emo_id, emo_label, _emo_cn, _emo_en in char_spec["emotions"]:
            items.append({
                "id": f"avatar_{cid}_{emo_id}",
                "group": "characters_p0",
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
                "prompt_cn": f"从定稿后的 `{cid}/{emo_id}.png` 半身立绘胸上肩颈区【等比正方形裁切并缩至 256×256】RGBA 透明底头像（参考 `04_Character_And_Style_References/ye_zhou_avatar_neutral.png`），严禁将竖图压扁。",
                "prompt_en": f"Exact 1:1 square head-and-shoulders crop scaled to 256x256 RGBA from the approved {cid} {emo_id} half-body sprite, maintaining pure transparent background and zero aspect distortion",
                "negative_prompt": CHAR_NEG,
            })
        items.append({
            "id": f"portrait_{cid}",
            "group": "characters_p0",
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
            "prompt_cn": f"从定稿后的 `{cid}/neutral.png` 半身立绘胸上区域【等比正方形裁切并缩至 512×512】RGBA 透明底肖像，用于记录档案与对话兜底。",
            "prompt_en": f"Exact 1:1 square upper-torso portrait crop scaled to 512x512 RGBA from the approved {cid} neutral half-body sprite, pure transparent background",
            "negative_prompt": CHAR_NEG,
        })

    # 2. P0 Stage 1 Whole-Page Concept Masters (4)
    for cspec in CONCEPT_SPECS:
        items.append({
            "id": cspec["id"],
            "group": "concepts_p0",
            "priority": "P0",
            "label": cspec["title"],
            "zip_delivery_path": f"concepts/{cspec['id']}.png",
            "godot_drop_in_path": f"docs/concepts/v19_prologue/{cspec['id']}.png",
            "width": 1920,
            "height": 1080,
            "allowed_sizes": [[1920, 1080]],
            "requires_alpha": False,
            "min_transparent_ratio": 0.0,
            "prompt_cn": f"【Stage 1 整页概念母图｜参考：{cspec['scene_ref']}】1920×1080 整页实机概念设计：{cspec['desc_cn']}",
            "prompt_en": cspec["desc_en"],
            "negative_prompt": "blurry, low contrast, illegible layout, wrong aspect ratio, watermark",
        })

    # 3. P0 Stage 2 Clean Production Backgrounds (4 sets x 2 aspect ratios = 8)
    for sspec in CLEAN_SCENE_SPECS:
        key = sspec["key"]
        for suffix, w, h, ratio_desc in [("", 1920, 1080, "16:9 标准全高清 1920×1080"), ("_wide", 2340, 1080, "20:9 超宽延展 2340×1080（左右各 210px 自然延展）")]:
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
                "negative_prompt": SCENE_CLEAN_NEG,
            })

    # 4. P1 Optional Missing Character Expression Avatars (12)
    for cid, cname, emo, desc_cn in P1_MISSING_AVATARS:
        items.append({
            "id": f"avatar_{cid}_{emo}",
            "group": "avatars_p1",
            "priority": "P1",
            "character_id": cid,
            "character_name": cname,
            "emotion": emo,
            "label": f"{cname}（{emo}）精修方形头像 [P1可选]",
            "zip_delivery_path": f"avatars_p1/{cid}_{emo}.png",
            "godot_drop_in_path": f"assets/sprites/characters/phase_two/avatars/{cid}_{emo}.png",
            "width": 256,
            "height": 256,
            "allowed_sizes": [[256, 256]],
            "requires_alpha": True,
            "min_transparent_ratio": 0.08,
            "prompt_cn": f"【P1 可选精修｜当前引擎已支持从 emotions/{cid}/{emo}.png 自动裁切显示】请基于现行 `emotions/{cid}/{emo}.png` 等比正方形裁切至 256×256 RGBA 头像（{desc_cn}），补齐人物头像独立文件。",
            "prompt_en": f"Exact 1:1 square head-and-shoulders crop scaled to 256x256 RGBA from existing official emotion sprite {cid}/{emo}.png, transparent background",
            "negative_prompt": CHAR_NEG,
        })

    # 5. P1 Optional Highlight Parallax Cutscene (2)
    items.append({
        "id": "cutscene_prologue_duel_clash_bg",
        "group": "cutscene_p1",
        "priority": "P1",
        "label": "操场四人正对而立 / 柳宇龙反击过场背景层 [P1可选]",
        "zip_delivery_path": "cutscenes/cutscene_prologue_duel_clash_bg.png",
        "godot_drop_in_path": "assets/backgrounds/cutscenes/cutscene_prologue_duel_clash_bg.png",
        "width": 2340,
        "height": 1080,
        "allowed_sizes": [[2340, 1080]],
        "requires_alpha": False,
        "min_transparent_ratio": 0.0,
        "prompt_cn": "【P1 可选高光过场 BG｜2340×1080】充满戏剧张力的阿瑞忒操场广角晴昼斜光背景，草地与跑道透视拉深，伴随微风扬尘光粒，无人物无UI无文字。",
        "prompt_en": "2340x1080 dramatic wide-angle academy athletic field background with dynamic sunlight streaks and drifting wind dust particles, zero characters, zero UI, zero text",
        "negative_prompt": SCENE_CLEAN_NEG,
    })
    items.append({
        "id": "cutscene_prologue_duel_clash_fg",
        "group": "cutscene_p1",
        "priority": "P1",
        "label": "操场四人正对而立 / 柳宇龙反击过场前景层 [P1可选]",
        "zip_delivery_path": "cutscenes/cutscene_prologue_duel_clash_fg.png",
        "godot_drop_in_path": "assets/backgrounds/cutscenes/cutscene_prologue_duel_clash_fg.png",
        "width": 1920,
        "height": 1080,
        "allowed_sizes": [[1920, 1080]],
        "requires_alpha": True,
        "min_transparent_ratio": 0.35,
        "prompt_cn": "【P1 可选高光过场 FG｜1920×1080 RGBA】透明背景动态前景层：右侧前景柳宇龙持卡蓄势反击的潇洒剪影/半身透视动作 + 飞扬白衣角与轻微能量卡光弧，避让屏幕底部 710..1080 对话框区。",
        "prompt_en": "1920x1080 pure transparent RGBA foreground parallax layer featuring athletic blonde teenager Liu Yulong raising a glowing tactical card dynamically on the right half with fluttering blazer edge, keeping bottom y=710..1080 clear for dialogue UI",
        "negative_prompt": "opaque background, solid sky, white box, text, watermark, UI",
    })

    return {
        "pack_version": "v19_prologue_characters_and_scenes",
        "generated_date": "2026-11-21",
        "script_source": "docs/story/user_write/序章.md",
        "counts": {
            "characters_p0": sum(1 for x in items if x["group"] == "characters_p0"),
            "concepts_p0": sum(1 for x in items if x["group"] == "concepts_p0"),
            "scenes_p0": sum(1 for x in items if x["group"] == "scenes_p0"),
            "avatars_p1": sum(1 for x in items if x["group"] == "avatars_p1"),
            "cutscene_p1": sum(1 for x in items if x["group"] == "cutscene_p1"),
            "total": len(items),
        },
        "items": items,
    }


def _readme_md(counts: dict) -> str:
    return f"""# IGA 美术需求包 v19：新序章（`序章.md`）人物与场景全套素材需求

> **编制日期**：2026-11-21  
> **剧本来源**：`docs/story/user_write/序章.md`（樱林解围 → 操场海选赛 2v2 对决与锁血剧情杀 → 决斗社团第一次会议）  
> **交付结构**：遵循项目 `AGENTS.md` 中的 **「1920×1080 整页概念母图（Stage 1） → 洁净生产底图与透明立绘（Stage 2）」** 标准流程。

---

## 一、压缩包内容清单

- `00_README_新序章人物与场景素材需求总控指南.md` — 本总控指南
- `01_新序章人物设定与立绘头像需求清单.md` — **P0 新增 2 名人物（18 件）** + **P1 主角补缺精修头像（12 件）**
- `02_新序章三幕场景与战斗舞台需求清单.md` — **P0 Stage 1 整页概念母图（4 张）** + **P0 Stage 2 洁净生产底图（8 张）** + **P1 可选过场（2 件）**
- `03_asset_manifest_v19_prologue.json` — 全量 **{counts['total']} 项** 机读清单（含 `godot_drop_in_path` 与中英文 Prompt）
- `04_Character_And_Style_References/` — 官方 4 张人设图、5 位主角现行半身立绘、表情样本、头像裁切标杆与 4 张战斗立绘
- `05_Current_Game_Scene_References/` — 现行 4 张底图参考、手帐对话框/战斗战台组件，以及本轮实装新序章后的最新 4 张 `1600×900` 实机参考截图
- `06_Tools/qa_check_v19_prologue.py` — 零第三方依赖 PNG 自检脚本

---

## 二、优先级与引擎无缝接管说明

| 优先级 | 分组 | 数量 | 是否阻塞运行 | 说明 |
| :---: | :--- | :---: | :--- | :--- |
| **P0** | `characters_p0` | {counts['characters_p0']} | 否（引擎已安全隐去占位） | `小混混 (thug_grunt)` 与 `小混混老大 (thug_boss)` 各自 4 表情半身立绘 + 4 同源头像 + 1 档案肖像；外貌为**推荐参考方向** |
| **P0** | `concepts_p0` | {counts['concepts_p0']} | Stage 1 审定用 | 含 UI、人物站位与文字层级的 4 张 `1920×1080` 整页概念母图 |
| **P0** | `scenes_p0` | {counts['scenes_p0']} | 否（引擎已按回退底图运行） | 4 组洁净底图 × `1920×1080` + `2340×1080` 宽屏版本；投放后自动覆盖暂借底图 |
| **P1** | `avatars_p1` | {counts['avatars_p1']} | 否（引擎已从 `emotions/` 自动裁切） | 叶舟/杨子英/柳宇龙/姜梓各 3 枚缺漏表情 `256×256` 独立头像 |
| **P1** | `cutscene_p1` | {counts['cutscene_p1']} | 可选增强 | 操场四人正对而立 / 柳宇龙反击双层视差过场 |

> **零改代码合入约定**：您按清单中 `godot_drop_in_path` 放回工程目录并执行 `Godot --headless --import --quit` 后，`PhaseTwoContent` 与 `DialogueScreen` 会自动识别并加载全部新立绘、新头像与新场景底图（含 `thug_grunt`、`thug_boss`、`prologue_sakura_road`、`prologue_sports_field`、`battle_sports_field`、`prologue_club_meeting`）。

---

## 三、自检命令（无需安装 Pillow 等任何第三方库）

```bash
# 仅检查 P0 必交资源（2 名混混 + 4 概念图 + 8 洁净底图 = 30 项）
python 06_Tools/qa_check_v19_prologue.py <产图输出根目录> --group p0

# 按分组或全量检查
python 06_Tools/qa_check_v19_prologue.py <产图输出根目录> --group characters_p0
python 06_Tools/qa_check_v19_prologue.py <产图输出根目录> --group scenes_p0
python 06_Tools/qa_check_v19_prologue.py <产图输出根目录> --group all
```
"""


def _chars_md(items: list[dict]) -> str:
    lines = [
        "# 01 · 新序章人物设定与立绘头像需求清单",
        "",
        "## 一、已全量齐备可复用的角色资产（无需重绘）",
        "",
        "- **叶舟 (`ye_zhou`) / 杨子英 (`yang_zi_ying`) / 黄秋枫 (`huang_qiufeng`) / 柳宇龙 (`liu_yu_long`) / 姜梓 (`jiang_zi`)**：",
        "  - 5 位主要角色的 `halfbody/*.png`、`emotions/*/{6~8}.png` 均已齐备；",
        "  - 操场 2v2 对决战斗所需 4 位角色战斗立绘（`ye_zhou_idle`、`combat_yang_zi_ying_idle`、`combat_liu_yu_long_idle`、`combat_jiang_zi_idle`）与 `liu_yu_long_cutin` 均已实装并验证方向对齐。",
        "  - 参考样本见 `04_Character_And_Style_References/`。",
        "",
        "## 二、P0 新增角色设定与立绘需求（18 件：2 名混混各 4 立绘 + 4 头像 + 1 肖像）",
        "",
        "> **重要合规守则（v9.1 柔性防拉伸版）**：",
        "> 1. **禁止不等比拉伸**：推荐 `1054×1581` RGBA 透明 PNG，同时兼容 `2:3 ~ 3:4 ~ 4:5`（`0.48 ≤ 宽/高 ≤ 0.92`，宽 `≥ 512 px`、高 `≥ 800 px`）任意原生竖图，严禁强压变形。",
        "> 2. **男性去女性化八条铁律**：明确下颌折角、平直眉、横向男性眼型；严禁下眼睑粉红/紫红眼影、浓密下睫毛、湿润反光唇、仰角魅态下巴。",
        "> 3. **发丝大块面聚拢**：全头归纳为 3–5 组饱满闭合主发束，消除游离飞丝碎点。",
        "> 4. **同源方形头像**：`256×256` 头像与 `512×512` 肖像必须从同角色定稿立绘胸上区域**等比正方形裁切**。",
        "",
    ]
    for char_spec in THUG_SPECS:
        cid = char_spec["char_id"]
        lines.append(f"### {char_spec['name']} (`{cid}`) — {char_spec['role']}")
        lines.append(f"- **设定自由度说明**：{char_spec['recommended_note']}")
        lines.append(f"- **推荐外观描述**：{char_spec['appearance_cn']}")
        lines.append("")
        for it in [x for x in items if x["group"] == "characters_p0" and x["character_id"] == cid]:
            lines.append(f"#### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}` RGBA）")
            lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
            lines.append(f"- **引擎投放路径**：`{it['godot_drop_in_path']}`" + (f"（建议同时复制一份至 `{it['also_copy_if_neutral']}`）" if it.get("also_copy_if_neutral") else ""))
            lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
            lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
            lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
            lines.append("")

    lines.extend([
        "## 三、P1 可选精修：主角组缺漏细分表情独立头像（12 件）",
        "",
        "> 引擎现已实装 `emotions/<id>/<emo>.png` 自动等比裁切兜底（见 `05_Current_Game_Scene_References/23_prologue_sports_field.png` 姜梓惊讶头像效果）。若希望与现有 `avatars/` 统一独立出图，可按同源等比裁切导出以下 12 枚 `256×256` RGBA PNG：",
        "",
    ])
    for it in [x for x in items if x["group"] == "avatars_p1"]:
        lines.append(f"- **`{it['id']}`**（`{it['godot_drop_in_path']}`）：{it['prompt_cn']}")
    lines.append("")
    return "\n".join(lines)


def _scenes_md(items: list[dict]) -> str:
    lines = [
        "# 02 · 新序章三幕场景与战斗舞台需求清单（两阶段流程）",
        "",
        "> **安全区坐标约定（`1920×1080` 主设计画布）**：",
        "> - **剧情对话舞台**：顶部 `0..65` 场记条；中央 `65..757` 为人物与主视觉舞台（左右角色槽位 `Left x=80..800`、`Right x=1120..1840`）；底部 `711..987` 为 `StoryChrome` 手帐对话框与左下拍立得头像区；最底 `987..1080` 为操作条。",
        "> - **战斗舞台 v8**：顶部 `0..76` 为靛蓝锻带顶栏；`78..206` 为双方血条与状态标签带；`y = 634` 为统一足底站台地坪；`654..1080` 为行动手册手牌区。",
        "",
        "---",
        "",
        "## 一、Stage 1（P0 必先出）：1920×1080 整页概念母图（4 张）",
        "",
        "供主创先行审定构图比例、角色融入度与 UI 层级后再进入 Stage 2 洁净生产：",
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
        "## 二、Stage 2（P0 生产交付）：洁净无 UI / 无字 / 无人物背景底图（4 组 × 2 比例 = 8 张）",
        "",
        "> **红线**：Stage 2 交付图片中 **严禁烘焙任何 UI 边框、空白纸贴按钮、人物剪影或文字**！`2340×1080` 宽屏版须保证中心 `[210..2130]` 与 `1920×1080` 完全对位、左右各 `210px` 自然场景延展。",
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
        "## 三、P1 可选高光：操场对决双层视差过场（2 件）",
        "",
    ])
    for it in [x for x in items if x["group"] == "cutscene_p1"]:
        lines.append(f"### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}`）")
        lines.append(f"- **包内交付路径**：`{it['zip_delivery_path']}`")
        lines.append(f"- **引擎投放路径**：`{it['godot_drop_in_path']}`")
        lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


QA_SCRIPT_BODY = r'''"""Zero-dependency PNG verification tool for IGA v19 New Prologue Asset Pack."""
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
        choices=["p0", "characters_p0", "concepts_p0", "scenes_p0", "avatars_p1", "cutscene_p1", "all"],
        default="p0",
    )
    parser.add_argument("--manifest", help="Optional path to 03_asset_manifest_v19_prologue.json")
    args = parser.parse_args()

    target_root = Path(args.target_root).resolve()
    manifest_path = Path(args.manifest).resolve() if args.manifest else (Path(__file__).resolve().parents[1] / "03_asset_manifest_v19_prologue.json")
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
    ("sheet_01_ye_zhou.png", "assets/references/characters/叶舟人设图.png"),
    ("sheet_02_yang_zi_ying.png", "assets/references/characters/杨子英人设图.png"),
    ("sheet_03_liu_yu_long.png", "assets/references/characters/柳宇龙人设图.png"),
    ("sheet_04_jiang_zi.png", "assets/references/characters/姜梓人设图.png"),
    ("halfbody_ye_zhou.png", "assets/sprites/characters/phase_two/halfbody/ye_zhou.png"),
    ("halfbody_yang_zi_ying.png", "assets/sprites/characters/phase_two/halfbody/yang_zi_ying.png"),
    ("halfbody_huang_qiufeng.png", "assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png"),
    ("halfbody_liu_yu_long.png", "assets/sprites/characters/phase_two/halfbody/liu_yu_long.png"),
    ("halfbody_jiang_zi.png", "assets/sprites/characters/phase_two/halfbody/jiang_zi.png"),
    ("emotion_sample_ye_zhou_angry.png", "assets/sprites/characters/phase_two/emotions/ye_zhou/angry.png"),
    ("emotion_sample_liu_yu_long_happy.png", "assets/sprites/characters/phase_two/emotions/liu_yu_long/happy.png"),
    ("avatar_sample_ye_zhou_neutral.png", "assets/sprites/characters/phase_two/avatars/ye_zhou_neutral.png"),
    ("avatar_sample_liu_yu_long_neutral.png", "assets/sprites/characters/phase_two/avatars/liu_yu_long_neutral.png"),
    ("combat_ye_zhou_idle.png", "assets/sprites/characters/phase_three/combat/ye_zhou_idle.png"),
    ("combat_yang_zi_ying_idle.png", "assets/sprites/characters/phase_three/combat/combat_yang_zi_ying_idle.png"),
    ("combat_liu_yu_long_idle.png", "assets/sprites/characters/phase_three/combat/combat_liu_yu_long_idle.png"),
    ("combat_jiang_zi_idle.png", "assets/sprites/characters/phase_three/combat/combat_jiang_zi_idle.png"),
]

SCENE_REFS = [
    ("bg_ref_morning_road.png", "assets/backgrounds/phase_two/morning_road.png"),
    ("bg_ref_school_gate.png", "assets/backgrounds/phase_two/school_gate.png"),
    ("bg_ref_battle_campus.png", "assets/backgrounds/phase_two/battle_campus.png"),
    ("bg_ref_home_room_morning_v1.png", "assets/ui/player_experience/home_room_morning_v1.png"),
    ("ui_ref_story_chrome.png", "assets/ui/school_objects/story_chrome.png"),
    ("ui_ref_dialogue_choice_9slice.png", "assets/ui_core/theme/dialogue_choice_9slice.png"),
    ("ui_ref_combat_stage_platform_day.png", "assets/ui_core/theme/combat_stage_platform_day.png"),
    ("capture_22_prologue_sakura.png", "test_artifacts/captures_1600x900/captures/22_prologue_sakura.png"),
    ("capture_23_prologue_sports_field.png", "test_artifacts/captures_1600x900/captures/23_prologue_sports_field.png"),
    ("capture_24_prologue_duel_2v2.png", "test_artifacts/captures_1600x900/captures/24_prologue_duel_2v2.png"),
    ("capture_25_prologue_club_meeting.png", "test_artifacts/captures_1600x900/captures/25_prologue_club_meeting.png"),
]


def build_pack() -> None:
    missing_refs = [src for _dst, src in CHAR_REFS + SCENE_REFS if not (ROOT / src).is_file()]
    if missing_refs:
        raise FileNotFoundError(f"Missing reference files: {missing_refs}")

    manifest = _build_manifest()
    items = manifest["items"]

    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_ZIP.parent.mkdir(parents=True, exist_ok=True)

    (STAGING_DIR / "00_README_新序章人物与场景素材需求总控指南.md").write_text(_readme_md(manifest["counts"]), encoding="utf-8")
    (STAGING_DIR / "01_新序章人物设定与立绘头像需求清单.md").write_text(_chars_md(items), encoding="utf-8")
    (STAGING_DIR / "02_新序章三幕场景与战斗舞台需求清单.md").write_text(_scenes_md(items), encoding="utf-8")
    (STAGING_DIR / "03_asset_manifest_v19_prologue.json").write_text(
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
    (tools_dir / "qa_check_v19_prologue.py").write_text(QA_SCRIPT_BODY, encoding="utf-8")

    if ARCHIVE_ZIP.exists():
        ARCHIVE_ZIP.unlink()
    file_count = 0
    with zipfile.ZipFile(ARCHIVE_ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for path in sorted(STAGING_DIR.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(STAGING_DIR).as_posix())
                file_count += 1

    print(json.dumps({
        "ok": True,
        "zip_path": str(ARCHIVE_ZIP),
        "zip_bytes": ARCHIVE_ZIP.stat().st_size,
        "entries": file_count,
        "counts": manifest["counts"],
        "char_refs": len(CHAR_REFS),
        "scene_refs": len(SCENE_REFS),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build_pack()
