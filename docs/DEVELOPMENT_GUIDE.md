# 当前开发与架构指引

先读 [世界观与全案重构设计书](story/2026-11-14-世界观与全案重构设计书.md)、[HANDOFF.md](../HANDOFF.md) 与 [CURRENT_DESIGN.md](CURRENT_DESIGN.md)。开发过程中沿用公共模块与现有服务，定位根因后执行真机与隔离回归测试验证，避免重复实现。

## 核心模块映射

| 模块 | 当前入口与职责 |
| --- | --- |
| 玩家状态 | `scripts/global/game_state.gd`：卡牌收藏与出战、体力、资源、日历、主线/自由探索/训练检查点、`execute_shop_trade()`、`complete_phase_two_step()`；全 16 张战术刻印卡定义位于 `_init_default_cards()`。 |
| 存档与测试档 | `scripts/global/save_manager.gd`（`SaveManager`）：带全量字段校验与 `.bak` 备份（`user://saves/slot_1.json`、`user://settings.json`），支持标题页及系统菜单内「常驻全解锁测试存档」（`test_session = true` 隔离写盘）。 |
| 场景与转场 | `scripts/global/scene_manager.gd`（`SceneManager`）：6 主题加载页（`SceneLoadingScreen`）、斜边战斗进出条带与统一新卡/物品弹出框（`RewardCardPopup`）。 |
| 音频服务 | `scripts/global/audio_manager.gd`（`AudioManager`）：8 路程序化 SFX 池（`assets/audio/sfx/*.wav`）及 6 条外部 BGM 淡入淡出路由（见 `assets/audio/bgm/README.txt`；`Dummy` 音频驱动自动跳过混音入队）。 |
| 昼夜与日历 | `scripts/global/day_cycle.gd`（`DayCycle`）：10 月 1 日起三时段（早晨/下午/夜晚，`ACTIONS_PER_PERIOD = 3`）；`CalendarContent.STORY_DATES` 目前留空待后续 2–5 章日程填入。 |
| 地区与日常 | `scripts/campus/{campus_life,region_catalog,world_region_content,campus_places,campus_screen,campus_dialogue_ui}.gd`：管理 6 主地区解锁、旅行校验、两级地图与各地点短剧情。 |
| 两级地图与概念场景 | `map_screen.gd` 配合 `region_atlas_view.gd` / `region_map_view.gd`；新场景、三所大学 Home 及功能地点通过 `SceneDesignCatalog`、`SceneObjectView`、`HomeObjectButton`、`RegionHomeLayout` 与 `SceneSurfaceUI` 实现热区/纸签/宽屏延伸。 |
| Home 与工作台 | `home_screen.gd`、`player_workspace.gd`（3 套 5 卡方案工坊 / 同伴切换 / 放映机记录）、`campus_shop_panel.gd`（16 卡与材料/补给商店）、`zodiac_album_panel.gd`（《十二星座图鉴》及战场共鸣切换）、`student_terminal.gd`（智能终端资料）。 |
| 共享界面组件 | `HomePanels`、`NotebookUI`、`SchoolObjectUI`、`DaylightUI`、`SceneSkin`、`CombatSkin`：提供统一字体加粗变体（`DaylightUI.body_font()`）、纸面 NinePatch、`borderless()` 无额外描边按钮及选中反馈。 |
| 主线与薄膜过场 | `PhaseTwoContent`（第一章 `FLOW_STEPS` / `SCRIPTS` / `CUTSCENES`）、`DialogueScreen`（头像匹配、呼吸翻页标、历史记录）、`SchoolDialoguePresentation`、`ParallaxCutsceneStage`（双层视差电影过场）。 |
| 模拟训练 | `SchoolExplorationFlow`、`SchoolExplorationRoutes`、`ExplorationContent`、`school_route_screen.gd`：体育馆多路线分支探索、随机/轮换校园事件与终点对决。 |
| 战斗表现层 | `combat_screen.gd`、`CombatPresentation`、`CombatVFX`、`CombatCardUI`、`EnemyUnitUI`、`FloatingText`：定尺 3 敌上限、同伴 3 卡 Cut-in 协战、星座开局/回合被动、头顶双层信息栏+状态行徽章与 `4×2` 序列帧特效。 |

## 关键开发规则与测试入口

- **卡组与商店边界**：`GameState.apply_equipped_deck()` 与 `PlayerWorkspace` 在装备层保证每套出战方案至少 1 张 `ATTACK` 卡；商店交易经 `CampusShopCatalog.REGION_SHOPS` 与 `GameState.execute_shop_trade()` 校验库存、余额、防重放与特殊卡不可买卖规则。
- **缩进与类型**：不同目录沿用各自既有缩进风格（`run_godot_tests.py` 预检强制同一 `.gd` 文件内禁止混用 Tab 与空格）；禁止在无类型字典取值上使用 `:=`，避免 GDScript 静态分析报错。
- **自动化与视觉回归**：
  - 统一隔离测试器位于 `tools/run_godot_tests.py`（支持 `--suite {regions,home,scenes,zodiac,all}`、`--resolution 1600x900|1600x720` 与 `--captures`）；测试使用临时隔离用户目录，不污染本机存档。
  - Linux 云端可使用 `bash tools/cloud/setup.sh`、`bash tools/cloud/check.sh` 与 `bash tools/cloud/test_p5.sh`。
  - 界面改动除无界面跑通外，须在 `1600×900` 与 `1600×720` 下查验真实截图与交互热区。
