# P5 第一、二阶段工程交付 · 2026-10-24

> 历史阶段记录。2026-10-25已替换旧家具层并清理历史截图/一次性脚本；6张概念原图与原验收数据原样保留。当前实现、检查与恢复清单见[场景重置](../../2026-10-25/SCENE_RESET.md)。下文旧验收数字只代表该阶段。

本轮基于远端 main `93f0835` 实施真实代码。任务分支：`codex/p5-six-regions-2026-10-24`。完成的是六地区配置、导航和访问状态底座；三个新学院 Home 均已按主创后续“直接先实装”授权接入分层交互，两剧情地区继续保留明确TEST入口，**没有宣称正式场景美术完成**。

## 运行入口与兼容

社团 Home → 校园地图 → 地区总图，可进入六地区 TEST 导航。阿瑞忒沿用现有校园绘图、地点和社团 Home，额外提供沿海道路、海滩两个 TEST 地区内节点。世界页采用无地理含义的工程列表，不提前决定六地区相对位置。

| 地区 key | Home / 访问落点 | 解锁标记 |
| --- | --- | --- |
| `university_nomos` | `nomos_home_test`，巨树内部小酒馆 | `region_nomos_unlocked` |
| `university_arete` | **原 `club` 社团 Home**，不改原场景或图片 | 随既有起始校园内容开放 |
| `university_agora` | `agora_home_test`，强制劳动集中营集体宿舍 | `region_agora_unlocked` |
| `university_techne` | `techne_home_test`，黑白研究制造室 | `region_techne_unlocked` |
| `region_failed_alliance` | 无 Home，剧情探索入口与地区地图 | `region_failed_alliance_unlocked` |
| `region_iga_church` | 无 Home，剧情探索入口与地区地图 | `region_iga_church_unlocked` |

新的五个剧情解锁标记默认不发放。未来剧本通过现有 `GameState.set_story_flag(key,true)` 开放，不写死章节、日期或开放顺序。自动化测试只在隔离测试存档中设置标记。世界页、地区地图入口、具体地点旅行和 Home 快捷入口均受同一个底层锁定检查；未知地区、跨地区伪造地点、活动训练及模态面板期间的旅行均会拒绝。

首次实际旅行转入地区各自的 **TEST 首次到达页**，不是浏览即访问。状态分为 `arrived` / `completed`；未完成时读档仍回到首次到达页，完成后重访直达学院 Home 或剧情入口。`first_visit_event_id` 目前全为空，`first_visit_started(region_id,event_id)` 留给后续正式剧本接入；当前不自动编造或播放正式首次剧情。

四学院 Home 复用 `HomeScreen` / `CampusScreen`、公共 `PlayerWorkspace`、菜单和日期服务；三处 TEST Home 支持卡牌整理、记录和伙伴交流；按本轮主创反馈已移除休息入口。伙伴交流只显示明确 TEST 的待定内容，不消耗活动、不推进时段、不发奖励；关闭对话恢复入口焦点。操作与地图标签通过 `object_label` / `map_object_label` 各自配置当地代表物品，不改功能接口与存档。两剧情地区以配置提供两个 **TEST 难度 A/B（无数值）**、商店和特殊功能入口。难度入口只显示待定说明，不启动副本、不发奖励、不交易、不消耗活动次数。

旧 `campus`、`resistance`、`sanctuary`、其地点、Home、解锁标记和旧世界绘图均保留。**新失败者同盟 ≠ 旧反抗联盟；新教团 ≠ 旧圣地。** 世界页底部保留历史入口。`club` 等旧校园地点保留原默认归属；仅在明确选择阿瑞忒导航时保存新地区上下文，实现已获主创批准的 Home 共享适配。没有自动迁移全部旧校园或旧组织。

仍使用 SaveManager v1；在原 `player_profile.campus_life` 下增加可选 `region_id`、`region_visits`，不重建状态管理器。无新增字段的旧档有效，错配地区/地点和非法访问状态会被校验拒绝；解锁撤销后的落点回退旧社团并提交安全位置。浏览地图始终保留实际出发地区/地点，Esc 总图→地区地图→实际地点；在地图保存仍恢复真实地点。旅行与观察不改日历/行动；休息和训练沿用现行规则。

## 代码入口

- `scripts/campus/world_region_content.gd`：六地区配置、三处 TEST Home、首次到达页、两剧情地区入口、阿瑞忒海岸节点。
- `region_catalog.gd` / `campus_places.gd`：扩展现有注册表和旧档校验，保留历史配置。
- `campus_life.gd`：统一权限、地区上下文、首次到达、Home 快捷、返回和读档。
- `region_atlas_view.gd` / `region_map_view.gd` / `map_screen.gd`：六地区导航、灰显和标记变化刷新，阿瑞忒复用绘图。
- `campus_screen.gd`：共享 TEST 页及既有整理/记录/菜单接口；未复制四套 Home。后续新增共享 `RegionHomeView` / `RegionHomeLayout` / `HomeObjectButton` 接入三个新Home的透明家具按钮与反馈，`TechneHomeView`保留兼容，沿用同一个 `CampusScreen`、地图与公共功能面板。
- `map_page_geometry.gd`：历史三地区的绘图仅遍历历史注册表，避免新增无几何配置地区影响旧入口。

## 验证与证据

执行方式：

```bash
bash tools/cloud/check.sh
bash tools/cloud/test_p5.sh
# 有 Xvfb / X11 时，实际图形回归；两个尺寸分别运行
DISPLAY=:97 P5_RESOLUTION=1920x1080 P5_CAPTURE_DIR=/tmp/p5-1920 bash tools/cloud/test_p5.sh
DISPLAY=:97 P5_RESOLUTION=1600x900 P5_CAPTURE_DIR=/tmp/p5-1600 bash tools/cloud/test_p5.sh
```

脚本均隔离 XDG 数据/配置/缓存；测试保存到隔离的 `user://p5_tests/`。云端默认命令沙箱禁止 socket，需允许网络执行权限供**现有 MCP 本地监听**使用；测试本身不访问远程服务。图形运行使用 Dummy 音频驱动，避免无声卡环境把 ALSA 初始化误记为游戏错误。

最终结果见 [validation.json](validation.json)。集成测试使用真实自动加载、场景切换、生产校验器和磁盘 JSON I/O。覆盖六地区配置、锁定绕过、剧情标记实时刷新、首次到达保存/续读、键盘完成、重访、四 Home/两剧情地区、浏览与 Esc 返回、跨地区实际出发点、撤销解锁、安全落点、时段不消耗、新 Home 伙伴交流零消耗及鼠标/键盘开关与焦点恢复、旧地区/旧档、卡牌整理/记录、训练暂停恢复和战斗存档/恢复/胜败逃跑结算。

鼠标、Enter、Esc 通过 Godot Viewport 投递真实输入事件验证；并在 Xvfb＋Mesa llvmpipe 的真实 OpenGL 渲染下保存两种尺寸截图。**这是自动化输入与渲染核对，不是人工完整 P6 验收**；战斗结算由测试调用既有结果方法，不代表完整逐回合战斗或所有页面均已人工试玩。测试开启减少动态，图形驱动仅有不支持 VSync 切换的环境 warning。

[1920×1080 截图](https://github.com/2716025420/just-life/tree/b74cbdd/docs/2026-10-24/p5-delivery/screenshots/1920x1080/)与 [1600×900 截图](https://github.com/2716025420/just-life/tree/b74cbdd/docs/2026-10-24/p5-delivery/screenshots/1600x900/)每种尺寸20张，包含世界锁定/开放、四学院 Home、六地区地图、两剧情入口、旧联盟/圣地地图与三个伙伴交流 Home 的物品标签。核对 TEST 页文字、按钮和热区均可见，无新溢出；阿瑞忒沿用画面和旧人物，人物本轮未重做。截图是引擎输出，不是概念图。

## 美术审核及未实现事项

[三个 Home 概念与实施说明](concepts/REVIEW.md)保留原始母图。主创先认可忒克捏高视角与扣图建议，随后授权另外两个场景直接先实装，本轮三景均已接入独立背景＋四个RGBA物品层与实时UI。三景物品专项headless174项、两种运行分辨率各198项通过，48张状态/长日期截图见 [分层及分辨率交付](OBJECT_FEEDBACK.md)。

**六张原始概念PNG均未改动**；[ORIGINALS.json](concepts/ORIGINALS.json)记录路径/原始尺寸/SHA256，已与旧提交逐字节校验。新图层、引擎截图与源图分开存放。源母图1672×941，提取层尺寸各异，均按真实值记录；按1920逻辑画布实装。生成重绘的材质/比例差异、原生1920母图、人物/对白和独立夜景仍待后续完善。

仍未实施：正式解锁/首次剧情、人物与互动内容、三处新 Home 最终美术和两剧情地区正式地图/功能页美术；副本规则、数值、奖励、商店经济、福利账户、博彩和劳动玩法；十二特殊卡数据/分配、势力 Boss、圣人身份、正式序章与完整 P6。后续先完成整页母图审核，再拆层和实机还原。无需为测试入口补造这些内容。
