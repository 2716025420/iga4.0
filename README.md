# Inorganic General Alien（IGA）· just-life

基于 **Godot 4.7.2 stable**（GDScript，1920×1080 设计分辨率，支持 1600×900 与 1600×720 / 20:9 全屏适配）的红月学园都市卡牌对战与剧情冒险工程。

当前最高优先级世界观与全案基线见 [世界观与全案重构设计书](docs/story/2026-11-14-世界观与全案重构设计书.md)，序章／第一章聚焦方案见 [序章与第一章聚焦重构与清理方案](docs/story/2026-11-16-序章与第一章聚焦重构与清理方案.md)。

## 当前已实现核心特性

- **序章与第一章主线闭环（`n0` → `n_find_yang`）**：支持新档直入「樱林解围」、校门非致命终端护盾切磋（`n_gate`）、双层视差电影过场（`dusk_corridor`、`qiufeng_crystal`、`red_moon_finale` 等）、红月超限战（Overclock，切换红月锁定夜战舞台与警戒地坪）与第一章觉醒「#01 白羊座·英雄」母卡；另有标题页及读档页挂载的常驻全解锁测试存档（不覆写磁盘存档）。
- **回合制战术刻印卡与定尺战场 HUD**：实装全部 16 张战术刻印卡（进攻/防护/恢复/支援/反击，1–3 回合冷却），支持桌面数字键 `1–5` 出牌、`Tab` 切目标、`Space/Enter` 结束回合、`H` 开关战报；同伴 3 卡自动触发切入协战（杨子英／柳宇龙／姜梓）、12 星座母卡全局共鸣、同屏最多 3 敌定尺槽位与「信息显示栏 → 图标+数字状态行」双层头顶 HUD。
- **六地区总图、三时段校园循环与功能工作台**：覆盖阿瑞忒、诺莫斯、阿戈拉、忒克捏四大学院（独立 `Home` 与宽屏地标地图）及失败者同盟、IGA 信仰教团两处剧情地区；支持早晨／下午／夜晚三时段切换、16 卡实体地区商店（含「仅未拥有」筛选）、3 套出战方案整理与材料强化工坊、博物馆风《十二星座图鉴》、放映机档案及体育馆多路线「模拟训练」。
- **音频管线**：内置 16 个程序化合成 `.wav` 音效（8 路 SFX 池），并在 [BGM 槽位说明](assets/audio/bgm/README.txt) 预留 6 条外部 `.ogg` 音乐自动淡入淡出路由。

## 文档导航

- 协作与设计规范：[AGENTS.md](AGENTS.md)
- 最新工程交接与验收记录：[HANDOFF.md](HANDOFF.md)
- 现行设计与交互基准：[CURRENT_DESIGN.md](docs/CURRENT_DESIGN.md)
- 代码架构与开发指引：[DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md)
- 云端环境开发说明：[CLOUD_DEVELOPMENT.md](docs/CLOUD_DEVELOPMENT.md)
- 核心设定与剧本纲要：`docs/story/`

## 验证运行

使用隔离回归测试运行器校验 GDScript 缩进、无界面逻辑及 1600×900 / 1600×720 实机渲染（不污染真实玩家 `user://` 存档）：

```bash
python tools/run_godot_tests.py --godot <GODOT_CONSOLE_BIN> --suite all
python tools/run_godot_tests.py --godot <GODOT_CONSOLE_BIN> --suite all --resolution 1600x900 --captures .godot/visual-review
```
