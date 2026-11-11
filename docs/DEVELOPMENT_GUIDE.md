# 当前开发入口

先读 [HANDOFF](../HANDOFF.md)、[当前设计](CURRENT_DESIGN.md) 与最新[场景重置记录](2026-10-25/SCENE_RESET.md)。保留已有未提交改动；沿用现有模块与公共工具，定位原因并实机验证，避免重复实现和无关重构。

最新增量见[智能终端/星座卡/商店](2026-10-25/TERMINAL_ZODIAC.md)。`StudentTerminal`提供六个资料应用；`ZodiacCatalog`只定义名称、人格与既定能力，`SpecialCardCollection.acquire_from_story()`提供幂等剧情收藏接口。`CampusShopCatalog.REGION_SHOPS`注册六地区到店服务，`GameState.execute_shop_trade()`统一白名单、库存、数量、余额和重复请求校验。终端无购物入口；旧存档可没有新增的收藏/交易字段。

`TerminalConceptUI`按各页母图的原像素注册控件，`TerminalProjection`将屏内结构和实时文字/输入映射到概览的同一屏幕；物理机身只读`layouts/overview.png`。保留这层映射，不把星座页或其它原始概念的整块不同平板直接替回。新增回归场景为`tools/tests/student_terminal.tscn`；隔离运行器可用`--suite terminal`或`--suite all`，先检查GDScript缩进，再严格检查引擎错误、断言和截图实际尺寸。云端可用`P5_TEST_SCENE=res://tools/tests/student_terminal.tscn bash tools/cloud/test_p5.sh`。

## 架构定位

| 模块 | 当前入口与职责 |
| --- | --- |
| 玩家状态 | `scripts/global/game_state.gd`：卡牌、体力、资源、日历、主线与训练检查点、可选 player_profile；卡牌定义仍在 `_init_default_cards()` |
| 存档与设置 | `scripts/global/save_manager.gd`，自动加载 `SaveManager`：验证、备份、设置与 active_session；默认 `user://saves/slot_1.json` |
| 场景流程 | `scripts/global/scene_manager.gd`，自动加载 `SceneManager`：加载、连续对白、战斗条带与统一奖励层 |
| 昼夜与日期剧情 | `scripts/global/day_cycle.gd`，自动加载 `DayCycle`：时段活动、休息、日期/星期、关键故事排队与阅读断点；`calendar_content.gd` 的 `CalendarContent.STORY_DATES` 为剧本日期表，当前按主创决定留空 |
| 地区与校园日常 | `scripts/campus/campus_life.gd`，自动加载 `CampusLife`，统一旅行、解锁拦截、地图来源与存档落点；`region_catalog.gd` 定义地区/剧情标记/位置/功能分区，`campus_places.gd` 定义地点/NPC/校园短剧情；`campus_screen.gd` 复用实际地点场景，`campus_dialogue_ui.gd` 是日常对话 |
| 两级地图 | `map_screen.gd` 驱动独立 `local_map_screen.tscn` / `region_atlas_screen.tscn`；`region_atlas_view.gd` 使用新旅行概念图及原坐标物件热区，`territory_button.gd` 保留旧路线兼容；`region_map_view.gd` 自动按昼夜显示朱砂/靛蓝，无手动切换，上下信息无大底板；`map_page_ui.gd` 提供轻量按钮反馈，焦点无描边 |
| 场景概念与图层 | `SceneDesignCatalog` 定义新地点/地图及源坐标，`SceneObjectView` 负责物件点击流程，`SceneSurfaceUI` 复用提取纸签。`HomeObjectButton` 从同一母图剪出遮罩和热区，`RegionHomeLayout` 定义三Home的注册坐标。`map_page_geometry.gd` / `region_geometry.gd` 只保留旧路线与缺图后备。首轮简化原图及配准建筑裁片先于原生标题/名称绘制；建筑有点击区域，地点名为 `MOUSE_FILTER_IGNORE` 的纯黑文本，无功能说明、圆点、独立按钮或底板。`PAINTED_LABELS` 按各自原图将名称放在建筑附近较浅色块，建筑热区仍用 `PAINTED_RECTS`。`TargetScene.CAMPUS_LIFE` 和 `campus_life` 存档键保留名称兼容 |
| Home 与功能页 | `home_screen.gd`；`StudentTerminal`负责智能终端资料，`PlayerWorkspace`负责卡牌整理，`CampusShopPanel`负责地点柜台，`CampusGuidePanel`负责训练选择，`SchoolObjectPanels`仍服务同学交流等入口；旧记录布局保留兼容 |
| 共享旧模块 | `HomePanels` 仍提供快照、EquipSlot、经历记录及后备；`NotebookUI` 仍服务战斗/菜单/文字工厂；不能按名称或年代直接移走 |
| 主线与回看 | `PhaseTwoContent` 定义角色、`SCRIPTS`、`FLOW_STEPS`；`DialogueScreen` 处理阅读、分支、日志和检查点；`SchoolDialoguePresentation` 布局 |
| 模拟训练 | `SchoolExplorationFlow`、`SchoolExplorationRoutes`、`ExplorationContent` 与 `school_route_screen.gd`；主线、自由探索、训练分别保存与恢复 |
| 战斗与成长 | `combat_screen.gd`、`CombatPresentation`、`CombatCardUI`、`EnemyUnitUI`；`CardData` 计算现行成长/次数/CD，`PlayerJourney` 负责方案、材料练习与成长奖励 |
| 物品 | `ItemCatalog` 与 GameState 库存/奖励服务；测试道具保持测试标识，不在新游戏自动发放 |
| 美术与样式 | `SchoolObjectUI`、`SchoolPaperSurface`、`DaylightUI`、`SceneSkin` 与现用分层 PNG；`PhaseTwoSkin`仅保留无旧资源的兼容类名，当前调用均已迁移；`SchoolObjectUI.borderless()` 统一按钮描边处理 |

路径未完整列出时在 `scripts/` 下搜索同名类。新增功能先查调用方与数据校验，不把旧技能中“所有剧本写进 DialogueScreen”“按 40% 成长”等样例当成现行实现。数值以 `CardData`、战斗结算和当前玩法记录为准。

卡组规则由装备层保证，按用户最终要求不在关卡/战斗新增检查。`PlayerJourney.deck_summary()` 以 `CardType.ATTACK` 识别攻击卡；`GameState.apply_equipped_deck()` 验证并统一提交，`equip_card()` / `unequip_card()` / `unequip_slot()` 与方案应用共用。新游戏只装备「找准空隙」一张，并在方案1明确显示，避免可见空草稿却隐藏四张默认装备。最后一张攻击卡不能卸下或换成非攻击；有别的攻击卡时可正常调整。`PlayerWorkspace` 在移出/替换、保存/应用中同步约束，未完成草稿不生效。旧无攻击装备在 `import_progress()` 的装备读取边界修补，战斗仍直接使用实际装备或训练出发快照。见 [本轮修复与验证](2026-10-18/empty_training_deck/CURRENT_STATUS.md)。

训练面板属于体育馆 `CampusScreen._open_workspace("training")`。Home 已移除体育馆快捷按钮，`_open_training()` 兼容处理只打开校园地图；主推荐也不绕过地图。路线暂停/结束/出口调用 `CampusLife.return_from_training()`。战斗 `_on_escape_pressed()` 走即时失败：训练通过已有结算服务终止整次路线，主线清除本场快照并恢复安全体力；`SaveManager` 允许已经提交的失败结果保存，禁止将其重新写为战斗快照。卡组草稿、成长与回看仍复用原服务。

地区由具体地点推导；浏览地图不修改当前地区。`current_location` / `player_profile.campus_life.last_location` 是实际落点；`map_region_id` 是当前浏览地区，`map_return_location` 记录打开地图前的实际地点，不因跨地区浏览覆盖。新增 `TargetScene.LOCAL_MAP=7` 与 `REGION_ATLAS=8`，旧枚举数字保持原值。地图 Esc 链为总图→浏览地区地图→实际出发地点；未解锁地区的返回回退校园。

`RegionCatalog.is_unlocked()` 从已有 `story_flags` 读取 `region_resistance_unlocked` / `region_sanctuary_unlocked`，校园始终开放；总图监听 `story_flag_updated` 即时更新禁用状态与键盘链。剧本未来通过 `GameState.set_story_flag()` 设置；不新增存档版本或猜测触发节点。地图入口和旅行接口都校验解锁，`restore_saved_location()` 对旧原型未解锁落点回退社团教室。

校园早晨/下午使用 `campus_vermilion_first_pass.png`，夜晚用 `campus_indigo_first_pass.png`；`CampusLife.map_concept()` 从 `DayCycle.period()` 推导，不再提供 setter 或手动切换。旧可选 `map_concept`（包括已退役 `verdant`）仍通过存档校验，但不决定画面。`RegionMapView` 监听日历变化，合并同帧刷新，并安全恢复仍在树内的焦点，避免旧按钮延迟抓焦点报错。空间规划入口与 `show_geometry` 已删除，`MapPageGeometry` 仍供世界总图和缺图后备。不使用第二次简化及后续强化环境版。继续/手动读档、地区 Home 回看返回使用 `restore_saved_location()`；社团教室到达时同步地点。

## 时间与剧本日期

`DayCycle` 在 `CampusLife` 后注册。`PERIODS=[morning,afternoon,night]` 与 `PERIOD_NAMES` 统一三个时段，`ACTIONS_PER_PERIOD=3` 可调。`spend_action()` 统一消耗，`rest()` 推进早晨→下午→夜晚→次日早晨。`START_MONTH=10`、`START_DAY=1`，内部累计第1日对应10月1日星期三；`calendar_date()` / `day_for_date()` 在累计日与月日之间换算，`date_label()` 输出月日/星期/时段。当前为无年份常年日历，二月28天，跨年星期继续推进。`PERIOD_HOURS=[8,14,20]` 与旧 `game_hour/minute` 只作内部兼容及记录数据，界面不显示钟点。`due_event()` 按转换后的累计日×3+时段排序，避免跨月和未来时段提前触发。

`player_profile.calendar` 是可选字典，含 `day`、`phase`、`remaining`、`completed` 和 `pending`；旧进度没有该字段也有效。`pending` 记录完整事件与 `line_index`；完成后写入 `completed[id]=true` 并清空待办。Profile 校验通过 `DayCycleService.valid_calendar()`。

`CalendarContent.STORY_DATES` 当前为空，后续由剧本填入唯一 `id`、`month`（1–12）、`day`（月内日期）、`phase=morning/afternoon/night`、`location` 和 `dialogue`，可附 `required_flags` 与 `flags`（布尔字典）。`event_day()` 转成累计日；一月至九月排在初次十二月之后，拒绝无效大小月日期。省略时段默认早晨，旧 `phase=day` 为早晨别名；无 `month` 的旧累计日事件保留读取兼容。地点须存在于 `CampusPlaces.PLACES`，对白须存在于 `PhaseTwoContent.SCRIPTS`，地区须解锁。不要把验收日期写入正式表。

到期事件按时间顺序选取；安全地点自动经 `CampusLife.travel_to()` 前往目的地，再进入 `DialogueScreen`。战斗、训练、回看、日常对白、面板与切场期间等待。`DialogueScreen._calendar_mode` 恢复/保存行号，完成时优先走日历分支，不触发旧章时间跳转；暂离保存后回标题，继续游戏重进待办。`SchoolDialoguePresentation` 优先使用 `SceneDesignCatalog.place_path()` 的当前目的地母图，避免日期对白回退到旧环境；原社团与宿舍的既有分层保持。Home 自由日不任意启动旧章，原副按钮改为休息。旧 `FLOW_STEPS` 与章节兼容代码仍服务旧检查点/回看。

新训练只在创建路线时消费一次，恢复训练与路线内部不重复扣；成功强化由 `PlayerJourney.train()` 扣一次；自习由 `CampusLife` 扣除；普通聊天与阅读/配送查看免费，仍不打断待处理的日期事件。卡组整理、记录与旅行免费。`HomeScreen.artwork_for_period()` 统一三时段的四层 PNG 路径，Home `_refresh_artwork()` 与社团教室日期故事背景共用；夜晚使用浅色文字。素材与提示词见 [三个时段记录](2026-10-18/three_period_home/CURRENT_STATUS.md)。

`SceneManager` 仍保留 `WORLD_MAP`、`EXPLORATION` 的旧路径；`node_map.gd`、`world_map.gd`、`lines_canvas.gd` 和 `ThemePalette` 仍属于可达兼容链。校园地图当前入口由 `CampusLife.open_map()` 处理。没有专门的移除与迁移任务时，保留旧路径。

## 修改与验证

整理页按最新要求不显示当前出战提示和复制当前卡组按钮；应用文案不随草稿脏状态变化，仅按唯一应用状态显示“应用／应用中”，脏状态仍控制应用可用性。见 [控件精简](2026-10-18/loadout_controls/CURRENT_STATUS.md)。

方案身份使用可选的 `player_profile.active_loadout_index`，0–2为唯一应用方案，-1为自定义。`PlayerJourney.save_loadout()` 仅保存候选；`apply_loadout()` 经 `GameState.apply_equipped_deck(ids,index)` 一并提交装备和身份，信号发出时已一致。直接装备变化转为自定义，禁止用数组相同来推断多个“应用中”。旧档无字段时在导入边界选首个匹配方案，已有-1不重新关联。普通战斗读取实际装备，训练使用出发时独立快照，恢复路线不重新取当前装备。见 [方案流程验证](2026-10-18/loadout_application/CURRENT_STATUS.md)。

选项按钮完成自身样式设置后调用 `SchoolObjectUI.set_selected(button, selected)`，使选中项的 hover / hover_pressed 分别与 normal / pressed 同色；文字、图标及公共悬浮调亮遵守相同规则。动态开关状态变化时再次调用，取消选择会恢复原有悬浮样式。保留按下反馈及键盘操作，不用禁用代替选中。见 [悬浮规则验收](2026-10-18/selected_hover/CURRENT_STATUS.md)。

现有本地 Godot MCP 通过 `.mcp.json` 配置。使用同一编辑器；`.gd` 使用 `script_edit`/`script_write` 并 `script_check`，场景通过 MCP 场景工具编辑。连接适配器是 `tools/visual_review/school_mcp.mjs`，依赖本机 Node/npm 缓存，缓存位置需以实际机器为准。不要另开编辑器或照抄旧文档中的 D 盘可执行文件与工程路径。

界面改动检查相关脚本、当前渲染、真实鼠标/键盘交互及运行日志。按钮无边框需检查 normal/hover/pressed/hover_pressed/focus，不能只看默认截图。布局需检查四页、滚动、长文和输入热区，不能把视觉移动与输入位置分开。

最新用户明确当前为开发测试阶段，不需保护游玩存档；可以按测试需要重置进度。本轮使用独立 `user://qa_three_periods/` 完成夹具验收，最后在正常路径保存早晨 Home 演示并保留设置。后续优先完成开发与验证，无需反复询问旧存档保护。历史 STATE_BEFORE 仅为当次证据；不要自动恢复旧快照，也不要重放 build/apply/fix/restore 等一次性实施脚本。若以后用户提出保留进度，再按当时的新鲜现场恢复。

存档兼容同时考虑旧卡牌/敌人/角色 ID、可选 profile 字段、暂停主线、暂停训练及安全回看。归档资源前检查直接引用、目录拼接、格式化路径、主题后备与 UID，并保留 SHA256、原路径和恢复方法。运行代码仍有引用时先分类说明，不能仅因“很旧”就搬走。

## 协作记忆

用户指定由 Codex 继续维护。用户质疑某设计、可能尚不清楚原用途时，先说明设计服务的操作场景，再询问是否修改；已经明确的修改继续执行，不重复确认。

保留纯鼠标操作、现有变色反馈、减少动态和存档读取能力；开发存档按最新用户许可处理。新增美术按母图、分层、还原、实机审图推进；自主选择的版本不能写成主创已确认。最新结果写入简洁交接入口，历史过程归档可追溯。
