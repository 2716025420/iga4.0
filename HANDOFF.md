> **2026-11-14 全案重构最新基线**：[世界观与全案重构设计书](docs/story/2026-11-14-世界观与全案重构设计书.md) 已确认作后续剧本、系统、UI 与素材需求的最高优先级总纲；以下旧 10-28 提示保留溯源。
> **2026-10-28 序章历史说明**：黄秋枫（原暂称梧桐）序章原始脉络见[黄秋枫序章剧情逻辑](docs/story/2026-10-28-黄秋枫序章剧情逻辑.md)。

## 2026-11-20 冗余代码/素材清理、免费商用 BGM/SFX 实装与商店/选拔赛窗口 v18 三套需求交付

- **状态**：完成仓库冗余资产与死代码精简，实装 7 首免费商用背景音乐（PeriTune CC-BY 4.0）与 17 枚免费商用音效（Kenney CC0 1.0），并打包交付「商店柜台商品窗口 (`CampusShopPanel`) & 体育馆代表选拔赛窗口 (`QualifierModal`)」v18 三套整页概念图与二阶段拆层需求压缩包。**`smoke` 全量回归与双分辨率 OpenGL 实机截图全通过**。
- **冗余素材与代码清理**：
  - 删除 `193` 个废止与冗余文件（释放 `85.28 MB`）：含 `art/`、原尺寸冗余 `assets/sprites/characters/v17_scene/`、`phase_two/expressions/`、旧双线联盟/教团地图（`map_legacy_*`）、`battle_paper.png`/`paper_panel.png`、未引用相机/HUD/VFX JSON、过时脚本 `export_v13_*`/`build_v13~16_*`/`audit_scene_assets.py` 及 `docs/2026-10-24`/`25` 历史稿；在 `docs/references/`、`docs/concepts/`、`test_artifacts/` 建立 `.gdignore` 并清除误导入 `.import` 缓存。
  - 精简 [home_panels.gd](scripts/home/home_panels.gd)（清理约 660 行死 UI 构建逻辑并改用 `RefCounted` + `known_records()`）、[home_screen.gd](scripts/home/home_screen.gd)、[scene_stage_layers.gd](scripts/campus/scene_stage_layers.gd)（移除 v13 蓝图 Canvas 与冒泡锚点）、[scene_hud_layout.gd](scripts/campus/scene_hud_layout.gd)、[scene_object_view.gd](scripts/campus/scene_object_view.gd)（全量并入 `_build_unified_scene()` 并消除传统模式分支）、[scene_design_catalog.gd](scripts/campus/scene_design_catalog.gd)、[campus_places.gd](scripts/campus/campus_places.gd)、[campus_screen.gd](scripts/campus/campus_screen.gd)、[school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd)、[dynamic_ui.gd](scripts/ui/dynamic_ui.gd)、[combat_skin.gd](scripts/global/combat_skin.gd)、[scene_skin.gd](scripts/global/scene_skin.gd)、[exploration_content.gd](scripts/global/exploration_content.gd)、[phase_two_content.gd](scripts/global/phase_two_content.gd)、[dialogue_screen.gd](scripts/story/dialogue_screen.gd) 与 [sync_story.py](tools/story_studio/sync_story.py)。
- **BGM 与 SFX 推荐下载及实装**：
  - 新增下载脚本 [fetch_free_audio.py](tools/audio/fetch_free_audio.py) 并完成抓取校验：`7` 首 `.mp3` BGM（`bgm_title_serene`、`bgm_campus_daily`、`bgm_shop_breeze`、`bgm_dusk_memory`、`bgm_duel_practice`、`bgm_redmoon_overclock`、`bgm_victory_stinger`）+ `17` 枚 `.ogg/.wav` SFX（替换旧程序合成 `.wav` 占位音），署名清单见 [CREDITS.txt](assets/audio/CREDITS.txt)，混音与扩展曲库指南见 [2026-11-20-背景音乐与音效推荐及实装清单.md](docs/design/2026-11-20-背景音乐与音效推荐及实装清单.md)。
  - 完善 [audio_manager.gd](scripts/global/audio_manager.gd)（新增 `shop_coin`、`.ogg/.wav/.mp3` 多扩展名支持、除 `bgm_victory_stinger` 外 BGM 默认循环、细分商店/旧公园/红月追击音乐路由），并在 [campus_screen.gd](scripts/campus/campus_screen.gd)、[campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd)、[combat_screen.gd](scripts/combat/combat_screen.gd) 接入商店币响、结算短奏与进出/休整切曲同步；[sync_story.py](tools/story_studio/sync_story.py) 同步补充 `bgm_shop_breeze` 与 `.ogg/.wav/.mp3` 识别并完成 `--export`。
- **v18 商店与体育馆窗口三套概念需求包**：
  - 方案文档：[2026-11-20-商店柜台商品窗口与体育馆大赛窗口三套概念需求方案_v18.md](docs/design/2026-11-20-商店柜台商品窗口与体育馆大赛窗口三套概念需求方案_v18.md)
  - 打包器：[build_v18_shop_gym_modal_pack.py](tools/build_v18_shop_gym_modal_pack.py)
  - 交付包（位于本地 `archive/`）：`archive/IGA_Asset_Pack_Brief_v18_Shop_Gym_Windows_3Sets.zip`（`51` 个条目 / `29,528,148` 字节，通过 `zipfile.testzip()` 完整性验证）：含阶段一 `1920×1080` **商店柜台（A 晴空手账 / B Potionomics 木框 / C Blue Archive 终端）** 与 **体育馆选拔赛（A 晴空竞技 / B 金红荣誉册 / C 电子看板）** 共 6 套整页概念提示词与精确控件坐标、阶段二 `layers_shop`（11 件）/`layers_gym`（11 件）透明九宫格清单、`42` 份现行截图/舞台/UI/立绘/卡图/经济图标参考、`4` 份外部参考与 `06_Tools/qa_check_v18_windows.py`。
- **验收结果**：
  - Godot 4.7.2 `--headless --import --quit` 零报错完成 24 份新音频导入；[core_smoke.gd](tools/tests/core_smoke.gd) 新增 `_test_audio_assets()` 校验全 7 首 BGM 与全 17 枚 SFX；
  - `python tools/run_godot_tests.py ... --suite smoke`：**`1760` 项检查通过、`0` 失败**；
  - 双分辨率 OpenGL 实机截图：`1600×900`（`21` 张，0 失败）与 `1600×720`（`21` 张，0 失败）均通过，并已目检社团教室、校园商店与选拔赛弹窗。

## 2026-11-20 v17 八场景定稿分层素材、UI Set A 实装、旧失败素材清理与全界面顶栏统一

- **状态**：已将主创审定交付包 `archive/IGA_v17_Selected_Scene_Layers.zip` 中全部 **8 场景分层底图（天空/窗景、中景、前景）+ 15 套定位人物立绘与接触阴影 + 15 张原尺寸透明人物立绘 + UI Set A（7 组件 + 13 枚平面青绿图标）** 全量合入工程并完成实装；同时删除 `assets/` 下全部历史失败的 `v14` 塑料 UI、`scene_reset/places/` 平面底图与 `campus_life/` 旧场景素材（共清理 **101 个文件 / 51.15 MB**），按主创最新指令将人物剧情对话框统一回主线 `StoryChrome` 手帐样式、统一社团教室与 8 场景顶栏为 **单行 56px 等高 v17 UI**，并移除所有人物头顶冒泡对话提示。**`smoke` 回归及 `1600×900` / `1600×720` 双分辨率实机 OpenGL 截图（各 21 张）全过并逐张目检确认**。
- **素材合入与清理**：
  - 合入 88 张 v17 定稿 PNG 并完成 Godot 4.7.2 `--headless --import --quit` 零报错导入：
    - `assets/ui/scene_reset/staged/{dorm,shop,rooftop,coast,old_park,beach,library,gym}/`（53 张：`*_sky_wide`、`*_midground_wide`、`*_foreground_wide` 与 `actors/*_{sprite,contact_shadow}.png` + `v17_scene_layers.json`）；
    - `assets/ui_core/v17_ui_a/`（7 张 Set A 组件 + 13 枚 `icons/*.png` + `scene_hud_layout.json`）；
    - `assets/sprites/characters/v17_scene/`（15 张 `1024×1536` 透明原图）。
  - 彻底删除旧失败素材：`assets/ui/scene_reset/places/`（12 张旧平面场景）、`assets/ui/campus_life/`（7 张旧宿舍/商店/人物）、`assets/ui_core/v14_ui/{dials,icons,maps,panels}/` 与 `v14_ui/buttons/` 下旧塑料按钮（保留 v15 审定的 `v14_ui/zodiac/` 对开典籍与 `ui_seal_claimed_badge.png` 火漆印章），以及零引用遗留脚本 `scripts/campus/shop_counter_theme.gd`。
- **代码实装与界面精修**：
  - [scene_stage_layers.gd](scripts/campus/scene_stage_layers.gd)：将 `dorm`（学生宿舍）正式纳入五层舞台体系；新增 `STAGED_VARIANTS` 全 15 姿态像素级坐标表、`set_staged_variant()` 与 `pulse_slot_actor()`；`apply_period_lighting()` 改为室内 4 场景恒用专属窗景 `*_sky_wide.png` 并随昼/昏/夜/红月调色，室外 4 场景晴昼使用专属天空、黄昏与红月切换共享 `sky_arete_{dusk,redmoon}_wide.png`。
  - [dynamic_ui.gd](scripts/ui/dynamic_ui.gd) & [scene_hud_layout.gd](scripts/campus/scene_hud_layout.gd)：新增 `v17_capsule_box()`、`v17_panel_box()`、`make_v17_button()` 与 `v17_icon()`；将 `SceneHUDLayout` 升级为 v17 Set A 浮动和纸行动卡片与真表盘 `PeriodDial`，顶栏 `LocationCapsule` / `ResourceCapsule`（单行体力·练习点·零用钱）/ `OpenMap` / `OpenMenu` 统一为 **56px 等高对齐**；保持 `BackLocation` 在对话框开启时仅禁用不隐藏避免底板留空。
  - [scene_object_view.gd](scripts/campus/scene_object_view.gd)、[campus_screen.gd](scripts/campus/campus_screen.gd)、[campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd)、[campus_life.gd](scripts/campus/campus_life.gd)、[campus_dialogue_ui.gd](scripts/campus/campus_dialogue_ui.gd) & [school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd)：8 场景全部接入 v17 定位姿态（天台按时段轮切 3 人、海滩按随行同伴切 3 人、图书馆主线位林知夏递卡+黄秋枫窗边共框、体育馆选拔赛双态、商店分栏模式右移 `150px` 零遮挡唐小满并改用 v17 56px 零用钱胶囊与对话气泡底板）；移除所有 8 场景人物头顶冒泡提示；`CampusDialogueUI` 统一保持主线 `StoryChrome` 手帐对话框样式；主线图书馆剧情 `school_affairs` 切换至 v17 分层舞台背景。
  - [home_screen.gd](scripts/home/home_screen.gd)：社团教室顶部 `StatusCapsule`（体力/练习点/零用钱）与 `MainMenuButton`、`RooftopExit` 统一为 **v17 单行 56px 等高胶囊**，`HomePeriodDial` 同步使用 v17 真表盘并移除姜梓头顶 `TalkHint` 冒泡提示。
- **验收结果**：
  - [core_smoke.gd](tools/tests/core_smoke.gd) & [capture_scenes.gd](tools/tests/capture_scenes.gd) 扩展至全 8 场景（含 `21_dorm`）、v17 资产加载、56px 顶栏等高及零头顶冒泡校验：
  - `python tools/run_godot_tests.py --godot "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --suite smoke`：**`1728` 项检查通过、`0` 失败（`13.77s`）**。
  - 顺序执行 OpenGL 实机截图：`1600×900`（**21 张，`20.79s`，0 失败**）与 `1600×720`（**21 张，`18.95s`，0 失败**）全通过，逐张目检社团教室、全 8 场景、商店分栏、主线风格人物对话框与天台黄昏/红月切换，画面饱满、顶栏单行等高对齐、无文字截断与宽屏接缝。

## 2026-11-20 v17「场景 + 场景人物立绘 + UI 套件」三套组合需求包 & 故事工作台卡片流滚动修复

- **状态**：针对“空场景缺乏视觉重心”问题，保留现行游戏场景交互结构与 HUD 布局不变，打包交付 v17 组合需求包（含主要人物 21 张官方设定/现行立绘、8 场景驻场人物立绘 × 3 套、场景 UI 套件 × 3 套、带驻场人物焦点的 8 场景整页概念图 × 3 套）；同时修复 Story Studio 气泡卡片流重绘跳顶问题。
- **交付与工具**：
  - 设计方案：[2026-11-20-场景人物立绘与UI三套组合需求方案_v17.md](docs/design/2026-11-20-场景人物立绘与UI三套组合需求方案_v17.md)
  - 打包器：[build_v17_scene_char_ui_combo_pack.py](tools/build_v17_scene_char_ui_combo_pack.py)
  - 本地需求包（不入库，位于 `archive/`）：`archive/IGA_Asset_Pack_Brief_v17_Scene_Char_UI_3Sets_Combo.zip`（`38` 个条目 / `36,955,528` 字节；含 `24` 项带环境光染的驻场人物立绘、`21` 项 3 套 UI 套件组件、`24` 项带人物焦点的整页概念图提示词、`21` 张主要人物参考图、`11` 张 UI 与人物融入构图参考图及 `07_Tools/qa_check_v17_combo.py`）。
  - Story Studio 卡片流滚动修复：[app.js](tools/story_studio/app.js) 在 `renderEditor()` 与 `renderSidebar()` 重绘前后保存恢复 `scrollTop`，新增/移动/切换角色后通过 `scrollIntoView({ block: 'nearest' })` 与 `focus({ preventScroll: true })` 稳定停留在原位（`node --check` 通过）。

## 2026-11-20 v16 八场景 × 三套整页概念母图参考需求包（纯画风参照、无元素/蓝图束缚）

- **状态**：在保留现有游戏场景交互与 HUD 结构不变的前提下，完成阶段一「八场景（学生宿舍、校园商店、教学楼天台、沿海公路、旧公园、阿瑞忒海滩、图书馆、体育馆）× 三套差异化整体概念母图（Set A 清透日常纵深 / Set B 电影透视光影冲击 / Set C 海滨诗意叙事，共 24 项）」需求方案与本地素材参考包导出；待主创从 3 套中挑出定稿后，再进入阶段二元素拆层与实机替换。
- **交付与工具**：
  - 设计方案：[2026-11-20-八场景三套整页概念母图设计方案_v16.md](docs/design/2026-11-20-八场景三套整页概念母图设计方案_v16.md)
  - 打包器：[build_v16_scene_concept_pack.py](tools/build_v16_scene_concept_pack.py)
  - 本地需求包（不入库，位于 `archive/`）：`archive/IGA_Asset_Pack_Brief_v16_Scene_Concepts_3Sets.zip`（`14` 个条目 / `15,692,032` 字节；含总控规范、24 项宏观氛围中英文 Prompt、清单 JSON、`10` 张纯画风/光影/立绘笔触参照 `03_Pure_Style_References/` 及零依赖 PNG 质检器 `04_Tools/qa_check_v16_concepts.py`；刻意不附带任何线框蓝图与 UI 截图，不限制具体物件摆位与创作发挥）。

## 2026-11-20 IGA 剧情流式创作工作台（Story Studio）导出与双向同步工具落地

- **状态**：已将现行游戏主线剧情、主创口述序章原案草稿、第 2–5 章规划大纲、校园 NPC/场景互动、8 篇《风物纪要》、8 组训练路线留言及全量角色/星座/资源清单导出至独立 Web 工具工作台（[tools/story_studio/](tools/story_studio/index.html)）与 `docs/story/scripts/*.md`；支持免填表流式连写、气泡卡片双视图、1920×1080 实机画面实时预览试玩及一键双向写回 `.gd` 工程脚本。**`smoke` 回归及服务接口校验全部通过**。
- **核心入口与功能**：
  - [启动剧情工作台.bat](启动剧情工作台.bat) & [server.py](tools/story_studio/server.py)：双击启动本地零依赖 HTTP 服务（自动打开浏览器），提供 `/api/status`、`/api/bundle`、`/api/save`、`/api/apply_game`、`/api/reload_from_gd` 实现网页端修改直写工程 `.gd` 与 `.md`。直接双击 [index.html](tools/story_studio/index.html) 亦可通过内联 [story_data.js](tools/story_studio/story_data.js) 与相对 `assets/` 路径完整离线编辑、预览并导出。
  - [sync_story.py](tools/story_studio/sync_story.py)：负责全量导出（`--export` 生成 `story_bundle.json`、`story_data.js` 与 `docs/story/scripts/01..05*.md`）及双向写回（`--apply` 更新 `phase_two_content.gd`、`campus_places.gd`、`school_exploration_routes.gd` 与 `campus_life.gd` 并严格保留各文件 Tab/单空格缩进与换行符）。
  - [index.html](tools/story_studio/index.html) / [style.css](tools/story_studio/style.css) / [app.js](tools/story_studio/app.js)：免填表流式语法（`角色名: 台词`、`角色名(表情): 台词`、`? 选项 [+好感]`、`[指令: 参数]`）、同台角色「回车自动换人」与 `Tab`/`Alt+0..9` 切人、光标跟随表情与演出胶囊条、气泡卡片流、智能外部文本导入、1920×1080 实机舞台同步预览（含双层视差过场、256×256 头像、半身情绪立绘、`.wav` 音效试玩与 55 字舒适区提醒）。
- **验收结果**：
  - `python tools/story_studio/sync_story.py --export --fresh` & `--apply --verify` 退出码 `0`（缩进校验 `0` 错），`node --check tools/story_studio/app.js` 语法通过，`story_data.js` VM 加载校验通过，本地服务 API 自检（`/api/status`、`/api/bundle`、`/api/save`、`/api/apply_game` 与静态立绘/背景/音效资源）全通过。
  - `python tools/run_godot_tests.py --godot "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --suite smoke`（在 `/api/apply_game` 写回 `.gd` 后运行）：**`1738` 项检查通过、`0` 失败（`16.11s`）**。

## 2026-11-19 水彩纸绘社团文具风格 UI 统一、悬浮同形修复、零小图标清理与 HUD 交互梳理

- **状态**：已将全游 `v14` 高光塑料按钮/胶囊/状态条/图标替换为与社团教室同源的水彩手绘纸品与文具 UI（`assets/ui_core/theme/`），消除按钮悬浮方形/尖角变形，清理 HUD 与按钮上所有小图标，并梳理主场景/地点 HUD 布局与弹窗交互逻辑；**`smoke` 回归及 `1600×900` / `1600×720` 双分辨率 OpenGL 实机截图全部通过并完成逐张目检**。
- **核心改动**：
  - [dynamic_ui.gd](scripts/ui/dynamic_ui.gd)：统一 `make_cel_button()` 六态纹理形状（仅调整纸面染色与明暗，不再切换纹理避免圆角/矩形跳变）；接入 `paper_modal_9slice.png`、`dialogue_choice_9slice.png`、`ui_tutorial_callout_9slice.png` 与 `ribbon_header_9slice.png`，新增 `make_paper_tag()` 哑光和纸标签、`apply_world_card_style()` 浅色便签卡片样式，并将 `V14_CAPSULE_KEYS` 清空、保持目标高度等比缩放缓存。
  - [scene_hud_layout.gd](scripts/campus/scene_hud_layout.gd)：移除 `PipDot_0..2`、`HpIcon`、`PointsIcon`、`MoneyIcon`、`MapIcon`、`MenuIcon`、`ActionIcon`、`BubbleIcon` 与字符前缀；右上角统一为 `ResourceCapsule` + `OpenMap` + 最右侧 `OpenMenu`（右侧齐平至 `x=1884`）；`DockBacking` 使用水彩稿纸，`ConceptStatusBacking` 使用缝线布标缎带并内缩 `48px` 避开铜铆钉；`PeriodDial` 改为与 `StageLayers.force_sky_mode` 同步的纯水彩 `_draw()` 时段印章与 3 段墨迹活动弧；`RemainingActivities` 改用 `PipCount` 和纸计数条。
  - [home_screen.gd](scripts/home/home_screen.gd)：主场景顶部右上栏同步去图标化并令 `MainMenuButton` 居最右侧；移除冗余 `QuickMapButton` 与 `QuickRestButton`，保留 `RooftopExit` 与透明布告栏热区叠加；`ActivityPipBadge` / `ClaimBadge` 改用 `make_paper_tag()`，`TalkHint` 改用纸质便签并移除 `BubbleIcon` 与前缀符号。
  - [scene_object_view.gd](scripts/campus/scene_object_view.gd) & [campus_screen.gd](scripts/campus/campus_screen.gd)：移除地点气泡/天台条目多余字符前缀，修复天台对话按钮回调改为动态读取 `CampusLife.rooftop_active_npc()`，移除 `old_park` 与 `arete_beach_test` 与底部 `BackLocation` 重复的 `Action_go`；修复 `_open_menu()` / `_open_companion_switcher()` / `_open_qualifier_modal()` 的交互锁定（禁用 HUD 按钮并保存/恢复焦点）并将弹窗切换为水彩纸质面板。
  - [campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd)、[region_map_view.gd](scripts/campus/region_map_view.gd)、[region_atlas_view.gd](scripts/campus/region_atlas_view.gd) & [player_workspace.gd](scripts/home/player_workspace.gd)：移除商店小图标并统一至和纸标签与便利贴卡面；校园图/地区总图改为水彩稿纸标题卡、缝线布标缎带底条（文本避让铜铆钉）与和纸定位标签；放映档案室委托栏位、领奖按钮及「社团已盖章」条幅统一为哑光纸绘风格。
- **验收结果**：
  - `python tools/run_godot_tests.py --godot "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --suite smoke`：**`1738` 项检查通过、`0` 失败（`14.14s`）**（涵盖主题水彩贴图加载、悬浮六态同形、零小图标、`MainMenuButton` 右侧对齐、无重复 `Action_go`、菜单开闭禁用/恢复 HUD 交互）。
  - 顺序执行 OpenGL 实机截图：`1600×900`（**20 张，`19.41s`，0 失败**）与 `1600×720`（**20 张，`17.66s`，0 失败**）全部通过；目检 `02_home_club`、`03_projection_records`、`05_campus_map`、`06_world_atlas`、`07_library_npc`、`08_shop_npc`、`09_shop_counter`、`10_gym_qualifier`、`13_rooftop`、`17_rooftop_dusk`、`18_rooftop_redmoon` 及 `20:9` 宽屏多张画面，文字避让铜铆钉、水彩天象表盘三时段切换与 `20:9` 宽屏边距表现正常。

## 2026-11-19 v14 UI 控件、九宫格面板、地图铭牌与手绘图标全量接入

- **状态**：已将 `archive/IGA_Asset_Delivery_v14_UI_Controls_Buttons.zip` 中全部 **32 张** PNG 合入 `assets/ui_core/v14_ui/{dials,panels,buttons,maps,icons}/` 并完成 Godot 4.7.2 无头导入与全游戏 UI 控件接入；**所有界面已通过 `smoke` 回归及 `1600×900` / `1600×720` 双分辨率实机截图目检，下一步可继续按 [IGA_正式剧本编写范本](docs/story/IGA_正式剧本编写范本.md) 撰写正式剧本或接入后续章节内容**。
- **素材与代码改动**：
  - 合入 32 张 `v14` PNG 至 `assets/ui_core/v14_ui/`（`qa_check_v14_ui.py` 校验 **`32 passed, 0 failed, 0 missing / 32 total`**，Godot `--headless --import --quit` 零报错生成 32 个 `.png.import`）。
  - [dynamic_ui.gd](scripts/ui/dynamic_ui.gd)：新增 `v14_texture()`、`nine_slice_box()`（内置按图实测外缘透明阴影 `V14_EXPAND_HALOS` 自动扩展 `expand_margin`，并新增按控件目标高度等比缩放缓存 `_scaled_tex_cache` 与半圆胶囊 `V14_CAPSULE_KEYS` 水平三宫格 `T=0, B=0` 整弧映射，彻底消除 `2×` 胶囊/按钮在 `1×` 控件高度下被纵向九宫格挤压成两头尖角的问题）、`apply_nine_slice_panel()` 与 `attach_leading_icon()`；全面升级 `make_cel_button()` 与 `apply_world_card_style()` 自动匹配朱砂/青绿/返回冷白/暖白九宫格胶囊按钮与六地区巡回卡片底板。
  - [scene_hud_layout.gd](scripts/campus/scene_hud_layout.gd) & [scene_stage_layers.gd](scripts/campus/scene_stage_layers.gd)：`PeriodDial` 改以内部 `DialArt` `TextureRect` + `_PeriodArcOverlay` 叠加三段剩余活动弧，随早/午（黄昏）/夜/红月自动切换 4 枚金边天象圆盘并与 `StageLayers.force_sky_mode` 联动；升级 `DockBacking`、`ResourceCapsule`、`ConceptStatusBacking`、`HpIcon`、`PipDot_0..2`、`OpenMap`/`OpenMenu` 图标、`add_action_row()` 左侧手绘图标与 `CostBadge` 红/青徽章、`add_npc_bubble()` 气泡与聊天图标。
  - [home_screen.gd](scripts/home/home_screen.gd)、[campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd)、[campus_screen.gd](scripts/campus/campus_screen.gd)：接入主场景顶部胶囊、`MainMenuButton` 菜单图标、`ActivityPipBadge`/`ClaimBadge`、`TalkHint` 与 `PrimaryActivity`；接入商店 `ProductsBoard`、`DetailBoard`、选中/普通货架卡片 `Product_*`、`BalanceBacking`、`ClerkSpeechBubble`/`ClerkTag` 与 `Talk` 图标；接入 `CompanionSwitcherModal` / `QualifierModal` 条目九宫格底板。
  - [region_map_view.gd](scripts/campus/region_map_view.gd)、[region_atlas_view.gd](scripts/campus/region_atlas_view.gd) & [player_workspace.gd](scripts/home/player_workspace.gd)：升级校园图与世界总图标题铭牌、深蓝描金边底部状态条与红/青定位徽章；在放映档案室成就页接入 `Goal_*` 九宫格底板、`Claim_*` 领奖按钮与已领奖 `SealBadge_*` 火漆印鉴。
- **验收结果**：
  - [core_smoke.gd](tools/tests/core_smoke.gd) 新增全量 32 张 `v14` 贴图加载及各界面 `StyleBoxTexture` / `TextureRect` 断言；`python tools/run_godot_tests.py --godot "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --suite smoke` **`1627` 项检查通过、`0` 失败（`13.21s`）**。
  - 顺序运行 OpenGL 实机截图 **`1600×900`（20 张，`18.04s`，`0` 失败）** 与 **`1600×720`（20 张，`16.54s`，`0` 失败）** 全通过，并目检 `02_home_club`、`03_projection_records`、`05_campus_map`、`06_world_atlas`、`07_library_npc`、`08_shop_npc`、`09_shop_counter`、`10_gym_qualifier`、`13_rooftop`、`17_rooftop_dusk`、`18_rooftop_redmoon` 确认所有胶囊与圆角按钮两端圆润饱满、无任何尖角变形。

## 2026-11-19 Step 3 v13 分层美术素材合入与 7 场景双分辨率实机验收

- **状态**：已合入 `archive/IGA_v13_Scene_Reset_Layered_Delivery.zip` 中全部 **17 张** `2340×1080` 分层 PNG 至 `assets/ui/scene_reset/staged/`，并完成真机双分辨率逐张目检与 `20:9` 宽屏外缘无缝延展修复；**下一步可按 [IGA_正式剧本编写范本](docs/story/IGA_正式剧本编写范本.md) 推进正式剧本，或继续替换其他未重置地区背景**。
- **改动与验收指标**：
  - 合入 `assets/ui/scene_reset/staged/{shared,rooftop,shop,gym,library,coast,old_park,beach}/*.png`（17 张 PNG + 17 个 `.png.import`）：`qa_check_v13_layers.py` 清单校验 **`17 passed, 0 failed, 0 missing / 17 total`**；Godot `--headless --import --quit` 零报错导入 17 项 `Texture2D`。
  - `scripts/campus/scene_stage_layers.gd`：新增 `WIDE_EXTEND_PAD = 180.0` 外缘镜像延展着色器（蓝图导出模式下自动停用），彻底消除 `1600×720`（`20:9`）最右 `20px` 截断接缝，同时保持 `[210..2130]` 安全区与立绘槽位像素对齐不变。
  - `tools/tests/core_smoke.gd` & `tools/tests/capture_scenes.gd`：新增 7 处地点真实 `SkyTexture`/`MidgroundTexture`/`ForegroundTexture` 加载与晴昼/黄昏/红月切换断言，补充 `17_rooftop_dusk` 与 `18_rooftop_redmoon` 实机截图。
  - 最终代码后全量回归：`smoke` **1261 项通过**（`12.46s`，`0` 失败）；`captures` **`1600×900`（18 张，`16.63s`，0 失败）**与 **`1600×720`（18 张，`15.35s`，0 失败）**全过并完成全部场景/商店分栏/手帐对话/晴昼黄昏红月/宽屏边缘目检。
  - **星座图鉴左卡右文对开典籍详情与 `v15` 美术合入验收**：
    - `scripts/home/zodiac_album_panel.gd` 重构为「6×2 十二星座总览墙 + 对开皮质典籍详情双页」，已合入 `v15` 交付包全部 **3 张 RGBA 成品图**至 `assets/ui_core/v14_ui/zodiac/{ui_zodiac_book_spread,ui_zodiac_ribbon_sage,ui_zodiac_ribbon_rose}.png`（`qa_check_v15_zodiac_book.py` **`3/3 PASS`**，Godot 4.7.2 `--import` 零报错导入）。
    - 移除真实书本画框内多余的程序 `CardNiche` 深框，精准贴合 `Rect2(193, 120, 424, 640)` 内凹阴影盒与 `412×618` 卡面；最终代码后全量回归通过：`smoke` **1446 项通过**（`12.84s`，`0` 失败），**`1600×900`（`17.37s`，20 张）与 `1600×720`（`15.88s`，20 张）OpenGL 截图全过并目检**。
    - 本地增量/通用需求包记录（不入库，见 `archive/`）：
      - `archive/IGA_Asset_Pack_Brief_v14_UI_Controls_Buttons.zip`（`tools/build_v14_ui_pack.py`，`27` 个条目 / `22,008,899` 字节，保持原 **32 项** UI/按钮/怀表/手绘图标清单，待交付合入）。
      - `archive/IGA_Asset_Pack_Brief_v15_Zodiac_Book_Spread.zip`（`tools/build_v15_zodiac_book_pack.py`，**3 项**对开典籍素材需求包 — 已按交付物合入完毕）。

## 2026-11-19 Step 2 五层舞台、统一场景 HUD/对话/商店/选拔赛实装与 v13 分层素材需求包

- **状态**：主创审定 `docs/design/2026-11-19-场景重置与UI画风统一方案.md` 六项决策后，完成 Step 2 引擎端全面重构与 Step 3 `v13` 分层素材需求压缩包导出；**下一步可继续完成正式剧本撰写，并按 v13 清单分批生成透明分层美术并由 `res://assets/ui/scene_reset/staged/` 自动接入**。
- **主要代码改动**：
  - `scripts/campus/scene_stage_layers.gd`（新建）：`SceneStageLayers` 五层拼装底座（`Layer0_Sky` / `Layer1_Midground` / `Layer2_Actors` Slot A & Slot B / `Layer3_Foreground` / `BlueprintGuideOverlay`），`2340×1080` 宽屏舞台、`1920×1080` 安全中心、7 处场景实时青透蓝灰赛璐璐占位于一体与 `staged/` 资源自动接管、昼/黄昏/红月夜实时调光。
  - `scripts/campus/scene_hud_layout.gd`（新建）：`03` 风格统一 HUD（`PeriodDial` 时段表盘、左侧垂直停靠栏与宽屏左出血、右上资源胶囊、防裁剪浮动 `StageBubbles`）。
  - `scripts/campus/scene_object_view.gd`、`scripts/campus/campus_places.gd`、`scripts/campus/campus_life.gd`、`scripts/campus/region_map_view.gd`、`scripts/campus/scene_design_catalog.gd`：统一 7 处待重置场景 + `dorm` 到新 HUD；补齐天台饮料贩卖机、随行同伴切换与分时段常驻 NPC（早杨子英 / 午柳宇龙 / 夜姜梓）。
  - `scripts/campus/campus_shop_panel.gd`、`scripts/campus/campus_dialogue_ui.gd`、`scripts/campus/campus_screen.gd`、`scripts/home/home_screen.gd`：实装 `03/01` 商店左货架右店员实时交互分栏、`CampusDialogueUI` 恢复 `256×256` 头像并统一并入 `story_chrome.png`、`03/03` 体育馆双栏三轮选拔赛弹窗、`HomeScreen` `05` 式主场景表盘与快捷入口。
  - `tools/export_v13_blueprints.tscn/.gd`、`tools/build_v13_asset_pack.py`、`tools/tests/core_smoke.gd`、`tools/tests/capture_scenes.gd`：新增 7 张 `2340×1080` 蓝图导出场景与 v13 素材包构建工具及冒烟/截图断言。
- **本地验收与产物**：
  - 最终代码后全量回归通过：`python tools/run_godot_tests.py --godot "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --suite smoke`（**1239 项通过**，`11.72s`，`0` 失败）；`1600×900`（`12.22s`，16 张，0 失败）与 `1600×720`（`11.56s`，16 张，0 失败）OpenGL 实机截图全过并目检选拔赛左栏折行、商店分栏、暖纸手帐对话、天台/海滩/图书馆/体育馆五层舞台。
  - 本地交付包（不入库，见 `archive/`）：`archive/IGA_Asset_Pack_Brief_v13_Scene_Reset_Layered.zip`（`31` 个文件 / `13,685,535` 字节，含 `7` 张实机导出 `2340×1080` 线框蓝图、`17` 项分层美术清单及零依赖校验脚本 `06_Tools/qa_check_v13_layers.py`）。

## 2026-11-19 正式剧本范本、五场景重置与四大画风统一方案（待主创审核）

- **正式剧本编写范本**：新增 [IGA_正式剧本编写范本.md](docs/story/IGA_正式剧本编写范本.md)，提供可直接转入引擎的极简 Markdown 剧本语法、序章主线与驻场 NPC 完整示范样本、空白填空模板及全量现行角色/表情/背景/过场/BGM/SFX/敌人 ID 速查表。
- **场景重置与四大画风统一设计方案**：新增 [2026-11-19-场景重置与UI画风统一方案.md](docs/design/2026-11-19-场景重置与UI画风统一方案.md)，明确由「直出整图抠热区」升级为「布局先导 + 5 层模块化拼装（独立天空层 + 中景地坪与 Slot A/B 槽位 + NPC 角色层 + 前景遮挡层 + 统一四角落 HUD 与右侧交互停靠栏）」，补齐天台定位、体育馆选拔赛视觉中心、图书馆/沿海公路主线 NPC 槽位与 `CampusDialogueUI` 隐藏头像等隐性漏洞。
- **互联网精选参考图归档（23 张逐张目检）**：下载并按 4 大类归档至 `docs/references/2026-11-19-scene-ui-redesign/`（`01_场景画风与空间构图`、`02_UI控件与HUD布局`、`03_交互窗口与商店选拔赛`、`04_地图画风与导航`），本轮未修改游戏运行代码，待主创审定 6 项决策点后进入代码骨架与分层素材阶段。

## 2026-11-18 进度盘点、弃用批处理需求包与冗余旧素材清理（保留世界地图背景）

- **主创审定与素材清理结论（释放 911.46 MB，移除 53 项旧/无引用资源）**：
  - **保留当前大世界地图背景**：[world.png](assets/ui/scene_reset/maps/world.png) 与 [world_wide.png](assets/ui/scene_reset/maps/world_wide.png) 经主创确认保留作为六地区巡回总图底图；现行可玩阿瑞忒昼夜校园图（[region_maps](assets/ui/region_maps/)）、社团教室/放映室/卡匣工坊与战斗素材均保留完好，[characters](assets/references/characters/) 四张唯一角色人设参照亦完整保留。
  - **终止并撤除最新提示词生图批次与过时归档包**：因 v12 批次提示词成图效果未达预期，已删除 `archive/` 下全部 29 份过时或弃用的需求与交付压缩包（`v1–v12`、`864.23 MB`）。
  - **清理项目内确认零引用的旧占位素材**：删除已被替换的 `assets/ui/region_maps/campus_{indigo,vermilion}_first_pass.png`（含 `.import`）、从未纳入导入的废弃 `assets/references/wave5_concepts/`（16 项早期废案草图与图框，含已废除的 `study` / `stockroom` / 抽卡包概念，释放 `41.9 MB`），以及零引用遗留图标 `zodiac_crest.svg`、`icon_card_pack.png`（含 `.import`）。
- **当前已实装功能与待推进现状总览**：
  - **主线与校园养成闭环（标题 → 序章 → 社团日常⇄主线 → 代表选拔赛）**：次日运动会伏笔、`n_club_intro` 引导、白羊座母卡 `hero` 共鸣、放映档案室四合一（11 枚印章领奖、8 篇《风物纪要》、7 人拍立得与 `Lv.1–3` 协战）、三档校园商店（`6 → 11 → 16` 卡）、0 活动点工坊强化及体育馆 3 轮选拔赛已全线贯通。
  - **地图精简与动态 UI**：阿瑞忒校园地图已整合为 7 大主地标（《旧公园》与《阿瑞忒海滩》迁入《沿海公路》双分支入口）；六地区巡回总图已去除冗余 `Browse_*` 按钮，改为每区唯一卡片 `RegionCard_<id>` 与动态航线；[dynamic_ui.gd](scripts/ui/dynamic_ui.gd) 动效与 6 份脚本纯 Tab 缩进修复已落库。
  - **待下一轮决定项**：第 2–5 章正式剧本与其余 5 地区保持框架占位；暂缓大规模重绘提示词发包，后续按新确认方向定向替换仍需重做的单张背景或 UI。

## 2026-11-18 地图入口精简、世界总图单卡化、动态 UI 体系与脚本 Tab 统一

- **校园地图 7 地标精简 & 沿海公路双分支接入**：
  - [campus_places.gd](scripts/campus/campus_places.gd)、[world_region_content.gd](scripts/campus/world_region_content.gd)、[region_catalog.gd](scripts/campus/region_catalog.gd) 与 [scene_design_catalog.gd](scripts/campus/scene_design_catalog.gd)：
    - 将 `old_park`（旧公园）与 `arete_beach_test`（阿瑞忒海滩）的归属父级 `parent` 与出口跳转统一并入 `arete_coast_test`（沿海公路），校园主图简化为 `教学楼天台 / 学生宿舍 / 社团教室 / 图书馆 / 校园商店 / 体育馆 / 沿海公路` 共 **7 处核心地点**（Esc 从旧公园/海滩逐级返回沿海公路 → 地图）。
  - [campus_screen.gd](scripts/campus/campus_screen.gd) & [scene_object_view.gd](scripts/campus/scene_object_view.gd)：在沿海公路内挂载动态引导入口 `Action_enter_old_park`（未开放提示 / `✦ 旧公园（黄昏之约）` 悬浮微动+扫光 / 常态入口）与 `Action_go`（走向海滩），并将旧公园悬停/返回逻辑切换至沿海公路；清理 `campus_screen.gd` / `scene_object_view.gd` / `day_cycle.gd` 混合 Tab 缩进。
- **全新 UI 按钮、总图单一卡片化与动态 UI 系统（保持既有室内功能区不变）**：
  - 新建公共模块 [dynamic_ui.gd](scripts/ui/dynamic_ui.gd)（`DynamicUI`）：实现悬停弹跳 `attach_hover_pop`、徽标轻量浮漂 `attach_float_bob`、脉冲扩散环 `_PulseRingControl`、Shader 对角扫光 `attach_sheen`、错峰滑入 `slide_in`、触感 3D 厚涂赛璐璐胶囊按钮 `make_cel_button` 及世界卡样式 `apply_world_card_style`；严格遵守 `SaveManager.settings["reduced_motion"]` 与 `SchoolObjectUI.borderless()`。
  - 升级 [region_map_view.gd](scripts/campus/region_map_view.gd)：新增 `HeaderBacking` 与 4 枚赛璐璐功能按钮、地标悬停/聚焦名牌联动缩放、昼夜切换淡入平滑过渡、`old_park`/`beach` 当前所在与 `n_dusk` 剧情标签自动映射至 `arete_coast_test`（顶部 `library` 徽标智能下挂避让按钮），以及 `● 当前所在` 脉冲光环与 `✦` 徽标浮动扫光。
  - 升级 [region_atlas_view.gd](scripts/campus/region_atlas_view.gd)：彻底移除冗余的 `Browse_*`（地区地图）、`Enter_*` 与 `RegionStatus_*` 多重入口；为六地区各自渲染 **唯一 1 张统一卡片 `RegionCard_<id>`**（含序号圆章 `01..06`、地区标题与精简状态），统一顶栏风格并升级 `TourRouteOverlay` 流动虚线与发光信标效果。
- **回归与双分辨率验收**：
  - [core_smoke.gd](tools/tests/core_smoke.gd) 新增校园地图 7 地标归拢校验（有 `NameBacking_arete_coast_test` 且无独立 `old_park`/`beach` 牌）、世界总图单卡零 `Browse_*` 校验及沿海公路双入口校验；同时将 `day_cycle.gd / dynamic_ui.gd / campus_screen.gd / scene_object_view.gd / region_map_view.gd / region_atlas_view.gd` 共 6 份脚本统一转为纯 Tab（`\t`）缩进，避免 Godot 编辑器「制表符」模式下将 4 空格自动折算导致混合缩进解析失败；`Godot --headless --quit` 零报错、`smoke` 957 项检查 **0 失败**（`14.79s`），OpenGL `1600×900`（`13.39s`、`12` 张）全通过。

## 2026-11-18 v11 蔚蓝档案 × 罗小黑水彩设计感地图全量验收与实装接入

- **交付包全检与资产入库（9/9 项全过 `qa_check_scenes_and_ui.py` 与目检）**：
  - 解包核对 `IGA_v11_Batch_01_Arete_Day.zip`、`Batch_02_Arete_Night.zip`、`Batch_03_Map_Pin_Plates.zip`、`Batch_04_World_Tour.zip`：全套 9 张 PNG `8-bit`、`210px` 超宽延展无拖尾、`ui_map_pin_plates.png` 真透明 `alpha=0` 占比 `82.5%` 全部 `[PASS]`；保留清透简化水彩建筑群与充足留白，彻底解决 v10 写实噪点。
  - 合入运行路径：`assets/ui/region_maps/{map_arete_day,map_arete_day_wide,map_arete_night,map_arete_night_wide,ui_map_pin_plates}.png`、`assets/ui/scene_reset/maps/{world,world_wide}.png` 及概念母图 `docs/concepts/v11/`，并完成 Godot `--headless --import --quit` 重导。
- **地图坐标配准、贴片与超宽屏适配**：
  - [region_catalog.gd](scripts/campus/region_catalog.gd)、[region_map_view.gd](scripts/campus/region_map_view.gd)、[map_page_ui.gd](scripts/campus/map_page_ui.gd) 与 [map_screen.gd](scripts/campus/map_screen.gd)：
    - 将阿瑞忒昼（`vermilion` 晨海绘卷）与夜（`indigo` 夜月星图）双底图及 `2340×1080` `WideMapBackground` 接入校园地图，将含 **《旧公园》《沿海公路》《阿瑞忒海滩》在内全 9 处地点** 统一标绘于地图实景之上并移除旧版底部 3 栏外置按钮；
    - 用 `ui_map_pin_plates.png` 真透明手绘叶边胶囊签（鼠尾草绿/晴空蓝/暖琥珀）呈现清晰地标名牌，同步扩展 `MapPageUI.button` 支持零灰框 `disabled` 锁闭态（如未解锁《旧公园》）与半透顶部功能栏。
  - [scene_design_catalog.gd](scripts/campus/scene_design_catalog.gd) & [region_atlas_view.gd](scripts/campus/region_atlas_view.gd)：按新水彩六地区总图重配 `WORLD` 六区多边形与名牌坐标，彻底避让所有建筑、巡回航线节点与底部分区条；`MapScreen._layout()` 兼容识别 `WideWorldBackground`。
- **最终回归与双分辨率视觉验收（最后一次编辑后全通过）**：
  - `--headless` `--suite smoke`：**945 项检查，0 失败**（`11.82s`，新增旧公园水彩路牌与 `2340` 宽边节点校验）；
  - OpenGL `1600×900`（`13.42s`）与 `1600×720`（`12.20s`）`--suite captures`：均输出 12 张截图（**0 失败**），已逐图目检双分辨率 `05_campus_map.png` 与 `06_world_atlas.png`——9 地标名牌/双徽章与六地区航线布局清朗零重叠，超宽边自然平滑延展。

## 2026-11-18 v10 素材审查定调（退回写实地图、保住既有 UI）、v11 地图专项包与地图/交互/后续内容升级

- **4 批 v10 交付包全检与美术方向决断（已停止错误合入写实UI/重影家具）**：
  - 逐图检核用户传入的 `IGA_v10_P0-1_Maps.zip`、`P0-2_Core_UI_and_Arena.zip`、`P0-3_Old_Park_and_Campus.zip` 与 `P1_Story_and_Card_Art.zip` 共 35 项后，确认仅技术规范通过 `qa_check_scenes_and_ui.py`，美术存在明显「过度写实、碎叶/木纹/砖石细节过载」问题；且 `P0-3` 7 处 `*_objects.png` 与现有背景自带家具产生重影叠加。
  - 按主创指令**不重绘/不覆写现有社团、放映室、工坊及校园室内 UI**，仅从 `P1` 遴选合入洁净无水印的 [card_art_final_trump.png](assets/combat/card_art/card_art_final_trump.png)（512×512 完成 Godot `--headless --import`）；并专项输出面向 **「蔚蓝档案清透光影色彩对比度 × 罗小黑战记水彩留白与简化组合感标志地标」** 的地图重制需求总包：[IGA_GPT_Asset_Pack_Brief_v11_Maps_Stylized.zip](archive/IGA_GPT_Asset_Pack_Brief_v11_Maps_Stylized.zip)（含 9 项地图清单、`campus_vermilion/indigo_first_pass` 简化参考、v10 写实对照反例、`07_asset_manifest_v11.json` 与 `qa_check_scenes_and_ui.py`）。
- **地图功能增强（[campus_life.gd](scripts/campus/campus_life.gd)、[region_map_view.gd](scripts/campus/region_map_view.gd)、[region_atlas_view.gd](scripts/campus/region_atlas_view.gd)）**：
  - **校园地图**：新增 `● 当前所在` 位置徽章（与珊瑚红 `✦ 主线/选拔赛` 徽章错位共存）、左下双行实时悬停/聚焦地标情报卡（含产出收益、时段在场人物与未解锁条件说明）、右上「进入下一时段」按钮与「切至夜课星图/放学晨图」手动切换（合法持久化至 `campus_life.map_concept`）；
  - **六地区巡回总图**：新增 `TourRouteOverlay` 深海蓝描边＋象牙/琥珀巡回航线（第 1 站阿瑞忒通关选拔赛后点亮通往诺莫斯的琥珀航线）与底部 `AtlasPreviewText` 情报带，悬停任意已解锁或未解锁地区即展示巡回站序、据点风貌定位与解锁进度。
- **场景交互与选拔赛后后续衔接（[scene_object_view.gd](scripts/campus/scene_object_view.gd)、[campus_screen.gd](scripts/campus/campus_screen.gd)、[player_journey.gd](scripts/global/player_journey.gd)）**：
  - 场景交互热点（`Landmark_*`、`Action_*`、剧情触发点）统一挂载左下悬停收益说明，明确是否消耗活动次数；
  - `CampusScreen` 新增活动收益飘字胶囊 `_run_activity()` 与 `M` 键呼出地图快捷键；选拔赛全胜后在 `QualifierModal` 增加「巡回总图 →」快捷入口，并在社团黑板 `home_snapshot()` 动态追踪剩余印章、16 张行动卡与 8 篇《风物纪要》收集，同步提示第 2 站《诺莫斯》筹备衔接。
- **本轮最终改动后三环境校验全通过**：
  - `--headless` `--suite smoke`：**937 项检查，0 失败**（`11.82s`，新增地图按钮/预览条/徽章/切换器校验）；
  - OpenGL `1600×900` & `1600×720` `--suite captures`：均输出 12 张截图（**0 失败**，`13.23s` / `12.12s`），已目检 `05_campus_map` 与 `06_world_atlas` 双分辨率画面，航线对比度、双向徽章、预览情报栏均清晰无遮挡。

## 2026-11-18 阶段二全面重构落地：序章-日常-主线-选拔赛闭环、放映档案室、8 场景驻场功能与测试精简

- **重塑宏观流程（标题 → 序章 → 社团引导 → 日常⇄主线交替 → 选拔赛终幕）**：
  - [game_state.gd](scripts/global/game_state.gd)、[phase_two_content.gd](scripts/global/phase_two_content.gd)、[dialogue_screen.gd](scripts/story/dialogue_screen.gd)、[school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd) 与 [parallax_cutscene_stage.gd](scripts/ui/parallax_cutscene_stage.gd)：
    - 新增次日 `09:20` 运动会第 4 名呼吸伏笔、`n_club_intro`（`club_welcome`）社团教室入驻引导与 `story_flags.club_onboarding_done` 状态流；
    - 打通阶段边界交接：`n_club_intro` 结算进入 `HOME` 开启自由探索与主线交替，`n_affairs`（图书馆与黄秋枫会面）与 `n_find_yang` 分别解锁/推进校园闭环，并于次晨唤醒白羊座母卡 `hero`；兼容迁移既有测试/旧存档的 `n_club_intro` 与 `hero`。
    - 删除对话与卡牌文案中遗留的「学生智能终端」设定表达（`player_journey`、`game_state`、`phase_two_content`、`combat_screen`），统一为战术刻印与护盾裁决表述；[title_screen.gd](scripts/title/title_screen.gd) 顶部版本栏更新为「阿瑞忒篇 · 序章至校内代表选拔赛」。
- **升级《放映档案室》四合一中枢与委托成就盖章（替代终端记录设定）**：
  - [player_workspace.gd](scripts/home/player_workspace.gd)、[home_screen.gd](scripts/home/home_screen.gd)、[player_journey.gd](scripts/global/player_journey.gd)、[home_panels.gd](scripts/home/home_panels.gd) 与 [school_object_panels.gd](scripts/home/school_object_panels.gd)：
    - 社团桌面「records」入口正式更名为「放映档案室」并挂载待领红点 `ClaimBadge`（如 `★ 8项可盖章`）；
    - `PlayerWorkspace("records")` 重构为 **委托与成就（11 枚社团巡回印章领奖）/ 故事胶片（含第 3 子页《风物纪要》读取 8 篇校园笔记）/ 同学拍立得（7 人遇面羁绊与 `Lv.1–3` 协战成长档）/ 社团收纳**；
    - 同伴「同学交流」与工坊行动卡强化全面改为 **0 活动点消耗**（交谈每时段限领一次 `+8` 好感），协战随好感度分 3 档成长（`Lv.1` / `>=35 Lv.2` / `>=70 Lv.3`）。
- **阿瑞忒 8 场景功能闭环、三档商店库存、驻场立绘与代表选拔赛**：
  - [campus_places.gd](scripts/campus/campus_places.gd)、[campus_life.gd](scripts/campus/campus_life.gd)、[campus_screen.gd](scripts/campus/campus_screen.gd)、[scene_design_catalog.gd](scripts/campus/scene_design_catalog.gd)、[scene_object_view.gd](scripts/campus/scene_object_view.gd)、[region_map_view.gd](scripts/campus/region_map_view.gd)、[region_atlas_view.gd](scripts/campus/region_atlas_view.gd)、[campus_shop_catalog.gd](scripts/data_models/campus_shop_catalog.gd)、[campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd) 与 [combat_screen.gd](scripts/combat/combat_screen.gd)：
    - 合并冗余 `study` / `stockroom` 功能至「图书馆」与「校园商店」，正式开放 `old_park`（旧公园，复用 `cutscene_old_park_dusk_bg.png` 2340 宽图），清除海滩、沿海公路、旧公园及 [item_catalog.gd](scripts/data_models/item_catalog.gd) / [save_manager.gd](scripts/global/save_manager.gd) / `RegionAtlasView` 页脚等遗留 `"TEST"` 文案；
    - 实装各场景不重叠产出（商店兼职 `+100` 零用钱、图书馆研习 `+35` 练习点+风物纪要、天台复盘回血加好感、沿海/海滩散步加羁绊与材料、旧公园追忆），接入三档随剧情解锁的商店行动卡供货（`6 → 11 → 16` 款）；
    - 挂载 `ResidentActors` 驻场/剧情立绘（林知夏、唐小满、柳宇龙、杨子英、黄秋枫）并修复 `_actor_layer` 与 `HomeObjectButton` 遮挡顺序及 NPC 交互标签位置，同时为地图/场景/总图提示条增加磨砂深色底板；
    - 实装体育馆「阿瑞忒巡回代表选拔赛」3 轮递增挑战弹窗（`QualifierModal`）与非超限选拔战逻辑（`CombatScreen._qualifier_mode`），完赛颁发「阿瑞忒代表通行章」并在世界总图标识诺莫斯「第二章待开」。
- **自动化测试精简与双分辨率验收结果（最终改动后全量通过）**：
  - 移除旧重型套件 `tools/tests/{p5_regions,home_objects,scene_reset,zodiac_and_shop}.*`，新建精简回归入口 [core_smoke.gd](tools/tests/core_smoke.gd) / `.tscn` 与按需实机截图 [capture_scenes.gd](tools/tests/capture_scenes.gd) / `.tscn`，同步精简 [run_godot_tests.py](tools/run_godot_tests.py) 与 [test_p5.sh](tools/cloud/test_p5.sh) 仅开放 `--suite smoke` 与 `--suite captures`。
  - `--headless` `--suite smoke`：**919 项检查，0 失败**（`14.85s`）。
  - OpenGL `1600×900` `--suite captures`：产出并目检 12 张完整 UI 截图（**0 失败**，`13.23s`），确认商店/图书馆 NPC 完整无裁剪、标签零遮脸、放映档案室/黑板/商店/选拔赛/地图排版正常。
  - OpenGL `1600×720` `--suite captures`：产出 12 张宽屏截图并逐图目检 `02_home_club`、`03_projection_records`、`07_library_npc`、`08_shop_npc`、`10_gym_qualifier`、`11_old_park`、`12_coast`（**0 失败**，`12.21s`）。

## 2026-11-18 全游内容设计审核（v2）、流程与胶片手帐中枢重构方案及 v10 GPT 素材总包

- **按主创批示完成方案全面修订与重构实施方案落库**：
  - 更新 [2026-11-18-全游内容设计审核与重构实施方案.md](docs/story/2026-11-18-全游内容设计审核与重构实施方案.md)（本轮未改运行期代码，待确认后执行阶段二）：
    - **重排宏观游戏顺序**：从“脱离场景播完 9 幕后断崖”调整为**「标题页 → 独立序章（含运动会伏笔与初战） → 社团教室主场景交互引导 → 日常场景游玩循环 ⇄ 第一章分阶段剧情交替 → 校内代表选拔赛决胜」**。
    - **废弃「学生智能终端」，升级《放映档案与成就领奖室》**：结合游戏木质社团与胶片手帐美学，将放映室重构为「成就委托盖章领奖（投放零用钱/材料/新卡）+ 故事胶片 + 同伴拍立得羁绊墙 + 社团仓库」四合一中枢；校园地图正式新增可探索剧情场景**《旧公园》**。
    - **清理冗余与修 Bug 路线**：聊天/升级归零活动点，修复 `CampusScreen` 跳过 `_build_actor()` 致 NPC 消失与 `study` 死房间，商店兼职解决零用钱断源，合并精简 `tools/tests/`（1,510 行 / 5,636 项检查 → `core_smoke.gd` + 按需 `capture_scenes.gd`）。
- **GPT 素材需求总包 [IGA_GPT_Asset_Pack_Brief_v10_Scene_and_Loop_Remake.zip](archive/IGA_GPT_Asset_Pack_Brief_v10_Scene_and_Loop_Remake.zip) 更新与全检通过**：
  - 彻底摆脱早期粗糙框图坐标束缚，精准收录 **35 项**清单（`P0-1` 含旧公园 8 地标昼夜校园地图与近未来六地区总图、`P0-2` 自由重绘放映档案室/卡匣工坊/选拔赛擂台、`P0-3` 新增旧公园实景与 7 处现有场景透明拆层、`P1` 运动会过场与终局卡去水印），附 7 份文档、新版 3 张布局蓝图 `TPL_01..03`、20 张参考图与零依赖自动质检工具 `08_Tools/qa_check_scenes_and_ui.py`。

## 2026-11-17 剧情人物立绘统一规格（v9.1）、页面布局占比制定与 75 项新立绘全量合入

- **交付素材包 [IGA_Story_Portraits_v9.1_Delivery.zip](archive/IGA_Story_Portraits_v9.1_Delivery.zip) 审核校验与全量接入**：
  - 解包复核并逐图验收全部 75 张 `8-bit sRGB RGBA PNG`（`halfbody/` 14 张 + `emotions/` 32 张均保留原生 `2:3` `1054×1581` 零拉伸比例、`portraits/` 5 张 `512×512`、`avatars/` 24 张 `256×256`，新增 `huang_qiufeng_angry.png`、`lin_zhi_xia_neutral.png` 与 `tang_xiao_man_neutral.png`），经 `qa_check_portraits.py` 全量检核 `75/75` 通过且目检确认男相去女性化、柳宇龙紫眸、发丝大块面聚拢与黄秋枫无血光纤/结晶细节全部达标，合入 `assets/sprites/characters/phase_two/` 并完成 Godot `--headless --import --quit` 重导（保留历史兼容 `expressions/` 与 `fullbody/`）。
  - [campus_screen.gd](scripts/campus/campus_screen.gd)：`CampusDialogueUI` 在图书馆（`lin_zhi_xia`）与商店（`tang_xiao_man`）对话时优先加载 `256×256` 同源新头像，若回退至 `halfbody/` 则按纹理尺寸等比裁剪不再硬编码旧 `900×1200` 区域。
- **全页占比、弹性无拉伸规格与需求总包落库**：
  - 结合 ADV/JRPG 7:3 视野配比与 `SchoolDialoguePresentation` / `StoryChrome` 定型 `1920×1080` 四段占比（顶栏 `6.0%` + 清晰舞台 `64.1%` + 对话框 `21.3%` + 底栏 `8.6%`），去除了会诱发强行拉伸的硬性像素对齐约束，方案文档归档至 [2026-11-17-剧情人物立绘统一规格与页面布局方案.md](docs/story/2026-11-17-剧情人物立绘统一规格与页面布局方案.md)，需求模板与防变形质检总包打包为 [IGA_GPT_Asset_Pack_Brief_v9_Story_Portraits.zip](archive/IGA_GPT_Asset_Pack_Brief_v9_Story_Portraits.zip)（`22,441,431` 字节，21 项）。
- **合入后三环境全量回归验证通过**：
  - `--headless`（`--suite all`）：`regions` 544、`home` 174、`scenes` 540、`zodiac` 544 —— 合计 **1,802 项检查，0 失败**。
  - OpenGL `1600×900`（`--suite all`）：`regions` 564、`home` 198、`scenes` 594、`zodiac` 561 —— 合计 **1,917 项检查，0 失败**；已逐图目检 `story_exploration_note.png`、`v7_chapter_banner.png`、`v7_dialogue_qiufeng_cursor.png` 与 `dialogue_library.png`。
  - OpenGL `1600×720`（`--suite all`）：`regions` 564、`home` 198、`scenes` 594、`zodiac` 561 —— 合计 **1,917 项检查，0 失败**；已逐图目检宽屏 `story_exploration_note.png`、`v7_chapter_banner.png` 与 `v7_dialogue_qiufeng_cursor.png`。

## 2026-11-16 序章与第一章聚焦重构（方案 B）、历史清理、UI/UX、音频与 v7 需求包

- **方案文档与 v7 素材需求包落库**：
  - 保存完整开发、清理、UI/UX 与音乐规划方案：[2026-11-16-序章与第一章聚焦重构与清理方案.md](docs/story/2026-11-16-序章与第一章聚焦重构与清理方案.md)。
  - 生成并校验 [IGA_GPT_Asset_Pack_Brief_v7.zip](archive/IGA_GPT_Asset_Pack_Brief_v7.zip)（14,851,023 字节，14 项：`00_v7_Brief_and_Prompts.md`、`01_v7_asset_manifest.json`、10 张现有参考图及 P0/P1 清单），聚焦 `enemy_ch1_hunter_mech`、红月封锁夜战背景、统一风格 256×256 全员小头像及第一章补完素材。
- **打通「新游戏 → 序章／第一章」主线闭环与教学战升级**：
  - [game_state.gd](scripts/global/game_state.gd)、[player_journey.gd](scripts/global/player_journey.gd)、[title_screen.gd](scripts/title/title_screen.gd) 与 [home_screen.gd](scripts/home/home_screen.gd)：新游戏初始预装 3 张战术刻印卡（`wrench_smash` / `scrap_shield` / `icy_soda`），点击「开始新游戏」直接切入 `campus_morning`「樱林解围」；未通关第一章前，`PlayerJourney.home_snapshot()` 正确返回 `action = "story"` 且 `HomeScreen._start_chapter()` 接通 `_legacy_start_chapter()`（`DayCycle` 无待触发日程时不再把新档阻断在空桌面）；`GameState._open_phase_two_node()` 按节点 `briefing_flag` 泛化「先对话 → 再开战」流程。
  - [phase_two_content.gd](scripts/global/phase_two_content.gd)、[node_map.gd](scripts/exploration/node_map.gd)、[combat_screen.gd](scripts/combat/combat_screen.gd)、[combat_presentation.gd](scripts/combat/combat_presentation.gd)、[combat_skin.gd](scripts/global/combat_skin.gd)：为 `n_gate` 实装对话后直入 `liu_yu_long_duel` 非致命护盾切磋教学战（开局暖纸教学提示，固定由杨子英助阵避免柳宇龙自打）；移除 `principal`（`校长现身`）与 `保安拦路` 文案，第一章 Boss 替换为 `ch1_hunter_mech`（灰区超限猎杀终端，纳入 `is_overclock_combat`，旧存档 `principal`/`boss_frank` 兼容映射到同终端）；修正 `#09 射手座` 已废除的 `"35岁死亡程序"` 文案（[zodiac_catalog.gd](scripts/data_models/zodiac_catalog.gd)）。
- **对话、战斗操作、训练路线与商店 UX 优化**：
  - [dialogue_screen.gd](scripts/story/dialogue_screen.gd) & [school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd)：`_refresh_speaker_avatar()` 全面接入全员头像（含 `huang_qiufeng` 胸像与 `rebel_operative_masked` 截取，优先匹配后续 v7 `avatars/`）；文本框右下新增随 `story_chrome` 箭头错位呼吸的 `点击继续` 提示（`ContinueCursor`）；`Auto` 模式根据台词长度在 `1.0s–3.2s` 动态停留。
  - [combat_screen.gd](scripts/combat/combat_screen.gd) & [daylight_ui.gd](scripts/global/daylight_ui.gd)：新增战斗桌面快捷键（`1`–`5` 出牌、`Tab` 切换目标、`Space`/`Enter` 结束回合、`H` 开关战报）；`FirstBattleHintWash` 支持 `n_gate` 护盾教学与 `n_guard` 红月超限警示两段指引。
  - [home_screen.gd](scripts/home/home_screen.gd)、[school_exploration_routes.gd](scripts/global/school_exploration_routes.gd)、[campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd) 与 [shop_counter_theme.gd](scripts/campus/shop_counter_theme.gd)：桌面 `TalkJiangZi` 新增悬停气泡「和姜梓聊聊」；训练探索「拾到的留言」在保留第 0 层路牌指引的同时扩充第 1 层起 7 组轮换校园微故事；商店「行动卡」购买页增加 `FilterUnowned`（「仅未拥有」）筛选切换。
- **程序化音频生成与全界面 SFX / BGM 路由接入**：
  - 新增生成器 [generate_sfx.py](tools/audio/generate_sfx.py) 并合成 16 个 `.wav` 音效至 `assets/audio/sfx/`（随 Godot 重导 `.import`），另设外部 BGM 槽位说明 [README.txt](assets/audio/bgm/README.txt)。
  - [audio_manager.gd](scripts/global/audio_manager.gd)、[scene_manager.gd](scripts/global/scene_manager.gd)、[combat_card_ui.gd](scripts/combat/combat_card_ui.gd)、[zodiac_album_panel.gd](scripts/home/zodiac_album_panel.gd) & [reward_card_popup.gd](scripts/ui/reward_card_popup.gd)：实现 8 路 SFX 播放池、`bgm_player`/`bgm_secondary` 交叉淡入淡出、全 UI 悬停/点击/弹窗/翻页/交易/卡牌/受击/协战/星座/胜利音效，并实现 `_exit_tree()` 彻底清理播放句柄防止退出泄露。
- **历史遗留文件与兼容引用清理**：
  - 删除零引用或已被取代的 `scripts/campus/techne_home_view.gd`（+`.uid`）、`scripts/world_map/world_map.gd`（+`.uid`）、`scenes/world_map/world_map.tscn`、`assets/ui/phase_three/cards/{bag,opening,pressure,route_step,support,water}.png`（+`.import`）、`assets/ui/phase_three/card_paper.png`（+`.import`）、`assets/sprites/enemies/phase_two/principal.png` 与 `portraits/principal.png`（+`.import`），同步移除 [main_theme.tres](main_theme.tres)、[scene_manager.gd](scripts/global/scene_manager.gd)、[scene_skin.gd](scripts/global/scene_skin.gd)、[phase_two_content.gd](scripts/global/phase_two_content.gd)、[daylight_ui.gd](scripts/global/daylight_ui.gd) 中过时引用与 `WorldMap` 死分支，并在 [save_manager.gd](scripts/global/save_manager.gd) 补齐 `school_gate_duel_briefed` 测试档标志位。
- **交付素材包 [IGA_Asset_Delivery_v7.zip](archive/IGA_Asset_Delivery_v7.zip) 全部 30 项 PNG 校验与实机全量接入**：
  - 依据清单完成全部 30 张 PNG 像素尺寸/RGBA/RGB 校验并合入 `assets/`（`--headless --import --quit` 零报错导入）：
    - **灰区超限猎杀终端与红月夜战舞台**：`enemy_ch1_hunter_mech.png`（`900×1200`）正式作为 `n5_boss` 敌人立绘；[daylight_ui.gd](scripts/global/daylight_ui.gd) 在 `CombatPresentation.is_overclock_combat()` 触发时自动切换 `battle_red_moon_lockdown_wide.png` / `battle_red_moon_lockdown.png`（`2340×1080` + `1920×1080`）。
    - **全员 256×256 统一对话头像（18 张）**：合入 `assets/sprites/characters/phase_two/avatars/`，`DialogueScreen._refresh_speaker_avatar()` 已优先匹配 `ye_zhou`、`huang_qiufeng`、`yang_zi_ying`、`liu_yu_long`、`jiang_zi` 与 `rebel_operative_masked`。
    - **敌方锁定目标光环 & 教学便签九宫格框**：[combat_vfx.gd](scripts/combat/combat_vfx.gd) 注册 `"target_reticle"`（`vfx_target_reticle_4x2.png`，`10 fps` 循环），[enemy_unit_ui.gd](scripts/combat/enemy_unit_ui.gd) 在当前选中敌人脚底绑定 `LoopVFX_target_reticle`（支持 `Tab` 切目标切换）；[daylight_ui.gd](scripts/global/daylight_ui.gd) 将 `FirstBattleHintWash` 升级为 `ui_tutorial_callout_9slice.png`（48px 四边九宫格）。
    - **章节幕牌、海滩场景与校内配角立绘**：[school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd) 与 [dialogue_screen.gd](scripts/story/dialogue_screen.gd) 在第一章开篇首句叠加渐变淡入淡出的 `ui_chapter_banner.png`（`ChapterBannerToast`）；[scene_design_catalog.gd](scripts/campus/scene_design_catalog.gd) 将 `arete_beach_test` 切换为 `beach[_wide].png` 并重配海面与木长椅热区；[phase_two_content.gd](scripts/global/phase_two_content.gd) 与 [campus_screen.gd](scripts/campus/campus_screen.gd) 接入 `lin_zhi_xia`／`tang_xiao_man`（`neutral`／`happy` `900×1200` 半身立绘）作图书馆／商店对话头像。
- **战斗四段式分层布局重构、朝向修正、多余中场符号清理与 [IGA_GPT_Asset_Pack_Brief_v8.zip](archive/IGA_GPT_Asset_Pack_Brief_v8.zip)**：
  - [combat_presentation.gd](scripts/combat/combat_presentation.gd)、[enemy_unit_ui.gd](scripts/combat/enemy_unit_ui.gd)、[combat_skin.gd](scripts/global/combat_skin.gd)、[combat_screen.gd](scripts/combat/combat_screen.gd) 与 [daylight_ui.gd](scripts/global/daylight_ui.gd)：
    - 移除原 `_layout_arena_emblems()` 造成中场漂浮视觉杂音的 `DuelCrestVS`、`TurnArrowSweep` 与 `RedMoonReticle`；
    - 梳理为「顶栏 (`0..84`) → 上方独立 HUD 信息带 (`84..230`, 含 `ArenaHUDBand`、玩家/同伴/敌人铭牌意图及居中 `FirstBattleHintWash`) → 统一足底地平线站台 (`566..658`, `CombatStagePlatform`, 预留 `combat_stage_platform_{day,redmoon}.png` 扩展位) → 底部手牌区 (`654..1080`)」，所有角色与敌人的脚底统一对齐 `y = 626 px` 并搭配脚下阴影及锁定光环；
    - 通过 `CombatSkin.enemy_needs_flip_h()` 修正敌我朝向（`enemy_ch1_hunter_mech`、`enemy_duel_student_ace`、`enemy_national_finalist`、`enemy_church_guardian` 原生朝左保持不翻转，`security_guard`/`campus_robot`/`enemy_alliance_operative`/`liu_yu_long_duel` 镜像朝左），同步让右下角目标小头像与漂浮伤害文字锚点贴合真实角色体表；
    - [audio_manager.gd](scripts/global/audio_manager.gd) 为 `--audio-driver Dummy` 自动化测试环境跳过硬件混音入队，彻底消除退出时的音频句柄竞态告警。
  - 生成并校验 [IGA_GPT_Asset_Pack_Brief_v8.zip](archive/IGA_GPT_Asset_Pack_Brief_v8.zip)（16,264,663 字节，13 项：含 `00_Progress_Audit_and_v8_Brief.md`、`01_v8_asset_manifest.json` 与 11 张参考图），覆盖昼/夜战斗站台地坪带、朝左重绘 `enemy_security_guard`/`enemy_campus_robot`、最后 3 枚第一章缺口头像与 `enemy_alliance_operative` 原生朝左版的需求、参考与验收标准。
- **交付素材包 [IGA_Asset_Delivery_v8.zip](archive/IGA_Asset_Delivery_v8.zip) 全部 8 项 PNG 校验与实机全量接入**：
  - 依据清单完成全部 8 张 RGBA PNG 尺寸/透明通道/哈希校验并合入 `assets/`（`--headless --import --quit` 零报错导入）：
    - **昼/夜统一战台地坪条带**：`combat_stage_platform_day.png` 与 `combat_stage_platform_redmoon.png`（`2340×120` RGBA）落位于 `assets/ui_core/theme/`，由 `CombatSkin.platform_texture(overclock)` 与 `CombatStagePlatformArt` 自动挂载至 `566..658` 站台区域。
    - **原生朝左第一章敌兵重绘**：`enemy_security_guard.png`、`enemy_campus_robot.png` 与 `enemy_alliance_operative.png`（`900×1200` RGBA）均原生朝左面向叶舟；[combat_skin.gd](scripts/global/combat_skin.gd) `enemy_needs_flip_h()` 已移除此三项（仅保留 `drone`、`preacher`、`liu_yu_long_duel` 镜像翻转），同步更新 [scene_reset.gd](tools/tests/scene_reset.gd) 朝向与地坪节点断言。
    - **第一章最后 3 枚缺口对话头像**：`huang_qiufeng_surprised.png`、`huang_qiufeng_crystal_stasis.png` 与 `rebel_operative_unmasked_neutral.png`（`256×256` RGBA）落位于 `assets/sprites/characters/phase_two/avatars/`，已由 `DialogueScreen._refresh_speaker_avatar()` 路径直接命中。
- **战斗定尺槽位、双层头顶 HUD（信息显示栏 → 图标+数字状态行）与三敌同屏上限重构**：
  - [combat_screen.gd](scripts/combat/combat_screen.gd)、[combat_presentation.gd](scripts/combat/combat_presentation.gd)、[enemy_unit_ui.gd](scripts/combat/enemy_unit_ui.gd) 与 [daylight_ui.gd](scripts/global/daylight_ui.gd)：
    - **同屏人数上限与定尺比例**：`_setup_combat_from_state()` 将同屏敌人上限锁定为 3 名（`raw_enemy_ids.slice(0, 3)`）；每个敌人在 1/2/3 敌同屏时恒定分配 `ENEMY_SLOT_SIZE = 332×572` 槽位与 `290×400` 站姿包围盒（脚底固定对齐 `local y = 554`），不再随人数变化缩小或放大；叶舟固定位于左侧主战位（`center_x = 456`，`292×404`），同伴固定位于左后方站位（`comp_center_x = 152`，`224×376`、`foot_y = 544` 略靠后微错位，头上**无任何信息栏或状态栏**）。
    - **双层头顶层级（上：信息显示栏 ／ 下贴头顶：状态行）**：统一将 `ArenaHUDBand` 规划在 `y = 78..206`，使所有可战单位先紧贴头顶排列 `PlayerStatusIcons` / `EnemyStatusIcons`（`y = 170..202`），其上方才是 `PlayerIdentity` / `IdentityPaper` 信息牌（`y = 82..166`）。移除叶舟右侧冗余白底战术框与共振副框，将体力 `HPLabel`、白羊共鸣徽章及同伴助阵摘要整合进单一横版铭牌内并校正左右安全边距。
    - **全套战斗状态 SVG 与字体颜色层级**：在 `assets/ui_core/icons/combat/` 新增与现有线性手绘风一致的 `64×64` 状态图标：[burn_suppress.svg](assets/ui_core/icons/combat/burn_suppress.svg)、[reflect_counter.svg](assets/ui_core/icons/combat/reflect_counter.svg)、[companion_assist.svg](assets/ui_core/icons/combat/companion_assist.svg) 与 [zodiac_crest.svg](assets/ui_core/icons/combat/zodiac_crest.svg)（已通过 Godot `--import` 写入 `.import`）；抽出共用 `CombatPresentation.sync_status_chip()` 徽章辅助器与配色表（护盾冰蓝、净受击/压制绯红、零伤挡住翠绿、反击琥珀、虚弱梅紫、协战 2/3 金框高亮），统一零描边高对比 `NotoSerifSC-SemiBold.ttf` 数字与分级字号，并修复 `FirstBattleHintWash` 在 `n_guard` / `n_gate` 下的容器缓存宽度导致的文本右偏。
  - [zodiac_and_shop.gd](tools/tests/zodiac_and_shop.gd)：新增 4 敌截断为 3 敌、3 敌等宽槽位、头顶信息栏与状态行上下秩序、同伴零头顶 UI、无压制仅虚弱时的 `StatusIcon` 可见性、v8 昼/夜地坪与左向立绘／新头像校验，及 `1600×900` / `1600×720` 双分辨率 `v8_combat_day_platform.png`、`v8_combat_three_enemies.png` 视觉截屏。
- **全量验证结果（最终定稿后三环境全量通过）**：
  - `--headless`（`--suite all`）：`regions` 544、`home` 174、`scenes` 540、`zodiac` 544 —— 合计 **1,802 项检查，0 失败，0 报错与资源泄露**。
  - OpenGL `1600×900`（`--suite all`）：`regions` 564、`home` 198、`scenes` 594、`zodiac` 561 —— 合计 **1,917 项检查，0 失败**；已逐图目检 `v8_combat_day_platform.png`、`v8_combat_three_enemies.png` 与 `v7_n_guard_hint.png`。
  - OpenGL `1600×720`（全 4 套件分轮验证全部 0 失败）：`regions` 564、`home` 198、`scenes` 594（初次并发桌窗失焦重跑全过）、`zodiac` 561 —— 合计 **1,917 项检查，0 失败**；已逐图目检宽屏 `v8_combat_day_platform.png`、`v8_combat_three_enemies.png` 与 `v7_n_guard_hint.png`。

## 2026-11-16 v6 交付素材全量接入、动效联调与视觉回归验证

- **交付素材包校验与导入（42/42 PNG）**：
  - 解包并 SHA-256 校验 [IGA_Asset_Delivery_v6.zip](archive/IGA_Asset_Delivery_v6.zip) 全部 42 个运行期 PNG（`P0`: 14、`P1`: 21、`P2`: 7；含 18 项现有资产升级与 24 项新增资产，其中 7 张 `2340×1080` `*_wide.png` 无缝扩展图与 `enemy_alliance_operative.png` 规范化尺寸 `900×1200` 已合入 `assets/`），经 Godot 4.7.2 `--headless --import --quit` 重导通过（无损 `compress/mode=0`、透明描边修正开启）。
- **6 套 `4×2` 序列帧 VFX 与 UI 动态叠加实装**：
  - [combat_vfx.gd](scripts/combat/combat_vfx.gd)：在 `SHEETS` 与 `EFFECT_SPECS` 接入 `debuff`、`companion_assist`、`overclock_redmoon`、`counter_reflect`、`pack_tear`、`crystal_shimmer`（全部 `512×512` 单元格、`start_idx = 0` 按清单帧率播放），并为 `play_burst()` 新增 `z_layer` 参数及新增循环接口 `play_loop()`。
  - [combat_screen.gd](scripts/combat/combat_screen.gd)、[combat_presentation.gd](scripts/combat/combat_presentation.gd)、[combat_card_ui.gd](scripts/combat/combat_card_ui.gd) 与 [combat_skin.gd](scripts/global/combat_skin.gd)：实装同伴斜斩 Cut-in（`CompanionCutinOverlay`、`CombatSkin.character_cutin_path()`、文字描边与常/减动效安全淡出）、超限遭遇红月脉冲角框（`RedMoonHudPulse`）、主角白羊/星座激活金环徽章（`ZodiacHaloEmblem`）、手牌 9 宫格微光边框（`HoverGlowFrame`，`48px` 边距、`draw_center = false`），并在对应攻击/反击/减益/超限/协战节点触发新序列帧。
  - [zodiac_album_panel.gd](scripts/home/zodiac_album_panel.gd) & [reward_card_popup.gd](scripts/ui/reward_card_popup.gd)：十二星座详情卡背面接入慢速旋转共鸣光环（`DetailResonanceHalo`），新卡解锁弹窗叠加拆封撕裂星芒（`VFX_pack_tear`，`z_index = 44`）与绽放特效（`VFX_pack`，`z_index = 45`）。
- **立绘、剧情表情、过场与训练对话卡死修复**：
  - [phase_two_content.gd](scripts/global/phase_two_content.gd)、[parallax_cutscene_stage.gd](scripts/ui/parallax_cutscene_stage.gd)、[school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd) 与 [dialogue_screen.gd](scripts/story/dialogue_screen.gd)：接入反叛组织袭击者（蒙面/摘面具）、诺莫斯/阿戈拉/忒克捏地区代表半身像、黄秋枫 `damaged_fiber` 与 `crystal_stasis` 状态表情（叠加 `crystal_shimmer` 循环闪烁），注册 `"qiufeng_crystal"`（含前景 `LoopVFX_crystal_shimmer`）与 `"red_moon_finale"` 双层过场（`status: "integration_candidate"`）；并修复 `DialogueScreen` `old_shimmer` 类型推断 Parse Error 导致的训练「拾到的留言」对话卡死与 `_layout_story_scene()` 重排清空 `_current_cutscene_id` 的问题。
- **测试、MCP 检查与全量视觉回归状态**：
  - [zodiac_and_shop.gd](tools/tests/zodiac_and_shop.gd) 与 [scene_reset.gd](tools/tests/scene_reset.gd) 增补全套 v6 资产、Cut-in 横幅、UI 动态节点、双层过场、`pack_tear`、全项目 `.gd`/`.tscn` 编译加载、训练「拾到的留言」推进/退出及 `find_yang` + `Esc` 回归校验。
  - **MCP 服务器检查**：执行 `node tools/visual_review/mcp_client.mjs list` 返回退出码 1（`Error: No installed Godot MCP server. Set GODOT_MCP_SERVER_ENTRY to its dist/index.js.`）；视觉校验通过 Godot 4.7.2 离屏 OpenGL 渲染完成并逐图复核：
    - OpenGL `1600×900`：`regions` 562、`home` 198、`scenes` 596、`zodiac` 455（合计 1,811 项，0 失败）
    - OpenGL `1600×720`：`regions` 562、`home` 198、`scenes` 596、`zodiac` 455（合计 1,811 项，0 失败）
    - `--headless`：`regions` 542、`home` 174、`scenes` 542、`zodiac` 444（合计 1,702 项，0 失败）

## 2026-11-14 v6 全案世界观重构、第一章黄秋枫主线衔接、16 卡商店、同伴协战与星座共鸣实装

- **总纲设计书与最高优先级基准同步**：
  - 新增 [2026-11-14-世界观与全案重构设计书.md](docs/story/2026-11-14-世界观与全案重构设计书.md)，并同步更新 [AGENTS.md](AGENTS.md) 与 [CURRENT_DESIGN.md](docs/CURRENT_DESIGN.md)：以「红月学园都市＋学生终端战术刻印卡」统一日常合法护盾切磋与黄昏/红月超限（Overclock）实弹冲突，梳理五章主线（第一章阿瑞忒旧公园与白羊星火 → 第五章失败者同盟与红月圣堂）与十二大 UI 界面体系。
- **黄秋枫运行期资产与第一章主线实装**：
  - 从 `concept_huang_qiufeng_draft.png` 裁切导入 9 个透明通道 PNG 至运行期目录（`assets/sprites/characters/phase_two/{halfbody,portraits}/huang_qiufeng.png`、`assets/sprites/characters/phase_two/emotions/huang_qiufeng/{neutral,happy,shy,surprised,angry,worried}.png` 及 `assets/sprites/characters/phase_three/combat/combat_huang_qiufeng_idle.png`）。
  - [phase_two_content.gd](scripts/global/phase_two_content.gd)、[home_panels.gd](scripts/home/home_panels.gd)、[parallax_cutscene_stage.gd](scripts/ui/parallax_cutscene_stage.gd) 与 [game_state.gd](scripts/global/game_state.gd)：注册 `"huang_qiufeng"` 角色数据、补充角色与敌兵立绘回退路径，重构第一章主线流程（开学日街角解围 → 校园日常演练 → 旧公园黄昏与亲吻 → 红月门禁拦截战 → 反叛组织袭击与同伴驰援超限头目战），并在 `chapter_1_completed` 时触发 `SpecialCardCollection.acquire_from_story("hero", "chapter_1_aries_awakening")` 觉醒白羊座母卡。
- **16 张战术刻印卡商店与工坊/图鉴/战斗联动**：
  - [campus_shop_catalog.gd](scripts/data_models/campus_shop_catalog.gd)、[campus_shop_panel.gd](scripts/campus/campus_shop_panel.gd) 与 [shop_counter_theme.gd](scripts/campus/shop_counter_theme.gd)：将商店 `"cards"` 类扩充至全部 16 张战术刻印卡（去除卡牌名多余的 `· TEST` 尾缀并统一设定文案），为 `ProductsBoard` 接入 `ProductsScroll`（`Rect2(190, 320, 998, 578)`）与 `ProductsGrid` 坐标映射，使 3×2 木框货架格子对齐并支持向下滚动翻看全 16 张卡。
  - [player_journey.gd](scripts/global/player_journey.gd)、[game_state.gd](scripts/global/game_state.gd)、[player_workspace.gd](scripts/home/player_workspace.gd)、[zodiac_album_panel.gd](scripts/home/zodiac_album_panel.gd)、[combat_screen.gd](scripts/combat/combat_screen.gd) 与 [combat_presentation.gd](scripts/combat/combat_presentation.gd)：
    - 新增 `COMPANION_ORDER`、`COMPANION_ASSISTS`（杨子英/柳宇龙/姜梓 每打出 3 张卡自动触发助阵协战 + `_play_unit_lunge()` 微突进）与工坊右上角 `CompanionButton` 切换入口。
    - 新增 `ZODIAC_RESONANCES`（12 星座母卡战斗全局被动）、图鉴详情页 `ResonateButton` 激活/取消切换，及战斗左栏 `CompanionResonancePill`（`CompanionAssistBadge` 与 `ZodiacResonanceBadge`）；实装开局护盾/回血/降攻/压制、每回合回血、攻击/护盾加成与断点存档持久化（`cards_played_total`）。
- **UI 动态与美术需求压缩包**：
  - 生成完整需求包 [IGA_GPT_Asset_Pack_Brief_v6.zip](archive/IGA_GPT_Asset_Pack_Brief_v6.zip)（33,327,149 字节，28 项内容：含 `00_Master_Redesign_and_Asset_Brief_v6.md`、`01_Character_Prompts_and_Specs.md`、`02_UI_Dynamic_and_VFX_Animation_Specs.md`、`03_asset_manifest_v6.json` 及 24 个风格参考与待重延 `2340×1080` 宽屏源图）。
- **MCP 与全量回归验证状态**：
  - **Godot MCP 服务器排查**：执行 `node tools/visual_review/mcp_client.mjs list`（沙箱内外均返回退出码 1，`Error: No installed Godot MCP server. Set GODOT_MCP_SERVER_ENTRY to its dist/index.js.`），本机尚未安装 `@npgamedev/godot-mcp-server`，实际视觉检查改由 Godot 4.7.2 OpenGL 离屏截图＋逐张图像目检完成。
  - **自动化与视觉检查结果**：[tools/tests/zodiac_and_shop.gd](tools/tests/zodiac_and_shop.gd) 新增 `_v6_systems()`（`huang_qiufeng` 资产、16 卡商店、`CompanionButton`、`ResonateButton` 与防重叠几何检查、白羊共鸣开局护盾、柳宇龙 3 卡协战及日志）及三张专属截图验证。经最后一次改动后全部通过：
    - OpenGL `1600×900`：`regions` 562、`home` 198、`scenes` 476、`zodiac` 430（合计 1,666 项，0 失败）
    - OpenGL `1600×720`：`regions` 562、`home` 198、`scenes` 476、`zodiac` 430（合计 1,666 项，0 失败）
    - `--headless`：`regions` 542、`home` 174、`scenes` 425、`zodiac` 420（合计 1,561 项，0 失败，0 引擎报错）
    - 目检修复并复验了商店滚动网格对齐、`ZodiacDescription`/`ResonateButton` 分区防重叠及战斗左栏 `CompanionResonancePill` 文字防裁切与站位避让。

## 2026-11-14 v5 素材交付全量合入、20:9 叠层修复与战斗 VFX / 过场接入

- **Wave 5A 概念与草图归档（不作正式实装）**：
  - 将 14 张整页概念图（`A1..A14`）、`concept_huang_qiufeng_draft.png` 及说明归档至 [assets/references/wave5_concepts/](assets/references/wave5_concepts/README.md)（受 `assets/references/.gdignore` 隔离）；遵循 `AGENTS.md` 不改动 `CalendarContent.STORY_DATES`（保持为空）、`PhaseTwoContent` 与未定正式剧本。
- **Wave 5B 加载主题、双层视差过场、2340×1080 宽屏延伸与 VFX / SVG 实装**：
  - [scene_loading_screen.gd](scripts/ui/scene_loading_screen.gd) & [scene_manager.gd](scripts/global/scene_manager.gd)：新增 6 组宽屏加载主题（`after_school`、`red_moon`、`nomos`、`agora`、`techne`、`tournament`）及 `apply_theme()` / `theme_for_context()`（避免覆盖 `Control.set_theme`），根据目标场景与当前地区动态切换加载底图。
  - [parallax_cutscene_stage.gd](scripts/ui/parallax_cutscene_stage.gd) & [school_dialogue_presentation.gd](scripts/story/school_dialogue_presentation.gd)：按相机配置 JSON 接入 4 组双层视差过场——`red_moon_street`、`arena_spotlight`（状态 `"integration_candidate"`）与 `old_park_dusk`、`rebel_warning`（仅标 `"story_concept_review"` 不自动绑定对话），`after_school` 继续保留 `"dusk_corridor"`。
  - [player_workspace.gd](scripts/home/player_workspace.gd)、[campus_screen.gd](scripts/campus/campus_screen.gd)、[scene_object_view.gd](scripts/campus/scene_object_view.gd)、[region_map_view.gd](scripts/campus/region_map_view.gd)、[scene_surface_ui.gd](scripts/ui/scene_surface_ui.gd)、[map_screen.gd](scripts/campus/map_screen.gd) 与 [platform_service.gd](scripts/global/platform_service.gd)：接入 `prep_scene_*_wide`、`records_*_wide`、`dorm_bg_wide`、`{rooftop,library,gym,shop,coast}_wide` 及 `{map_failed,map_church}_wide`（保留原始 `1920×1080` 底图纹理供地标像素裁切/测试定位）；修复 `_PlatformEdgeBleed`（原默认 `z_index = 0`）在 20:9（`1600×720`）覆盖 `SceneObjectView` / `RegionMapView` 中 `z_index = -3/-2/-1` 宽图与热点的叠层重影问题，将其固定至 `bleed.z_index = -100` 并在 `finish_layering()` 保护 `WideMapBackground`。
  - [combat_vfx.gd](scripts/combat/combat_vfx.gd) & [reward_card_popup.gd](scripts/ui/reward_card_popup.gd)：新增 `CombatVFX`（4 套 `4×2` 赛璐璐序列帧 `slash`/`shield`/`heal`/`pack`，跳过空白第 0 帧以 `14 FPS` 从第 1 帧即时起效并支持 `reduced_motion` 淡出，及 4 个 SVG 常量），接入玩家/敌方攻击、护盾、治疗、反击与 `RewardCardPopup` 解锁新卡爆星演出（修正 `presentation` 缩放坐标中心并扩大 `pack` 至 `760×760`）。
- **Wave 5C 决斗卡背、10 张测试卡牌插画、同伴助阵与 4 名测试对手**：
  - [combat_skin.gd](scripts/global/combat_skin.gd)、[scene_skin.gd](scripts/global/scene_skin.gd)、[card_data.gd](scripts/data_models/card_data.gd)、[game_state.gd](scripts/global/game_state.gd) & [save_manager.gd](scripts/global/save_manager.gd)：新增 `card_back_duel.png`、`combat_{liu_yu_long,jiang_zi,yang_zi_ying}_idle.png`、`enemy_{duel_student_ace,national_finalist,alliance_operative,church_guardian}.png` 与 10 张 `card_art_*.png`；在 `SceneSkin.illustration_texture()` 中对 `card_art_final_trump.png` 裁剪底部 `28px` 遮除生图白字水印；注册 10 张 `· TEST` 卡牌至 `GameState.all_cards` 并将 `SaveService.build_test_progress()` 扩充至全部 16 张卡及 `"决斗包·TEST"`（保持 `new_game()` 初始 4 张起步不变）。
  - [combat_presentation.gd](scripts/combat/combat_presentation.gd)、[combat_screen.gd](scripts/combat/combat_screen.gd) & [enemy_unit_ui.gd](scripts/combat/enemy_unit_ui.gd)：新增左侧 `DuelDeckBack`、中场 `DuelCrestVS` / `TurnArrowSweep` / `RedMoonReticle` 矢量徽标、`CompanionSprite` 助阵站位（互不遮挡）、4 名 `·TEST` 对手配置（优化长名称字号避免 `…` 截断），并将待命中的 `debuff.svg` / `heal.svg` 接入敌人意图与状态标签（`压制` 显示下箭头图标）。
- **已知原始素材瑕疵记录（已做运行时规避，留待下次调优）**：
  - `assets/combat/card_art/card_art_final_trump.png` 底边存在极小生成白字水印（游戏内已由 `h - 28` 裁切遮除）。
  - `2340×1080` 宽屏延展中 `map_failed_wide.png`、`prep_scene_room_wide.png`、`records_room_wide.png` 拼接自然；`gym_wide.png`、`rooftop_wide.png`、`library_wide.png`、`shop_wide.png`、`coast_wide.png` 与 `map_church_wide.png` 左右外缘各约 `210px` 存在横向像素拉伸拖尾（中间 `1920×1080` 主体完好），`dorm_bg_wide.png` 极外侧边缘亦有轻微拉伸。
- **验证基线**：
  - [tools/tests/zodiac_and_shop.gd](tools/tests/zodiac_and_shop.gd)、[tools/tests/scene_reset.gd](tools/tests/scene_reset.gd)、[tools/tests/home_objects.gd](tools/tests/home_objects.gd) 与 [tools/tests/p5_regions.gd](tools/tests/p5_regions.gd) 覆盖 GDScript 缩进预检、Godot `--headless` 与 OpenGL `1600×900` / `1600×720` 全量回归（含 16 卡全解锁、卡背/立绘/对手资源、28px 裁切、`ParallaxCutsceneStage` 5 组预设与概念边界、`SceneLoadingScreen` 6 主题、`CombatVFX` 8 帧/SVG、`CompanionSprite` + `"决斗包·TEST"` + `debuff.svg` + `VFX_slash`/`VFX_pack` 实机渲染，及 `20:9` 下基于真实视口矩形的标题不越界检查）。

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
  - **回归测试与验证基线**：7 个相关脚本通过检查（0 错误），完成 26 张实机截图复核并产出评估摘要；随后已通过 v3–v8 迭代全面升级并在 2026-11-16 完成全部三环境回归验证。
