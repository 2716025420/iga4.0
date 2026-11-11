---
name: fun-in-end-world-dev
description: 开发与审核《地球继续转动》（just-life，目录历史名 FunInEndWorld）的 Godot 校园卡牌、对白、自由探索与界面；定位现行架构、美术约定、存档兼容和实机验证流程。
---

# 地球继续转动 · 项目开发

保留技能名称以兼容原有调用。项目已采用校园题材；目录历史名不代表继续使用末世设定。

从项目根目录读取 `HANDOFF.md`、`docs/CURRENT_DESIGN.md` 和 `docs/DEVELOPMENT_GUIDE.md`。它们是当前交接、美术/交互约定和架构入口；相关近期 `CURRENT_STATUS.md` 提供具体证据。后续用户明确决定优先，不使用历史“风格圣经”覆盖新决定。

- 保留现有未提交成果，先定位和实机核实，沿用公共模块。`HomePanels`、`NotebookUI`、旧地图链与旧标识仍有共享或兼容用途，不按年代删除。
- 剧本定义在 `PhaseTwoContent.SCRIPTS/FLOW_STEPS`，日常地点与短剧情在 `CampusPlaces`，现行数值由 `CardData`、`PlayerJourney` 和战斗服务计算；不要按旧末世技能样例扩展。
- 美术先完整概念，再分层并还原原构图；Home 可适度写实，功能页按物品和心情抽象，避免统一手帐。文字和热区保持实时。角色与正式剧情仍由主创完善。
- 保留按钮鼠标操作、轻微悬浮/按下反馈、键盘操作与减少动态；去除按钮选中/焦点描边。对话继续/结束不能只剩快捷键提示。商店交易和通用悬停介绍已撤回。
- 连接现有 Godot 编辑器。用 MCP 修改/校验 GDScript 和场景；检查实际渲染与输入。测试前新捕获现场、隔离存档，结束恢复当前玩家进度/设置/UI；不要拿旧快照覆盖后来游玩进度或重放历史实施脚本。
- 用户质疑尚未理解用途的设计时，先解释使用场景再询问是否修改；已经明确的决定继续执行，不重复确认。

本文件的版本化副本是 `docs/DEVELOPMENT_SKILL.md`；`.agents/skills/fun-in-end-world-dev/SKILL.md` 是本机生效副本。旧版技能与旧规范只在 `docs/history/` 保留参考。
