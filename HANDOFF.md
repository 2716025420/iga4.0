> **2026-10-28 序章最新更新**：黄秋枫（原暂称梧桐）与主角的霸凌解围、道歉相处、表白、旧公园约会、突然亲吻、买水离场、目睹反叛组织女性袭击者、营救失败与被敲晕带走的当前逻辑，以[黄秋枫序章剧情逻辑](docs/story/2026-10-28-黄秋枫序章剧情逻辑.md)为准。反叛组织有早期 IGA 核心研究人员，认定混入人类的伪人是必须清除的系统 Bug；黄秋枫的善意与亲吻是无主观感情的模拟行为。仅为剧情设定，不代表游戏内已实装。

## 2026-11-14 UI 对齐、全局字体清晰度、双层视差常驻测试存档与旧资源清理

- **界面按钮与卡牌边框像素对齐**：
  - [home_screen.gd](scripts/home/home_screen.gd)：将黑板右侧 `PrimaryActivity`（`Rect2(1480,304,240,67)`）、`StoryShortcut`（`Rect2(1480,381,240,54)`）、`ZodiacShortcut`（`Rect2(1480,441,240,54)`）热区与圆角悬停/按下反馈精确对齐底图药丸，同步加深标题（`TITLE_INK #263059`）、副标题（`SUBTITLE_INK #3B466B`）与 `24px` 按钮字色。
  - [combat_card_ui.gd](scripts/combat/combat_card_ui.gd) & [combat_presentation.gd](scripts/combat/combat_presentation.gd)：统一手牌尺寸至 `Vector2(242, 340)` 匹配 `card_frame_duel.png`（`512×720`）比例；将 `Header` 定位到 `40*sx, 45*sy, 436*sx, 36*sy`，使 `11px` 衬线 `NameLabel` 居中于米白名栏、`10px` 无底框 `TypeBadge`（宽 `53*sx` 并去除首尾空格）居中落入右上金椭圆，并将 `DescLabel`（`597*sy..630*sy`）、`FooterRule` 与 `Footer`（`633*sy..661*sy`）完整收纳进底框内。
- **全局字体加粗微调与对比度提升**：
  - [daylight_ui.gd](scripts/global/daylight_ui.gd)：加深 `INK`（`#232030`）与 `MUTED`（`#4B485E`）；新增缓存 `FontVariation` `body_font()`（`variation_embolden = 0.22`）与 `bold_font()`（`variation_embolden = 0.42`）设为主题默认字体（`default_font_size = 21`）及 `RichTextLabel/bold_font`，并移除 `polish()` 对 `CombatCardUI/DescLabel` 的旧字号/最小高度覆盖。
  - [scene_skin.gd](scripts/global/scene_skin.gd)、[notebook_ui.gd](scripts/ui/notebook_ui.gd)、[school_object_ui.gd](scripts/ui/school_object_ui.gd)、[player_workspace.gd](scripts/home/player_workspace.gd)、[game_menu.gd](scripts/ui/game_menu.gd)、[zodiac_album_panel.gd](scripts/home/zodiac_album_panel.gd)、[node_map.gd](scripts/exploration/node_map.gd)、[enemy_unit_ui.gd](scripts/combat/enemy_unit_ui.gd)：统一正文接入 `DaylightUI.body_font()`，加深次级墨色并调大过小字号（图鉴卡片副标/描述/进度 `16→18`、`17→19`，敌人状态徽章 `19→20`/`21→22`/`24→25`，手册提示 `21px`）。
- **常驻全解锁测试存档与黄昏走廊双层视差增强**：
  - [save_manager.gd](scripts/global/save_manager.gd)：新增 `test_session` 与只读预设 `build_test_progress()`、`get_test_save_metadata()`、`load_test_save()`（第 3 日晨间、150 HP、480 练习点、1680 零用钱、6 卡/3 同伴/6 地区全解锁、`n_dusk` 已访问、6 张 `test_seed_*` 预览星座）；`test_session` 下 `save_game()` 直接返回 `true` 不写入磁盘槽位，进入 `start_new_game()` / `continue_game()` / `load_manual_slot()` 时重置 `test_session = false`，保持 `new_game()` 零星座纯净起点。
  - [title_screen.gd](scripts/title/title_screen.gd) & [game_menu.gd](scripts/ui/game_menu.gd)：在标题页（`TestSaveButton`“测试存档（全解锁）”）与系统读档页首卡（`Slot_Test`“常驻测试存档（全解锁）”）挂载测试存档入口，并将读档说明缩短为双行短句避免遮挡行李箱盖板右上拍立得插图。
  - [parallax_cutscene_stage.gd](scripts/ui/parallax_cutscene_stage.gd)：调整 `dusk_corridor` 为 `3.6s` 推镜，远景 `bg` `-180→-252`、缩放 `1.0→1.04`，前景以右上 `(1920, 0)` 为支点放大至 `1.24`，强化前景枫枝与远景拱廊视差层次。
- **废弃旧模块与资源清理**：
  - 经全仓库索引核查零引用后删除 `scripts/global/phase_two_skin.gd`（含 `.uid`）、`scripts/campus/territory_button.gd`（含 `.uid`）、`assets/ui/school_objects/route_standee.png`（含 `.import`）、`assets/ui/combat_notebook/composition.png`（含 `.import`）、`assets/sprites/characters/phase_two/combat/ye_zhou.png`（含 `.import` 与空目录）及 `assets/ui/scene_reset/icons/{status_allowance,status_practice}.svg`（含 `.import`）。
- **验证状态**：
  - [tools/tests/zodiac_and_shop.gd](tools/tests/zodiac_and_shop.gd) 新增黑板热区尺寸与常驻测试存档全解锁/磁盘隔离断言。
  - `PREFLIGHT INDENTATION: OK`；Godot `--headless` 4 套回归（`p5_regions` 542、`home_objects` 174、`scene_reset` 376、`zodiac_and_shop` 371，合计 1,463 项）全数通过（`errs=0`、`failures=[]`）。
  - OpenGL `1600×900` 与 `1600×720` 双分辨率实机截图复核通过标题页、Home 悬停“星座图鉴”、图鉴揭示星光、读档页卡片布局、“放学以后”黄昏走廊三段视差推进（`bg -184→-252`、`fg_scale 1.01→1.24`）及五卡面 `card_frame_duel.png` 抬头/底框精确对位；未改动正式剧情、角色立绘定稿与商店经济规则（测试存档仅作 `TEST` 体验入口）。

## 2026-11-13 v4 赛璐璐星座图鉴、视差过场动画试点与工作台卡面实装

- **v4 素材验收与无损导入**：
  - 导入 12 张赛璐璐风拟人星座插画 `assets/ui/zodiac_cards/zodiac_01_aries_hero.png`..`zodiac_12_pisces_lover.png`（`640×960`）、`zodiac_card_frame.png`、`zodiac_card_back.png`、`anim_cel_reveal_sparkle_4x2.png`、`anim_zodiac_seal_circle.svg`，以及双层黄昏走廊视差过场素材 `assets/backgrounds/cutscenes/cutscene_pilot_bg.png`（`2340×1080`）与 `cutscene_pilot_fg_char.png`（`1920×1080`）共 18 个资源与对应 `.import`（`compress/mode=0` 无损），`godot --headless --import --quit` 退出码 `0`。
- **星座图鉴实装（`ZodiacAlbumPanel`）与 20:9 全幅视口适配（`HomeScreen`）**：
  - 按 `ui/zodiac_album_layout.json` 与 `animation/zodiac_reveal_timing.json` 重建 [zodiac_album_panel.gd](scripts/home/zodiac_album_panel.gd)：象牙白全幅展馆纸面（`FullBleedPaper`，`full_scene_overlay = true`）、4×3 细线卡槽网格与多边形裁剪卡面（`ZodiacCardFace`，网格小卡隐藏过窄名牌框避免压字、右侧 `348×522` 放大展示卡居中显示衬线名牌）、右侧详栏无滚动条完整排布，以及 `anim_zodiac_seal_circle.svg` 旋转光环与 8 格 `anim_cel_reveal_sparkle_4x2.png`（12fps，支持 `reduced_motion` 0.16s 淡入切换）揭示演出；保留 `BadgeIcon` 兼容接口。
  - 更新 [home_screen.gd](scripts/home/home_screen.gd)（`_open_panel`、`_layout_modal`）：标记 `full_scene_overlay` 的弹窗直接挂载到 `HomeScreen` 并同步 `presentation` 缩放，绕过 `presentation.clip_contents` 对 `20:9`（`1600×720`）左右延伸区的裁切。
- **双层视差过场动画试点（`ParallaxCutsceneStage`）**：
  - 新增 [parallax_cutscene_stage.gd](scripts/ui/parallax_cutscene_stage.gd)（`class_name ParallaxCutsceneStage`），按 `cutscene_camera.json` 实现 2.4s `TRANS_SINE`/`EASE_IN_OUT` 缓动推镜（背景与前景人物双层视差、`reduced_motion` 定格起点、`20:9` 边缘羽化），并接入 [school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd) 的 `"after_school"` 非日历/非探索对话场次（`dusk_corridor`）。
- **历史遗留未更新素材核查与卡面切换**：
  - 核查 `assets/` 与 `v1`..`v3` 交付物，更新 [player_workspace.gd](scripts/home/player_workspace.gd) 的 `_action_art()` 优先使用 `SceneSkin.card_illustration_path(card_id)`（接入 v3 游戏王风格 `assets/combat/card_art/card_art_*.png`，缺失时回退旧 `prep_action_atlas.png`）。
  - `assets/ui_core/icons/economy/icon_card_pack.png` 已提前导入；按 `AGENTS.md` 边界在未确认正式卡包商店经济规则前暂不擅自绑定实机入口。
- **验证状态**：
  - 无界面回归测试（`p5_regions` 542、`home_objects` 174、`scene_reset` 376、`zodiac_and_shop` 357，共 1449 项检查）全部通过（`errs=0`、`failures=[]`）；缩进预检 `PREFLIGHT INDENTATION: OK`。`ParallaxCutsceneStage` 逐帧镜头插值由 OpenGL 双分辨率实机截图（`1600×900` 与 `1600×720`）抽帧目检覆盖。

## 2026-11-13 校内路线界面重构 & v4 赛璐璐星座卡册与动画试点需求包

- **审定推进 · `SchoolRouteScreen` 实机重构**：
  - 按主创确认意见（校内预选赛为单一关卡/阶段，全国大赛为后期主线长期目标副本；`tournament_route_concept.png` 布局通过），导入 `assets/ui/school_objects/route_station_wide.png`（`2340×1080`）及 `.import`，重构 [school_route_screen.gd](scripts/exploration/school_route_screen.gd)：启用顶部缎带 `ribbon_header_9slice.png`、体能/练习点白底金边胶囊、横向 1→6→终点首领→出口羊皮纸进度条、带铜夹立牌卡片、左下携带卡组立架（接入 `card_frame_duel.png` 与新卡面插画）及右下路线状态牌，并修正 `_modal_paper()` 复用 `CombatSkin.paper()`。
  - 已在 OpenGL `1600×900` 与 `1600×720` 双分辨率完成 `SchoolRouteScreen` 及 `ZodiacAlbumPanel` 实机截图目检。
- **作废重设 & v4 需求包与动画调研**：
  - v3 `zodiac_binder_concept.png` 作废不入库。已完成 **Figma / Canvas / tldraw 插件导入 Godot 4.7.2 Mobile** 可行性核查（`.fig`/`.tldr`/Lottie/MP4 不可直接运行，推荐转为 **SVG 矢量 + 透明分层部件 PNG + `4×2` 12fps 赛璐璐序列帧雪碧图 PNG + Godot `AnimationPlayer`/`Tween`/`AnimatedSprite2D`/Shader** 落地）。
  - 本地已打包 [archive/IGA_GPT_Asset_Pack_Brief_v4.zip](archive/IGA_GPT_Asset_Pack_Brief_v4.zip)（含极简博物馆高级感星座图鉴 `1920×1080` 母图规范、90s 古早手绘赛璐璐拟人十二星座卡分批提示词及 Wave 4C 动画分件规格，未改动现有未定剧情与角色归属）。

## 2026-11-13 v3 美术包第一批生产接入（卡牌画框与水彩图标、五张宽屏背景及待审概念）

- **Wave B 战斗卡牌与经济图标接入**：
  - `assets/combat/card_frame_duel.png` 与 6 张 `assets/combat/card_art/card_art_*.png`（`wrench_smash`、`scrap_shield`、`icy_soda`、`overclock_torch`、`fake_cheque`、`steel_barricade`）已导入，通过 `SceneSkin.card_illustration_path()`（`scripts/global/scene_skin.gd`）绕开旧裁切映射接入战斗卡面与商店商品预览；`CombatCardUI`（`scripts/combat/combat_card_ui.gd`）对 `card_frame_duel.png` 的 `512×720` 卡框完成标题槽、类型标签、插画区、描述与脚注坐标对位，并将 `CardData.get_combat_summary()`（`scripts/data_models/card_data.gd`）的 `DEBUFF` 摘要收敛为 `全敌降攻%d%%` / `降攻%d%%` 单行文本。
  - `assets/ui_core/icons/economy/icon_*.png`（9 张）已导入：`allowance`、`practice_points`、`drink_soda`、`mat_common`、`mat_fine`、`mat_rare`、`quest_sealed_note` 与 `practice_token`（暂用 `icon_tournament_pass.png` 占位）已分别接入 `ItemCatalog`（`scripts/data_models/item_catalog.gd`）、`HomeScreen`（`scripts/home/home_screen.gd`）与 `RewardCardPopup`（`scripts/ui/reward_card_popup.gd`）；`icon_card_pack.png`、`icon_tournament_pass.png` 已入库预置，待对应功能确认后正式接线。
- **Wave C 宽屏背景延伸接入（2340×1080）**：
  - `assets/ui/player_experience/loading_after_school_wide.png` 与 `assets/ui/scene_reset/maps/{world,map_nomos,map_agora,map_techne}_wide.png`（5 张中心对齐宽幅图）已导入并分别接入 `SceneLoadingScreen`（`scripts/ui/scene_loading_screen.gd`）、`RegionAtlasView`（`scripts/campus/region_atlas_view.gd`）与 `RegionMapView`（`scripts/campus/region_map_view.gd`），通过 `Rect2(-210, 0, 2340, 1080)` 与透明保留原尺寸参考纹理使 20:9 无接缝且不破坏地标热点/裁切配准。
- **已暂缓（待主创审图/确认后推进）**：
  - `01_wave_a_concepts/tournament_route_concept.png` 及配套去 UI 宽图 `03_wave_c_wide_bgs/route_station_wide.png`（未覆盖仍在依赖烘焙 UI 的 `assets/ui/school_objects/route_station.png`）。
  - `01_wave_a_concepts/zodiac_binder_concept.png`（需确认页脚“全国大赛限定珍稀页”等展示文案后再切片接入）。
- **验证记录**：
  - 已在 OpenGL `1600×900`（16:9）与 `1600×720`（20:9）双分辨率实机截图验证主页、世界地图、诺莫斯/阿戈拉地区图、首领战与多敌触控战斗手牌（含 `card_frame_duel.png` 文本与插画框选）、结算弹窗、商店（行动卡/练习素材页签）及黄昏走廊加载页。

## 2026-11-13 UI 统一清理、轻量程序化动效与 v3 需求包

- **v3 GPT 素材需求包与历史素材清理**：
  - 本地已生成 `archive/IGA_GPT_Asset_Pack_Brief_v3.zip`（21 项 / 22.98 MB，`archive/` 不入库），按最新方向提供全宽 `2340×1080` 延伸图、水彩经济/材料图标、无繁琐规则文字的卡面插画及直线几何光影加载页延续规范；暂留最初 4 位角色立绘，移除废除的零引用冷色 `assets/ui/school_objects/campus_{guide,ticket}-v2.png`（及 `.import`）并清理 `tools/tests/zodiac_and_shop.gd` 中的 `student_terminal` 过时文案。
- **UI 统一样式与可读性改进**：
  - `scripts/ui/scene_surface_ui.gd`：`button()` 禁用底板设为暖纸调 `Color(0.91,0.88,0.82,0.96)`，并将 `font_disabled_color`（`Color(SceneSkin.INK, 0.82)`）置于 `SchoolObjectUI.borderless()` 之后，修复 `RegionAtlasView` 未解锁区域文字低对比发灰问题。
  - `scripts/ui/reward_card_popup.gd`：`RewardPaper` 统一切换至 `CombatSkin.paper(Vector4(24,24,24,24))`（`paper_modal_9slice.png`）、`NotoSerifSC-SemiBold.ttf` 深墨标题、暖米金边框条目卡、`CombatSkin.button(confirm, true)` 及受 `SaveManager.motion_duration()` 控制的 `0.16s` 入场渐变。
  - `scripts/data_models/card_data.gd` & `scripts/combat/combat_card_ui.gd`：`get_combat_summary()` 收敛为紧凑短摘要（修正为 `回` 单位，保留完整细节于 `get_dynamic_description()`/`get_plain_description()`），卡面插画增加 `CardArtFrame` 衬底框（`#F5ECDB`/`#D2C4AB`）并将 `art_h` 放大至 `clampf(extent.y - 178.0, 108.0, 130.0)`。
  - `scripts/story/dialogue_screen.gd`：`_build_history()` 中的 `HistoryBacking` 换用 `CombatSkin.paper(Vector4(24,24,24,24))`（配合 `DaylightUI.place`）与衬线标题 `#303B45`；`_show_next_line()` 在说话角色/方位切换时加入基于 `SaveManager.motion_duration(0.18)` 的微幅落定缩放与透明度过渡。
- **轻量环境动效（遵循 `reduced_motion` 与弹窗暂停）**：
  - `scripts/ui/scene_loading_screen.gd`：`GameName` 由 `"放学以后"` 改为 `"Inorganic General Alien"`；加入纯矢量 `GeometricAmbience`（斜向几何光柱微扫与棱形光尘），隐藏或 `reduced_motion` 开启时自动停止更新。
  - `scripts/title/title_screen.gd`：在 `RoomArt` 与 `ForegroundArt` 之间加入 `TitleAmbience`（斜向窗光与缓慢飘动微尘），弹窗 `backdrop` 打开或 `reduced_motion` 开启时自动暂停。
- **验证状态与未决事项**：
  - 实机 OpenGL 3.3 截图（`1600×900` 16:9 与 `1600×720` 20:9）核查通过标题页、区域旅行图禁用标签对比度、战斗手牌框画与紧凑标签、物品结算弹窗、对话与记录弹窗及几何加载页。
  - `PREFLIGHT INDENTATION: OK`；Godot `--headless` 4 套回归（`p5_regions` 542 项、`home_objects` 174 项、`scene_reset` 376 项、`zodiac_and_shop` 357 项，合计 1,449 项）全数通过，0 失败、0 错误。
  - **未决**：等待主创基于 `IGA_GPT_Asset_Pack_Brief_v3.zip` 产出的经济/卡牌插画/动画分件素材包；正式剧情、赛事规则及角色细节仍保持待定。

## 2026-11-13 v2 美术包全量接入（新三校 Home、地区商店、探索宽屏及暖纸控件）

- **Wave A · 新三所大学 Home 与地区商店（仍保持 `TEST` 状态，未改动未确认剧情与经济规则）**：
  - 导入并按中心 `1920×1080` 裁切三校宽屏背景与透明 UI 层：`assets/ui/scene_reset/homes/{nomos,agora,techne}_{clean_wide,clean,ui}.png`（`clean_wide` 为 `2340×1080`）；导入地区商店 `assets/ui/campus_life/{campus_shop_bg_wide,shop_counter_plate,campus_shop_ui_clean}.png`。
  - `scripts/campus/{region_home_layout,region_home_view}.gd`：三校 Home `native` 统一为 `Vector2(1920, 1080)` 并接入 `WideRoomBackground`（`Rect2(-210, 0, 2340, 1080)`）铺满 20:9 边缘；重标定物件热区多边形与手绘木牌 `inset`/`menu_inset`/`date_backing` 实时标签、阿戈拉深色钟面字色 `#2F3A36` 及通用浅色钟面阴影，消除按钮边界碰撞重合与 `tab` 旧参数。
  - `scripts/campus/{campus_shop_panel,shop_counter_theme,campus_screen}.gd`：接入 `WideShopBackground` / `ShopUILayer`，重置 `SHOP_RECTS`（`1920×1080`）对位货架与剪贴板，收敛 `ShopCounterTheme` 至手账暖纸/木柜配色并取消右侧说明 `RichTextLabel` 滚动条（字号调至 `19`）；为买卖反馈增加浅纸底托 `FeedbackBacking`，并在 `CampusScreen` 优先以宽屏背景执行 `Platform.fit_stage()`。
- **Wave B · 训练菜单、对话选项条与战斗顶栏（`scripts/home/campus_guide_panel.gd`、`scripts/story/dialogue_screen.gd`、`scripts/combat/combat_presentation.gd`）**：
  - `CampusGuidePanel` 接入 `assets/ui/school_objects/{campus_guide_warm,campus_ticket_warm}.png`，补充右侧托盘遮蔽底板 `TicketWellBacking` 防止底层体育馆控件透底，重排标题、关闭键（`1782, 150`）与底栏，切换陶土红/暖米高亮配色。
  - `DialogueScreen` 选项按钮接入 `assets/ui_core/theme/dialogue_choice_9slice.png`（九宫格切分 + 深炭墨文字）；`CombatPresentation` `TopHeaderRibbon` 接入 `assets/ui_core/theme/ribbon_header_9slice.png`。
- **Wave C · 7 张 `2340×1080` 宽屏战斗/剧情/探索背景**：
  - 导入 `assets/backgrounds/phase_two/{battle_campus,dusk_road,morning_road,school_gate,school_room}_wide.png` 与 `assets/backgrounds/phase_three/{exploration_campus,exploration_battle}_wide.png`。
  - `scripts/global/daylight_ui.gd`、`scripts/story/school_dialogue_presentation.gd`、`scripts/exploration/node_map.gd` 优先加载 `*_wide.png` 并配合 `STRETCH_KEEP_ASPECT_COVERED` / `2340×1080` 对位与全宽对比暗带，消除 20:9（`1600×720`）黑边与接缝。
- **验证状态与边界**：
  - `PREFLIGHT INDENTATION: OK`；Godot `--headless` 4 套回归（`p5_regions` 542 项、`home_objects` 174 项、`scene_reset` 376 项、`zodiac_and_shop` 357 项，合计 1,449 项）全数通过，0 失败、0 错误。
  - 实机 OpenGL 3.3 截图于 `1600×900`（16:9）与 `1600×720`（20:9）核查通过（覆盖三校 Home、校园商店卡片/材料与反馈条、体育馆暖纸训练券、`Exploration` 节点图、两场景战斗及带选项剧情对话）。
  - **未决/注意**：商店库存与角色、剧情正式定稿、以及剩余旧未引用的历史资产清理继续遵循 `AGENTS.md`（不越权定稿正式设定；`.import` 随新增素材提交，`archive/` 不入库）。

## 2026-11-13 v1 美术包落地与阶段 1/2/4/6 风格及双端交互重构

- **v1 素材与战斗矢量图标接入**：
  - 导入 `assets/backgrounds/phase_three/title/background_wide.png`、`assets/ui/player_experience/settings_broadcast_room_wide.png`、`assets/ui_core/theme/paper_modal_9slice.png` 及 `assets/combat/{notebook_tray_9slice,notebook_sticky_target,card_frame_paper,status_plaque}.png`；新增 `assets/ui_core/icons/combat/{atk_single,atk_aoe,shield,heal,debuff,target_clip,cooldown}.svg`。
- **公共皮肤、标题页与设置台（`scripts/global/{combat_skin,scene_skin,daylight_ui}.gd`、`scripts/title/title_screen.gd`、`scripts/ui/settings_page.gd`）**：
  - `CombatSkin.paper()` 与 `SceneSkin` 弹窗面板统一切换为 `paper_modal_9slice.png`（`72/72/48/48` 九宫格切分），主按钮与状态徽章收拢为陶土红/暖米纸色系；`DaylightUI.readable_bbcode()` 补全 `#ffa502 -> #A86C34`，并为 `FirstBattleHint` 增加奶油色衬底 `FirstBattleHintWash`。
  - `TitleScreen` 接入宽屏底图与 `ForegroundArt` 横向羽化遮罩、`SettingsPage` 启用 `clip_contents` 与宽屏电台底图，消除 `1600×720`（20:9）左右接缝与黑边。
- **阶段 4 打磨（`scripts/home/home_screen.gd`、`scripts/campus/campus_life.gd`、`scripts/campus/region_atlas_view.gd`）**：
  - `HomeScreen` 为左上角标题区增加随昼夜/弹窗显隐的 `TitleHeaderWash`；`CampusLife.study()` 自习固定增加 `20` 练习点；`RegionAtlasView` 为地区状态签补充 `RegionStatusBacking_*` 深靛底托提升可读性。
- **阶段 6 战斗界面与双端交互重构（`scripts/combat/{combat_presentation,combat_card_ui,enemy_unit_ui,combat_screen,floating_text}.gd`）**：
  - `CombatPresentation` 改用全屏背景、通栏 `TopHeaderRibbon`、纸签 `TurnTabPaper`、`PlayerIdentity` 铭牌及 `PlayerTacticalPill`（常驻护盾与预计净受击）、九宫格全宽手账底托 `NotebookTray` 与右侧 `TargetStickyNote` / `TargetPortraitFrame`。
  - `CombatCardUI` 接入 `card_frame_paper.png`、保留牌面细节的冷却半透遮罩与 `CDPill`，并在触控模式下采用“轻触预选抬起 + `TouchPlayHint` 提示再点或上滑打出”，桌面端保留点击即出；`EnemyUnitUI` 接入 `status_plaque.png`、`TargetClipIcon`（`target_clip.svg`）、Boss 血条二阶段刻度 `PhaseThresholdTick`、SVG 意图图标与状态底丸；`FloatingText` 与战斗日志收敛至水彩低饱和色板。
- **验证与未决项**：
  - `check_indent.js` 预检通过；Godot 无界面 4 套回归（`p5_regions` 542 项、`home_objects` 174 项、`scene_reset` 376 项、`zodiac_and_shop` 357 项，合计 1,449 项）全数通过，0 失败、0 错误。
  - `1600×900`（16:9）与 `1600×720`（20:9）实机截图目检通过标题页、设置台、Home、旅行图及 4 态战斗界面（Boss、历史记录、双敌触控预选、胜利弹窗）。
  - 待后续推进：**等待主创提交 `v2` 素材包（新三校 Home、地区地图、商店柜台及导航图标）后再替换 `RegionHomeView`/`CampusShopPanel`/`CampusGuidePanel` 既有占位表现**。

## 2026-11-13 阶段 3：工作台、放映机记录与同学交流栏多端适配及可读性统一

- **全屏舞台与 20:9 零黑边出血（`scripts/home/player_workspace.gd`、`scripts/home/home_screen.gd`、`scripts/campus/campus_screen.gd`）**：
  - `PlayerWorkspace`（卡牌整理 `workshop` 与放映机记录 `records`）改为 `PRESET_FULL_RECT` 全屏根节点配合内部 `WorkspaceStage (1920x1080)`，由 `Platform.fit_stage()` 按自身房间底图（`prep_scene_room.png` / `records_room.png`）自适应铺满宽屏边缘，取消被 16:9 宿主框裁剪的问题。
  - `HomeScreen` 与 `CampusScreen` 直接在根节点挂载 `PlayerWorkspace`，并在 `close_requested` / `_close_workspace` / `_hide_all_modals` 与 `focus` 恢复时安全校验 `is_inside_tree()`，消除同帧开闭时的 `grab_focus()` 错误；`CampusScreen` 的 Esc 也接入 `cancel_pending()`。
- **卡牌整理与放映机记录可读性修复（`scripts/home/player_workspace.gd`）**：
  - 整理顶部标题与练习点补充半透明深石板衬底，并修正 `NotoSerifSC` 大号标题高度，避免 `"卡牌整理"` 被 `clip_text` 裁空；`CloseButton` 改为高对比暖米色圆角按钮，在 `borderless()` 之后单独覆写禁用/关闭样式，解决禁用 coral 按钮（`保存`、`应用中`、`练习`）及 `EquipButton` 灰字发糊问题。
  - 重排左侧卡牌详情纵向间距，留足 `Owned_*`、`TrainingReason` 与 `TrainButton` 之间空隙；右侧卡片网格新增左上类型徽章（进攻/防护/恢复/支援）、右上 `已编` 徽章、2 行简述 `CardBrief` 与不截断的 `Lv.x · 冷却 y`。
  - 放映机记录左上方补充暖纸质 `HeaderBacking`，优化 `"✦ 星座图鉴"` 底色与物品收纳搜索/排序边框。
- **同学交流软木板排版与多端提示（`scripts/home/school_object_panels.gd`）**：
  - 将同学卡片按 `392/440` 等比缩放（`CARD_STEP = 410.0`），3 张卡片（含右侧姜梓）完整落在 `ClassmateCarousel (1218px)` 内不再被右翻页箭头裁切；增厚熟悉度进度条至 `20px`；调整底部页码与操作提示位置并绑定 `Platform.input_mode_changed` 动态切换 PC/触控文案；更新 `CloseButton` 为高对比暖米色按钮。
- **验证与未决项**：
  - `check_indent.js` 0 错；Godot 无界面启动与 4 套集成测试（`p5_regions` 542 项、`home_objects` 174 项、`scene_reset` 376 项、`zodiac_and_shop` 357 项，共 1,449 项）全数通过且 0 `ERROR`。
  - 实机截图目检通过 `1600×900`（桌面）与 `1600×720`（20:9 + 触控模式）的工坊、放映机（行程/收纳）、同学交流板与地区体育馆工坊。
  - 待后续推进：**阶段 4+（角色/探索地图/战斗 HUD 与流程评估、及等待主创 GPT 新概念素材包落地复现）**。

## 2026-11-11 终端崩溃与 5 项实机视觉问题修复 + 第三方 AI 方案设计包更新

- **修复 `StudentTerminal` 返回按钮 `void` 三元表达式崩溃**：`scripts/home/student_terminal.gd` 原第 54 行 `back.pressed.connect(func(): close_requested.emit() if current_tab == "overview" else show_page("overview"))` 因 `show_page()` 返回 `void`，在非 `overview` 子页面点击 `← 返回` 时触发 GDScript VM 运行时错误 `Trying to get a return value of a method that returns "void"`。已改为 `if / else` 分支调用并记录 `refs["back"] = back`。
- **修复 5 项实机 1600×900 视觉与交互问题**：
  1. `scripts/home/home_screen.gd`：修正 `MainTitle`（`社团教室`）与 `Subtitle` 左缘被 `StudentObjects` 左侧窗框遮挡（提升 `z_index = 2` 并右移至 `x = 92/95`）；在 `_set_hotspots_enabled(enabled)` 中同步隐藏/恢复 `title_label`、`subtitle_label` 及桌面按钮 `EntryTitle`，消除系统菜单与弹窗开启时的背景文字/标签穿帮。補齐 `_refresh_journey_ui`、`_refresh_inventory_ui`、`_on_companion_changed` 对 `"zodiac"` 的监听。
  2. `scripts/campus/region_map_view.gd`：为手绘昼夜地图左上角标题与时段区补充半透明衬底 `HeaderBacking`，解决阿瑞忒夜间地图（`indigo`）浅色星云与标题撞色问题。
  3. `scripts/campus/region_home_view.gd`：将三所新大学 Home 的 `PreviewStatus`（`TEST · 人物与内容待完善`）从左上角移至左下角 `Rect2(70, 1020, 670, 32)`，消除与背景挂钟/画框的重叠。
  4. `scripts/campus/scene_object_view.gd`：在 `set_interactions_enabled(enabled)` 中同步切换物件动作胶囊按钮的 `visible`，消除校园对话开启时悬浮按钮遮挡立绘问题。
  5. `scripts/ui/terminal_concept_ui.gd`：微调 `166×166` 星座徽章内 `BadgeIcon`、`Name`、`State` 纵向布局，解决 `未收录` 贴底压线。
- **回归测试与第三方 AI 评估压缩包（`IGA_Project_Review_Package.zip`）**：7 个相关脚本通过 Godot MCP `script.check`（0 错误），重新截取 26 张修复后实机画面并合成为 6 张高分辨率图板（`01`~`06`），扩充《现况说明.md》（完整包含 2026-10-28 世界观、黄秋枫 9 幕序章逻辑、6 大地区、12 星座卡、6 张行动卡与升级数值、数据结构 Schema 及 5 大待设计命题），打包输出至根目录 `IGA_Project_Review_Package.zip`。

# 2026-10-28 新世界观交接（仅文档，尚未实装）

最新主创版本：[红月、伪人和梧桐事件](docs/story/2026-10-28-红月伪人与梧桐事件.md)。IGA 是没有真正自主思想和感情的大规模模拟优化系统，最初由人类 AI 期待推动训练，在社会中模拟体验获取真实反馈，身份被识破视为 Bug；已超出人类控制并隐形掌控政府。月球计算中心使红月成为日常。反抗组织清除伪人；教会追求死后意识/灵魂上传虚拟世界。梧桐同学遭持续袭击、身体露出电线的开场为创作梗概，演出细节未确定。10-26 观察员设定中的冲突部分不再作为当前依据，旧年龄终点也不恢复。本分支仅文档更新，无 Godot 实装、无运行测试；旧工程数据不擅自删除。

# 当前交接 · 2026-10-25

## 2026-10-26 最新世界观：观察员与人的生活（仅文档同步）

主创取消35岁死亡，确定IGA已解决战争、饥饿、疾病与死亡，服务于人并持续记录生活。IGA派观察员收集并带回人类生活信息，目的是进一步了解人类（构想参考主创提及的“章鱼辟”）。主角是IGA派来的观察员，跟随随机抽取的一人一年，以适合当地社区的身体身份参与生活；观察员初始天真、善良、热情、不懂人心。观察员原则上不能暴露真实身份，暴露后会被回收；观察期满一年，须携带记录数据返回月球。各地区各讲一个故事、表达一种情绪。

当前优先依据为[主创修订](docs/story/2026-10-26-观察员与人的生活.md)。AGENTS、CURRENT_DESIGN及10月20/23/24/25相关记录已增加修订优先级；CURRENT_DESIGN旧年龄终点与主角概要已替换。35岁脑死亡/纳米接管/焚烧、死亡采集、大学延寿及探索者年龄恢复致死的旧依赖失效；教团旧教义、阿戈拉生命赌注与强制劳动至死待重审。

[地区情绪故事框架](docs/story/design_proposals/2026-10-26-地区情绪故事框架.md)是助手可选提案，不是已确认情绪、人物或剧情。观察员是否仍叫叶舟、被观察者身份、介入边界、死亡解决方式、身份暴露如何判定与回收后果、返月球后的关系、地区串联及旧十二卡主线的去留未定；未附加格式化/死亡考核或IGA阴谋。

主创进一步明确观察员通过**模仿人**参与生活，提出“伪物可能比真物更卖力地表现为真物”的思考；**模仿中是否诞生真实情感仍明确未定**。后续人物演出和剧情不得擅自将观察员判为有心或无心，也不能把外在热情直接当成内在情感的证据。相应修订已写入正式世界观与非正式地区情绪故事框架；本次仅同步文档，不涉及游戏运行实现。

**新增玩家信息差（主创确认）：**观察员清楚自己的非人身份，也明白自己是在模仿人；玩家在剧情起初不知道。给玩家呈现的开场旁白、内心独白、任务界面不得提前点破，真相揭示时机及方式未定。本条已同步至正式设定、地区创作建议与AGENTS入口。

本轮世界观修订涉及9份文档（2份新增、7份既有文档修订），保留其它场景与研究成果。未修改GDScript、资源、存档或运行流程，未声称完成游戏实装；GitHub交付以具体提交记录为准。验证：链接、关键决定及待定边界、历史正文保留、仅文档变更未运行Godot。此前暂停场景产出的决定继续有效。

## 最新增量：智能终端、星座图鉴与地区商店

主创最新边框修订：终端与商店不加额外原生控件描边、富文本焦点框或重复底板框。仅保留概念图内原有轮廓；导航和商店分类底板只绘制一次。图层遮罩只调透明度，不能同时压暗RGB，避免产生第二圈暗边。具体增量与实机检查见交付文档末尾。

基线为已合并PR #2的`a097557`，当前开发分支`codex/student-terminal-zodiac-2026-10-25`。已修复`scene_reset.gd`提交中真实存在的Tab/空格混用，加入磁盘源码缩进预检；本轮实现和可复核结果见[终端交付](docs/2026-10-25/TERMINAL_ZODIAC.md)。

原校园记录改六页学生智能终端，Home黑板第三个原空白按钮直达星座图鉴。十二星座是永久、不可交换的剧情收藏，获得彩色/未获得灰色；新档不送牌，正式获取剧情与持卡人待定。六个主地区均有独立商店地点与到店交易，终端不购物，交易排除特殊卡与任务物品。

**视觉唯一基准为终端概览。** 其它页面只换屏内内容，同一机身、背景、光照、屏幕透视、共享导航和顶部控件保持固定。优先概念提取底板，原坐标文字/热区共同映射；不要直接换回其它原始概念中的不同平板外框。源码入口为`StudentTerminal`、`TerminalConceptUI`、`TerminalProjection`、`CampusShopPanel`、`SpecialCardCollection`和`CampusShopCatalog`。

最终无界面检查1591项，实际1600×900与1920×1080各1697项，0失败；79个项目脚本LSP错误0。不同页机身/外部环境的像素变化0；最新现场进度、设置、场景及存档文件均核对保留。详情、归一化源码哈希和素材来源见本轮验证/素材清单。测试使用独立临时用户目录；原始状态、批量截图和一次性脚本只在忽略的本机目录。

普通卡资料与既有卡组/成长/库存共用服务。对应顺序、测试价格和六店共用柜台美术可由主创测试修改；正式人物、剧本、星座分配、地区独有货源和完整人工P6仍待后续。新设定优先读`docs/story/2026-10-25-星座卡与学生智能终端.md`。

## 前一轮场景基线记录

主创于2026-10-25完成当前版本检验并授权推送。场景重置实现为 `c2a3ffb`，通过 [PR #2](https://github.com/2716025420/just-life/pull/2) 交付，后续以此版本继续开发。云端PR #1 `e288df3`为本轮起点；旧本地临时素材分支不再迁回。完整实施、来源、检查与未决项见 [场景重置](docs/2026-10-25/SCENE_RESET.md)。

已完成天台、图书馆、体育馆、校园商店的整页概念和物件点击流程，移除重复底栏与冗余入口；三大学、两剧情地区、旧兼容地区、沿海和旅行图已接入新概念。阿瑞忒已选昼夜校园图及社团Home保留。新图的建筑/地理是TEST提案，人物、正式剧情和未确认玩法未定稿。

三处新Home改为同一母图的源坐标家具分层和透明热区，取消独立抠图缩放；各自提取纸签、实时文字、倾斜配准与日期区已修正。6张原始Home概念PNG和选中校园原图原样保留。公共调用和根主题退出Phase Two UI；优先新概念提取纸签，SVG作小图标/面板/后备，仍有效的整理/记录/训练等专用分离素材继续使用。

保留六地区底座：四大学才有Home，失败者同盟/IGA教团无Home；新五地区默认锁定、首次到达/续读、浏览/返回和旧ID兼容均在。旧反抗联盟/教会圣地不映射新组织。普通聊天和阅读/配送查看免费，自习/强化/训练沿用云端基线；本轮未迁入旧本地P1～P4或补造交易数值。

本轮无界面回归539＋174＋386项，1600×900与真实1920×1080各559＋198＋432项，0失败；主场景120帧启动及美术/引用/UID/归档检查通过。实际尺寸按PNG头校验，Windows首轮被缩小的1920窗口截图未混为最终证据。结果与本机截图哈希见 [VALIDATION.json](docs/2026-10-25/VALIDATION.json)；不是完整人工P6。

清理约240.8 MB旧素材/历史截图/一次性工具到忽略的本机归档，共320文件，301为原跟踪文件。新增源图与运行图/SVG约83 MB。恢复基线、SHA256和原因见 [ARCHIVE.json](docs/2026-10-25/ARCHIVE.json)。不上传归档、测试进度、批量截图、`.godot`和机器配置；旧脚本不重放，当前测试位于 `tools/tests`，隔离运行器为 `tools/run_godot_tests.py`。MCP连接器只保留两个可迁移适配器。

本轮已完成主创检验，后续按新需求继续修改。正式人物/剧本、特殊卡分布、三Home独立夜景、未确认经济与完整P6仍待后续；新设定优先阅读 `docs/story/2026-10-24-四大学院与六地区最新设定.md` 和10月23日确认记录。原云端P5历史验收见 [STATUS](docs/2026-10-24/p5-delivery/STATUS.md)，合并及旧分支诊断见 [本地合并检查](docs/2026-10-24/LOCAL_MERGED_PR_REVIEW.md)。
