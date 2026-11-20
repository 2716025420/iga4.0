"""Build v18 Asset Brief Pack for Shop Counter & Gym Qualifier Windows (3 Concept Sets + Split Specs)."""
from __future__ import annotations

import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_DIR = ROOT / "archive"
OUT_ZIP = ARCHIVE_DIR / "IGA_Asset_Pack_Brief_v18_Shop_Gym_Windows_3Sets.zip"

README_MD = """# IGA 美术需求包 v18：商店柜台商品窗口 & 体育馆大赛窗口（三套概念图方案 + 拆层总控）

本需求包专为「阿瑞忒·商店柜台商品窗口（`CampusShopPanel`）」与「阿瑞忒巡回代表选拔赛窗口（`QualifierModal`）」的界面视觉升级设计，严格遵循项目 `AGENTS.md` 中的**「1920×1080 整页概念母图 → 主创选定 → 透明拆层落地」**两阶段流程：

## 工作流说明
1. **第一阶段（先出 6 张整页概念母图供三选一）**：
   - 分别生成「商店柜台商品窗口」的 **Set A / Set B / Set C** 3 张 `1920×1080` 完整实机概念图，以及「体育馆大赛窗口」的 **Set A / Set B / Set C** 3 张 `1920×1080` 完整实机概念图。
   - **重要**：第一阶段必须包含完整 UI 边框、中文标题/按钮排版示意、商品卡片/对手头像布局以及右侧/背后场景融合效果，方便直接同屏对比选定方案。
2. **第二阶段（中选后拆出透明分层，程序实时还原文字与交互）**：
   - 待主创从三套概念中各自选定一套后，仅对选中套装拆分 `layers_shop`（11 件）与 `layers_gym`（11 件）透明九宫格/装饰底图。
   - **拆层红线**：第二阶段分层的 PNG **绝不可烘焙任何中文文字、价格数字、静态商品图或角色/对手肖像**；圆角外轮廓保留透明 Alpha 通道，中心平铺区纹理均匀以便 Godot `StyleBoxTexture` 九宫格无痕拉伸。

## 压缩包目录结构
- `00_README_商店与体育馆窗口三套概念与拆层总控指南.md` — 本总控指南
- `01_商店柜台商品窗口_三套整页概念图提示词与布局规格.md` — 商店三套提示词 + 精确坐标骨架 + Phase 2 拆层清单
- `02_体育馆大赛窗口_三套整页概念图提示词与布局规格.md` — 体育馆三套提示词 + 精确坐标骨架 + Phase 2 拆层清单
- `03_asset_manifest_v18_windows.json` — 机读清单（`concepts` 6 张 + `layers_shop` 11 件 + `layers_gym` 11 件，含尺寸与九宫格边距）
- `04_Current_Game_Stage_And_UI_References/` — 当前游戏实机截图、v17 舞台前景中景图层、v17 UI Set A 风格锚点、唐小满/叶舟/柳宇龙/选手立绘与卡图经济图标参考
- `05_External_UI_References/` — 精选外部排版参考（Potionomics / 蔚蓝档案 / 火山的女儿）
- `06_Tools/qa_check_v18_windows.py` — 产图自检脚本（支持 `--group concepts|layers_shop|layers_gym|all`）

## 核心统一规范
- 目标画布：`1920×1080`（需同时兼容 `1600×900` 与 `1600×720` 等比例适配）。
- 整体调性：延续 **Inorganic General Alien（IGA）** 晴空沿海校园轻科幻日系手账感，清澈明快、可点击要素与文本对比度高（深藏青文字 `#1E314D` 配高亮底板）。
- 注意事项：严禁把唐小满或体育馆背景画死在 UI 九宫格框里；第二阶段拆层只需输出纯净框体、标签底片、状态卡底板与徽章贴片。
"""

SHOP_MD = """# 01｜商店柜台商品窗口（`CampusShopPanel`）：三套整页概念图 + 拆层规格

> 画布基准：`1920×1080`；左侧主货架账本板占据 `x: 28..1004`，右侧保留透明视窗与店内实时实景（唐小满站于柜台后方偏右迎客，上方挂聊天气泡与零用钱胶囊）。

---

## 一、精确控件定尺（概念图与程序共用）

| 区域 / 控件名 | 坐标 `(x, y, w, h)` | 视觉功能与交互反馈 |
| :--- | :--- | :--- |
| `ProductsBoard` | `(28, 22, 976, 1036)` | 左侧商店主窗口大底板，承载标题、分类、商品网与详情区 |
| `LocationName` / `LocalService` | `(54, 38, 440, 44)` / `(56, 82, 430, 28)` | 「阿瑞忒 · 商店柜台」+「战术刻印卡 · 练习素材 · 饮品补给」 |
| `Mode_buy` / `Mode_sell` / `CloseButton` | `(506,44,130,52)` / `(648,44,152,52)` / `(812,44,166,52)` | 购买 / 物品回收 / 返回柜台 × |
| `Category_cards` / `materials` / `supplies` / `FilterUnowned` | `y=126`, w=`220`/`220`/`220`/`210`, h=`46` | 行动卡 / 练习素材 / 饮品补给 / 仅看未拥有 |
| `ProductsScroll` & `ProductsGrid` | `(52, 186, 928, 466)` | 3 列商品网格，每张商品卡 `288×218`（含 `248×124` 卡图、名称、单价或「已拥有」标识） |
| `DetailBoard` | `(52, 668, 928, 312)` | 下半部商品详情与结账区：左侧预览图 `(74,738,214,126)` + 说明 `(304,740,312,124)`；右侧 `- 1 +` 数量步进、`合计 / 余款`、珊瑚红主确认钮 `(646,856,296,62)` |
| `Rules` | `(56, 1018, 920, 28)` | 底部提示：「交易不消耗活动次数 · 已上架行动卡 16/16 款（随主线推进到货）」 |
| `ClerkSpeechBubble` & `Talk` | `(1038, 96, 594, 114)` & `(1650, 118, 234, 54)` | 右半屏上方唐小满店员语音气泡与「和唐小满聊聊」按钮 |
| `BalanceBacking` | `(1622, 26, 272, 56)` | 右上角零用钱计数胶囊（与主 HUD `ui_hud_resource_capsule_9slice` 同高同风格） |

> 参考底图见 `04_Current_Game_Stage_And_UI_References/captures/09_shop_counter.png` 及 `assets_stage/shop_*`。

---

## 二、三套整页概念母图设计方案（每套均输出 `1920×1080` PNG）

### 方案 A（Set A · 推荐）：晴空手账玻璃柜台（延续 v17 UI Set A）
- **视觉定位**：清澈日系轻手账 + 薄荷绿点心屋玻璃镶边，与 `04_Current_Game_Stage_And_UI_References/ui_v17_a/` 中的顶栏胶囊与气泡完全同源。
- **材质配色**：外框奶白硬卡纸 `#FCF9F2` 配薄荷绿描边 `#359686` 与极浅玻璃内高光；激活页签「行动卡」「购买」用柔和海风青绿 `#2D8C7F`；选中商品卡发金色/青绿双层柔光边框；左下主结账按钮用明亮珊瑚橙红 `#E05A47`；右上方气泡与右上胶囊同步带浅薄荷描边。
- **中文生图提示词**：`1920x1080 游戏 UI 整页概念设计图，参考当前右侧校园商店明亮阳光场景与微笑挥手的褐色高马尾女店员（唐小满），左半屏（宽约976px）放置高完成度日系二次元手账玻璃风格商店主面板「阿瑞忒·商店柜台」：顶部暖奶白标题栏含「购买 / 物品回收 / 返回柜台×」胶囊按钮；第二行青绿高亮标签「行动卡」及「练习素材 / 饮品补给 / 仅看未拥有」；中部 3 列 2 行共 6 张精致圆角商品卡展示色彩鲜明的战术卡牌缩略图、名称与「已拥有」轻角标，其中一张带高光选中框；下方分隔出清晰商品详情结算区，含左侧放大卡图与描述、右侧 `- 1 +` 数量胶囊和珊瑚红「确认购买」按钮；右半屏通透展示店员立绘、左上角带三角尾标店员气泡「唐小满：欢迎光临...」、右上角「零用钱 1680」圆润胶囊及「和唐小满聊聊」按钮。整体光线通透明快，界面层级清晰、无杂乱噪点、保留完美 16:9 实机 UI 感。`
- **English Prompt**：`Full 1920x1080 anime campus game UI concept master of a split-screen shop counter window matching sunny mint-cream bakery/card shop interior on the right half (smiling brown high-ponytail shopkeeper behind wooden counter, beverage fridge in sunlight) and a crisp sunlit coastal stationery glass-edged ledger board occupying the left half (x 28..1004). Clean cream paper card base (#FCF9F2) with soft mint-teal trim (#359686), sleek rounded capsule tabs ("购买 / 物品回收 / 返回柜台×", category tabs "行动卡 / 练习素材 / 饮品补给 / 仅看未拥有"), a 3x2 grid of neatly framed tactical card item tiles with subtle gold/teal selected highlight and neat corner badges, and a lower checkout detail sub-card featuring zoomed preview, description text, -/+ stepper, and a tactile coral-red purchase button. Top right features a matching translucent speech bubble with speaker tag, "Talk" button, and an aligned pill currency capsule. Ultra crisp 2D cel anime UI typography layout, sunlit clean composition.`

### 方案 B（Set B）：海岸小卖部木框便利贴（*Potionomics* 温情手作货架感）
- **视觉定位**：温润浅橡木展示架 + 牛皮便利贴，强调学园社团小卖部的烟火气息，强化商品“实体陈列感”。
- **材质配色**：主面板外缘采用浅枫木镶框 `#C8A072` 配内衬温暖米黄卡纸 `#FAF2E2`；每格商品像嵌在木格橱窗里的小方卡，右上角带一枚淡牛皮/红印「已拥有」胶带贴纸；数量加减区做成像机械价格签；右半屏保持店员实体柜台自然延伸，气泡做成像手写便条夹。
- **中文生图提示词**：`1920x1080 二次元学园商店整页 UI 概念设计，参考 Potionomics 左货架详情与右店员同屏布局及我方晴空校园小卖部场景：左侧大面板为温润浅橡木边框配米白手账木格陈列柜「阿瑞忒·商店柜台」，顶部黄铜铆钉风切换钮与「返回柜台」木牌；分类签做成像便利贴指数卡签；中部 3×2 木格货架摆放高对比度卡牌与饮品缩略图，角部带小小牛皮纸胶带与印章标签，选中格泛暖橙微光；底部为撕边便签质感详情结账区与珊瑚红封印「购买结算」印钮；右侧留足通透空间展示店员唐小满在木质柜台后热情推荐，气泡为带小夹子的浅纸签造型，右上角挂木纹边框零用钱铭牌。温暖治愈、日系精致立绘感、16:9 完整实机画面。`
- **English Prompt**：`Full 1920x1080 cozy anime school shop UI concept master blending left display shelf panel and right live counter character scene cleanly. Left half features a warm light-oak wooden frame display board filled with ivory cardstock shelves ("阿瑞忒·商店柜台"), index-card category tabs, 3x2 wooden display cubbies holding bright tactical cards and soda icons with small masking-tape corner accents and glowing orange selection frame, plus a lower ledger detail notepad with tactile brass-trimmed +/- quantity dials and warm terracotta purchase button. Right half keeps the sunlit counter shopkeeper girl completely unobstructed with a clipped-note speech bubble above her head and compact allowance badge at top-right. High clarity, handcrafted stationery aesthetic, anime game UI.`

### 方案 C（Set C）：刻印战术终端展柜（*Blue Archive* 清爽轻科幻陈列感）
- **视觉定位**：配合游戏世界观中「战术刻印卡 + 学生智能终端」的校园轻科幻质感，使用倾斜切片高光、瓷白板与清澈天蓝/海青色阶，视觉对比极其明快利落。
- **材质配色**：洁净瓷白底板 `#F3F8FD` 配极细学院蓝描边 `#3A78BD` 及右上角浅斜切几何网格暗纹；激活页签带轻微菱形斜角（仿 BA 商店页签）；商品格左下或右下带简洁青色价格铭牌，选中格呈现清爽天空蓝流光边框；底部详情板呈简洁双栏仪表盘形态。
- **中文生图提示词**：`1920x1080 蔚蓝档案风格清爽轻科幻校园商店整页 UI 概念图：右半屏呈现阳光通透的小卖部场景与唐小满店员，左半屏放置干净利落的瓷白与学院天蓝配色商店终端柜面板「阿瑞忒·商店柜台」。顶部为微斜切胶囊切换按钮与明快深青蓝文字；类别栏使用带斜切边的高亮激活标签「行动卡」与灰白未选中标签；中部 3×2 商品矩阵整齐陈列高饱和卡牌插画，卡片角标为简洁斜切状态标签，选中卡带亮天蓝外发光边框；底部详情结算区自带微透蓝网格暗纹，右侧为清爽几何风 `- 1 +` 计数条与高对比珊瑚橙主确认钮；右上角零用钱胶囊与唐小满气泡统一采用轻玻璃拟态与天蓝细线。干净锋利、高可读性、无杂乱装饰。`
- **English Prompt**：`Full 1920x1080 crisp Blue Archive inspired anime tactical card shop UI concept master. Right half shows the bright seaside school store and cheerful clerk Tang Xiaoman clearly; left half houses a sleek porcelain-white and sky-blue (#3A78BD) catalog terminal panel with subtle diagonal geometric corner accents. Angled capsule mode buttons ("购买 / 物品回收 / 返回柜台×"), crisp chamfered category tabs, neat 3x2 product cards with vibrant card thumbnails, clean price chips, and glowing cyan selection outline; bottom checkout module with enlarged card preview, crisp description space, geometric +/- stepper, and coral-orange confirm button. Clean glass-morphic speaker bubble and top-right currency capsule. Ultra clean vector-like anime UI, readable hierarchy.`

---

## 三、第二阶段（选定后拆层规范：`layers_shop` 共 11 件）

待主创从 A / B / C 选定一款后，仅按中选套装输出下列透明底组件 PNG（无任何静态汉字/数字）：
1. `ui_shop_ledger_board_9slice.png` (`320×320` / RGBA / margin `48,48,48,48`) — 左侧商店主账本大底板
2. `ui_shop_detail_board_9slice.png` (`240×180` / RGBA / margin `36,36,36,36`) — 下方详情结算板底图
3. `ui_shop_clerk_bubble_9slice.png` (`240×120` / RGBA / margin `32,32,32,32`) — 右侧唐小满语音气泡框
4. `ui_shop_balance_capsule_9slice.png` (`220×64` / RGBA / margin `30,18,30,18`) — 右上零用钱胶囊框
5. `ui_shop_card_normal_9slice.png` (`288×218` / RGBA / margin `26,26,26,26`) — 商品网格卡常态底板
6. `ui_shop_card_selected_9slice.png` (`288×218` / RGBA / margin `28,28,28,28`) — 商品网格卡选中高亮底板
7. `ui_shop_tab_active_9slice.png` (`180×56` / RGBA / margin `24,14,24,14`) — 激活态页签/模式按钮
8. `ui_shop_tab_idle_9slice.png` (`180×56` / RGBA / margin `24,14,24,14`) — 常态未激活页签按钮
9. `ui_shop_btn_confirm_9slice.png` (`220×64` / RGBA / margin `26,16,26,16`) — 主操作珊瑚色确认按钮底板
10. `ui_shop_qty_pill_9slice.png` (`96×56` / RGBA / margin `18,14,18,14`) — `- / +` 数量步进小按钮底板
11. `ui_shop_badge_owned.png` (`128×44` / RGBA / margin `16,10,16,10`) — 卡牌/商品「已拥有」纯色底徽章贴片（不含文字）
"""

GYM_MD = """# 02｜体育馆大赛窗口（`QualifierModal`）：三套整页概念图 + 拆层规格

> 画布基准：`1920×1080`；背景为蓝色玻璃海景体育馆大厅 + 半透明暗遮罩，主弹窗居中于 `Rect2(240, 130, 1440, 820)`。

---

## 一、精确控件定尺（概念图与程序共用）

| 区域 / 控件名 | 坐标 `(x, y, w, h)`（相对整页或弹窗） | 视觉功能与交互反馈 |
| :--- | :--- | :--- |
| 背景遮罩 `QualifierBackdrop` | 全屏覆罩 | `Color(0.12, 0.16, 0.25, 0.56)` 半透明微醺遮罩压暗四周体育馆 |
| `QualifierModal`（主窗体） | 整页 `(240, 130, 1440, 820)` | 居中大型双栏赛事公告窗口 |
| `QualifierTitle` & `QualifierSub` | 窗内 `(44, 28, 720, 50)` / `(44, 80, 960, 32)` | 「阿瑞忒巡回代表选拔赛」+「按顺序赢得 3 轮非致命学园护盾裁决…」 |
| `AtlasPreviewButton`（通关解锁后） & `CloseButton` | 窗内 `(1044, 30, 194, 56)` / `(1254, 30, 148, 56)` | 右上「巡回总图 →」（金色，3战全胜后显示）+ 「返回 ×」常驻按钮 |
| `QualifierLeftCol`（左栏编组战绩板） | 窗内 `(40, 126, 404, 656)` | 垂直信息栏，含叶舟头像 `(26,24,108,108)`、代表进度（`0/3 胜`）、卡匣状态（`5/5`）、随行协战（杨子英）、星座共鸣（白羊座）、底部 `GotoWorkshopBtn`「整备行动卡匣 →」 `(26,566,352,62)` |
| `RoundRow_1..3`（右栏三轮赛程卡） | 窗内 `(464, 126 + i*224, 936, 206)` | 3 张横向赛程卡（第1战 新锐资格战 / 第2战 双人战术演武 / 第3战 阿瑞忒首席代表战） |
| ├─ `EnemyFrame` | 卡内 `(18, 18, 154, 170)` | 对手全身/立绘肖像展示窗（第1轮：王牌代表；第2轮：柳宇龙；第3轮：全国种子） |
| ├─ `Title` / `Sub` / `Reward` | 卡内 `x=192`, `y=20/66/138` | 轮次标题、规则说明、奖励（零用钱·练习点·代表通行章）与当前状态提示 |
| └─ `Challenge_1..3` | 卡内 `(704, 68, 208, 70)` | 右侧主状态动作钮：当前可战（珊瑚红「登台挑战」）、已胜（青绿「再次切磋」）、未解锁（柔灰「待解锁」） |

> 参考底图见 `04_Current_Game_Stage_And_UI_References/captures/10_gym_qualifier.png` 及 `assets_stage/gym_*`。

---

## 二、三套整页概念母图设计方案（每套均输出 `1920×1080` PNG）

### 方案 A（Set A · 推荐）：晴空体育馆竞技告示牌（延续 v17 UI Set A）
- **视觉定位**：延续 v17 Set A 清新校园风并融入体育馆玻璃钢架钴蓝质感，通透明亮、不压抑，同时用高饱和竞技橙红与青绿清晰拉开 3 轮解锁进度。
- **材质配色**：主窗瓷白略暖纸板 `#F9FBFE` 配体育馆钴蓝描边 `#3668A8` 与微金属斜切角饰；左栏叶舟信息卡用柔白带微浅海蓝框线；右侧当前可登台第 1 轮卡片用柔橙暖边突出，按钮使用醒目竞技能量橙红 `#DC5842`；已通关卡带清澈青绿 `#2F9484`；第 3 轮锁定态呈淡冷静灰蓝质感，并带小小通行章剪影徽记。
- **中文生图提示词**：`1920x1080 二次元学园竞技赛事整页 UI 概念设计图：背景为半透明深蓝微压暗的蓝色海景玻璃体育馆与发光战台，正中放置清晰通透的双栏主弹窗「阿瑞忒巡回代表选拔赛」（1440×820）。主体为瓷白带精细学院钴蓝（#3668A8）线条与微金属角饰的赛程大窗，右上角放置圆润「返回×」胶囊按钮；左栏垂直选手状态板顶部展示主角叶舟头像框、代表资格进度「0/3 胜」，中部规整列出「当前出战卡匣 5/5」「随行协战：杨子英」「星座共鸣」，底部配有蓝绿描边「整备行动卡匣 →」按钮；右栏自上而下排列三张横向赛程卡：第1轮带暖橙高亮边界、左侧立绘窗与右侧鲜明珊瑚橙「登台挑战」主钮；第2轮与第3轮呈干净灰蓝未解锁状态与「待解锁」按钮（第3轮隐约点缀代表通行章奖励标识）。极高文字可读性，清爽阳光轻运动风。`
- **English Prompt**：`Full 1920x1080 bright anime sports-club tournament modal UI concept master centered over a softly dimmed sunlit blue glass-roof seaside arena background. Crisp porcelain-white modal frame (#F9FBFE, 1440x820 zone) with refined stadium cobalt-blue (#3668A8) borders, subtle brushed metallic corner accents, and clean top-right "返回 ×" pill button. Left vertical column (404px wide) displays player Ye Zhou avatar badge, "0/3 Wins" progress, deck readout, companion assist summary, zodiac slot, and bottom secondary button "整备行动卡匣 →". Right column presents 3 stacked horizontal bout cards: Round 1 highlighted with active warm accent border, character frame on left, reward/summary text in center, and bold coral-red "登台挑战" CTA button on right; Rounds 2 & 3 neatly styled in locked cool slate state with muted "待解锁" buttons and subtle champion pass emblem hint on Round 3. Ultra clean cel anime game UI.`

### 方案 B（Set B）：阿瑞忒金红锦标赛手册（传统学园杯赛荣誉册）
- **视觉定位**：把「赢取阿瑞忒代表通行章」作为核心仪式感，融合 *火山的女儿* 暖纸双栏与竞技绶带印章设计，典雅又不失少年感。
- **材质配色**：温暖象牙手账纸面 `#FBF5E8` 配学院暗金框线 `#C69948` 与绯红绸带顶眉；左上带一枚小小阿瑞忒绿色/金色学院书签折角；第 3 轮卡带精致金色奖章边框提示「阿瑞忒代表通行章」终极目标；挑战主按钮带轻微金线描边绯红填充。
- **中文生图提示词**：`1920x1080 学院锦标赛荣誉手册风格全屏 UI 概念设计：背景为半透明压暗的蓝色体育馆舞台，居中展示暖象牙纸张与学院暗金（#C69948）细边框的「阿瑞忒巡回代表选拔赛」大弹窗。顶部有精致微金缎带抬头装饰与「返回×」按钮；左栏编组卡带温柔羊皮纸质感与叶舟头像、出战卡匣与协战清单；右栏三张并排赛程横卡呈现档案赛程页效果：第1轮活跃卡片用绯红金边「登台挑战」醒目按钮点亮，第2轮「柳宇龙」及第3轮压轴战卡边镶金色细框与「代表通行章」印记，已获胜/未解锁状态徽章清晰区分。复古优雅、高对比深藏青中文排版、细腻日系手账画风。`
- **English Prompt**：`Full 1920x1080 warm ivory tournament ledger modal UI concept over a dimmed blue campus stadium stage. Centered 1440x820 cream parchment-toned frame bordered with refined academic gold trim (#C69948) and subtle crimson ribbon accent at the top header ("阿瑞忒巡回代表选拔赛"). Left column resembles a neat competitor dossier card featuring Ye Zhou portrait box, win counter, deck count, assist partner, zodiac slot, and workshop button. Right column stacks 3 horizontal match cards styled like tournament brackets: Round 1 active card glows softly with crimson-gold bordered "登台挑战" button; Round 3 subtly wears a gold crest trim denoting the Regional Pass reward. Crisp dark-navy typography readability, refined cel anime illustration UI.`

### 方案 C（Set C）：战术终端电子赛程看板（*Blue Archive* 竞技场风格）
- **视觉定位**：直接呼应体育馆内的蓝光六角全息擂台与学生终端赛前检录体验，用斜切色块、科技蓝指示条与紧凑清晰的状态徽章表现极强现代战术感。
- **材质配色**：亮雪白功能底板 `#F2F7FC` + 体育馆电光青蓝 `#2C82D8` + 细微点阵网格暗纹；三张赛程横卡左侧头像框做成轻微斜切运动边框；状态分明——可挑战轮左缘亮起橙红色垂直指示条、已通关轮亮起翠绿对勾条、未解锁轮用淡网格灰锁定遮罩。
- **中文生图提示词**：`1920x1080 蔚蓝档案竞技场电子看板风整页 UI 概念设计图：底层为隐约可见蓝色六角战台的体育馆场景，居中打开亮雪白配电光天蓝（#2C82D8）的「阿瑞忒巡回代表选拔赛」电子赛程面板。右上带简洁科技风「返回×」按钮；左栏选手数据面板顶部为叶舟高清证件头像框、代表赛进度条与下方的卡匣/协战/星座模块；右栏三张赛程横卡自带极淡点阵工程暗纹与左侧状态色条——第1轮左侧亮珊瑚橙条、选手框呈利落微斜切造型、右侧高对比橙红斜角钮「登台挑战」；第2、第3轮呈规整冷静浅灰锁定状态与状态标签，整体极度干净锐利、无多余杂线、典型现代日式策略手游赛程UI。`
- **English Prompt**：`Full 1920x1080 modern Blue Archive arena bracket UI concept master centered over a subtly dimmed glowing-platform blue gymnasium. Sleek bright snow-white modal panel (#F2F7FC) accented with electric cyan-blue (#2C82D8) chamfered header bar, faint blueprint dot-grid watermark, and clean "返回 ×" pill. Left player status column neatly frames Ye Zhou avatar badge, 0/3 tournament rank bar, 5/5 deck indicator, assist specs, and crisp workshop button. Right column shows 3 sharp horizontal match cards with left status indicator bars and slanted portrait frames: Round 1 highlights active status with coral-orange side bar and bold slanted "登台挑战" button; Rounds 2 & 3 use crisp cool muted slate locking styling. Ultra clean vector precision anime UI.`

---

## 三、第二阶段（选定后拆层规范：`layers_gym` 共 11 件）

待主创从 A / B / C 选定一款后，仅按中选套装输出下列透明底组件 PNG（无任何静态汉字/数字）：
1. `ui_gym_modal_board_9slice.png` (`360×280` / RGBA / margin `56,64,56,48`) — 选拔赛主窗口外框底板
2. `ui_gym_left_col_9slice.png` (`240×320` / RGBA / margin `32,32,32,32`) — 左栏选手出战状态垂直卡底板
3. `ui_gym_round_row_active_9slice.png` (`360×160` / RGBA / margin `40,28,40,28`) — 右栏当前可挑战赛程卡底板
4. `ui_gym_round_row_won_9slice.png` (`360×160` / RGBA / margin `40,28,40,28`) — 右栏已通关赛程卡底板
5. `ui_gym_round_row_locked_9slice.png` (`360×160` / RGBA / margin `40,28,40,28`) — 右栏未解锁赛程卡底板
6. `ui_gym_enemy_frame_9slice.png` (`154×170` / RGBA / margin `22,22,22,22`) — 对手立绘相框底板
7. `ui_gym_btn_challenge_active_9slice.png` (`208×70` / RGBA / margin `24,16,24,16`) — 主挑战钮（登台挑战态）
8. `ui_gym_btn_challenge_won_9slice.png` (`208×70` / RGBA / margin `24,16,24,16`) — 已胜再战钮（再次切磋态）
9. `ui_gym_btn_challenge_locked_9slice.png` (`208×70` / RGBA / margin `24,16,24,16`) — 未解锁灰按钮（待解锁态）
10. `ui_gym_btn_secondary_9slice.png` (`240×62` / RGBA / margin `24,14,24,14`) — 整备行动卡匣 / 巡回总图次级按钮底板
11. `ui_gym_badge_pass_ribbon.png` (`140×48` / RGBA / margin `18,10,18,10`) — 通行章/冠军印记装饰小缎带贴片（不含文字）
"""

MANIFEST = {
    "pack_version": "v18_shop_gym_windows_3sets",
    "target_resolution": [1920, 1080],
    "workflow": {
        "phase_1": "Generate all 6 whole-page 1920x1080 concepts (3 sets for Shop Counter Window + 3 sets for Gym Qualifier Window) for selection.",
        "phase_2": "After user selects 1 set per window, export only that set's transparent split 9-slice/badge assets with zero baked Chinese text/numbers/dynamic icons."
    },
    "concepts": [
        {"id": "concept_shop_set_a", "window": "shop_counter", "set": "A", "label": "晴空手账玻璃柜台（衔接v17 Set A）", "file": "concepts/concept_shop_set_a.png", "width": 1920, "height": 1080, "alpha_required": False},
        {"id": "concept_shop_set_b", "window": "shop_counter", "set": "B", "label": "海岸小卖部木框便利贴（Potionomics）", "file": "concepts/concept_shop_set_b.png", "width": 1920, "height": 1080, "alpha_required": False},
        {"id": "concept_shop_set_c", "window": "shop_counter", "set": "C", "label": "刻印战术终端展柜（Blue Archive）", "file": "concepts/concept_shop_set_c.png", "width": 1920, "height": 1080, "alpha_required": False},
        {"id": "concept_gym_set_a", "window": "gym_qualifier", "set": "A", "label": "晴空体育馆竞技告示牌（衔接v17 Set A）", "file": "concepts/concept_gym_set_a.png", "width": 1920, "height": 1080, "alpha_required": False},
        {"id": "concept_gym_set_b", "window": "gym_qualifier", "set": "B", "label": "阿瑞忒金红锦标赛手册", "file": "concepts/concept_gym_set_b.png", "width": 1920, "height": 1080, "alpha_required": False},
        {"id": "concept_gym_set_c", "window": "gym_qualifier", "set": "C", "label": "战术终端电子赛程看板（Blue Archive）", "file": "concepts/concept_gym_set_c.png", "width": 1920, "height": 1080, "alpha_required": False},
    ],
    "layers_shop": [
        {"id": "ui_shop_ledger_board_9slice", "file": "layers_shop/ui_shop_ledger_board_9slice.png", "width": 320, "height": 320, "margins": [48, 48, 48, 48], "alpha_required": True, "godot_target": "ProductsBoard"},
        {"id": "ui_shop_detail_board_9slice", "file": "layers_shop/ui_shop_detail_board_9slice.png", "width": 240, "height": 180, "margins": [36, 36, 36, 36], "alpha_required": True, "godot_target": "DetailBoard"},
        {"id": "ui_shop_clerk_bubble_9slice", "file": "layers_shop/ui_shop_clerk_bubble_9slice.png", "width": 240, "height": 120, "margins": [32, 32, 32, 32], "alpha_required": True, "godot_target": "ClerkSpeechBubble"},
        {"id": "ui_shop_balance_capsule_9slice", "file": "layers_shop/ui_shop_balance_capsule_9slice.png", "width": 220, "height": 64, "margins": [30, 18, 30, 18], "alpha_required": True, "godot_target": "BalanceBacking"},
        {"id": "ui_shop_card_normal_9slice", "file": "layers_shop/ui_shop_card_normal_9slice.png", "width": 288, "height": 218, "margins": [26, 26, 26, 26], "alpha_required": True, "godot_target": "Product_* (normal)"},
        {"id": "ui_shop_card_selected_9slice", "file": "layers_shop/ui_shop_card_selected_9slice.png", "width": 288, "height": 218, "margins": [28, 28, 28, 28], "alpha_required": True, "godot_target": "Product_* (selected)"},
        {"id": "ui_shop_tab_active_9slice", "file": "layers_shop/ui_shop_tab_active_9slice.png", "width": 180, "height": 56, "margins": [24, 14, 24, 14], "alpha_required": True, "godot_target": "Mode_* / Category_* (active)"},
        {"id": "ui_shop_tab_idle_9slice", "file": "layers_shop/ui_shop_tab_idle_9slice.png", "width": 180, "height": 56, "margins": [24, 14, 24, 14], "alpha_required": True, "godot_target": "Mode_* / Category_* / Close (idle)"},
        {"id": "ui_shop_btn_confirm_9slice", "file": "layers_shop/ui_shop_btn_confirm_9slice.png", "width": 220, "height": 64, "margins": [26, 16, 26, 16], "alpha_required": True, "godot_target": "ConfirmTrade"},
        {"id": "ui_shop_qty_pill_9slice", "file": "layers_shop/ui_shop_qty_pill_9slice.png", "width": 96, "height": 56, "margins": [18, 14, 18, 14], "alpha_required": True, "godot_target": "QuantityMinus / QuantityPlus"},
        {"id": "ui_shop_badge_owned", "file": "layers_shop/ui_shop_badge_owned.png", "width": 128, "height": 44, "margins": [16, 10, 16, 10], "alpha_required": True, "godot_target": "Product owned corner pill"},
    ],
    "layers_gym": [
        {"id": "ui_gym_modal_board_9slice", "file": "layers_gym/ui_gym_modal_board_9slice.png", "width": 360, "height": 280, "margins": [56, 64, 56, 48], "alpha_required": True, "godot_target": "QualifierModal"},
        {"id": "ui_gym_left_col_9slice", "file": "layers_gym/ui_gym_left_col_9slice.png", "width": 240, "height": 320, "margins": [32, 32, 32, 32], "alpha_required": True, "godot_target": "QualifierLeftCol"},
        {"id": "ui_gym_round_row_active_9slice", "file": "layers_gym/ui_gym_round_row_active_9slice.png", "width": 360, "height": 160, "margins": [40, 28, 40, 28], "alpha_required": True, "godot_target": "RoundRow_* (unlocked)"},
        {"id": "ui_gym_round_row_won_9slice", "file": "layers_gym/ui_gym_round_row_won_9slice.png", "width": 360, "height": 160, "margins": [40, 28, 40, 28], "alpha_required": True, "godot_target": "RoundRow_* (won)"},
        {"id": "ui_gym_round_row_locked_9slice", "file": "layers_gym/ui_gym_round_row_locked_9slice.png", "width": 360, "height": 160, "margins": [40, 28, 40, 28], "alpha_required": True, "godot_target": "RoundRow_* (locked)"},
        {"id": "ui_gym_enemy_frame_9slice", "file": "layers_gym/ui_gym_enemy_frame_9slice.png", "width": 154, "height": 170, "margins": [22, 22, 22, 22], "alpha_required": True, "godot_target": "EnemyFrame"},
        {"id": "ui_gym_btn_challenge_active_9slice", "file": "layers_gym/ui_gym_btn_challenge_active_9slice.png", "width": 208, "height": 70, "margins": [24, 16, 24, 16], "alpha_required": True, "godot_target": "Challenge_* (unlocked)"},
        {"id": "ui_gym_btn_challenge_won_9slice", "file": "layers_gym/ui_gym_btn_challenge_won_9slice.png", "width": 208, "height": 70, "margins": [24, 16, 24, 16], "alpha_required": True, "godot_target": "Challenge_* (won)"},
        {"id": "ui_gym_btn_challenge_locked_9slice", "file": "layers_gym/ui_gym_btn_challenge_locked_9slice.png", "width": 208, "height": 70, "margins": [24, 16, 24, 16], "alpha_required": True, "godot_target": "Challenge_* (locked)"},
        {"id": "ui_gym_btn_secondary_9slice", "file": "layers_gym/ui_gym_btn_secondary_9slice.png", "width": 240, "height": 62, "margins": [24, 14, 24, 14], "alpha_required": True, "godot_target": "GotoWorkshopBtn / CloseButton / AtlasPreviewButton"},
        {"id": "ui_gym_badge_pass_ribbon", "file": "layers_gym/ui_gym_badge_pass_ribbon.png", "width": 140, "height": 48, "margins": [18, 10, 18, 10], "alpha_required": True, "godot_target": "Qualifier pass / ribbon tag"},
    ],
}

QA_SCRIPT = '''"""Validate v18 concepts and Phase 2 split layers against 03_asset_manifest_v18_windows.json."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from PIL import Image


def check_item(base: Path, item: dict) -> list[str]:
    errs: list[str] = []
    path = base / item["file"]
    if not path.exists():
        return [f"MISSING: {item['file']}"]
    with Image.open(path) as img:
        w, h = img.size
        exp_w, exp_h = int(item["width"]), int(item["height"])
        if (w, h) != (exp_w, exp_h):
            errs.append(f"SIZE {item['file']}: got {w}x{h}, expected {exp_w}x{exp_h}")
        if item.get("alpha_required", False):
            rgba = img.convert("RGBA")
            alpha = list(rgba.getdata(3))
            trans_ratio = sum(1 for a in alpha if a < 250) / max(1, len(alpha))
            if trans_ratio < 0.01:
                errs.append(f"ALPHA {item['file']}: expected rounded/cutout transparent corners, transparent_ratio={trans_ratio:.4f}")
    return errs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    ap.add_argument("--manifest", type=Path, default=Path(__file__).resolve().parents[1] / "03_asset_manifest_v18_windows.json")
    ap.add_argument("--group", choices=["concepts", "layers_shop", "layers_gym", "all"], default="concepts")
    args = ap.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    groups = ["concepts", "layers_shop", "layers_gym"] if args.group == "all" else [args.group]
    all_errs: list[str] = []
    checked = 0
    for grp in groups:
        for item in manifest.get(grp, []):
            checked += 1
            all_errs.extend(check_item(args.root, item))
    print(json.dumps({"group": args.group, "checked": checked, "error_count": len(all_errs), "errors": all_errs}, ensure_ascii=False, indent=2))
    return 0 if not all_errs else 1


if __name__ == "__main__":
    raise SystemExit(main())
'''

# Relative source -> path inside 04_Current_Game_Stage_And_UI_References/ & 05_External_UI_References/
STAGE_UI_REFS = [
    ("test_artifacts/captures_1600x900/captures/08_shop_npc.png", "04_Current_Game_Stage_And_UI_References/captures/08_shop_npc.png"),
    ("test_artifacts/captures_1600x900/captures/09_shop_counter.png", "04_Current_Game_Stage_And_UI_References/captures/09_shop_counter.png"),
    ("test_artifacts/captures_1600x900/captures/10_gym_qualifier.png", "04_Current_Game_Stage_And_UI_References/captures/10_gym_qualifier.png"),
    ("test_artifacts/captures_1600x900/captures/16_gym_stage.png", "04_Current_Game_Stage_And_UI_References/captures/16_gym_stage.png"),
    ("assets/ui/scene_reset/staged/shop/shop_sky_wide.png", "04_Current_Game_Stage_And_UI_References/stage_shop/shop_sky_wide.png"),
    ("assets/ui/scene_reset/staged/shop/shop_midground_wide.png", "04_Current_Game_Stage_And_UI_References/stage_shop/shop_midground_wide.png"),
    ("assets/ui/scene_reset/staged/shop/shop_foreground_wide.png", "04_Current_Game_Stage_And_UI_References/stage_shop/shop_foreground_wide.png"),
    ("assets/ui/scene_reset/staged/shop/actors/a_sprite.png", "04_Current_Game_Stage_And_UI_References/stage_shop/a_sprite_tang_xiaoman.png"),
    ("assets/ui/scene_reset/staged/gym/gym_sky_wide.png", "04_Current_Game_Stage_And_UI_References/stage_gym/gym_sky_wide.png"),
    ("assets/ui/scene_reset/staged/gym/gym_midground_wide.png", "04_Current_Game_Stage_And_UI_References/stage_gym/gym_midground_wide.png"),
    ("assets/ui/scene_reset/staged/gym/gym_foreground_wide.png", "04_Current_Game_Stage_And_UI_References/stage_gym/gym_foreground_wide.png"),
    ("assets/ui/scene_reset/staged/gym/actors/b_sprite.png", "04_Current_Game_Stage_And_UI_References/stage_gym/b_sprite_liu_yulong.png"),
    ("assets/ui_core/v17_ui_a/panels/ui_hud_dock_strip_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_v17_a/ui_hud_dock_strip_9slice.png"),
    ("assets/ui_core/v17_ui_a/panels/ui_hud_resource_capsule_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_v17_a/ui_hud_resource_capsule_9slice.png"),
    ("assets/ui_core/v17_ui_a/panels/ui_npc_bubble_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_v17_a/ui_npc_bubble_9slice.png"),
    ("assets/ui_core/v17_ui_a/panels/ui_story_dialogue_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_v17_a/ui_story_dialogue_9slice.png"),
    ("assets/ui_core/v17_ui_a/buttons/ui_btn_cel_normal_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_v17_a/ui_btn_cel_normal_9slice.png"),
    ("assets/ui_core/theme/paper_modal_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_legacy_theme/paper_modal_9slice.png"),
    ("assets/ui_core/theme/ui_tutorial_callout_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_legacy_theme/ui_tutorial_callout_9slice.png"),
    ("assets/ui_core/theme/ribbon_header_9slice.png", "04_Current_Game_Stage_And_UI_References/ui_legacy_theme/ribbon_header_9slice.png"),
    ("assets/ui_core/v14_ui/buttons/ui_seal_claimed_badge.png", "04_Current_Game_Stage_And_UI_References/ui_legacy_theme/ui_seal_claimed_badge.png"),
    ("assets/sprites/characters/phase_two/avatars/ye_zhou_neutral.png", "04_Current_Game_Stage_And_UI_References/characters/ye_zhou_neutral.png"),
    ("assets/sprites/characters/phase_two/avatars/ye_zhou_happy.png", "04_Current_Game_Stage_And_UI_References/characters/ye_zhou_happy.png"),
    ("assets/sprites/characters/phase_two/avatars/tang_xiao_man_neutral.png", "04_Current_Game_Stage_And_UI_References/characters/tang_xiao_man_neutral.png"),
    ("assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png", "04_Current_Game_Stage_And_UI_References/characters/halfbody_tang_xiao_man_neutral.png"),
    ("assets/sprites/characters/phase_two/halfbody/tang_xiao_man_happy.png", "04_Current_Game_Stage_And_UI_References/characters/halfbody_tang_xiao_man_happy.png"),
    ("assets/sprites/characters/phase_two/portraits/liu_yu_long.png", "04_Current_Game_Stage_And_UI_References/characters/portrait_liu_yu_long.png"),
    ("assets/sprites/enemies/phase_three/enemy_duel_student_ace.png", "04_Current_Game_Stage_And_UI_References/enemies/enemy_duel_student_ace.png"),
    ("assets/sprites/enemies/phase_three/enemy_national_finalist.png", "04_Current_Game_Stage_And_UI_References/enemies/enemy_national_finalist.png"),
    ("assets/combat/card_art/card_art_wrench_smash.png", "04_Current_Game_Stage_And_UI_References/sample_cards/card_art_wrench_smash.png"),
    ("assets/combat/card_art/card_art_scrap_shield.png", "04_Current_Game_Stage_And_UI_References/sample_cards/card_art_scrap_shield.png"),
    ("assets/combat/card_art/card_art_icy_soda.png", "04_Current_Game_Stage_And_UI_References/sample_cards/card_art_icy_soda.png"),
    ("assets/combat/card_art/card_art_overclock_torch.png", "04_Current_Game_Stage_And_UI_References/sample_cards/card_art_overclock_torch.png"),
    ("assets/combat/card_art/card_art_desk_vault.png", "04_Current_Game_Stage_And_UI_References/sample_cards/card_art_desk_vault.png"),
    ("assets/combat/card_art/card_art_tag_assist.png", "04_Current_Game_Stage_And_UI_References/sample_cards/card_art_tag_assist.png"),
    ("assets/ui_core/icons/economy/icon_allowance.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_allowance.png"),
    ("assets/ui_core/icons/economy/icon_drink_soda.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_drink_soda.png"),
    ("assets/ui_core/icons/economy/icon_mat_common.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_mat_common.png"),
    ("assets/ui_core/icons/economy/icon_mat_fine.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_mat_fine.png"),
    ("assets/ui_core/icons/economy/icon_mat_rare.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_mat_rare.png"),
    ("assets/ui_core/icons/economy/icon_practice_points.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_practice_points.png"),
    ("assets/ui_core/icons/economy/icon_tournament_pass.png", "04_Current_Game_Stage_And_UI_References/economy_icons/icon_tournament_pass.png"),
]

EXTERNAL_REFS = [
    ("docs/references/2026-11-19-scene-ui-redesign/03_交互窗口与商店选拔赛/01_商店左货架详情与右店员同屏融合_Potionomics.jpg", "05_External_UI_References/01_商店左货架详情与右店员同屏融合_Potionomics.jpg"),
    ("docs/references/2026-11-19-scene-ui-redesign/03_交互窗口与商店选拔赛/02_商店左侧分类签与规整商品卡_蔚蓝档案.webp", "05_External_UI_References/02_商店左侧分类签与规整商品卡_蔚蓝档案.webp"),
    ("docs/references/2026-11-19-scene-ui-redesign/03_交互窗口与商店选拔赛/03_选拔赛窗口_左战绩编组与右三轮对手卡_蔚蓝档案.png", "05_External_UI_References/03_选拔赛窗口_左战绩编组与右三轮对手卡_蔚蓝档案.png"),
    ("docs/references/2026-11-19-scene-ui-redesign/03_交互窗口与商店选拔赛/05_暖纸双栏功能弹窗排版_火山的女儿.jpg", "05_External_UI_References/05_暖纸双栏功能弹窗排版_火山的女儿.jpg"),
]


def main() -> int:
    missing: list[str] = []
    for rel_src, _ in STAGE_UI_REFS + EXTERNAL_REFS:
        if not (ROOT / rel_src).is_file():
            missing.append(rel_src)
    if missing:
        print(json.dumps({"ok": False, "missing": missing}, ensure_ascii=False, indent=2))
        return 1

    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(OUT_ZIP, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        zf.writestr("00_README_商店与体育馆窗口三套概念与拆层总控指南.md", README_MD.encode("utf-8"))
        zf.writestr("01_商店柜台商品窗口_三套整页概念图提示词与布局规格.md", SHOP_MD.encode("utf-8"))
        zf.writestr("02_体育馆大赛窗口_三套整页概念图提示词与布局规格.md", GYM_MD.encode("utf-8"))
        zf.writestr("03_asset_manifest_v18_windows.json", json.dumps(MANIFEST, ensure_ascii=False, indent=2).encode("utf-8"))
        zf.writestr("06_Tools/qa_check_v18_windows.py", QA_SCRIPT.encode("utf-8"))

        for rel_src, arc_dst in STAGE_UI_REFS + EXTERNAL_REFS:
            zf.write(ROOT / rel_src, arcname=arc_dst)

    print(json.dumps({
        "ok": True,
        "zip_path": str(OUT_ZIP),
        "zip_bytes": OUT_ZIP.stat().st_size,
        "docs_count": 4,
        "tools_count": 1,
        "stage_ui_refs": len(STAGE_UI_REFS),
        "external_refs": len(EXTERNAL_REFS),
        "concepts_spec": len(MANIFEST["concepts"]),
        "layers_shop_spec": len(MANIFEST["layers_shop"]),
        "layers_gym_spec": len(MANIFEST["layers_gym"]),
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
