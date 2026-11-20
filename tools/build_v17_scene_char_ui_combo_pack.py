"""Build IGA v17 Scene + Scene-Character Portraits + UI Kits (3-Set Combo) Brief Pack."""
from __future__ import annotations

import json
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGING_DIR = ROOT / ".godot/v17_staging/pack_root"
ARCHIVE_ZIP = ROOT / "archive/IGA_Asset_Pack_Brief_v17_Scene_Char_UI_3Sets_Combo.zip"

CHAR_STYLE_TAIL = (
    "matching IGA official character art style: crisp delicate dark-brown anime linework, "
    "clean soft cel-shading with warm atmospheric rim light matching scene lighting, "
    "isolated single character on pure transparent RGBA background, generous margin around hair and arms, "
    "zero background scenery, zero props cutting off canvas edges, zero text, zero watermarks"
)

CHAR_NEG = (
    "background scenery, room walls, white rectangular box, opaque background, multiple characters collage, "
    "extra limbs, distorted hands, text, letters, UI overlays, photorealistic, harsh muddy black shadows, watermark"
)

CONCEPT_STYLE_TAIL = (
    "vibrant Blue Archive daylight clarity blended with cozy theatrical anime cinema lighting, "
    "the character naturally integrated into the environment with matching rim light, floor contact shadow, "
    "and atmospheric perspective (NOT pasted on), leaving clean breathing space on left and top edges for game HUD, "
    "zero UI widgets, zero dialogue boxes, zero text, zero watermarks, 21:9 ultrawide 2340x1080"
)

CONCEPT_NEG = (
    "UI buttons, HUD, dialogue box, speech bubble, text, readable letters, Chinese characters, watermarks, "
    "photorealistic noise, muddy grunge, pasted cutout character look, mismatched lighting"
)

UI_NEG = (
    "text, letters, typography, Chinese characters, English words, numbers, characters, anime faces, "
    "opaque rectangular white backdrop outside rounded edges, 3D heavy bevel plastic, neon cyberpunk, "
    "messy asymmetrical border across 9-slice stretch middle, watermark"
)

CHARACTER_ANCHORS = {
    "ye_zhou": {
        "name": "叶舟",
        "ref_files": ["char_01_ye_zhou_sheet.png", "char_05_ye_zhou_halfbody.png"],
        "en_anchor": (
            "teenage boy Ye Zhou: slightly messy short dark-brown hair with soft bangs, warm amber-brown eyes, "
            "wearing muted slate-blue tailored school blazer over crisp off-white dress shirt, deep burgundy-plum necktie, dark charcoal trousers"
        ),
        "cn_anchor": "叶舟（深棕微蓬短发、暖棕琥珀眸、灰蓝西装校服+浅白衬衫+深紫红领带+深灰长裤）",
    },
    "huang_qiufeng": {
        "name": "黄秋枫",
        "ref_files": ["char_06_huang_qiufeng_halfbody.png", "char_07_huang_qiufeng_happy.png", "char_08_huang_qiufeng_shy.png"],
        "en_anchor": (
            "teenage girl Huang Qiufeng: long wavy chestnut-brown hair half-tied up with a small orange-red autumn maple leaf hairpin above left ear, "
            "warm amber-tea eyes, wearing crisp white collared shirt with deep brick-red ribbon bow, cozy cream-beige cable-knit cardigan, dark terracotta pleated skirt"
        ),
        "cn_anchor": "黄秋枫（棕色长波浪半扎发、左耳上方别橙红小枫叶发饰、暖琥珀茶眸、白衬衫+砖红领结+米杏麻花针织开衫+红棕百褶裙）",
    },
    "yang_zi_ying": {
        "name": "杨子英",
        "ref_files": ["char_02_yang_zi_ying_sheet.png", "char_09_yang_zi_ying_halfbody.png", "char_10_yang_zi_ying_fullbody.png"],
        "en_anchor": (
            "energetic teenage girl Yang Ziying: high reddish-brown ponytail, bright warm reddish-brown eyes, "
            "wearing crisp white school sailor uniform with deep burgundy collar trim and red ribbon bow, dark burgundy pleated skirt, carrying compact camera strap"
        ),
        "cn_anchor": "杨子英（偏红棕高马尾、红棕暖眸、白色水手服配深酒红领边与红领结+深酒红百褶裙，常带相机）",
    },
    "liu_yu_long": {
        "name": "柳宇龙",
        "ref_files": ["char_03_liu_yu_long_sheet.png", "char_11_liu_yu_long_halfbody.png", "char_12_liu_yu_long_fullbody.png"],
        "en_anchor": (
            "athletic carefree teenage boy Liu Yulong: tousled pale-blonde short hair, bright clear lavender-violet eyes, "
            "wearing pale lavender-gray school blazer over white shirt, dark purple-black necktie, dark charcoal trousers"
        ),
        "cn_anchor": "柳宇龙（浅金微乱短发、清亮浅紫眸、淡紫灰西装校服+浅白衬衫+紫黑领带+深灰长裤）",
    },
    "jiang_zi": {
        "name": "姜梓",
        "ref_files": ["char_04_jiang_zi_sheet.png", "char_13_jiang_zi_halfbody.png", "char_14_jiang_zi_fullbody.png", "char_21_home_seated_jiang_zi.png"],
        "en_anchor": (
            "composed studious teenage girl Jiang Zi: dark charcoal-black hair in twin braids resting over shoulders, thin round wire-frame glasses, reddish-brown eyes, "
            "wearing deep navy-blue sailor uniform with sky-blue ribbon bow, cozy cream fringed scarf, soft slate-blue pleated skirt, dark tights"
        ),
        "cn_anchor": "姜梓（黑灰双麻花辫、细圆框眼镜、红褐眸、深海军蓝水手服+浅蓝领结+奶白流苏围巾+灰蓝百褶裙+黑丝袜）",
    },
    "lin_zhi_xia": {
        "name": "林知夏",
        "ref_files": ["char_15_lin_zhi_xia_neutral.png", "char_16_lin_zhi_xia_happy.png"],
        "en_anchor": (
            "gentle librarian girl Lin Zhixia: shoulder-length wavy chestnut-brown hair with small golden double-leaf hairpin on right side, warm golden-amber eyes, "
            "wearing deep navy blazer, white shirt, khaki tie layered under warm cream cable-knit cardigan, holding neatly bound notebooks/books"
        ),
        "cn_anchor": "林知夏（栗棕齐肩微卷发、右侧金色双叶小发夹、暖金茶眸、深藏青校服西装+卡其领带+米色麻花针织开衫，常抱书）",
    },
    "tang_xiao_man": {
        "name": "唐小满",
        "ref_files": ["char_17_tang_xiao_man_neutral.png", "char_18_tang_xiao_man_happy.png"],
        "en_anchor": (
            "cheerful shopkeeper student girl Tang Xiaoman: high wavy warm chestnut-brown ponytail tied with yellow hairband, bright warm brown eyes, "
            "wearing deep plum-brown rolled-sleeve blazer, brick-red ribbon bow, neat light-khaki canvas shop apron with brass snaps and front pocket"
        ),
        "cn_anchor": "唐小满（暖栗棕高波浪马尾配黄色发圈、暖茶眸、深莓紫棕挽袖西装+砖红领结+浅卡其铜扣帆布围裙）",
    },
    "rebel_operative": {
        "name": "灰区女特工",
        "ref_files": ["char_19_rebel_masked.png", "char_20_rebel_unmasked.png"],
        "en_anchor": (
            "mysterious rebel female operative: sharp silver-gray short hair, cool steel-gray eyes with cyan tactical monocle visor over right eye, "
            "optional dark tactical respirator mask over lower face, high-collared dark taupe-brown buckled tactical trench coat and red armband with white X emblem"
        ),
        "cn_anchor": "灰区女特工（银灰干练短发、冷灰眸+右眼青色战术单目镜、可选双滤罐面罩、深灰棕多扣带高领风衣+红底白×臂章）",
    },
}

SCENE_CHAR_AND_COMBO_SPECS = [
    {
        "scene_id": "dorm",
        "scene_name": "学生宿舍",
        "primary_char": "ye_zhou",
        "sets": {
            "set_a": {
                "title": "清晨整备 · 明朗晨光",
                "char_id": "ye_zhou",
                "char_pose_cn": "清晨柔和日光从左侧洒来，叶舟轻松站姿半侧身正在单手检查战术卡匣，神态平静而略带少年干练感，带有清透清晨天光边光。",
                "char_pose_en": "standing relaxed three-quarter pose inspecting a sleek dark tactical card case in hand, calm observant expression, crisp bright morning window rim light across hair and blazer",
                "concept_cn": "带主角整合构图：清晨通透的学生宿舍单间，柔和日光从宽窗透入，叶舟站在窗畔书桌旁低头整理卡片，空间留白舒展，左侧保留余地适配场景UI停靠栏。",
                "concept_en": "Bright morning anime boarding dorm room with soft sunlight pouring through a wide window; Ye Zhou stands naturally beside the sunlit desk checking a card case, clean uncluttered composition with breathing space on left edge",
            },
            "set_b": {
                "title": "斜阳逆光 · 剧场光影",
                "char_id": "ye_zhou",
                "char_pose_cn": "强对比斜阳或窗光切面构图下的叶舟半身/七分身，单手插兜倚站、抬眼思考，衣褶呈现冷蓝暗部与暖金亮部的剧场版光影切割。",
                "char_pose_en": "leaning thoughtfully in cinematic pose with one hand in pocket looking slightly sideways, dramatic warm golden light edge against cool slate interior shadow tones",
                "concept_cn": "带主角整合构图：大广角电影感斜射阳光切片穿过学生宿舍，叶舟倚靠在窗框明暗交界处沉思，窗外是清透蓝天云层，镜头透视冲击力极强。",
                "concept_en": "Cinematic wide-angle dorm room sliced by bold diagonal afternoon sunbeams; Ye Zhou leans thoughtfully by the sunlit window edge between cool slate shadows and luminous outdoor sky",
            },
            "set_c": {
                "title": "暮蓝暖灯 · 静谧独处",
                "char_id": "ye_zhou",
                "char_pose_cn": "夜晚/黄昏桌边暖灯照明下的叶舟，微低头翻看手边便签或白羊徽记，脸上带有暖橘台灯反光与冷紫夜空反差，气氛安静温柔。",
                "char_pose_en": "seated or leaning lightly by warm desk light holding a small folded note, gentle reflective gaze illuminated by soft amber lamp glow against cool twilight shadows",
                "concept_cn": "带主角整合构图：暮蓝紫色黄昏窗景下的静谧宿舍，桌边一盏暖橘灯照亮正坐在书桌旁思考的叶舟，传递沉淀一天的温柔孤寂情绪。",
                "concept_en": "Twilight anime dorm room wrapped in cool violet-blue evening window light and one warm amber desk lamp illuminating Ye Zhou seated quietly in contemplation",
            },
        },
    },
    {
        "scene_id": "shop",
        "scene_name": "校园商店",
        "primary_char": "tang_xiao_man",
        "sets": {
            "set_a": {
                "title": "元气迎客 · 奶油薄荷小店",
                "char_id": "tang_xiao_man",
                "char_pose_cn": "正面微侧的唐小满（膝上/腰部以上适配柜台遮挡），一手轻扶文件夹或朝镜头元气挥手微笑，明亮清透的商店室内日光漫射质感。",
                "char_pose_en": "waist-up friendly welcoming pose waving cheerfully with warm bright smile, holding small clipboard lightly in other hand, bright clean pastel store daylight illumination",
                "concept_cn": "带店员整合构图：奶油白与淡薄荷青配色的校园商店，正面开阔视角，唐小满站在温润原木收银柜台后方右侧微笑迎客，货架与冷饮柜清爽整齐。",
                "concept_en": "Bright pastel cream and mint-teal anime school convenience shop front view; Tang Xiaoman stands cheerfully behind a warm wooden front counter on the right-center welcoming the visitor",
            },
            "set_b": {
                "title": "动态递物 · 广角纵深冲击",
                "char_id": "tang_xiao_man",
                "char_pose_cn": "富有透视活力的唐小满：身体微前倾，一手笑着向前递出一瓶冰镇橘子汽水，马尾随转身轻扬，冷饮柜清蓝反光与暖木店灯形成鲜明层次。",
                "char_pose_en": "dynamic waist-up lean-forward pose smiling brightly while holding out a chilled orange soda bottle toward viewer, high ponytail swinging lightly, crisp cool-blue and warm-gold store lighting",
                "concept_cn": "带店员整合构图：大广角斜向纵深感极强的校园小店，冷光玻璃饮品柜与暖黄柜台灯光交错，前景收银台后的唐小满正前倾身子递出汽水。",
                "concept_en": "Dynamic wide-angle depth view inside vibrant anime school store; behind the foreground counter Tang Xiaoman leans forward cheerfully offering an orange soda amidst cool cooler lights and warm wood shelves",
            },
            "set_c": {
                "title": "午后斜阳 · 怀旧托腮闲聊",
                "char_id": "tang_xiao_man",
                "char_pose_cn": "夏末午后斜阳暖光里的唐小满，单手支颐微歪头露出亲切俏皮笑意，发丝与围裙边缘镀上一层柔和金色夕阳绒边。",
                "char_pose_en": "relaxed waist-up pose leaning elbow lightly and resting cheek on hand with warm playful smile, soft golden-amber afternoon sunbeams catching ponytail and apron edges",
                "concept_cn": "带店员整合构图：夏末三四点的校园小店，金橙斜阳从店门落地窗拉出温柔长影，唐小满正托腮靠在柜台后方笑着和人闲聊，青春烟火气十足。",
                "concept_en": "Nostalgic late-afternoon golden sunbeams streaming through the school shop window; Tang Xiaoman rests her chin lightly behind the wooden counter chatting warmly",
            },
        },
    },
    {
        "scene_id": "rooftop",
        "scene_name": "教学楼天台",
        "primary_char": "yang_zi_ying",
        "sets": {
            "set_a": {
                "title": "晴空海风 · 杨子英摄影时光",
                "char_id": "yang_zi_ying",
                "char_pose_cn": "盛夏晴空海风下的杨子英全身/七分身，双手捧着挂颈相机微微回眸比出轻松微笑，高马尾与裙摆随海风向一侧轻扬。",
                "char_pose_en": "three-quarter cheerful pose holding compact camera near chest and turning back with bright sunny smile, high ponytail and skirt fluttering gently in crisp summer ocean breeze",
                "concept_cn": "带同伴整合构图：极度清透的盛夏蔚蓝海景教学楼天台，杨子英倚靠在透亮蓝白护栏旁拿着相机回头微笑，远方是碧海积云与白色灯塔。",
                "concept_en": "Airy bright summer anime school rooftop overlooking turquoise sea and fluffy clouds; Yang Ziying leans cheerfully by the railing with her camera turning back with a radiant smile",
            },
            "set_b": {
                "title": "云海大广角 · 柳宇龙热身邀战",
                "char_id": "liu_yu_long",
                "char_pose_cn": "宏大天空云海逆光下的柳宇龙全身/七分身，一手搭在肩后或举起一张发光战术刻印卡，露出爽朗不羁又自信满满的挑战笑容。",
                "char_pose_en": "confident athletic three-quarter pose flashing a glowing tactical card in one hand with a carefree charismatic grin, crisp summer sky highlights on blonde hair and lavender blazer",
                "concept_cn": "带同伴整合构图：强透视仰拍大广角天台，巨型立体积云铺满半壁蓝天，柳宇龙站在开阔地坪中央高举战术刻印卡潇洒邀战，冲击力极强。",
                "concept_en": "Dramatic wide-angle low-horizon school rooftop backed by monumental summer clouds and bright sea; Liu Yulong stands center-right confidently flashing a tactical card in invitation",
            },
            "set_c": {
                "title": "黄金晚霞 · 姜梓安静俯瞰",
                "char_id": "jiang_zi",
                "char_pose_cn": "黄昏暖霞逆光中的姜梓，怀抱深蓝烫金笔记本、扶了扶细圆框眼镜温柔侧望镜头，围巾与双麻花辫在夕阳海风中轻轻垂拂。",
                "char_pose_en": "serene poised three-quarter pose hugging a dark-blue notebook lightly and looking gently over her shoulder, warm sunset backlight glowing on cream scarf and twin braids",
                "concept_cn": "带同伴整合构图：黄金日落时分的海滨教学楼天台，珊瑚橙与紫蓝晚霞映亮海湾，姜梓抱书站在栏杆边静静回眸，安静又有剧情深意。",
                "concept_en": "Golden-hour sunset anime rooftop overlooking shimmering harbor; Jiang Zi stands quietly by the railing clutching a notebook, warm twilight breeze lifting her scarf",
            },
        },
    },
    {
        "scene_id": "coast",
        "scene_name": "沿海公路",
        "primary_char": "yang_zi_ying",
        "sets": {
            "set_a": {
                "title": "盛夏海堤 · 清爽并肩漫步",
                "char_id": "yang_zi_ying",
                "char_pose_cn": "盛夏阳光下自然侧身步行的杨子英，一手指向斜前方海湾或公园方向，眼神明亮充满活力，校服受碧海蓝天清透反光。",
                "char_pose_en": "lively walking three-quarter pose gesturing happily toward distant seaside path ahead, bright clear daylight bouncing soft turquoise ocean reflections onto uniform",
                "concept_cn": "带同伴整合构图：明净爽朗的阿瑞忒沿海林荫道，一侧碧海闪耀、一侧红枫小径分支，杨子英走在步道中段回头伸手指引方向。",
                "concept_en": "Sunny coastal promenade splitting toward turquoise sea stairs and shady maple park path; Yang Ziying walks ahead happily gesturing along the breezy seaside avenue",
            },
            "set_b": {
                "title": "大透视海湾 · 迎风回首张力",
                "char_id": "liu_yu_long",
                "char_pose_cn": "海风迎面吹拂的动态全身/七分身柳宇龙，迈步走在大道前方回头抬手打招呼，衣摆与金发带着清爽风感。",
                "char_pose_en": "dynamic breezy mid-stride pose looking back over shoulder with a relaxed wave and bright grin, wind sweeping through blonde hair and blazer hem",
                "concept_cn": "带同伴整合构图：电影感 S 形大弯道沿海公路，海风卷起树叶与海浪银光，柳宇龙大步走在视野中心偏右回首挥手，空间纵深与动感极强。",
                "concept_en": "Sweeping cinematic coastal road curve beside sparkling summer surf; Liu Yulong strides along the breezy boardwalk waving back with dynamic wide-horizon framing",
            },
            "set_c": {
                "title": "斜阳放学道 · 黄秋枫温柔同行",
                "char_id": "huang_qiufeng",
                "char_pose_cn": "黄昏柔光中的黄秋枫，双手轻拎着书包或轻拢被风吹乱的鬓发，带着微微慢半拍却认真注视你的柔和微笑。",
                "char_pose_en": "gentle walking pose lightly tucking windblown brown hair behind ear near maple hairpin while gazing warmly forward, soft golden-hour rim light on beige knit cardigan",
                "concept_cn": "带角色整合构图：放学斜阳染暖的沿海长堤步道，半透明金红树影洒在路面，黄秋枫站在步道暖光中央浅浅微笑着等待同行。",
                "concept_en": "Warm late-afternoon anime coastal promenade dappled in golden tree shadows; Huang Qiufeng pauses gently along the sunlit sea walkway with a soft tender smile",
            },
        },
    },
    {
        "scene_id": "old_park",
        "scene_name": "旧公园（沿海公路子场景）",
        "primary_char": "huang_qiufeng",
        "sets": {
            "set_a": {
                "title": "红枫静候 · 午后清透庭院",
                "char_id": "huang_qiufeng",
                "char_pose_cn": "双手轻叠于身前或轻坐于椅侧的黄秋枫，安静地抬头望向来人，眼神干净温柔、略带一丝笨拙的好奇与期待。",
                "char_pose_en": "gentle serene pose with hands lightly clasped in front looking calmly and sincerely toward viewer, warm soft park shade dappled light across knit cardigan",
                "concept_cn": "带角色整合构图：清透洁净的红枫银杏旧公园广场，街角立着发光橘子汽水自动贩卖机，黄秋枫安静地等候在中央树荫长椅旁。",
                "concept_en": "Clean tranquil autumn neighborhood park framed by stylized crimson maples with a glowing orange vending machine in the background corner; Huang Qiufeng waits quietly by the central wooden bench",
            },
            "set_b": {
                "title": "暮色逆光 · 心跳轻吻前夕",
                "char_id": "huang_qiufeng",
                "char_pose_cn": "强对比晚霞逆光中的黄秋枫特写半身/七分身，身体微微前倾靠近镜头，双眸倒映橙红暮光、神情专注而略带生涩的坚定感（呼应旧公园轻吻瞬间）。",
                "char_pose_en": "dramatic sunset backlit three-quarter pose leaning slightly closer toward viewer with earnest focused gaze and faint shy blush, luminous amber halo outlining wavy hair",
                "concept_cn": "带角色整合构图：极富戏剧张力的夕照红枫旧公园，炽热晚霞斜穿过树冠与长椅，黄秋枫立于长椅旁逆光微倾靠近，定格序章/第一章最令人心颤的瞬间。",
                "concept_en": "Dramatic golden-crimson dusk light piercing through secluded autumn park maples; Huang Qiufeng stands by the old park bench bathed in sunset rim light leaning closer in an unforgettable quiet moment",
            },
            "set_c": {
                "title": "橘子汽水 · 街角微羞约定",
                "char_id": "huang_qiufeng",
                "char_pose_cn": "脸颊泛起浅淡羞红的黄秋枫，怀里抱着两罐刚买回来的冰镇橘子汽水微微侧头微笑，整体被温暖的夕暮微光包裹。",
                "char_pose_en": "shy affectionate pose gently cradling two chilled orange soda cans against her cream cardigan with a soft rose blush and tender smile, cozy peach-gold twilight lighting",
                "concept_cn": "带角色整合构图：温柔暮色包裹的无人旧公园一隅，远处暖橙贩卖机微光柔和亮起，黄秋枫站在红枫长椅边微红着脸捧着橘子汽水微笑。",
                "concept_en": "Intimate twilight corner of an empty autumn park with soft warm glow from a corner vending machine; Huang Qiufeng holds two orange sodas by the bench with a gentle shy smile",
            },
        },
    },
    {
        "scene_id": "beach",
        "scene_name": "阿瑞忒海滩（沿海公路子场景）",
        "primary_char": "yang_zi_ying",
        "sets": {
            "set_a": {
                "title": "透明浅湾 · 拾材与踏浪",
                "char_id": "yang_zi_ying",
                "char_pose_cn": "在明亮海岸阳光下的杨子英，微蹲或微俯身展示刚在海边拾到的闪亮练习海岩，笑容灿烂充满夏日元气。",
                "char_pose_en": "cheerful sunlit pose bending slightly or holding out a smooth shiny sea stone found on shore with bright sparkling smile, crystal ocean light reflections",
                "concept_cn": "带同伴整合构图：澄澈透明的碧蓝浅湾沙滩，雪白细浪轻拍米白沙岸，杨子英站在浅水栈桥与沙滩交界处举起海岩笑着回望。",
                "concept_en": "Crystal-clear aquamarine anime beach and pale cream sand with wooden pier; Yang Ziying smiles brightly near the shallow surf holding up a sparkling coastal stone",
            },
            "set_b": {
                "title": "巨云栈桥 · 迎浪广角自由感",
                "char_id": "liu_yu_long",
                "char_pose_cn": "在海风大广角下的柳宇龙，脱去或敞开外套随性站于木栈桥尽头远眺海浪，扬起一只手向同伴招呼，极具盛夏少年感。",
                "char_pose_en": "exhilarated wide-breeze pose standing relaxed on coastal pier with blazer fluttering open, raising one hand in carefree greeting against dazzling sea sunlight",
                "concept_cn": "带同伴整合构图：低机位大广角震撼海滩，巍峨盛夏积云铺满蓝天，柳宇龙站在向碧海延伸的木栈桥尽头迎风挥手，青春自由感扑面而来。",
                "concept_en": "Low-angle breathtaking anime seashore beneath towering white cumulus clouds; Liu Yulong stands at the edge of the wooden pier waving freely against dazzling ocean surf",
            },
            "set_c": {
                "title": "午后金波 · 温柔海湾小憩",
                "char_id": "jiang_zi",
                "char_pose_cn": "午后温柔海风里的姜梓，坐在或倚靠在防波堤木栏旁摘下眼镜擦拭或闭眼感受海风，嘴角带着难得放松的浅笑。",
                "char_pose_en": "peaceful relaxed pose resting lightly beside coastal wooden pier railing with gentle serene smile, honey-warm afternoon ocean reflection on dark navy uniform",
                "concept_cn": "带同伴整合构图：临近黄昏前的温暖浅湾沙滩，蜂蜜般的金色海波荡漾，姜梓静静坐在防波堤阶梯旁吹海风歇息，治愈感拉满。",
                "concept_en": "Peaceful honey-warm late-afternoon sandy cove with gentle glittering ripples; Jiang Zi rests calmly by the wooden pier rail enjoying the quiet sea breeze",
            },
        },
    },
    {
        "scene_id": "library",
        "scene_name": "图书馆",
        "primary_char": "lin_zhi_xia",
        "sets": {
            "set_a": {
                "title": "海景大厅 · 林知夏迎客与阅读",
                "char_id": "lin_zhi_xia",
                "char_pose_cn": "站在原木借书台后方的林知夏（腰部以上适配前景借书台遮挡），怀抱翻开的《风物纪要》笔记本，露出温和知性的接待微笑。",
                "char_pose_en": "warm gentle librarian waist-up pose cradling open clothbound chronicle notebook with welcoming serene smile, soft bright library daylight illuminating hair clip",
                "concept_cn": "带人物整合构图：明亮通透的原木薄荷风海景图书馆，左侧弧形借书台后站着林知夏微笑迎候，右侧落地大窗前的阅读桌上黄秋枫正安静看书（双焦点层次清晰）。",
                "concept_en": "Bright sunlit coastal anime school library interior; Lin Zhixia greets gently behind a curved oak front desk on the left while Huang Qiufeng reads quietly by the huge ocean-view windows on the right",
            },
            "set_b": {
                "title": "丁达尔光束 · 书廊静谧交接",
                "char_id": "huang_qiufeng",
                "char_pose_cn": "斜射日光柱照亮侧脸与书页的黄秋枫，坐在窗边捧着一本恋爱小说微微抬眼望来，清透窗光在棕发与针织衫上勾出柔和亮边。",
                "char_pose_en": "poetic waist-up seated pose holding an open hardcover novel while looking up thoughtfully toward viewer, crisp diagonal window sunbeams catching maple hairpin and cardigan",
                "concept_cn": "带人物整合构图：挑高宏阔的原木图书馆，锐利通透的斜射日光柱穿过高窗落在窗边阅读席，黄秋枫抬起头注视来者，空气如剧场动画般透亮。",
                "concept_en": "Grand high-ceilinged anime library bathed in crisp volumetric daylight shafts; Huang Qiufeng looks up quietly from an open novel at a sunlit window table",
            },
            "set_c": {
                "title": "午后光尘 · 窗边借书卡约定",
                "char_id": "lin_zhi_xia",
                "char_pose_cn": "午后柔光中的林知夏，轻轻推过一张夹在旧书里的折角借书卡并微笑示意，眼神温和体贴，带有手绘暖纸故事氛围。",
                "char_pose_en": "gentle waist-up pose extending a book with a corner-folded library card tucked inside, tender knowing smile in warm golden dust-mote afternoon window glow",
                "concept_cn": "带人物整合构图：金色浮尘飘浮的午后靠窗图书馆一角，暖融融阳光洒在原木书架与阅读桌上，林知夏在服务台旁轻声递来新抄录的风物笔记。",
                "concept_en": "Warm peaceful afternoon corner inside a seaside anime library with golden dust motes; Lin Zhixia softly offers a newly transcribed chronicle note across the sunlit oak desk",
            },
        },
    },
    {
        "scene_id": "gym",
        "scene_name": "体育馆",
        "primary_char": "liu_yu_long",
        "sets": {
            "set_a": {
                "title": "日光木场 · 柳宇龙热身邀约",
                "char_id": "liu_yu_long",
                "char_pose_cn": "站在体育馆干净木地板上的柳宇龙全身/七分身，双臂轻松抱胸或单手叉腰、自信爽朗地大笑招呼，清爽日光洒在肩头。",
                "char_pose_en": "energetic confident three-quarter pose standing casually with arms lightly crossed or one hand on hip, bright competitive grin under clear high-window daylight",
                "concept_cn": "带同伴整合构图：高挑蓝白日光室内体育馆，干净浅枫木地板上绘有简洁赛场线，柳宇龙站在场边抱臂朝主角大笑着邀约切磋。",
                "concept_en": "Bright crisp sunlit anime indoor gymnasium with clean maple wood court and sky-blue roof trusses; Liu Yulong stands center-right grinning confidently ready for a practice match",
            },
            "set_b": {
                "title": "全息擂台 · 巡回选拔赛聚光",
                "char_id": "liu_yu_long",
                "char_pose_cn": "置于全息竞技擂台蓝白聚光灯下的柳宇龙动态半身/七分身，单手展开流光战术卡匣、眼神锐利专注进入战斗节奏，极具少年热血张力。",
                "char_pose_en": "dynamic tournament duel stance activating glowing tactical card deck with sharp focused lavender eyes and thrilling arena spotlight contrast",
                "concept_cn": "带同伴整合构图：剧场版级阿瑞忒代表选拔赛场，中央发光护盾裁决擂台聚光打亮全场，柳宇龙站在擂台边缘蓄势展开卡匣迎战。",
                "concept_en": "Epic indoor anime tournament stage inside the academy gymnasium with glowing cyan holographic arena floor and dramatic spotlights illuminating Liu Yulong readying his card deck",
            },
            "set_c": {
                "title": "斜阳加练 · 赛前沉淀微光",
                "char_id": "liu_yu_long",
                "char_pose_cn": "高窗斜阳下的柳宇龙，搭着毛巾或稍作喘息地站在场边长椅旁微笑点头，金色斜光映亮他平日少见的沉稳认真神情。",
                "char_pose_en": "quiet focused post-practice three-quarter pose with towel draped lightly around neck, calm determined smile lit by warm golden late-afternoon gym sunbeams",
                "concept_cn": "带同伴整合构图：近黄昏时分安静空旷的体育馆，高侧窗洒下浓稠金色斜阳光柱照在木地板长椅旁，柳宇龙加练完毕平静而坚定地望向赛场中央。",
                "concept_en": "Quiet late-afternoon anime school gymnasium pierced by steep golden-white sunbeams; Liu Yulong pauses beside a wooden court bench with calm pre-tournament resolve",
            },
        },
    },
]

UI_SETS = [
    {
        "set_id": "ui_set_a",
        "set_name": "UI Set A｜清透水彩和纸手帐风（日常青春基准）",
        "style_cn": "温暖米白和纸纹理（#FFFDF8）+ 薄荷青（#359686）/珊瑚红（#D45B49）手绘细线 + 哑光铜铆钉与轻微水彩边缘晕染",
        "style_en": "cozy hand-painted watercolor washi paper UI (#FFFDF8), delicate mint-teal (#359686) and coral (#D45B49) fine hand-drawn lines, subtle matte brass rivet accents, warm tactile journal craft",
    },
    {
        "set_id": "ui_set_b",
        "set_name": "UI Set B｜蔚蓝档案式通透磨砂玻璃 × 香槟金几何（高透氛围优先）",
        "style_cn": "高透光奶白/深海青磨砂玻璃（85% 通透度以透出新场景氛围）+ 极细锐利香槟金几何双线与轻微光环角标",
        "style_en": "Blue Archive inspired ultra-clean translucent frosted milk-glass and deep navy glass UI (high translucency letting background shine through), crisp hairline champagne-gold geometric trim, delicate glowing corner chevrons",
    },
    {
        "set_id": "ui_set_c",
        "set_name": "UI Set C｜复古胶片放映室 × 暖胡桃木黄铜风（电影叙事质感）",
        "style_cn": "温润羊皮纸搭配浅胡桃木细边框 + 复古黄铜卷草角花与胶片齿孔/火漆印记点缀，增强剧情故事书厚度感",
        "style_en": "vintage anime film-archive and storybook UI craft, warm cream parchment paired with smooth light-walnut wood edge trim, antique brass filigree corner brackets and subtle wax-seal accents",
    },
]

UI_COMPONENTS = [
    {
        "comp_id": "period_dial_day",
        "label": "时段表盘（晴昼）",
        "target_sub": "dials/ui_dial_morning.png",
        "w": 256,
        "h": 256,
        "min_alpha": 0.18,
        "desc_cn": "圆形怀表式昼间时段徽章，外环圆润、内部清透蓝天暖阳微景观，透明背景居中。",
        "desc_en": "circular pocket-watch time-of-day badge (bright sunny morning sky and golden sun inside), centered on pure transparent RGBA background",
    },
    {
        "comp_id": "period_dial_redmoon",
        "label": "时段表盘（红月夜）",
        "target_sub": "dials/ui_dial_redmoon.png",
        "w": 256,
        "h": 256,
        "min_alpha": 0.18,
        "desc_cn": "同系列圆形时段徽章（红月夜状态），深蓝夜空中悬着温柔却极具辨识度的绯红满月与轨道细环。",
        "desc_en": "matching circular pocket-watch badge (deep indigo night sky with luminous crimson full moon and thin white orbital ring inside), pure transparent RGBA background",
    },
    {
        "comp_id": "dock_strip_9slice",
        "label": "左侧垂直行动停靠底板",
        "target_sub": "panels/ui_hud_dock_strip_9slice.png",
        "w": 512,
        "h": 1024,
        "min_alpha": 0.02,
        "desc_cn": "竖向 9-Slice 左侧栏底板，中央大面积均匀干净用于排布行动按钮，右缘带柔和投影过渡到透明边。",
        "desc_en": "vertical 9-slice left dock sidebar panel plate, completely clean uniform center surface for readable UI text, refined vertical right-edge border fading cleanly into soft transparent drop shadow",
    },
    {
        "comp_id": "resource_capsule_9slice",
        "label": "右上资源状态胶囊条",
        "target_sub": "panels/ui_hud_resource_capsule_9slice.png",
        "w": 640,
        "h": 128,
        "min_alpha": 0.12,
        "desc_cn": "横向全圆角胶囊底板（承托体力/练习点/零用钱），四周外留透明柔影，中央干净均匀无竖分割线。",
        "desc_en": "horizontal stadium pill capsule 9-slice HUD bar centered on transparent RGBA canvas, uniform smooth interior with zero vertical dividers",
    },
    {
        "comp_id": "action_button_9slice",
        "label": "场景行动胶囊按钮",
        "target_sub": "buttons/ui_btn_cel_normal_9slice.png",
        "w": 420,
        "h": 104,
        "min_alpha": 0.14,
        "desc_cn": "用于左栏行动与对话选项的圆角胶囊按钮底图，居中留透明外阴影，中心区域平坦干净便于实时文字显示。",
        "desc_en": "9-slice horizontal rounded action button plate centered on transparent RGBA margin, crisp subtle inner highlight and completely plain readable center",
    },
    {
        "comp_id": "npc_bubble_9slice",
        "label": "人物头顶轻量交互气泡",
        "target_sub": "panels/ui_npc_bubble_9slice.png",
        "w": 360,
        "h": 112,
        "min_alpha": 0.18,
        "desc_cn": "挂在场景驻场人物头顶的小巧圆润气泡底板（带底部微小指向尖角与干净外阴影），透明背景。",
        "desc_en": "compact rounded 9-slice floating NPC speech-tag bubble with tiny clean bottom pointer tail centered on pure transparent RGBA canvas",
    },
    {
        "comp_id": "story_dialogue_panel_9slice",
        "label": "底部手帐对话条 / 弹窗主框",
        "target_sub": "panels/ui_story_dialogue_9slice.png",
        "w": 1600,
        "h": 320,
        "min_alpha": 0.08,
        "desc_cn": "横幅式手帐对话框与商店/选拔赛双栏通用底板（9-Slice 拉伸，中央大面积纯净易读，左上角留名牌视觉锚区）。",
        "desc_en": "wide horizontal 9-slice visual novel dialogue box & modal panel frame, spotless clean central reading surface with delicate top-left nameplate accent notch on transparent outer padding",
    },
]

CHAR_REF_COPY = [
    ("char_01_ye_zhou_sheet.png", "assets/references/characters/叶舟人设图.png", "叶舟官方三视图与配色人设表"),
    ("char_02_yang_zi_ying_sheet.png", "assets/references/characters/杨子英人设图.png", "杨子英官方三视图与配色人设表"),
    ("char_03_liu_yu_long_sheet.png", "assets/references/characters/柳宇龙人设图.png", "柳宇龙官方三视图与配色人设表"),
    ("char_04_jiang_zi_sheet.png", "assets/references/characters/姜梓人设图.png", "姜梓官方三视图与配色人设表"),
    ("char_05_ye_zhou_halfbody.png", "assets/sprites/characters/phase_two/halfbody/ye_zhou.png", "叶舟现行标准半身立绘"),
    ("char_06_huang_qiufeng_halfbody.png", "assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png", "黄秋枫现行标准半身立绘（含枫叶发饰与针织开衫）"),
    ("char_07_huang_qiufeng_happy.png", "assets/sprites/characters/phase_two/emotions/huang_qiufeng/happy.png", "黄秋枫微笑表情参照"),
    ("char_08_huang_qiufeng_shy.png", "assets/sprites/characters/phase_two/emotions/huang_qiufeng/shy.png", "黄秋枫害羞表情参照（适合旧公园）"),
    ("char_09_yang_zi_ying_halfbody.png", "assets/sprites/characters/phase_two/halfbody/yang_zi_ying.png", "杨子英现行半身立绘"),
    ("char_10_yang_zi_ying_fullbody.png", "assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png", "杨子英现行全身比例参照"),
    ("char_11_liu_yu_long_halfbody.png", "assets/sprites/characters/phase_two/halfbody/liu_yu_long.png", "柳宇龙现行半身立绘"),
    ("char_12_liu_yu_long_fullbody.png", "assets/sprites/characters/phase_two/fullbody/liu_yu_long.png", "柳宇龙现行全身比例参照"),
    ("char_13_jiang_zi_halfbody.png", "assets/sprites/characters/phase_two/halfbody/jiang_zi.png", "姜梓现行半身立绘"),
    ("char_14_jiang_zi_fullbody.png", "assets/sprites/characters/phase_two/fullbody/jiang_zi.png", "姜梓现行全身比例参照"),
    ("char_15_lin_zhi_xia_neutral.png", "assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_neutral.png", "林知夏图书馆驻场半身（平静）"),
    ("char_16_lin_zhi_xia_happy.png", "assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_happy.png", "林知夏图书馆驻场半身（微笑）"),
    ("char_17_tang_xiao_man_neutral.png", "assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png", "唐小满商店驻场半身（平静）"),
    ("char_18_tang_xiao_man_happy.png", "assets/sprites/characters/phase_two/halfbody/tang_xiao_man_happy.png", "唐小满商店驻场半身（微笑）"),
    ("char_19_rebel_masked.png", "assets/sprites/characters/phase_two/halfbody/rebel_operative_masked.png", "灰区女特工蒙面立绘"),
    ("char_20_rebel_unmasked.png", "assets/sprites/characters/phase_two/halfbody/rebel_operative_unmasked.png", "灰区女特工摘面具立绘"),
    ("char_21_home_seated_jiang_zi.png", "assets/ui/player_experience/home_midground_seated_v3.png", "【核心标杆】角色自然融入房间光影的坐姿立绘"),
]

UI_REF_COPY = [
    ("ref_01_approved_home_room_v3.png", "assets/ui/player_experience/home_room_v3.png", "本项目社团教室已定稿环境底图标杆"),
    ("ref_02_approved_home_desk_fg.png", "assets/ui/player_experience/home_foreground_desk_v3.png", "本项目前景桌面遮挡人物下身标杆"),
    ("ref_03_story_chrome.png", "assets/ui/school_objects/story_chrome.png", "现行主线/场景共用暖纸手帐对话框"),
    ("ref_04_paper_modal_9slice.png", "assets/ui_core/theme/paper_modal_9slice.png", "现行水彩和纸弹窗底板"),
    ("ref_05_dialogue_choice_9slice.png", "assets/ui_core/theme/dialogue_choice_9slice.png", "现行水彩对话选项条"),
    ("ref_06_ui_dial_morning.png", "assets/ui_core/v14_ui/dials/ui_dial_morning.png", "现行 v14 圆形怀表时段表盘参考"),
    ("ref_07_hud_top_and_bubbles.jpg", "docs/references/2026-11-19-scene-ui-redesign/02_UI控件与HUD布局/01_统一顶栏状态HUD与场景内联气泡_火山的女儿.jpg", "顶栏状态与气泡构图参考"),
    ("ref_08_outdoor_npc_drawer.jpg", "docs/references/2026-11-19-scene-ui-redesign/02_UI控件与HUD布局/02_户外场景NPC点击右侧抽屉菜单_火山的女儿.jpg", "户外场景人物焦点的交互视觉平衡参考"),
    ("ref_09_left_dock_and_dial.jpg", "docs/references/2026-11-19-scene-ui-redesign/02_UI控件与HUD布局/03_时段圆盘与左侧行动停靠栏_Potionomics.jpg", "左侧圆盘+垂直停靠栏+人物中心构图参考"),
    ("ref_10_npc_bubble_and_corner_hud.jpg", "docs/references/2026-11-19-scene-ui-redesign/02_UI控件与HUD布局/04_NPC头顶极简对话泡与角落定位HUD_P3R.jpg", "人物头顶轻气泡与角落极简HUD参考"),
    ("ref_11_dock_and_character_focus.jpg", "docs/references/2026-11-19-scene-ui-redesign/02_UI控件与HUD布局/05_左右功能停靠与人物视觉重心_重返未来1999.jpg", "人物焦点主导画面的UI呼应比例参考"),
]

QA_SCRIPT_BODY = r'''"""Zero-dependency PNG verification tool for IGA v17 3-Set Combo Asset Pack."""
from __future__ import annotations

import argparse
import json
import struct
import sys
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_root", help="Directory holding generated assets")
    parser.add_argument("--group", choices=["characters", "ui", "concepts", "all"], default="all")
    parser.add_argument("--manifest", help="Optional path to 04_asset_manifest_v17_combo.json")
    args = parser.parse_args()

    target_root = Path(args.target_root).resolve()
    manifest_path = Path(args.manifest).resolve() if args.manifest else (Path(__file__).resolve().parents[1] / "04_asset_manifest_v17_combo.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    items = [it for it in manifest["items"] if args.group == "all" or it["group"] == args.group]
    passed = failed = missing = 0
    for item in items:
        f = target_root / item["target_path"]
        if not f.exists():
            f_alt = target_root / f"{item['id']}.png"
            if f_alt.exists():
                f = f_alt
            else:
                print(f"[MISSING] {item['id']} -> {item['target_path']}")
                missing += 1
                continue
        info = inspect_png(f)
        errs = []
        allowed = item.get("allowed_sizes", [[item["width"], item["height"]]])
        if [info["width"], info["height"]] not in allowed:
            errs.append(f"size {info['width']}x{info['height']} not in {allowed}")
        if info["bit_depth"] != 8:
            errs.append(f"bit_depth {info['bit_depth']} != 8")
        if item["requires_alpha"]:
            if not info["has_alpha"]:
                errs.append("missing alpha channel (must be RGBA PNG)")
            elif info["transparent_ratio"] < float(item["min_transparent_ratio"]):
                errs.append(f"transparent {info['transparent_ratio']:.1%} < {float(item['min_transparent_ratio']):.1%}")
        if errs:
            print(f"[FAIL] {item['id']} -> " + "; ".join(errs))
            failed += 1
        else:
            print(f"[PASS] {item['id']} ({info['width']}x{info['height']}, alpha={info['has_alpha']}, transparent={info['transparent_ratio']:.1%})")
            passed += 1
    print(f"Summary ({args.group}): {passed} passed, {failed} failed, {missing} missing / {len(items)} total")
    return 0 if (failed == 0 and missing == 0) else 1


if __name__ == "__main__":
    raise SystemExit(main())
'''


def _build_manifest_items() -> list[dict]:
    items: list[dict] = []

    # 1. Scene-integrated character portraits (8 scenes x 3 sets = 24)
    for sc in SCENE_CHAR_AND_COMBO_SPECS:
        sid = sc["scene_id"]
        for set_id in ("set_a", "set_b", "set_c"):
            spec = sc["sets"][set_id]
            cid = spec["char_id"]
            c_info = CHARACTER_ANCHORS[cid]
            items.append({
                "id": f"char_{sid}_{set_id}_{cid}",
                "group": "characters",
                "scene_id": sid,
                "scene_name": sc["scene_name"],
                "set_id": set_id,
                "char_id": cid,
                "char_name": c_info["name"],
                "ref_files": c_info["ref_files"],
                "title": spec["title"],
                "target_path": f"v17_combo/characters/{sid}/char_{sid}_{set_id}_{cid}.png",
                "width": 1054,
                "height": 1581,
                "allowed_sizes": [[1054, 1581], [1200, 1600], [900, 1200], [1024, 1536]],
                "requires_alpha": True,
                "min_transparent_ratio": 0.25,
                "prompt_cn": f"【参考图：{', '.join(c_info['ref_files'])}】{c_info['cn_anchor']}。{spec['char_pose_cn']} 纯透明 RGBA 背景，无背景景物、无文字。",
                "prompt_en": f"{c_info['en_anchor']}; {spec['char_pose_en']}; {CHAR_STYLE_TAIL}",
                "negative_prompt": CHAR_NEG,
            })

    # 2. UI Kits (3 sets x 7 core components = 21)
    for u_set in UI_SETS:
        uid = u_set["set_id"]
        for comp in UI_COMPONENTS:
            items.append({
                "id": f"{uid}_{comp['comp_id']}",
                "group": "ui",
                "set_id": uid,
                "set_name": u_set["set_name"],
                "comp_id": comp["comp_id"],
                "label": comp["label"],
                "target_path": f"v17_combo/ui/{uid}/{comp['target_sub']}",
                "width": comp["w"],
                "height": comp["h"],
                "allowed_sizes": [[comp["w"], comp["h"]]],
                "requires_alpha": True,
                "min_transparent_ratio": comp["min_alpha"],
                "prompt_cn": f"【{u_set['set_name']}】{comp['label']}（{comp['w']}×{comp['h']} RGBA）：{comp['desc_cn']} 材质风格：{u_set['style_cn']}。严禁任何文字数字。",
                "prompt_en": f"Game UI asset ({comp['w']}x{comp['h']} RGBA): {comp['desc_en']}; art direction: {u_set['style_en']}; zero text, zero letters, zero numbers, no watermark",
                "negative_prompt": UI_NEG,
            })

    # 3. Character-integrated whole-page scene concepts (8 scenes x 3 sets = 24)
    for sc in SCENE_CHAR_AND_COMBO_SPECS:
        sid = sc["scene_id"]
        for set_id in ("set_a", "set_b", "set_c"):
            spec = sc["sets"][set_id]
            cid = spec["char_id"]
            c_info = CHARACTER_ANCHORS[cid]
            items.append({
                "id": f"combo_concept_{sid}_{set_id}",
                "group": "concepts",
                "scene_id": sid,
                "scene_name": sc["scene_name"],
                "set_id": set_id,
                "char_id": cid,
                "char_name": c_info["name"],
                "ref_files": c_info["ref_files"],
                "title": spec["title"],
                "target_path": f"v17_combo/concepts/{sid}/combo_concept_{sid}_{set_id}.png",
                "width": 2340,
                "height": 1080,
                "allowed_sizes": [[2340, 1080], [1920, 1080]],
                "requires_alpha": False,
                "min_transparent_ratio": 0.0,
                "prompt_cn": f"【参考人物：{', '.join(c_info['ref_files'])}】{spec['concept_cn']}（人物保持 {c_info['cn_anchor']} 一致，无 UI 框无文字）。",
                "prompt_en": f"{spec['concept_en']}; featuring {c_info['en_anchor']} ({spec['char_pose_en']}); {CONCEPT_STYLE_TAIL}",
                "negative_prompt": CONCEPT_NEG,
            })

    return items


def _readme_md() -> str:
    return """# IGA v17「场景 + 场景人物立绘 + UI 套件」三套组合全案需求包

> **编制日期**：2026-11-20  
> **设计定位**：解决纯空背景缺少视觉重心的问题。保留现行游戏的场景交互结构，分别提供 **「主要人物完整参照（21张）」+「8 场景驻场人物立绘 × 3 套（24项）」+「场景 UI 套件 × 3 套（21项）」+「带驻场人物焦点的整页概念图 × 3 套（24项）」**，方便您生成三套后任意组合挑选，定稿后再拆层实装！

---

## 一、三套方案如何自由组合（Mix & Match）

| 维度 | Set A（清透日常纵深） | Set B（剧场光影冲击） | Set C（诗意叙事故事感） |
| --- | --- | --- | --- |
| **人物立绘风格** | 爽朗明快日常姿态、晴空/店内漫射光 | 电影级大动作、逆光/聚光冷暖切面 | 暮色/暖灯温柔情绪、含蓄撩人氛围 |
| **场景 UI 套件** | 清透水彩和纸手帐风（和纸+薄荷/珊瑚） | 通透磨砂玻璃 × 香槟金（85%高透不挡画） | 复古胶片放映室 × 暖胡桃木黄铜风 |
| **带人整页概念** | 舒展留白视野，角色自然驻场 | 戏剧张力大广角，人物与光束交融 | 斜阳微光包围，浪漫/悬疑气氛浓 |

- **玩法建议**：
  - 您可以先按 `03_八场景带人物焦点整页概念图提示词_3套.md` 结合 `05_Main_Character_References/` 生出“有人在场景里”的整页概念图，**立刻就能看到饱满的构图与氛围冲击**；
  - 也可以直接生成 `01` 的独立场景人物立绘（3 套姿态）+ `02` 的 3 套 UI 套件，与您手上已有好氛围的场景底图自由叠加组合！

---

## 二、压缩包内容总览

- `00_README_场景人物UI三套组合总控指南.md`（本文件）
- `01_八场景驻场人物立绘需求与人设规范_3套.md`（8 位主要人物准确外貌锚点 + 8 场景 × 3 套 RGBA 透明立绘 Prompt）
- `02_场景UI套件与交互面板需求_3套.md`（保持现有 `SceneHUDLayout` 架构的 7 类核心 UI 控件 × 3 套材质风格 Prompt）
- `03_八场景带人物焦点整页概念图提示词_3套.md`（解决空场景问题：将对应人物自然融入 8 场景光影焦点）
- `04_asset_manifest_v17_combo.json`（全量 69 项机器可读交付清单）
- `05_Main_Character_References/`（**21 张主要人物官方设定图与现行标准半身/全身/表情立绘**）
- `06_UI_And_Composition_References/`（**11 张社团人物融合标杆 + 现行手帐 UI + 5 张优质游戏 HUD/构图参考**）
- `07_Tools/qa_check_v17_combo.py`（零依赖 PNG 质检工具，支持 `--group characters|ui|concepts|all`）
"""


def _chars_md(items: list[dict]) -> str:
    lines = [
        "# 01 · 主要人物参考锚点与 8 场景驻场人物立绘需求（× 3 套）",
        "",
        "> **核心说明**：为了避免立绘贴进场景后出现“僵硬站桩”或“与环境打光割裂”，本清单为每个场景设计了 **3 套不同动作姿态、情绪张力与环境光染** 的透明底立绘（RGBA PNG，2:3 或 3:4 比例均可）。生图时请务必附上 `05_Main_Character_References/` 中对应的官方人设/立绘参考图！",
        "",
        "## 一、主要人物外貌与服装锚点速查（生图垫图必看）",
        "",
    ]
    for cid, spec in CHARACTER_ANCHORS.items():
        lines.append(f"- **{spec['name']} (`{cid}`)**：{spec['cn_anchor']} ｜ 参考文件：`{', '.join(spec['ref_files'])}`")
    lines.append("")
    lines.append("## 二、八场景专属驻场人物立绘清单（24 项，RGBA 透明底）")
    lines.append("")

    cur_scene = ""
    for it in [x for x in items if x["group"] == "characters"]:
        if it["scene_id"] != cur_scene:
            cur_scene = it["scene_id"]
            lines.append(f"### {it['scene_name']} (`{cur_scene}`)")
            lines.append("")
        lines.append(f"#### `{it['id']}` · {it['char_name']} — {it['title']} (`{it['set_id']}`)")
        lines.append(f"- **必垫参考图**：`05_Main_Character_References/{', 05_Main_Character_References/'.join(it['ref_files'])}`")
        lines.append(f"- **建议规格**：`1054×1581`（或 `1200×1600` / `900×1200`）RGBA 真透明 PNG，透明边距 ≥ 25%")
        lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


def _ui_md(items: list[dict]) -> str:
    lines = [
        "# 02 · 场景 UI 套件与交互面板需求（保留现有布局结构 × 3 套）",
        "",
        "> **结构说明**：保留游戏现行 `SceneHUDLayout` 骨架（左上方时段表盘 + 左侧垂直功能停靠栏 + 右上体力/练习点/零用钱胶囊 + 行动胶囊按钮 + 人物头顶轻量气泡 + 底部手帐对话框/双栏面板），提供 **3 套风格迥异、可任意与场景底图搭配的 UI 皮肤**。生图时可参考 `06_UI_And_Composition_References/`。",
        "",
    ]
    cur_set = ""
    for it in [x for x in items if x["group"] == "ui"]:
        if it["set_id"] != cur_set:
            cur_set = it["set_id"]
            lines.append(f"## {it['set_name']}")
            lines.append("")
        lines.append(f"### `{it['id']}` · {it['label']}（`{it['width']}×{it['height']}` RGBA）")
        lines.append(f"- **归档路径**：`{it['target_path']}`")
        lines.append(f"- **中文制作指令**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


def _concepts_md(items: list[dict]) -> str:
    lines = [
        "# 03 · 8 场景「带驻场人物焦点」整页概念图提示词（× 3 套）",
        "",
        "> **解决痛点**：纯空房间/纯空街道生成出来往往显得空荡缺少第一眼冲击力。本清单在 **不限制具体家具小物件发挥、不烘焙文字和 UI 按钮** 的前提下，直接把对应驻场角色安排在光影视觉中心，供您搭配 `05_Main_Character_References/` 一次性生成充满剧情张力与整体感的画面；挑定组合后再做拆分实装！",
        "",
    ]
    cur_scene = ""
    for it in [x for x in items if x["group"] == "concepts"]:
        if it["scene_id"] != cur_scene:
            cur_scene = it["scene_id"]
            lines.append(f"## {it['scene_name']} (`{cur_scene}`)")
            lines.append("")
        lines.append(f"### `{it['id']}` · {it['title']}（含人物：{it['char_name']}）")
        lines.append(f"- **建议垫人物图**：`05_Main_Character_References/{', 05_Main_Character_References/'.join(it['ref_files'])}`")
        lines.append(f"- **画幅规格**：`2340×1080`（或 `1920×1080`）整页 PNG")
        lines.append(f"- **中文画面构思**：{it['prompt_cn']}")
        lines.append(f"- **Prompt (EN)**：\n  ```text\n  {it['prompt_en']}\n  ```")
        lines.append(f"- **Negative Prompt**：\n  ```text\n  {it['negative_prompt']}\n  ```")
        lines.append("")
    return "\n".join(lines)


def build_pack() -> None:
    if STAGING_DIR.exists():
        shutil.rmtree(STAGING_DIR)
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    ARCHIVE_ZIP.parent.mkdir(parents=True, exist_ok=True)

    items = _build_manifest_items()

    (STAGING_DIR / "00_README_场景人物UI三套组合总控指南.md").write_text(_readme_md(), encoding="utf-8")
    (STAGING_DIR / "01_八场景驻场人物立绘需求与人设规范_3套.md").write_text(_chars_md(items), encoding="utf-8")
    (STAGING_DIR / "02_场景UI套件与交互面板需求_3套.md").write_text(_ui_md(items), encoding="utf-8")
    (STAGING_DIR / "03_八场景带人物焦点整页概念图提示词_3套.md").write_text(_concepts_md(items), encoding="utf-8")

    manifest_payload = {
        "version": "v17_scene_char_ui_3sets_combo",
        "generated_date": "2026-11-20",
        "counts": {
            "characters": sum(1 for x in items if x["group"] == "characters"),
            "ui": sum(1 for x in items if x["group"] == "ui"),
            "concepts": sum(1 for x in items if x["group"] == "concepts"),
            "total": len(items),
        },
        "items": items,
    }
    (STAGING_DIR / "04_asset_manifest_v17_combo.json").write_text(
        json.dumps(manifest_payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    char_dir = STAGING_DIR / "05_Main_Character_References"
    char_dir.mkdir(parents=True, exist_ok=True)
    for dst_name, rel_src, _desc in CHAR_REF_COPY:
        src = ROOT / rel_src
        if not src.is_file():
            raise FileNotFoundError(f"Missing character reference: {src}")
        shutil.copy2(src, char_dir / dst_name)

    ui_dir = STAGING_DIR / "06_UI_And_Composition_References"
    ui_dir.mkdir(parents=True, exist_ok=True)
    for dst_name, rel_src, _desc in UI_REF_COPY:
        src = ROOT / rel_src
        if not src.is_file():
            raise FileNotFoundError(f"Missing UI/composition reference: {src}")
        shutil.copy2(src, ui_dir / dst_name)

    tools_dir = STAGING_DIR / "07_Tools"
    tools_dir.mkdir(parents=True, exist_ok=True)
    (tools_dir / "qa_check_v17_combo.py").write_text(QA_SCRIPT_BODY, encoding="utf-8")

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
        "counts": manifest_payload["counts"],
        "char_refs": len(CHAR_REF_COPY),
        "ui_refs": len(UI_REF_COPY),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    build_pack()
