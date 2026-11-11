# 用手机继续 IGA 云端开发

已完成（2026-10-22）：**IGA** 私有环境已发布，访问范围仅限我自己，GitHub 连接器仅选择 `2716025420/just-life`。Godot 4.7.2 stable 在 Linux x86_64 下完成干净缓存首次安装、资源导入及 120 帧无界面启动；验证通过的运行代码基线为 `2bd883b`，七处变量仅补充显式类型。手机打开 Codex → Cloud → IGA 即可发送任务。图形及鼠标/键盘交互仍需在相应功能开发时验证。

目标：家中电脑关闭时，在手机 Codex 中安排开发。运行位置选 **Cloud**；云端任务使用自己的仓库副本，不依赖家中 Windows、Godot MCP 端口或本地浏览器。

## 首次创建环境

在网页版或桌面端的 `Work in > Cloud > Select environment > Create environment` 选择 GitHub 仓库 `2716025420/just-life`。新环境建议命名为 **IGA**，访问范围选择自己。

完整工程使用默认分支 **`main`**；本次上传同时保留 **`codex/cloud-setup-2026-10-22`** 快照分支。首次创建环境选择 `main`，后续任务使用已推送的最新开发分支。

给环境配置助手的说明：

> 为 IGA 配置云端开发环境。读取 AGENTS.md、HANDOFF.md 和 docs/CLOUD_DEVELOPMENT.md，使用 main 分支。运行 bash tools/cloud/setup.sh，安装与本机一致的 Godot 4.7.2 stable，并完成资源导入及无界面启动检查。需要 curl、python3、sha512sum，以及运行 Godot Linux 所需的系统库；只在缺失时补齐。安装脚本需要访问 github.com 及其发布文件重定向域名。不要依赖 Windows 本机、E 盘、Godot MCP 或历史 npm 缓存。展示安装与检查结果，排除错误后发布环境。

安装脚本为 `bash tools/cloud/setup.sh`，后续基础检查为 `bash tools/cloud/check.sh`。引擎保存于已被 Git 排除的 `.godot/cloud-tools/`；资源导入会重建 `.godot` 缓存。安装使用 Godot 官方 4.7.2 stable 发布包，并核对官方 SHA-512 值。不安装 C#/.NET 或导出模板：本项目使用 GDScript，基础开发检查不需要导出游戏。

配置完成后选择 Publish，等待 Environment published，再在手机 Codex 的 Cloud 中选择 **IGA** 开始任务。仅推送 GitHub 不代表 Cloud 环境已创建或测试通过。

## 每次手机任务

可直接发送：

> 继续 IGA 项目，先读 AGENTS.md 和最新 HANDOFF。请完成：〔具体需求〕。运行相关检查，说明完成情况与未验证项，更新交接，并把成果提交推送到任务分支，给我可查看的提交或 PR 链接。

世界观和序章原文已随工程保存在 `docs/story/`。本机 `E:/game-story-design` 的后续修改仍须同步到仓库，云端不会自动读取本机文件。独立的「幕间 · 剧情工作台」不是游戏运行依赖，也不包含在这个游戏工程的上传范围中。

手机可继续提要求并审阅修改。界面、人物和场景任务还需检查实际图像与操作；headless 检查不能证明构图正确，也不能替代试玩。现有 `tools/visual_review/` 中很多脚本依赖本机 MCP 或旧现场，不能直接当成通用云端测试运行。

## 回到电脑后

先确认云端成果已经提交推送，再通过 Git 获取并合并对应任务分支。本地有未提交改动时先保存，不使用强制重置覆盖。家中电脑和云端不是同一份实时目录；每次换工作位置以已推送的提交和最新交接为准。

官方操作入口：[Codex Cloud](https://learn.chatgpt.com/docs/cloud)、[环境配置](https://learn.chatgpt.com/docs/environments/cloud-environments)。
